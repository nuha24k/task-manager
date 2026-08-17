-- ==============================================================================
-- MIGRATION: TASK INVITATIONS TABLE & ACCEPTANCE RPC
-- ==============================================================================

-- 1. Create Task Invitations Table
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

-- 2. Create Index on Token
CREATE INDEX IF NOT EXISTS idx_task_invitations_token ON public.task_invitations (token);
CREATE INDEX IF NOT EXISTS idx_task_invitations_task_id ON public.task_invitations (task_id);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.task_invitations ENABLE ROW LEVEL SECURITY;

-- RLS Policies for task_invitations
DROP POLICY IF EXISTS "Allow authenticated users to read active invitations" ON public.task_invitations;
DROP POLICY IF EXISTS "Allow authenticated users to insert invitations" ON public.task_invitations;
DROP POLICY IF EXISTS "Allow inviter to update invitations" ON public.task_invitations;

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

-- 4. Enable Realtime Engine for Task Invitations Table
ALTER PUBLICATION supabase_realtime ADD TABLE public.task_invitations;

-- 5. Stored Procedure (RPC) to Claim/Accept Task Invitation
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
