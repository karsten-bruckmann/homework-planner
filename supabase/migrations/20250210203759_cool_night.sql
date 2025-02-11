-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own membership" ON group_members;
DROP POLICY IF EXISTS "Admins can view all memberships" ON group_members;
DROP POLICY IF EXISTS "Admins can manage all memberships" ON group_members;
DROP POLICY IF EXISTS "Group admins can view their group members" ON group_members;
DROP POLICY IF EXISTS "Group admins can manage their members" ON group_members;
DROP POLICY IF EXISTS "Group admins can update their members" ON group_members;
DROP POLICY IF EXISTS "Group admins can delete their members" ON group_members;

-- Create simplified policies without recursion
CREATE POLICY "View own membership and group members"
  ON group_members FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() OR -- Can view own membership
    is_admin() OR -- Admins can view all
    EXISTS ( -- Group admins can view their group's members
      SELECT 1 FROM group_members admin_check
      WHERE admin_check.group_id = group_members.group_id
      AND admin_check.user_id = auth.uid()
      AND admin_check.role = 'group_admin'
      AND admin_check.user_id != group_members.user_id -- Prevent recursion
    )
  );

CREATE POLICY "Manage as admin"
  ON group_members FOR ALL
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

CREATE POLICY "Manage as group admin"
  ON group_members FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM group_members admin_check
      WHERE admin_check.group_id = group_members.group_id
      AND admin_check.user_id = auth.uid()
      AND admin_check.role = 'group_admin'
      AND admin_check.user_id != group_members.user_id -- Prevent recursion
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM group_members admin_check
      WHERE admin_check.group_id = group_members.group_id
      AND admin_check.user_id = auth.uid()
      AND admin_check.role = 'group_admin'
      AND admin_check.user_id != group_members.user_id -- Prevent recursion
    )
  );