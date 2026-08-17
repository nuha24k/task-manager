-- ==============================================================================
-- TASKFLOW SUPABASE DATABASE SCHEMA MIGRATION, RLS POLICIES & SEED DATA
-- ==============================================================================

-- 1. Create Enums
CREATE TYPE public.task_status AS ENUM ('todo', 'in_progress', 'done');
CREATE TYPE public.task_priority AS ENUM ('low', 'medium', 'high');

-- 2. Create Tasks Table
CREATE TABLE public.tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    status public.task_status NOT NULL DEFAULT 'todo',
    priority public.task_priority NOT NULL DEFAULT 'medium',
    assignee_ids UUID[] DEFAULT '{}',
    due_date TIMESTAMPTZ,
    position INT NOT NULL DEFAULT 0,
    progress DOUBLE PRECISION DEFAULT 0.0,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Create Task Comments Table
CREATE TABLE public.task_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3.5. Create Task Goals Table
CREATE TABLE public.task_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    project_name TEXT DEFAULT 'Charty App',
    priority public.task_priority NOT NULL DEFAULT 'medium',
    is_completed BOOLEAN NOT NULL DEFAULT false,
    due_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. Create Performance Indexes
CREATE INDEX idx_tasks_workspace_status ON public.tasks (workspace_id, status);
CREATE INDEX idx_tasks_position ON public.tasks (position);
CREATE INDEX idx_comments_task ON public.task_comments (task_id);
CREATE INDEX idx_goals_task ON public.task_goals (task_id);

-- 5. Enable Row Level Security (RLS)
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_goals ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies for Tasks
DROP POLICY IF EXISTS "Allow authenticated users to read tasks" ON public.tasks;
DROP POLICY IF EXISTS "Allow authenticated users to insert tasks" ON public.tasks;
DROP POLICY IF EXISTS "Allow authenticated users to update tasks" ON public.tasks;
DROP POLICY IF EXISTS "Allow authenticated users to delete tasks" ON public.tasks;

CREATE POLICY "Allow authenticated users to read tasks" 
ON public.tasks FOR SELECT 
TO authenticated 
USING (true);

CREATE POLICY "Allow authenticated users to insert tasks" 
ON public.tasks FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = created_by OR created_by IS NULL);

CREATE POLICY "Allow authenticated users to update tasks" 
ON public.tasks FOR UPDATE 
TO authenticated 
USING (true);

CREATE POLICY "Allow authenticated users to delete tasks" 
ON public.tasks FOR DELETE 
TO authenticated 
USING (auth.uid() = created_by OR created_by IS NULL);

-- 7. RLS Policies for Task Comments
DROP POLICY IF EXISTS "Allow authenticated users to read comments" ON public.task_comments;
DROP POLICY IF EXISTS "Allow authenticated users to insert comments" ON public.task_comments;

CREATE POLICY "Allow authenticated users to read comments" 
ON public.task_comments FOR SELECT 
TO authenticated 
USING (true);

CREATE POLICY "Allow authenticated users to insert comments" 
ON public.task_comments FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = user_id);

-- 8. RLS Policies for Task Goals
DROP POLICY IF EXISTS "Allow authenticated users to read goals" ON public.task_goals;
DROP POLICY IF EXISTS "Allow authenticated users to insert goals" ON public.task_goals;
DROP POLICY IF EXISTS "Allow authenticated users to update goals" ON public.task_goals;
DROP POLICY IF EXISTS "Allow authenticated users to delete goals" ON public.task_goals;

CREATE POLICY "Allow authenticated users to read goals" 
ON public.task_goals FOR SELECT 
TO authenticated 
USING (true);

CREATE POLICY "Allow authenticated users to insert goals" 
ON public.task_goals FOR INSERT 
TO authenticated 
WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update goals" 
ON public.task_goals FOR UPDATE 
TO authenticated 
USING (true);

CREATE POLICY "Allow authenticated users to delete goals" 
ON public.task_goals FOR DELETE 
TO authenticated 
USING (true);

-- 9. Enable Realtime Engine for Tasks, Comments & Goals Tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.tasks;
ALTER PUBLICATION supabase_realtime ADD TABLE public.task_comments;
ALTER PUBLICATION supabase_realtime ADD TABLE public.task_goals;

-- 10. Task Invitations Table & Policies
CREATE TABLE IF NOT EXISTS public.task_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
    inviter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    token TEXT UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(16), 'hex'),
    role TEXT NOT NULL DEFAULT 'editor',
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_task_invitations_token ON public.task_invitations (token);
CREATE INDEX IF NOT EXISTS idx_task_invitations_task_id ON public.task_invitations (task_id);

ALTER TABLE public.task_invitations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated users to read active invitations" 
ON public.task_invitations FOR SELECT 
TO authenticated 
USING (is_active = true);

CREATE POLICY "Allow authenticated users to insert invitations" 
ON public.task_invitations FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = inviter_id);

CREATE POLICY "Allow inviter to update invitations" 
ON public.task_invitations FOR UPDATE 
TO authenticated 
USING (auth.uid() = inviter_id);

ALTER PUBLICATION supabase_realtime ADD TABLE public.task_invitations;

-- 11. Stored Procedure (RPC) to Claim/Accept Task Invitation
CREATE OR REPLACE FUNCTION public.accept_task_invitation(p_token TEXT)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    task_id UUID
) AS $$
DECLARE
    v_invitation public.task_invitations%ROWTYPE;
    v_user_id UUID;
    v_assignees UUID[];
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN QUERY SELECT false, 'User not authenticated'::TEXT, NULL::UUID;
        RETURN;
    END IF;

    -- Find active invitation
    SELECT * INTO v_invitation
    FROM public.task_invitations
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

    -- Check if user is already an assignee
    SELECT assignee_ids INTO v_assignees
    FROM public.tasks
    WHERE id = v_invitation.task_id;

    IF v_user_id = ANY(COALESCE(v_assignees, '{}')) THEN
        RETURN QUERY SELECT true, 'Already a member of this task'::TEXT, v_invitation.task_id;
        RETURN;
    END IF;

    -- Add user_id to assignee_ids array on tasks table
    UPDATE public.tasks
    SET assignee_ids = array_append(COALESCE(assignee_ids, '{}'), v_user_id),
        updated_at = now()
    WHERE id = v_invitation.task_id;

    RETURN QUERY SELECT true, 'Successfully joined task'::TEXT, v_invitation.task_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


