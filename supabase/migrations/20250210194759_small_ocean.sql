/*
  # Fix group member policies - Final Version
  
  1. Changes
    - Remove all existing policies
    - Create simplified policies with proper NEW/OLD handling
    - Separate policies by operation type
    - Use security definer functions for complex checks
  
  2. Security
    - Maintain proper access control
    - Handle NEW/OLD references correctly
    - Keep RLS enabled
*/

-- Drop all existing policies to start fresh
DROP POLICY IF EXISTS "View own group membership" ON group_members;
DROP POLICY IF EXISTS "View groups as admin" ON group_members;
DROP POLICY IF EXISTS "Manage groups as admin" ON group_members;
DROP POLICY IF EXISTS "Group admins view members" ON group_members;
DROP POLICY IF EXISTS "Group admins insert members" ON group_members;
DROP POLICY IF EXISTS "Group admins update members" ON group_members;
DROP POLICY IF EXISTS "Group admins delete members" ON group_members;

-- Create helper function for checking group admin status
CREATE OR REPLACE FUNCTION check_group_admin_access(check_group_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM group_members gm
    WHERE gm.group_id = check_group_id
    AND gm.user_id = auth.uid()
    AND gm.role = 'group_admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Basic view policies
CREATE POLICY "Users can view own membership"
  ON group_members
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Admins can view all"
  ON group_members
  FOR SELECT
  TO authenticated
  USING (EXISTS (SELECT 1 FROM admins WHERE user_id = auth.uid()));

-- Management policies for admins
CREATE POLICY "Admins can manage all"
  ON group_members
  FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM admins WHERE user_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM admins WHERE user_id = auth.uid()));

-- Group admin policies
CREATE POLICY "Group admins can view their groups"
  ON group_members
  FOR SELECT
  TO authenticated
  USING (check_group_admin_access(group_id));

CREATE POLICY "Group admins can insert"
  ON group_members
  FOR INSERT
  TO authenticated
  WITH CHECK (check_group_admin_access(group_id));

CREATE POLICY "Group admins can update"
  ON group_members
  FOR UPDATE
  TO authenticated
  USING (check_group_admin_access(group_id))
  WITH CHECK (check_group_admin_access(group_id));

CREATE POLICY "Group admins can delete"
  ON group_members
  FOR DELETE
  TO authenticated
  USING (check_group_admin_access(group_id));