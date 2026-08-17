-- ==============================================================================
-- TASKFLOW SUPABASE DATABASE SCHEMA MIGRATION, RLS POLICIES & SEED DATA
-- CONCEPT: PROJECT MANAGEMENT (Project -> Goals/Tasks -> Invitations -> Task Assignees)
-- ==============================================================================

-- 1. Create Enums
CREATE TYPE public.task_status AS ENUM ('todo', 'in_progress', 'done');
CREATE TYPE public.task_priority AS ENUM ('low', 'medium', 'high');

-- 2. Create Projects Table
CREATE TABLE public.projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    status public.task_status NOT NULL DEFAULT 'todo',
    priority public.task_priority NOT NULL DEFAULT 'medium',
    position INT NOT NULL DEFAULT 0,
    progress DOUBLE PRECISION DEFAULT 0.0,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Create Project Goals Table (Goals = Tasks per Project)
CREATE TABLE public.project_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    status public.task_status NOT NULL DEFAULT 'todo',
    priority public.task_priority NOT NULL DEFAULT 'medium',
    assignee_ids UUID[] DEFAULT '{}',
    is_completed BOOLEAN NOT NULL DEFAULT false,
    due_date TIMESTAMPTZ,
    position INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 4. Create Project Comments Table
CREATE TABLE public.project_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 5. Create Project Invitations Table
CREATE TABLE public.project_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    inviter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    token TEXT UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(16), 'hex'),
    role TEXT NOT NULL DEFAULT 'editor',
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 6. Create Performance Indexes
CREATE INDEX idx_projects_workspace_status ON public.projects (workspace_id, status);
CREATE INDEX idx_projects_position ON public.projects (position);
CREATE INDEX idx_project_goals_project ON public.project_goals (project_id);
CREATE INDEX idx_project_comments_project ON public.project_comments (project_id);
CREATE INDEX idx_project_invitations_token ON public.project_invitations (token);
CREATE INDEX idx_project_invitations_project_id ON public.project_invitations (project_id);

-- 7. Enable Row Level Security (RLS)
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_invitations ENABLE ROW LEVEL SECURITY;

-- 8. RLS Policies for Projects
CREATE POLICY "Allow authenticated users to read projects" 
ON public.projects FOR SELECT 
TO authenticated 
USING (true);

CREATE POLICY "Allow authenticated users to insert projects" 
ON public.projects FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = created_by OR created_by IS NULL);

CREATE POLICY "Allow authenticated users to update projects" 
ON public.projects FOR UPDATE 
TO authenticated 
USING (true);

CREATE POLICY "Allow authenticated users to delete projects" 
ON public.projects FOR DELETE 
TO authenticated 
USING (auth.uid() = created_by OR created_by IS NULL);

-- 9. RLS Policies for Project Goals (Tasks)
CREATE POLICY "Allow authenticated users to read project_goals" 
ON public.project_goals FOR SELECT 
TO authenticated 
USING (true);

CREATE POLICY "Allow authenticated users to insert project_goals" 
ON public.project_goals FOR INSERT 
TO authenticated 
WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update project_goals" 
ON public.project_goals FOR UPDATE 
TO authenticated 
USING (true);

CREATE POLICY "Allow authenticated users to delete project_goals" 
ON public.project_goals FOR DELETE 
TO authenticated 
USING (true);

-- 10. RLS Policies for Project Comments
CREATE POLICY "Allow authenticated users to read project_comments" 
ON public.project_comments FOR SELECT 
TO authenticated 
USING (true);

CREATE POLICY "Allow authenticated users to insert project_comments" 
ON public.project_comments FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = user_id);

-- 11. RLS Policies for Project Invitations
CREATE POLICY "Allow authenticated users to read active project_invitations" 
ON public.project_invitations FOR SELECT 
TO authenticated 
USING (is_active = true);

CREATE POLICY "Allow authenticated users to insert project_invitations" 
ON public.project_invitations FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = inviter_id);

CREATE POLICY "Allow inviter to update project_invitations" 
ON public.project_invitations FOR UPDATE 
TO authenticated 
USING (auth.uid() = inviter_id);

-- 12. Enable Realtime Engine
ALTER PUBLICATION supabase_realtime ADD TABLE public.projects;
ALTER PUBLICATION supabase_realtime ADD TABLE public.project_goals;
ALTER PUBLICATION supabase_realtime ADD TABLE public.project_comments;
ALTER PUBLICATION supabase_realtime ADD TABLE public.project_invitations;

-- 13. Stored Procedure (RPC) to Claim/Accept Project Invitation
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
