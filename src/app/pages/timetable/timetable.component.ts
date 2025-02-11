import { Component, HostListener, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ScheduleService } from '../../services/schedule.service';
import { TimeSlot } from '../../models/time-slot.model';
import { IconComponent } from '../../shared/components/icons/icon.component';
import { animate, style, transition, trigger } from '@angular/animations';

@Component({
  selector: 'timetable',
  standalone: true,
  imports: [CommonModule, FormsModule, IconComponent],
  templateUrl: './timetable.component.html',
  styleUrls: ['./timetable.component.css'],
  animations: [
    trigger('slideAnimation', [
      transition(':increment', [
        style({ transform: 'translateX(100%)' }),
        animate('200ms ease-out', style({ transform: 'translateX(0)' }))
      ]),
      transition(':decrement', [
        style({ transform: 'translateX(-100%)' }),
        animate('200ms ease-out', style({ transform: 'translateX(0)' }))
      ])
    ])
  ]
})
export class TimetableComponent {
  days = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag'];
  periods = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];
  editingDay: string | null = null;
  currentDayIndex = signal(this.getCurrentDayIndex());
  touchStartX = 0;
  
  scheduleService = inject(ScheduleService);
  schedule = this.scheduleService.schedule;

  private getCurrentDayIndex(): number {
    const today = new Date();
    const dayOfWeek = today.getDay(); // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
    
    // Convert to our index (0 = Monday, ..., 4 = Friday)
    const index = dayOfWeek - 1;
    
    // Handle weekend (show Friday)
    if (dayOfWeek === 0 || dayOfWeek === 6) {
      return 4;
    }
    
    return index;
  }

  @HostListener('touchstart', ['$event'])
  onTouchStart(event: TouchEvent) {
    this.touchStartX = event.touches[0].clientX;
  }

  @HostListener('touchend', ['$event'])
  onTouchEnd(event: TouchEvent) {
    const touchEndX = event.changedTouches[0].clientX;
    const deltaX = touchEndX - this.touchStartX;
    
    if (Math.abs(deltaX) > 50) { // Minimum swipe distance
      if (deltaX > 0) {
        this.previousDay();
      } else if (deltaX < 0) {
        this.nextDay();
      }
    }
  }

  previousDay() {
    this.currentDayIndex.update(i => 
      i > 0 ? i - 1 : this.days.length - 1
    );
  }

  nextDay() {
    this.currentDayIndex.update(i => 
      i < this.days.length - 1 ? i + 1 : 0
    );
  }

  hasClass(day: string, period: string): boolean {
    return this.schedule().some(slot => slot.day === day && slot.time === period);
  }

  getClassInfo(day: string, period: string): string {
    const slot = this.schedule().find(slot => slot.day === day && slot.time === period);
    return slot?.course || '';
  }

  isEditingDay(day: string): boolean {
    return this.editingDay === day;
  }

  toggleDayEdit(day: string) {
    this.editingDay = this.editingDay === day ? null : day;
  }

  updateSlot(day: string, period: string, value: string) {
    if (value) {
      const existingSlot = this.schedule().find(slot => 
        slot.day === day && slot.time === period
      );
      
      if (existingSlot) {
        this.schedule.update(schedule =>
          schedule.map(slot =>
            slot.day === day && slot.time === period
              ? { ...slot, class: value }
              : slot
          )
        );
      } else {
        this.schedule.update(schedule => [
          ...schedule,
          { day, time: period, course: value }
        ]);
      }
    } else {
      this.schedule.update(schedule =>
        schedule.filter(slot => 
          slot.day !== day || slot.time !== period
        )
      );
    }
  }
}