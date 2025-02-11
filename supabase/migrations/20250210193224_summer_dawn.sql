/*
  # Remove teacher role and consolidate permissions

  1. Changes
    - Remove teacher role from role check constraint
    - Update existing teacher roles to group_admin
    - Update policies to use group_admin instead of teacher
    - Update helper functions
*/

-- Update group_members roles
ALTER TABLE group_members
DROP CONSTRAINT group_members_role_check,
ADD CONSTRAINT group_members_role_check 
  CHECK (role IN ('student', 'group_admin'));

-- Convert existing teachers to group_admins
UPDATE group_members
SET role = 'group_admin'
WHERE role = 'teacher';

-- Update helper function for group admin check
CREATE OR REPLACE FUNCTION is_group_admin(user_id uuid, group_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM group_members
    WHERE group_members.user_id = $1
    AND group_members.group_id = $2
    AND group_members.role = 'group_admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;