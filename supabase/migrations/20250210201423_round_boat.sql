/*
  # Rename class_groups table to groups
  
  This migration renames the class_groups table to groups and updates all related foreign key constraints.
*/

-- Rename the table
ALTER TABLE class_groups RENAME TO groups;

-- Update foreign key constraints in group_members
ALTER TABLE group_members 
  DROP CONSTRAINT group_members_group_id_fkey,
  ADD CONSTRAINT group_members_group_id_fkey 
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE;

-- Update policies to use new table name
DROP POLICY IF EXISTS "Users can view their groups" ON groups;
CREATE POLICY "Users can view their groups"
  ON groups FOR SELECT
  TO authenticated
  USING (
    is_admin() OR
    id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Admins can manage groups" ON groups;
CREATE POLICY "Admins can manage groups"
  ON groups FOR ALL
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());