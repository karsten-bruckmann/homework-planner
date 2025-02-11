/*
  # Multi-user schema for homework organizer

  1. New Tables
    - `class_groups`
      - `id` (uuid, primary key)
      - `name` (text)
      - `created_at` (timestamp)
      - `created_by` (uuid, references auth.users)
      
    - `group_members`
      - `group_id` (uuid, references class_groups)
      - `user_id` (uuid, references auth.users)
      - `role` (text, either 'teacher' or 'student')
      
    - `shared_tasks`
      - `id` (uuid, primary key)
      - `group_id` (uuid, references class_groups)
      - `class` (text)
      - `description` (text)
      - `due_date` (timestamp)
      - `created_at` (timestamp)
      - `created_by` (uuid, references auth.users)
      
    - `task_completions`
      - `task_id` (uuid, references shared_tasks)
      - `user_id` (uuid, references auth.users)
      - `completed_at` (timestamp)
      
    - `shared_timetables`
      - `id` (uuid, primary key)
      - `group_id` (uuid, references class_groups)
      - `day` (text)
      - `time` (text)
      - `class` (text)
      
    - `shared_classes`
      - `id` (uuid, primary key)
      - `group_id` (uuid, references class_groups)
      - `name` (text)
      - `created_at` (timestamp)
      
    - `shared_materials`
      - `id` (uuid, primary key)
      - `class_id` (uuid, references shared_classes)
      - `name` (text)
      - `type` (text)

  2. Security
    - Enable RLS on all tables
    - Add policies for teachers and students
*/

-- Create tables
CREATE TABLE class_groups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  created_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users NOT NULL
);

CREATE TABLE group_members (
  group_id uuid REFERENCES class_groups ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('teacher', 'student')),
  PRIMARY KEY (group_id, user_id)
);

CREATE TABLE shared_tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid REFERENCES class_groups ON DELETE CASCADE,
  class text NOT NULL,
  description text NOT NULL,
  due_date timestamptz,
  created_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users
);

CREATE TABLE task_completions (
  task_id uuid REFERENCES shared_tasks ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users ON DELETE CASCADE,
  completed_at timestamptz DEFAULT now(),
  PRIMARY KEY (task_id, user_id)
);

CREATE TABLE shared_timetables (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid REFERENCES class_groups ON DELETE CASCADE,
  day text NOT NULL,
  time text NOT NULL,
  class text NOT NULL
);

CREATE TABLE shared_classes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid REFERENCES class_groups ON DELETE CASCADE,
  name text NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE shared_materials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id uuid REFERENCES shared_classes ON DELETE CASCADE,
  name text NOT NULL,
  type text NOT NULL CHECK (type IN ('book', 'workbook', 'other'))
);

-- Enable Row Level Security
ALTER TABLE class_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_timetables ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_materials ENABLE ROW LEVEL SECURITY;

-- Policies for class_groups
CREATE POLICY "Users can view groups they are members of"
  ON class_groups
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = class_groups.id
      AND group_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Teachers can create groups"
  ON class_groups
  FOR INSERT
  WITH CHECK (auth.uid() = created_by);

-- Policies for group_members
CREATE POLICY "Users can view group members of their groups"
  ON group_members
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM group_members AS my_groups
      WHERE my_groups.group_id = group_members.group_id
      AND my_groups.user_id = auth.uid()
    )
  );

CREATE POLICY "Teachers can manage group members"
  ON group_members
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = group_members.group_id
      AND group_members.user_id = auth.uid()
      AND group_members.role = 'teacher'
    )
  );

-- Policies for shared_tasks
CREATE POLICY "Users can view tasks in their groups"
  ON shared_tasks
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = shared_tasks.group_id
      AND group_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Teachers can manage tasks"
  ON shared_tasks
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = shared_tasks.group_id
      AND group_members.user_id = auth.uid()
      AND group_members.role = 'teacher'
    )
  );

-- Policies for task_completions
CREATE POLICY "Users can view task completions in their groups"
  ON task_completions
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM shared_tasks
      JOIN group_members ON group_members.group_id = shared_tasks.group_id
      WHERE shared_tasks.id = task_completions.task_id
      AND group_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can manage their own task completions"
  ON task_completions
  FOR ALL
  USING (auth.uid() = user_id);

-- Policies for shared_timetables
CREATE POLICY "Users can view timetables in their groups"
  ON shared_timetables
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = shared_timetables.group_id
      AND group_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Teachers can manage timetables"
  ON shared_timetables
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = shared_timetables.group_id
      AND group_members.user_id = auth.uid()
      AND group_members.role = 'teacher'
    )
  );

-- Policies for shared_classes
CREATE POLICY "Users can view classes in their groups"
  ON shared_classes
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = shared_classes.group_id
      AND group_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Teachers can manage classes"
  ON shared_classes
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = shared_classes.group_id
      AND group_members.user_id = auth.uid()
      AND group_members.role = 'teacher'
    )
  );

-- Policies for shared_materials
CREATE POLICY "Users can view materials of classes in their groups"
  ON shared_materials
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM shared_classes
      JOIN group_members ON group_members.group_id = shared_classes.group_id
      WHERE shared_classes.id = shared_materials.class_id
      AND group_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Teachers can manage materials"
  ON shared_materials
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM shared_classes
      JOIN group_members ON group_members.group_id = shared_classes.group_id
      WHERE shared_classes.id = shared_materials.class_id
      AND group_members.user_id = auth.uid()
      AND group_members.role = 'teacher'
    )
  );