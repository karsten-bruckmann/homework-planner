import { Component, EventEmitter, Output, inject, computed, input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Material } from '../../../../models/course.model';
import { IconComponent } from '../../../../shared/components/icons/icon.component';
import { ScheduleService } from '../../../../services/schedule.service';

@Component({
  selector: 'material-buttons',
  standalone: true,
  imports: [CommonModule, IconComponent],
  template: `
    <div class="materials-buttons" *ngIf="(materials()?.length || 0) > 0">
      <button 
        type="button" 
        *ngFor="let material of materials()" 
        class="material-button"
        (click)="materialSelected.emit(material)">
        <span class="material-type-icon" [title]="material.type">
          <app-icon [name]="material.type"></app-icon>
        </span>
        {{material.name}}
      </button>
    </div>
  `,
  styles: [`
    .materials-buttons {
      display: flex;
      flex-wrap: wrap;
      gap: 0.5rem;
      margin-bottom: 0.5rem;
    }

    .material-button {
      display: inline-flex;
      align-items: center;
      gap: 0.5rem;
      padding: 4px 8px;
      background-color: #e3f2fd;
      color: #1976d2;
      border: 1px solid #bbdefb;
      border-radius: 4px;
      cursor: pointer;
      font-size: 0.875rem;
      transition: all 0.2s;
    }

    .material-button:hover {
      background-color: #bbdefb;
    }

    .material-type-icon {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 1.5rem;
      height: 1.5rem;
      color: #666;
    }

    .material-type-icon svg {
      width: 1.25rem;
      height: 1.25rem;
    }
  `]
})
export class MaterialButtonsComponent {
  courseName = input<string>('');
  @Output() materialSelected = new EventEmitter<Material>();
  
  scheduleService = inject(ScheduleService);
  
  materials = computed(() => {
    if (!this.courseName()) return [];
    const currentCourse = this.scheduleService.courses()
      .find(c => c.name === this.courseName());
    return currentCourse?.materials ?? [];
  });
}