import { Component, computed, inject, input, output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ScheduleService } from '../../../../services/schedule.service';
import { TimeSlot } from '../../../../models/time-slot.model';

export interface DateOption {
  date: Date;
  label: string;
}

@Component({
  selector: 'due-date-selector',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="due-date-selector">
      <select [(ngModel)]="selectedValue" (ngModelChange)="onDateChange($event)" required>
        <option [ngValue]="null">Bitte wählen</option>
        <option [ngValue]="'custom'">Datum wählen</option>
        <option *ngFor="let option of dateOptions()" [ngValue]="option">
          {{option.label}}
        </option>
      </select>
      <div *ngIf="selectedValue === 'custom'" class="custom-date">
        <input 
          type="date" 
          [ngModel]="customDate" 
          (ngModelChange)="onCustomDateChange($event)" 
          required>
      </div>
    </div>
  `,
  styles: [`
    .due-date-selector {
      display: flex;
      flex-direction: column;
      gap: 0.5rem;
    }

    select, input {
      width: 100%;
      padding: 8px;
      border: 1px solid #ddd;
      border-radius: 4px;
      font-family: inherit;
      color: inherit;
      font-size: 1.1rem;
    }

    input[type="date"] {
      background-color: white;
      font-size: 1.1rem;
    }
  `]
})
export class DueDateSelectorComponent {
  courseName = input.required<string>();
  selectedDate = output<Date | null>();
  
  scheduleService = inject(ScheduleService);
  selectedValue: DateOption | string | null = null;
  customDate = '';

  dateOptions = computed(() => {
    if (!this.courseName()) return [];
    return this.getNextOccurrences(this.courseName());
  });

  onDateChange(value: DateOption | string | null) {
    if (value === 'custom') {
      this.selectedValue = 'custom';
      const today = new Date();
      this.customDate = today.toISOString().split('T')[0];
      this.selectedDate.emit(today);
    } else if (value && typeof value !== 'string') {
      this.selectedValue = value;
      this.customDate = '';
      this.selectedDate.emit(value.date);
    } else {
      this.selectedValue = null;
      this.customDate = '';
      this.selectedDate.emit(null);
    }
  }

  onCustomDateChange(dateString: string) {
    if (dateString) {
      const date = new Date(dateString);
      date.setHours(0, 0, 0, 0);
      this.customDate = dateString;
      this.selectedDate.emit(date);
    }
  }

  private getNextOccurrences(courseName: string): DateOption[] {
    if (!courseName) return [];
    
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(today.getDate() + 1);
    
    const days = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag'];
    
    const courseSlots = this.scheduleService.schedule()
      .filter((slot: TimeSlot) => slot.course === courseName)
      .map((slot: TimeSlot) => days.indexOf(slot.day));
    
    if (courseSlots.length === 0) return [];
    courseSlots.sort((a: number, b: number) => a - b);

    const occurrences: DateOption[] = [];
    let currentDate = new Date(tomorrow);
    let weeksCount = 0;

    while (occurrences.length < 6 && weeksCount < 3) {
      const currentDayOfWeek = ((currentDate.getDay() + 6) % 7); // Convert Sunday (0) to 6, Monday (1) to 0, etc.
      
      if (courseSlots.includes(currentDayOfWeek)) {
        const isNextClass = occurrences.length === 0;
        occurrences.push({
          date: new Date(currentDate),
          label: isNextClass 
            ? `Nächste Stunde (${this.formatDate(new Date(currentDate))})` 
            : this.formatDate(new Date(currentDate))
        });
      }
      
      currentDate.setDate(currentDate.getDate() + 1);
      if (currentDate.getDay() === 1) {
        weeksCount++;
      }
    }

    return occurrences;
  }

  private formatDate(date: Date): string {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(today.getDate() + 1);
    const yesterday = new Date(today);
    yesterday.setDate(today.getDate() - 1);

    if (date.getTime() === tomorrow.getTime()) {
      return 'Morgen';
    } else if (date.getTime() === yesterday.getTime()) {
      return 'Gestern';
    } else if (date.getTime() === today.getTime()) {
      return 'Heute';
    }

    const currentWeekMonday = new Date(today);
    currentWeekMonday.setDate(today.getDate() - ((today.getDay() + 6) % 7));
    
    const weekDiff = Math.floor((date.getTime() - currentWeekMonday.getTime()) / (7 * 24 * 60 * 60 * 1000));
    const days = ['Sonntag', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag'];
    const dayName = days[date.getDay()];
    
    const isPast = date.getTime() < today.getTime();
    if (isPast) {
      return new Intl.DateTimeFormat('de-DE', {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric'
      }).format(date);
    }

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
}