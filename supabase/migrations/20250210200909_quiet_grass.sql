/*
  # Minimal Database Setup
  
  1. Core Tables
    - admins: For system administrators
    - class_groups: For managing groups
    - group_members: For group membership

  2. Security
    - Row Level Security enabled on all tables
    - Basic policies for admins and group management
*/

-- Drop existing tables
DROP TABLE IF EXISTS shared_materials CASCADE;
DROP TABLE IF EXISTS shared_classes CASCADE;
DROP TABLE IF EXISTS shared_timetables CASCADE;
DROP TABLE IF EXISTS task_completions CASCADE;
DROP TABLE IF EXISTS shared_tasks CASCADE;
DROP TABLE IF EXISTS group_members CASCADE;
DROP TABLE IF EXISTS class_groups CASCADE;
DROP TABLE IF EXISTS admins CASCADE;

-- Drop existing functions
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

-- Enable RLS
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;

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