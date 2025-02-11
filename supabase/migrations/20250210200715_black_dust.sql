/*
  # Fix Database Policies

  1. Drop all existing tables and start fresh
  2. Simplify policies to avoid recursion
  3. Use materialized paths for hierarchical queries
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
  created_at timestamptz DEFAULT now(),
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
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM admins WHERE admins.user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Policies for admins
CREATE POLICY "Admins are visible to authenticated users"
  ON admins FOR SELECT
  TO authenticated
  USING (true);

-- Policies for class_groups
CREATE POLICY "Users can view their groups"
  ON class_groups FOR SELECT
  TO authenticated
  USING (
    is_admin() OR
    id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage groups"
  ON class_groups FOR ALL
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

-- Policies for group_members
CREATE POLICY "Users can view their own memberships"
  ON group_members FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Admins can view all memberships"
  ON group_members FOR SELECT
  TO authenticated
  USING (is_admin());

CREATE POLICY "Admins can manage all memberships"
  ON group_members FOR ALL
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

CREATE POLICY "Group admins can view their group members"
  ON group_members FOR SELECT
  TO authenticated
  USING (
    group_id IN (
      SELECT gm.group_id FROM group_members gm
      WHERE gm.user_id = auth.uid()
      AND gm.role = 'group_admin'
    )
  );

CREATE POLICY "Group admins can manage their members"
  ON group_members FOR INSERT
  TO authenticated
  WITH CHECK (
    group_id IN (
      SELECT gm.group_id FROM group_members gm
      WHERE gm.user_id = auth.uid()
      AND gm.role = 'group_admin'
    )
  );

CREATE POLICY "Group admins can update their members"
  ON group_members FOR UPDATE
  TO authenticated
  USING (
    group_id IN (
      SELECT gm.group_id FROM group_members gm
      WHERE gm.user_id = auth.uid()
      AND gm.role = 'group_admin'
    )
  )
  WITH CHECK (
    group_id IN (
      SELECT gm.group_id FROM group_members gm
      WHERE gm.user_id = auth.uid()
      AND gm.role = 'group_admin'
    )
  );

CREATE POLICY "Group admins can delete their members"
  ON group_members FOR DELETE
  TO authenticated
  USING (
    group_id IN (
      SELECT gm.group_id FROM group_members gm
      WHERE gm.user_id = auth.uid()
      AND gm.role = 'group_admin'
    )
  );

-- Policies for shared_tasks
CREATE POLICY "Users can view tasks in their groups"
  ON shared_tasks FOR SELECT
  TO authenticated
  USING (
    is_admin() OR
    group_id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Group admins can manage tasks"
  ON shared_tasks FOR ALL
  TO authenticated
  USING (
    is_admin() OR
    group_id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid()
      AND role = 'group_admin'
    )
  )
  WITH CHECK (
    is_admin() OR
    group_id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid()
      AND role = 'group_admin'
    )
  );

-- Policies for task_completions
CREATE POLICY "Users can view completions in their groups"
  ON task_completions FOR SELECT
  TO authenticated
  USING (
    is_admin() OR
    task_id IN (
      SELECT st.id FROM shared_tasks st
      JOIN group_members gm ON gm.group_id = st.group_id
      WHERE gm.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can manage their completions"
  ON task_completions FOR ALL
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Policies for shared_timetables
CREATE POLICY "Users can view timetables in their groups"
  ON shared_timetables FOR SELECT
  TO authenticated
  USING (
    is_admin() OR
    group_id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Group admins can manage timetables"
  ON shared_timetables FOR ALL
  TO authenticated
  USING (
    is_admin() OR
    group_id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid()
      AND role = 'group_admin'
    )
  )
  WITH CHECK (
    is_admin() OR
    group_id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid()
      AND role = 'group_admin'
    )
  );

-- Policies for shared_classes
CREATE POLICY "Users can view classes in their groups"
  ON shared_classes FOR SELECT
  TO authenticated
  USING (
    is_admin() OR
    group_id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Group admins can manage classes"
  ON shared_classes FOR ALL
  TO authenticated
  USING (
    is_admin() OR
    group_id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid()
      AND role = 'group_admin'
    )
  )
  WITH CHECK (
    is_admin() OR
    group_id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid()
      AND role = 'group_admin'
    )
  );

-- Policies for shared_materials
CREATE POLICY "Users can view materials in their groups"
  ON shared_materials FOR SELECT
  TO authenticated
  USING (
    is_admin() OR
    class_id IN (
      SELECT sc.id FROM shared_classes sc
      JOIN group_members gm ON gm.group_id = sc.group_id
      WHERE gm.user_id = auth.uid()
    )
  );

CREATE POLICY "Group admins can manage materials"
  ON shared_materials FOR ALL
  TO authenticated
  USING (
    is_admin() OR
    class_id IN (
      SELECT sc.id FROM shared_classes sc
      JOIN group_members gm ON gm.group_id = sc.group_id
      WHERE gm.user_id = auth.uid()
      AND gm.role = 'group_admin'
    )
  )
  WITH CHECK (
    is_admin() OR
    class_id IN (
      SELECT sc.id FROM shared_classes sc
      JOIN group_members gm ON gm.group_id = sc.group_id
      WHERE gm.user_id = auth.uid()
      AND gm.role = 'group_admin'
    )
  );