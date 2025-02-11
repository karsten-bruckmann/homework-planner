-- Create a view to access auth.users safely
CREATE OR REPLACE VIEW users AS
  SELECT id, email, raw_user_meta_data
  FROM auth.users;

-- Drop and recreate group_members to fix foreign key relationship
DROP TABLE IF EXISTS group_members CASCADE;

CREATE TABLE group_members (
  group_id uuid REFERENCES groups ON DELETE CASCADE,
  user_id uuid,
  role text NOT NULL CHECK (role IN ('student', 'group_admin')),
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (group_id, user_id),
  CONSTRAINT group_members_user_id_fkey 
    FOREIGN KEY (user_id) 
    REFERENCES auth.users(id)
    ON DELETE CASCADE
);

-- Enable RLS
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;

-- Recreate policies
CREATE POLICY "Users can view own membership"
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