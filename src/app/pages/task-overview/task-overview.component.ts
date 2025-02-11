import { Component, computed, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TaskFormComponent } from './components/task-form/task-form.component';
import { TaskMessagesComponent, MOTIVATIONAL_MESSAGES, WARNING_MESSAGES } from './components/task-messages/task-messages.component';
import { ModalComponent } from '../../shared/components/modal/modal.component';
import { ScheduleService } from '../../services/schedule.service';
import { TaskItemComponent } from './components/task-item/task-item.component';
import { Task } from '../../models/task.model';
import { animate, state, style, transition, trigger } from '@angular/animations';
import { IconComponent } from '../../shared/components/icons/icon.component';

interface TaskGroup {
  date: string;
  tasks: Task[];
}

@Component({
  selector: 'task-overview',
  standalone: true,
  imports: [
    CommonModule, 
    TaskFormComponent, 
    ModalComponent, 
    TaskMessagesComponent,
    IconComponent,
    TaskItemComponent
  ],
  templateUrl: './task-overview.component.html',
  styleUrls: ['./task-overview.component.css'],
  animations: [
    trigger('taskEdit', [
      state('void', style({
        position: 'fixed',
        top: '{{startTop}}px',
        left: '{{startLeft}}px',
        width: '{{startWidth}}px',
        height: '{{startHeight}}px',
        transform: 'scale(1)',
        zIndex: 1000
      }), { params: { startTop: 0, startLeft: 0, startWidth: 0, startHeight: 0 } }),
      state('*', style({
        position: 'fixed',
        top: 0,
        left: 0,
        width: '100%',
        height: '100%',
        transform: 'scale(1)',
        zIndex: 1000
      })),
      transition('void => *', [
        style({
          position: 'fixed',
          top: '{{startTop}}px',
          left: '{{startLeft}}px',
          width: '{{startWidth}}px',
          height: '{{startHeight}}px',
          background: 'white',
          borderRadius: '8px',
          boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
          zIndex: 1000
        }),
        animate('300ms cubic-bezier(0.4, 0, 0.2, 1)', style({
          top: 0,
          left: 0,
          width: '100%',
          height: '100%',
          borderRadius: 0
        }))
      ]),
      transition('* => void', [
        style({
          position: 'fixed',
          top: 0,
          left: 0,
          width: '100%',
          height: '100%',
          background: 'white',
          zIndex: 1000
        }),
        animate('300ms cubic-bezier(0.4, 0, 0.2, 1)', style({
          top: '{{startTop}}px',
          left: '{{startLeft}}px',
          width: '{{startWidth}}px',
          height: '{{startHeight}}px',
          borderRadius: '8px'
        }))
      ])
    ])
  ]
})
export class TaskOverviewComponent {
  showModal = signal(false);
  editingTask = signal<Task | null>(null);
  editAnimationParams = signal<any>({ startTop: 0, startLeft: 0, startWidth: 0, startHeight: 0 });
  addTaskParams = signal<any>({ startTop: 0, startLeft: 0, startWidth: 0, startHeight: 0 });
  scheduleService = inject(ScheduleService);
  motivationalMessage = signal(MOTIVATIONAL_MESSAGES[Math.floor(Math.random() * MOTIVATIONAL_MESSAGES.length)]);
  warningMessage = signal(WARNING_MESSAGES[Math.floor(Math.random() * WARNING_MESSAGES.length)]);
  
  allTasksCompleted = (tasks: Task[]) => tasks.every(task => task.completed);

