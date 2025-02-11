/*
  # Fix Database Schema and Policies

  1. Drop everything and rebuild from scratch
  2. Fix group member policies to avoid recursion
  3. Simplify policy structure
*/

-- Drop everything first
DROP TABLE IF EXISTS shared_materials CASCADE;
DROP TABLE IF EXISTS shared_classes CASCADE;
DROP TABLE IF EXISTS shared_timetables CASCADE;
DROP TABLE IF EXISTS task_completions CASCADE;
DROP TABLE IF EXISTS shared_tasks CASCADE;
DROP TABLE IF EXISTS group_members CASCADE;
DROP TABLE IF EXISTS class_groups CASCADE;
DROP TABLE IF EXISTS admins CASCADE;

DROP FUNCTION IF EXISTS is_admin CASCADE;
DROP FUNCTION IF EXISTS check_group_admin_access CASCADE;

-- Create Tables
CREATE TABLE admins (
  user_id uuid PRIMARY KEY REFERENCES auth.users,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE class_groups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  created_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users NOT NULL
);

CREATE TABLE group_members (
  group_id uuid REFERENCES class_groups ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('student', 'group_admin')),
  PRIMARY KEY (group_id, user_id)
);

CREATE TABLE shared_tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid REFERENCES class_groups ON DELETE CASCADE,
  class text NOT NULL,
  description text NOT NULL,
  due_date timestamptz,
  created_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users
);

CREATE TABLE task_completions (
  task_id uuid REFERENCES shared_tasks ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users ON DELETE CASCADE,
  completed_at timestamptz DEFAULT now(),
  PRIMARY KEY (task_id, user_id)
);

CREATE TABLE shared_timetables (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid REFERENCES class_groups ON DELETE CASCADE,
  day text NOT NULL,
  time text NOT NULL,
  class text NOT NULL
);

CREATE TABLE shared_classes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid REFERENCES class_groups ON DELETE CASCADE,
  name text NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE shared_materials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id uuid REFERENCES shared_classes ON DELETE CASCADE,
  name text NOT NULL,
  type text NOT NULL CHECK (type IN ('book', 'workbook', 'other'))
);

-- Enable RLS
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_timetables ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_materials ENABLE ROW LEVEL SECURITY;

