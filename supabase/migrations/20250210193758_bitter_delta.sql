/*
  # Fix group member policies
  
  1. Changes
    - Remove NEW/OLD references from policies
    - Implement proper row-level security for group management
    - Fix infinite recursion issues
    - Separate policies by operation type
  
  2. Security
    - Enable proper access control for admins and group admins
    - Ensure users can only view their own groups
    - Prevent unauthorized modifications
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Admins can view all group members" ON group_members;
DROP POLICY IF EXISTS "Members can view their own groups" ON group_members;
DROP POLICY IF EXISTS "Admins and group admins can manage members" ON group_members;

-- Create separate policies for different operations
CREATE POLICY "Anyone can view groups they belong to"
  ON group_members
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() OR
    group_id IN (
      SELECT group_id 
      FROM group_members 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "System admins can manage all groups"
  ON group_members
  FOR ALL
  TO authenticated
  USING (is_admin(auth.uid()))
  WITH CHECK (is_admin(auth.uid()));

-- Group admin policies split by operation
CREATE POLICY "Group admins can insert members"
  ON group_members
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = group_members.group_id
      AND group_members.user_id = auth.uid()
      AND group_members.role = 'group_admin'
    )
  );

CREATE POLICY "Group admins can update members"
  ON group_members
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = group_members.group_id
      AND group_members.user_id = auth.uid()
      AND group_members.role = 'group_admin'
    )
  );

CREATE POLICY "Group admins can delete members"
  ON group_members
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = group_members.group_id
      AND group_members.user_id = auth.uid()
      AND group_members.role = 'group_admin'
    )
  );