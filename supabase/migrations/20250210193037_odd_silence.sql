/*
  # Add admin roles and permissions

  1. New Tables
    - `admins` - Stores system-wide administrators
      - `user_id` (uuid, references auth.users)
      - `created_at` (timestamp)

  2. New Policies
    - Allow admins to create and manage class groups
    - Allow group admins to manage their groups
    - Allow users to manage tasks in their groups

  3. Changes
    - Add admin check functions
    - Add group admin role
*/

-- Create admins table
CREATE TABLE IF NOT EXISTS admins (
  user_id uuid PRIMARY KEY REFERENCES auth.users,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;

-- Admin policies
CREATE POLICY "Admins are visible to all authenticated users"
  ON admins
  FOR SELECT
  TO authenticated
  USING (true);

-- Helper functions
CREATE OR REPLACE FUNCTION is_admin(user_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM admins
    WHERE admins.user_id = $1
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION is_group_admin(user_id uuid, group_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM group_members
    WHERE group_members.user_id = $1
    AND group_members.group_id = $2
    AND group_members.role = 'teacher'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update group_members roles
ALTER TABLE group_members
DROP CONSTRAINT group_members_role_check,
ADD CONSTRAINT group_members_role_check 
  CHECK (role IN ('teacher', 'student', 'group_admin'));

-- Update class_groups policies
DROP POLICY IF EXISTS "Teachers can create groups" ON class_groups;
CREATE POLICY "Admins can create and manage groups"
  ON class_groups
  FOR ALL
  USING (is_admin(auth.uid()))
  WITH CHECK (is_admin(auth.uid()));

CREATE POLICY "Group admins can manage their groups"
  ON class_groups
  FOR ALL
  USING (is_group_admin(auth.uid(), id))
  WITH CHECK (is_group_admin(auth.uid(), id));

-- Update shared_tasks policies
DROP POLICY IF EXISTS "Teachers can manage tasks" ON shared_tasks;
CREATE POLICY "Users can manage tasks in their groups"
  ON shared_tasks
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = shared_tasks.group_id
      AND group_members.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = shared_tasks.group_id
      AND group_members.user_id = auth.uid()
    )
  );