  isToday = (date: Date) => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const compareDate = new Date(date);
    compareDate.setHours(0, 0, 0, 0);
    return compareDate.getTime() === today.getTime();
  };

  overdueTasks = computed(() => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    return this.scheduleService.tasks()
      .filter((task: Task) => !task.archived)
      .filter((task: Task) => {
        if (!task.dueDate) return false;
        const dueDate = new Date(task.dueDate);
        dueDate.setHours(0, 0, 0, 0);
        return dueDate.getTime() <= today.getTime();
      })
      .sort((a: Task, b: Task) => new Date(a.dueDate!).getTime() - new Date(b.dueDate!).getTime());
  });

  todaysTasks = computed(() => {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(0, 0, 0, 0);
    return this.scheduleService.tasks()
      .filter((task: Task) => !task.archived)
      .filter((task: Task) => {
        const dueDate = new Date(task.dueDate!);
        dueDate.setHours(0, 0, 0, 0);
        return dueDate.getTime() === tomorrow.getTime();
      });
  });

  futureTasks = computed(() => {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(0, 0, 0, 0);
    
    const tasks = this.scheduleService.tasks()
      .filter((task: Task) => !task.archived)
      .filter((task: Task) => {
        if (!task.dueDate) return false;
        const dueDate = new Date(task.dueDate);
        dueDate.setHours(0, 0, 0, 0);
        return dueDate.getTime() > tomorrow.getTime();
      })
      .sort((a: Task, b: Task) => new Date(a.dueDate!).getTime() - new Date(b.dueDate!).getTime());

    const groupedTasks = new Map<string, Task[]>();
    
    tasks.forEach((task: Task) => {
      // Get the day before due date for grouping
      const dueDate = new Date(task.dueDate!);
      const workDate = new Date(dueDate);
      workDate.setDate(workDate.getDate() - 1);
      const date = this.formatDate(workDate);
      if (!groupedTasks.has(date)) {
        groupedTasks.set(date, []);
      }
      groupedTasks.get(date)!.push(task);
    });

    return Array.from(groupedTasks.entries()).map(([date, tasks]) => ({
      date,
      tasks
    }));
  });

  hasCompletedTasks = computed(() => {
    return this.scheduleService.tasks()
      .some(task => task.completed && !task.archived);
  });

  toggleTask(task: Task) {
    this.scheduleService.tasks.update(tasks =>
      tasks.map(t => t.id === task.id ? { ...t, completed: !t.completed } : t)
    );
  }

  archiveCompletedTasks() {
    this.scheduleService.archiveCompletedTasks();
  }

  showAddTaskModal(event: MouseEvent) {
    const button = event.currentTarget as HTMLElement;
    const rect = button.getBoundingClientRect();
    
    this.addTaskParams.set({
      startTop: rect.top,
      startLeft: rect.left,
      startWidth: rect.width,
      startHeight: rect.height
    });
    
    this.showModal.set(true);
  }

  editTask(task: Task, event: MouseEvent) {
    const element = (event.currentTarget as HTMLElement);
    const rect = element.getBoundingClientRect();
    
    this.editAnimationParams.set({
      startTop: rect.top,
      startLeft: rect.left,
      startWidth: rect.width,
      startHeight: rect.height
    });
    
    this.editingTask.set(task);
  }

  closeModal() {
    this.showModal.set(false);
    this.editingTask.set(null);
  }

  onTaskSubmitted() {
    this.showModal.set(false);
    this.editingTask.set(null);
    this.motivationalMessage.set(MOTIVATIONAL_MESSAGES[Math.floor(Math.random() * MOTIVATIONAL_MESSAGES.length)]);
    this.warningMessage.set(WARNING_MESSAGES[Math.floor(Math.random() * WARNING_MESSAGES.length)]);
  }

  formatDate(date: Date): string {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(today.getDate() + 1);
    const dayAfterTomorrow = new Date(tomorrow);
    dayAfterTomorrow.setDate(tomorrow.getDate() + 1);

    if (date.getTime() === tomorrow.getTime()) {
      return 'Morgen';
    }

    const currentWeekMonday = new Date(today);
    currentWeekMonday.setDate(today.getDate() - today.getDay() + 1);
    
    const weekDiff = Math.floor((date.getTime() - currentWeekMonday.getTime()) / (7 * 24 * 60 * 60 * 1000));
    const days = ['Sonntag', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag'];
    const dayName = days[date.getDay()];

    if (weekDiff === 0) {
      return `Diese Woche ${dayName}`;
    } else if (weekDiff === 1) {
      return `Nächste Woche ${dayName}`;
    } else if (weekDiff === 2) {
      return `Übernächste Woche ${dayName}`;
    } else {
      return `${dayName} in ${weekDiff} Wochen`;
    }
  }

  formatDueDate(date: Date): string {
    const dueDate = new Date(date);
    const days = ['Sonntag', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag'];
    return days[dueDate.getDay()];
  }
}