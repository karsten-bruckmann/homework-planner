import { Component, EventEmitter, Input, Output, computed, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ScheduleService } from '../../../../services/schedule.service';
import { Task } from '../../../../models/task.model';
import { Material } from '../../../../models/course.model';
import { IconComponent } from '../../../../shared/components/icons/icon.component';
import { MaterialButtonsComponent } from '../material-buttons/material-buttons.component';
import { DueDateSelectorComponent } from '../due-date-selector/due-date-selector.component';

@Component({
  selector: 'task-form',
  standalone: true,
  imports: [CommonModule, FormsModule, IconComponent, MaterialButtonsComponent, DueDateSelectorComponent],
  templateUrl: './task-form.component.html',
  styleUrls: ['./task-form.component.css']
})
export class TaskFormComponent {
  @Input() task?: Task;
  @Output() submitted = new EventEmitter<void>();
  
  scheduleService = inject(ScheduleService);
  
  formData = {
    course: '',
    description: '',
  };
  selectedDate = signal<Date | null>(null);

  currentCourseMaterials = computed(() => {
    if (!this.formData.course) return [];
    const currentCourse = this.scheduleService.courses()
      .find(c => c.name === this.formData.course);
    return currentCourse?.materials ?? [];
  });

  ngOnInit() {
    if (this.task) {
      this.formData = {
        course: this.task.course || '',
        description: this.task.description
      };
      if (this.task.dueDate) {
        this.selectedDate.set(new Date(this.task.dueDate));
      } else {
        this.selectedDate.set(null);
      }
    } else {
      this.formData = {
        course: '',
        description: ''
      };
      this.selectedDate.set(null);
    }
  }

  onCourseChange() {
    this.selectedDate.set(null);
  }

  insertMaterial(material: Material) {
    const textarea = document.querySelector('textarea');
    if (!textarea) return;

    const cursorPosition = textarea.selectionStart;
    const textBeforeCursor = this.formData.description.substring(0, cursorPosition);
    const textAfterCursor = this.formData.description.substring(cursorPosition);
    
    const words = textBeforeCursor.split(/\s/);
    const lastWord = words.pop() || '';
    
    const newTextBeforeCursor = words.join(' ') + (words.length > 0 ? ' ' : '') + material.name;
    
    this.formData.description = newTextBeforeCursor + ' ' + textAfterCursor;
    
    setTimeout(() => {
      textarea.focus();
      const newCursorPosition = newTextBeforeCursor.length + 1;
      textarea.setSelectionRange(newCursorPosition, newCursorPosition);
    });
  }

  onDateSelected(date: Date | null) {
    this.selectedDate.set(date);
  }

  onSubmit() {
    if (!this.formData.course || !this.formData.description || !this.selectedDate()) {
      return;
    }

    if (this.task) {
      // Update existing task
      this.scheduleService.tasks.update(tasks =>
        tasks.map(t => t.id === this.task!.id ? {
          ...t,
          course: this.formData.course,
          description: this.formData.description,
          dueDate: this.selectedDate()
        } : t)
      );
    } else {
      // Add new task
      this.scheduleService.tasks.update(tasks => [
        ...tasks,
        {
          id: crypto.randomUUID(),
          course: this.formData.course,
          description: this.formData.description,
          dueDate: this.selectedDate(),
          completed: false,
          archived: false,
          completedAt: null
        }
      ]);

      // Reset form for new task
      this.formData = { course: '', description: '' };
      this.selectedDate.set(null);
    }
    
    this.submitted.emit();
  }
}