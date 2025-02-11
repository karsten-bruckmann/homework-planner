import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ScheduleService } from '../../services/schedule.service';
import { Course, Material } from '../../models/course.model';
import { IconComponent } from '../../shared/components/icons/icon.component';

@Component({
  selector: 'courses',
  standalone: true,
  imports: [CommonModule, FormsModule, IconComponent],
  templateUrl: './courses.component.html',
  styleUrls: ['./courses.component.css']
})
export class CoursesComponent {
  scheduleService = inject(ScheduleService);
  newCourseName = '';
  newMaterialName: { [key: string]: string } = {};
  newMaterialType: { [key: string]: 'book' | 'workbook' | 'other' } = {};
  editingCourseId: string | null = null;

  addCourse() {
    if (!this.newCourseName.trim()) return;
    
    const newCourse: Course = {
      id: crypto.randomUUID(),
      name: this.newCourseName.trim(),
      materials: []
    };
    
    this.scheduleService.courses.update(courses => [...courses, newCourse]);
    this.newCourseName = '';
  }

  removeCourse(courseId: string) {
    const isUsed = this.scheduleService.schedule().some(slot => {
      const courseObj = this.scheduleService.courses().find(c => c.id === courseId);
      return slot.course === courseObj?.name;
    });

    if (isUsed) {
      alert('Dieses Fach kann nicht gelöscht werden, da es im Stundenplan verwendet wird.');
      return;
    }

    this.scheduleService.courses.update(courses =>
      courses.filter(c => c.id !== courseId)
    );
  }

  updateCourseName(courseId: string, event: Event) {
    const input = event.target as HTMLInputElement;
    const newName = input.value.trim();
    
    if (!newName) return;

    this.scheduleService.courses.update(courses =>
      courses.map(c => c.id === courseId ? { ...c, name: newName } : c)
    );

    const oldName = this.scheduleService.courses().find(c => c.id === courseId)?.name;
    if (oldName) {
      this.scheduleService.schedule.update(schedule =>
        schedule.map(slot => slot.course === oldName ? { ...slot, course: newName } : slot)
      );
    }
  }

  addMaterial(courseId: string) {
    if (!this.newMaterialName[courseId]?.trim()) return;
    
    const newMaterial: Material = {
      id: crypto.randomUUID(),
      name: this.newMaterialName[courseId].trim(),
      type: this.newMaterialType[courseId] || 'other'
    };
    
    this.scheduleService.courses.update(courses =>
      courses.map(c => c.id === courseId ? {
        ...c,
        materials: [...(c.materials || []), newMaterial]
      } : c)
    );
    
    this.newMaterialName[courseId] = '';
  }

  removeMaterial(courseId: string, materialId: string) {
    this.scheduleService.courses.update(courses =>
      courses.map(c => c.id === courseId ? {
        ...c,
        materials: c.materials.filter(m => m.id !== materialId)
      } : c)
    );
  }

  toggleEdit(courseId: string) {
    this.editingCourseId = this.editingCourseId === courseId ? null : courseId;
  }

  isEditing(courseId: string): boolean {
    return this.editingCourseId === courseId;
  }
}