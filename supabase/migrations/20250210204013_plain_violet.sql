-- Drop and recreate users view with proper grants
DROP VIEW IF EXISTS users;
CREATE VIEW users AS
  SELECT id, email, raw_user_meta_data
  FROM auth.users;

-- Grant access to the view
GRANT SELECT ON users TO authenticated;

-- Add comment to establish relationship
COMMENT ON VIEW users IS 'User information from auth.users';
COMMENT ON COLUMN users.id IS 'User ID from auth.users';

-- Add foreign key relationship comment
COMMENT ON CONSTRAINT group_members_user_id_fkey ON group_members IS
  E'@foreignKey (user_id) references users (id)\nUser reference for group member';