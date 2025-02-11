import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Task } from '../../../../models/task.model';
import { IconComponent } from '../../../../shared/components/icons/icon.component';

@Component({
  selector: 'task-item',
  standalone: true,
  imports: [CommonModule, IconComponent],
  template: `
    <div class="task" [class.completed]="task.completed">
      <input type="checkbox" 
             [checked]="task.completed" 
             (change)="toggleCompleted.emit(task)">
      <div class="task-content" (click)="edit.emit({ task: task, event: $event })">
        <div class="task-header">
          <span class="class-name">{{task.course}}</span>
          <span class="due-date" [class.overdue]="isOverdue">
            {{dueDateText}}
          </span>
        </div>
        <p class="description">{{task.description}}</p>
      </div>
    </div>
  `,
  styles: [`
    .task {
      display: flex;
      gap: 12px;
      padding: 12px;
      background-color: white;
      border-radius: 4px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }

    .task-content {
      flex: 1;
      min-width: 0;
      cursor: pointer;
      transition: background-color 0.2s;
      padding: 4px;
      margin: -4px;
      border-radius: 4px;
    }

    .task-content:hover {
      background-color: #f5f5f5;
    }

    .task.completed {
      opacity: 0.7;
    }

    .task.completed .task-content {
      text-decoration: line-through;
    }

    .task-header {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      justify-content: space-between;
      margin-bottom: 4px;
    }

    .class-name {
      font-weight: bold;
      color: #1976d2;
    }

    .due-date {
      color: #666;
      font-size: 0.9em;
    }

    .due-date.overdue {
      color: #c62828;
      font-weight: 500;
    }

    .description {
      margin: 0;
      color: #333;
      word-break: break-word;
    }
  `]
})
export class TaskItemComponent {
  @Input({ required: true }) task!: Task;
  @Input() dueDateText: string = '';
  @Input() isOverdue: boolean = false;
  
  @Output() toggleCompleted = new EventEmitter<Task>();
  @Output() edit = new EventEmitter<{task: Task, event: MouseEvent}>();
}