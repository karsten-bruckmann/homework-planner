import { Component, computed, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ScheduleService } from '../../services/schedule.service';
import { Task } from '../../models/task.model';
import { IconComponent } from '../../shared/components/icons/icon.component';

interface TaskGroup {
  date: string;
  tasks: Task[];
}

@Component({
  selector: 'completed-tasks',
  standalone: true,
  imports: [CommonModule, IconComponent],
  templateUrl: './completed-tasks.component.html',
  styleUrls: ['./completed-tasks.component.css']
})
export class CompletedTasksComponent {
  scheduleService = inject(ScheduleService);

  archivedTasks = computed(() => {
    const tasks = this.scheduleService.tasks()
      .filter(task => task.archived)
      .sort((a, b) => {
        if (!a.completedAt || !b.completedAt) return 0;
        return b.completedAt.getTime() - a.completedAt.getTime();
      });

    // Group tasks by completion date
    const groupedTasks = new Map<string, Task[]>();
    
    tasks.forEach(task => {
      if (!task.completedAt) return;
      
      const date = this.formatDate(task.completedAt);
      if (!groupedTasks.has(date)) {
        groupedTasks.set(date, []);
      }
      groupedTasks.get(date)!.push(task);
    });

    // Convert to array of objects for template
    return Array.from(groupedTasks.entries()).map(([date, tasks]) => ({
      date,
      tasks
    }));
  });

  unmarkCompleted(task: Task) {
    this.scheduleService.tasks.update(tasks =>
      tasks.map(t => t.id === task.id ? {
        ...t,
        completed: false,
        archived: false,
        completedAt: null
      } : t)
    );
  }

  deleteTask(taskId: string) {
    this.scheduleService.tasks.update(tasks => 
      tasks.filter(task => task.id !== taskId)
    );
  }

  formatDate(date: Date): string {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const yesterday = new Date(today);
    yesterday.setDate(today.getDate() - 1);
    const taskDate = new Date(date);
    taskDate.setHours(0, 0, 0, 0);

    if (taskDate.getTime() === today.getTime()) {
      return 'Heute';
    }
    if (taskDate.getTime() === yesterday.getTime()) {
      return 'Gestern';
    }

    return new Intl.DateTimeFormat('de-DE', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    }).format(date);
  }
}