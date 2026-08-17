-- ==============================================================================
-- MIGRATION 02: REFACTOR DB FROM TASK-CENTRIC TO PROJECT MANAGEMENT
-- ==============================================================================
-- Hierarchy Shift:
-- 1. `projects` (formerly `tasks`): Top-level project entity per workspace
-- 2. `project_goals` (formerly `task_goals`): Goals / Tasks inside a project ("goals = task") with assignees per task
-- 3. `project_invitations` (formerly `task_invitations`): Invitations to join a project
-- 4. `project_comments` (formerly `task_comments`): Comments belonging to a project
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. RENAME TABLES & COLUMNS (SAFE & IDEMPOTENT)
-- ------------------------------------------------------------------------------

-- 1.1 Rename `tasks` table to `projects`
ALTER TABLE IF EXISTS public.tasks RENAME TO projects;

-- 1.2 Rename `task_goals` table to `project_goals`
ALTER TABLE IF EXISTS public.task_goals RENAME TO project_goals;

-- 1.3 Rename `task_invitations` table to `project_invitations`
ALTER TABLE IF EXISTS public.task_invitations RENAME TO project_invitations;

-- 1.4 Rename `task_comments` table to `project_comments`
ALTER TABLE IF EXISTS public.task_comments RENAME TO project_comments;

-- Rename foreign key columns safely if they haven't been renamed yet
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'project_goals' AND column_name = 'task_id'
    ) THEN
        ALTER TABLE public.project_goals RENAME COLUMN task_id TO project_id;
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'project_invitations' AND column_name = 'task_id'
    ) THEN
        ALTER TABLE public.project_invitations RENAME COLUMN task_id TO project_id;
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'project_comments' AND column_name = 'task_id'
    ) THEN
        ALTER TABLE public.project_comments RENAME COLUMN task_id TO project_id;
    END IF;
END $$;

-- Add task-specific fields to `project_goals` (goals = tasks)
ALTER TABLE public.project_goals ADD COLUMN IF NOT EXISTS assignee_ids UUID[] DEFAULT '{}';
ALTER TABLE public.project_goals ADD COLUMN IF NOT EXISTS status public.task_status NOT NULL DEFAULT 'todo';
ALTER TABLE public.project_goals ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.project_goals ADD COLUMN IF NOT EXISTS position INT NOT NULL DEFAULT 0;
ALTER TABLE public.project_goals ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();
ALTER TABLE public.project_goals DROP COLUMN IF EXISTS project_name;

-- ------------------------------------------------------------------------------
-- 2. UPDATE PERFORMANCE INDEXES
-- ------------------------------------------------------------------------------
DROP INDEX IF EXISTS idx_tasks_workspace_status;
DROP INDEX IF EXISTS idx_tasks_position;
DROP INDEX IF EXISTS idx_goals_task;
DROP INDEX IF EXISTS idx_comments_task;
DROP INDEX IF EXISTS idx_task_invitations_token;
DROP INDEX IF EXISTS idx_task_invitations_task_id;

CREATE INDEX IF NOT EXISTS idx_projects_workspace_status ON public.projects (workspace_id, status);
CREATE INDEX IF NOT EXISTS idx_projects_position ON public.projects (position);
CREATE INDEX IF NOT EXISTS idx_project_goals_project ON public.project_goals (project_id);
CREATE INDEX IF NOT EXISTS idx_project_comments_project ON public.project_comments (project_id);
CREATE INDEX IF NOT EXISTS idx_project_invitations_token ON public.project_invitations (token);
CREATE INDEX IF NOT EXISTS idx_project_invitations_project_id ON public.project_invitations (project_id);

-- ------------------------------------------------------------------------------
-- 3. ENABLE ROW LEVEL SECURITY (RLS) & POLICIES
-- ------------------------------------------------------------------------------
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_invitations ENABLE ROW LEVEL SECURITY;

-- Clean up old policies
DROP POLICY IF EXISTS "Allow authenticated users to read tasks" ON public.projects;
DROP POLICY IF EXISTS "Allow authenticated users to insert tasks" ON public.projects;
DROP POLICY IF EXISTS "Allow authenticated users to update tasks" ON public.projects;
DROP POLICY IF EXISTS "Allow authenticated users to delete tasks" ON public.projects;

DROP POLICY IF EXISTS "Allow authenticated users to read goals" ON public.project_goals;
DROP POLICY IF EXISTS "Allow authenticated users to insert goals" ON public.project_goals;
DROP POLICY IF EXISTS "Allow authenticated users to update goals" ON public.project_goals;
DROP POLICY IF EXISTS "Allow authenticated users to delete goals" ON public.project_goals;

DROP POLICY IF EXISTS "Allow authenticated users to read comments" ON public.project_comments;
DROP POLICY IF EXISTS "Allow authenticated users to insert comments" ON public.project_comments;

DROP POLICY IF EXISTS "Allow authenticated users to read active invitations" ON public.project_invitations;
DROP POLICY IF EXISTS "Allow authenticated users to insert invitations" ON public.project_invitations;
DROP POLICY IF EXISTS "Allow inviter to update invitations" ON public.project_invitations;