-- Helper Functions
CREATE OR REPLACE FUNCTION is_admin(user_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM admins WHERE admins.user_id = $1
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Policies for admins table
CREATE POLICY "Admins are visible to all authenticated users"
  ON admins
  FOR SELECT
  TO authenticated
  USING (true);

-- Policies for class_groups
CREATE POLICY "Users can view their groups"
  ON class_groups
  FOR SELECT
  TO authenticated
  USING (
    is_admin(auth.uid()) OR
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = id
      AND group_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage groups"
  ON class_groups
  FOR ALL
  TO authenticated
  USING (is_admin(auth.uid()))
  WITH CHECK (is_admin(auth.uid()));

-- Simplified group_members policies
CREATE POLICY "Users can view group members"
  ON group_members
  FOR SELECT
  TO authenticated
  USING (
    is_admin(auth.uid()) OR
    user_id = auth.uid() OR
    group_id IN (
      SELECT gm.group_id 
      FROM group_members gm 
      WHERE gm.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage members"
  ON group_members
  FOR ALL
  TO authenticated
  USING (is_admin(auth.uid()))
  WITH CHECK (is_admin(auth.uid()));

CREATE POLICY "Group admins can manage members"
  ON group_members
  FOR ALL
  TO authenticated
  USING (
    group_id IN (
      SELECT gm.group_id 
      FROM group_members gm 
      WHERE gm.user_id = auth.uid() 
      AND gm.role = 'group_admin'
    )
  )
  WITH CHECK (
    group_id IN (
      SELECT gm.group_id 
      FROM group_members gm 
      WHERE gm.user_id = auth.uid() 
      AND gm.role = 'group_admin'
    )
  );

-- Policies for shared_tasks
CREATE POLICY "Users can view tasks in their groups"
  ON shared_tasks
  FOR SELECT
  TO authenticated
  USING (
    is_admin(auth.uid()) OR
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = shared_tasks.group_id
      AND group_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Group admins can manage tasks"
  ON shared_tasks
  FOR ALL
  TO authenticated
  USING (
    is_admin(auth.uid()) OR
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = shared_tasks.group_id
      AND group_members.user_id = auth.uid()
      AND group_members.role = 'group_admin'
    )
  )
  WITH CHECK (
    is_admin(auth.uid()) OR
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = shared_tasks.group_id
      AND group_members.user_id = auth.uid()
      AND group_members.role = 'group_admin'
    )
  );

-- Policies for task_completions
CREATE POLICY "Users can view task completions in their groups"
  ON task_completions
  FOR SELECT
  TO authenticated
  USING (
    is_admin(auth.uid()) OR
    EXISTS (
      SELECT 1 FROM shared_tasks
      JOIN group_members ON group_members.group_id = shared_tasks.group_id
      WHERE shared_tasks.id = task_completions.task_id
      AND group_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can manage their own task completions"
  ON task_completions
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policies for shared_timetables
CREATE POLICY "Users can view timetables in their groups"
  ON shared_timetables
  FOR SELECT
  TO authenticated
  USING (
    is_admin(auth.uid()) OR
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = shared_timetables.group_id
      AND group_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Group admins can manage timetables"
  ON shared_timetables
  FOR ALL
  TO authenticated
  USING (
    is_admin(auth.uid()) OR
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = shared_timetables.group_id
      AND group_members.user_id = auth.uid()
      AND group_members.role = 'group_admin'
    )
  )
  WITH CHECK (
    is_admin(auth.uid()) OR
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = shared_timetables.group_id
      AND group_members.user_id = auth.uid()
      AND group_members.role = 'group_admin'
    )
  );

-- Policies for shared_classes
CREATE POLICY "Users can view classes in their groups"
  ON shared_classes
  FOR SELECT
  TO authenticated
  USING (
    is_admin(auth.uid()) OR
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = shared_classes.group_id
      AND group_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Group admins can manage classes"
  ON shared_classes
  FOR ALL
  TO authenticated
  USING (
    is_admin(auth.uid()) OR
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = shared_classes.group_id
      AND group_members.user_id = auth.uid()
      AND group_members.role = 'group_admin'
    )
  )
  WITH CHECK (
    is_admin(auth.uid()) OR
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = shared_classes.group_id
      AND group_members.user_id = auth.uid()
      AND group_members.role = 'group_admin'
    )
  );

-- Policies for shared_materials
CREATE POLICY "Users can view materials of classes in their groups"
  ON shared_materials
  FOR SELECT
  TO authenticated
  USING (
    is_admin(auth.uid()) OR
    EXISTS (
      SELECT 1 FROM shared_classes
      JOIN group_members ON group_members.group_id = shared_classes.group_id
      WHERE shared_classes.id = shared_materials.class_id
      AND group_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Group admins can manage materials"
  ON shared_materials
  FOR ALL
  TO authenticated
  USING (
    is_admin(auth.uid()) OR
    EXISTS (
      SELECT 1 FROM shared_classes
      JOIN group_members ON group_members.group_id = shared_classes.group_id
      WHERE shared_classes.id = shared_materials.class_id
      AND group_members.user_id = auth.uid()
      AND group_members.role = 'group_admin'
    )
  )
  WITH CHECK (
    is_admin(auth.uid()) OR
    EXISTS (
      SELECT 1 FROM shared_classes
      JOIN group_members ON group_members.group_id = shared_classes.group_id
      WHERE shared_classes.id = shared_materials.class_id
      AND group_members.user_id = auth.uid()
      AND group_members.role = 'group_admin'
    )
  );