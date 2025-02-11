-- Fix infinite recursion in policies
DROP POLICY IF EXISTS "Users can view group members of their groups" ON group_members;
CREATE POLICY "Users can view group members of their groups"
  ON group_members
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM class_groups
      WHERE class_groups.id = group_members.group_id
      AND (
        is_admin(auth.uid()) OR
        EXISTS (
          SELECT 1 FROM group_members AS my_membership
          WHERE my_membership.group_id = group_members.group_id
          AND my_membership.user_id = auth.uid()
        )
      )
    )
  );

DROP POLICY IF EXISTS "Group admins can manage group members" ON group_members;
CREATE POLICY "Admins and group admins can manage group members"
  ON group_members
  FOR ALL
  TO authenticated
  USING (
    is_admin(auth.uid()) OR
    EXISTS (
      SELECT 1 FROM group_members AS admin_check
      WHERE admin_check.group_id = group_members.group_id
      AND admin_check.user_id = auth.uid()
      AND admin_check.role = 'group_admin'
    )
  )
  WITH CHECK (
    is_admin(auth.uid()) OR
    EXISTS (
      SELECT 1 FROM group_members AS admin_check
      WHERE admin_check.group_id = group_members.group_id
      AND admin_check.user_id = auth.uid()
      AND admin_check.role = 'group_admin'
    )
  );