-- Create Policies for `projects`
DROP POLICY IF EXISTS "Allow authenticated users to read projects" ON public.projects;
CREATE POLICY "Allow authenticated users to read projects" 
ON public.projects FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow authenticated users to insert projects" ON public.projects;
CREATE POLICY "Allow authenticated users to insert projects" 
ON public.projects FOR INSERT TO authenticated WITH CHECK (auth.uid() = created_by OR created_by IS NULL);

DROP POLICY IF EXISTS "Allow authenticated users to update projects" ON public.projects;
CREATE POLICY "Allow authenticated users to update projects" 
ON public.projects FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow authenticated users to delete projects" ON public.projects;
CREATE POLICY "Allow authenticated users to delete projects" 
ON public.projects FOR DELETE TO authenticated USING (auth.uid() = created_by OR created_by IS NULL);

-- Create Policies for `project_goals` (Tasks)
DROP POLICY IF EXISTS "Allow authenticated users to read project_goals" ON public.project_goals;
CREATE POLICY "Allow authenticated users to read project_goals" 
ON public.project_goals FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow authenticated users to insert project_goals" ON public.project_goals;
CREATE POLICY "Allow authenticated users to insert project_goals" 
ON public.project_goals FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Allow authenticated users to update project_goals" ON public.project_goals;
CREATE POLICY "Allow authenticated users to update project_goals" 
ON public.project_goals FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow authenticated users to delete project_goals" ON public.project_goals;
CREATE POLICY "Allow authenticated users to delete project_goals" 
ON public.project_goals FOR DELETE TO authenticated USING (true);

-- Create Policies for `project_comments`
DROP POLICY IF EXISTS "Allow authenticated users to read project_comments" ON public.project_comments;
CREATE POLICY "Allow authenticated users to read project_comments" 
ON public.project_comments FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow authenticated users to insert project_comments" ON public.project_comments;
CREATE POLICY "Allow authenticated users to insert project_comments" 
ON public.project_comments FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

-- Create Policies for `project_invitations`
DROP POLICY IF EXISTS "Allow authenticated users to read active project_invitations" ON public.project_invitations;
CREATE POLICY "Allow authenticated users to read active project_invitations" 
ON public.project_invitations FOR SELECT TO authenticated USING (is_active = true);

DROP POLICY IF EXISTS "Allow authenticated users to insert project_invitations" ON public.project_invitations;
CREATE POLICY "Allow authenticated users to insert project_invitations" 
ON public.project_invitations FOR INSERT TO authenticated WITH CHECK (auth.uid() = inviter_id);

DROP POLICY IF EXISTS "Allow inviter to update project_invitations" ON public.project_invitations;
CREATE POLICY "Allow inviter to update project_invitations" 
ON public.project_invitations FOR UPDATE TO authenticated USING (auth.uid() = inviter_id);

-- ------------------------------------------------------------------------------
-- 4. REALTIME ENGINE PUBLICATION UPDATE (IDEMPOTENT & SAFE)
-- ------------------------------------------------------------------------------
DO $$
DECLARE
    tbl_name TEXT;
    tbl_array TEXT[] := ARRAY['projects', 'project_goals', 'project_comments', 'project_invitations'];
BEGIN
    FOREACH tbl_name IN ARRAY tbl_array LOOP
        IF EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name = tbl_name
        ) AND NOT EXISTS (
            SELECT 1 
            FROM pg_publication_rel pr
            JOIN pg_class c ON pr.prrelid = c.oid
            JOIN pg_publication p ON pr.prpubid = p.oid
            WHERE p.pubname = 'supabase_realtime' 
              AND c.relname = tbl_name
        ) THEN
            EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', tbl_name);
        END IF;
    END LOOP;
END $$;

-- ------------------------------------------------------------------------------
-- 5. STORED PROCEDURE (RPC): CLAIM / ACCEPT PROJECT INVITATION
-- ------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.accept_task_invitation(TEXT);

CREATE OR REPLACE FUNCTION public.accept_project_invitation(p_token TEXT)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    project_id UUID
) AS $$
DECLARE
    v_invitation public.project_invitations%ROWTYPE;
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN QUERY SELECT false, 'User not authenticated'::TEXT, NULL::UUID;
        RETURN;
    END IF;

    -- Find active invitation
    SELECT * INTO v_invitation
    FROM public.project_invitations
    WHERE token = p_token AND is_active = true;

    IF v_invitation.id IS NULL THEN
        RETURN QUERY SELECT false, 'Invitation token is invalid or deactivated'::TEXT, NULL::UUID;
        RETURN;
    END IF;

    -- Check expiration
    IF v_invitation.expires_at IS NOT NULL AND v_invitation.expires_at < now() THEN
        RETURN QUERY SELECT false, 'Invitation link has expired'::TEXT, NULL::UUID;
        RETURN;
    END IF;

    RETURN QUERY SELECT true, 'Successfully joined project'::TEXT, v_invitation.project_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
