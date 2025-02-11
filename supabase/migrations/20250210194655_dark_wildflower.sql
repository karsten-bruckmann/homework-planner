/*
  # Fix group member policies
  
  1. Changes
    - Remove recursive policy checks
    - Implement proper row-level security for group management
    - Fix infinite recursion issues
    - Separate policies by operation type
  
  2. Security
    - Enable proper access control for admins and group admins
    - Ensure users can only view their own groups
    - Prevent unauthorized modifications
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can view groups they belong to" ON group_members;
DROP POLICY IF EXISTS "System admins can manage all groups" ON group_members;
DROP POLICY IF EXISTS "Group admins can insert members" ON group_members;
DROP POLICY IF EXISTS "Group admins can update members" ON group_members;
DROP POLICY IF EXISTS "Group admins can delete members" ON group_members;

-- Create non-recursive policies
CREATE POLICY "View own group membership"
  ON group_members
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "View groups as admin"
  ON group_members
  FOR SELECT
  TO authenticated
  USING (is_admin(auth.uid()));

CREATE POLICY "Manage groups as admin"
  ON group_members
  FOR ALL
  TO authenticated
  USING (is_admin(auth.uid()))
  WITH CHECK (is_admin(auth.uid()));

-- Create a secure function to check group admin status
CREATE OR REPLACE FUNCTION current_user_is_group_admin(check_group_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM group_members
    WHERE group_id = check_group_id
    AND user_id = auth.uid()
    AND role = 'group_admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Group admin policies using the secure function
CREATE POLICY "Group admins view members"
  ON group_members
  FOR SELECT
  TO authenticated
  USING (current_user_is_group_admin(group_id));

CREATE POLICY "Group admins insert members"
  ON group_members
  FOR INSERT
  TO authenticated
  WITH CHECK (current_user_is_group_admin(group_id));

CREATE POLICY "Group admins update members"
  ON group_members
  FOR UPDATE
  TO authenticated
  USING (current_user_is_group_admin(group_id))
  WITH CHECK (current_user_is_group_admin(group_id));

CREATE POLICY "Group admins delete members"
  ON group_members
  FOR DELETE
  TO authenticated
  USING (current_user_is_group_admin(group_id));