/*
  # Minimal Database Setup
  
  1. Core Tables
    - admins: For system administrators
    - class_groups: For managing groups
    - group_members: For group membership

  2. Security
    - Row Level Security enabled on all tables
    - Basic policies for admins and group management
*/

-- Drop existing tables
DROP TABLE IF EXISTS group_members CASCADE;

-- Create Tables
CREATE TABLE group_members (
  group_id uuid REFERENCES class_groups ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('student', 'group_admin')),
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (group_id, user_id)
);

-- Enable RLS
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;