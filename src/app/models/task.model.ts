export interface Task {
  id: string;
  course: string;
  description: string;
  dueDate: Date | null;
  completed: boolean;
  archived: boolean;
  completedAt: Date | null;
}