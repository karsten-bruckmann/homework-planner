-- Drop existing policies
DROP POLICY IF EXISTS "Users can view group members of their groups" ON group_members;
DROP POLICY IF EXISTS "Admins and group admins can manage group members" ON group_members;

-- Create base policy for admins
CREATE POLICY "Admins can view all group members"
  ON group_members
  FOR SELECT
  TO authenticated
  USING (is_admin(auth.uid()));

-- Create policy for group members to view their own groups
CREATE POLICY "Members can view their own groups"
  ON group_members
  FOR SELECT
  TO authenticated
  USING (
    group_id IN (
      SELECT group_id 
      FROM group_members 
      WHERE user_id = auth.uid()
    )
  );

-- Create policy for group management
CREATE POLICY "Admins and group admins can manage members"
  ON group_members
  FOR ALL
  TO authenticated
  USING (
    is_admin(auth.uid()) OR
    (
      role = 'group_admin' AND
      user_id = auth.uid()
    )
  )
  WITH CHECK (
    is_admin(auth.uid()) OR
    (
      role = 'group_admin' AND
      user_id = auth.uid()
    )
  );