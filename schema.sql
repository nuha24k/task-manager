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

-- 4. Create Performance Indexes
CREATE INDEX idx_tasks_workspace_status ON public.tasks (workspace_id, status);
CREATE INDEX idx_tasks_position ON public.tasks (position);
CREATE INDEX idx_comments_task ON public.task_comments (task_id);

-- 5. Enable Row Level Security (RLS)
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_comments ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies for Tasks
CREATE POLICY "Allow authenticated users to read tasks" 
ON public.tasks FOR SELECT 
TO authenticated 
USING (true);

CREATE POLICY "Allow authenticated users to insert tasks" 
ON public.tasks FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Allow authenticated users to update tasks" 
ON public.tasks FOR UPDATE 
TO authenticated 
USING (true);

CREATE POLICY "Allow authenticated users to delete tasks" 
ON public.tasks FOR DELETE 
TO authenticated 
USING (auth.uid() = created_by);

-- 7. RLS Policies for Task Comments
CREATE POLICY "Allow authenticated users to read comments" 
ON public.task_comments FOR SELECT 
TO authenticated 
USING (true);

CREATE POLICY "Allow authenticated users to insert comments" 
ON public.task_comments FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = user_id);

-- 8. Enable Realtime Engine for Tasks & Comments Tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.tasks;
ALTER PUBLICATION supabase_realtime ADD TABLE public.task_comments;
