import { computed, effect, signal } from '@angular/core';
import { TimeSlot } from '../models/time-slot.model';
import { Task } from '../models/task.model';
import { Course } from '../models/course.model';

export class ScheduleService {
  schedule = signal<TimeSlot[]>([]);
  tasks = signal<Task[]>([]);
  courses = signal<Course[]>([]);

  constructor() {
    const savedSchedule = localStorage.getItem('schedule');
    const savedTasks = localStorage.getItem('tasks');
    const savedCourses = localStorage.getItem('courses');

    if (savedSchedule) {
      try {
        const schedule = JSON.parse(savedSchedule);
        if (Array.isArray(schedule) && schedule.every(this.isValidTimeSlot)) {
          this.schedule.set(schedule);
        } else {
          console.warn('Invalid schedule data in localStorage');
          this.schedule.set([]);
        }
      } catch (e) {
        console.error('Error parsing schedule from localStorage:', e);
        this.schedule.set([]);
      }
    }

    if (savedTasks) {
      try {
        const tasks = JSON.parse(savedTasks);
        const validTasks = tasks.filter(this.isValidTask).map((task: Task) => ({
          ...task,
          dueDate: task.dueDate ? new Date(task.dueDate) : null,
          completedAt: task.completedAt ? new Date(task.completedAt) : null,
          archived: task.archived || false
        }));
        this.tasks.set(validTasks);
      } catch (e) {
        console.error('Error parsing tasks from localStorage:', e);
        this.tasks.set([]);
      }
    }

    if (savedCourses) {
      try {
        const courses = JSON.parse(savedCourses);
        if (Array.isArray(courses) && courses.every(this.isValidCourse)) {
          this.courses.set(courses);
        } else {
          console.warn('Invalid courses data in localStorage');
          this.courses.set([]);
        }
      } catch (e) {
        console.error('Error parsing courses from localStorage:', e);
        this.courses.set([]);
      }
    }

    effect(() => {
      localStorage.setItem('schedule', JSON.stringify(this.schedule()));
    });

    effect(() => {
      localStorage.setItem('tasks', JSON.stringify(this.tasks()));
    });

    effect(() => {
      localStorage.setItem('courses', JSON.stringify(this.courses()));
    });
  }

  private isValidTimeSlot(slot: any): slot is TimeSlot {
    return typeof slot === 'object' &&
           typeof slot.day === 'string' &&
           typeof slot.time === 'string' &&
           typeof slot.course === 'string';
  }

  private isValidTask(task: any): task is Task {
    return typeof task === 'object' &&
           typeof task.id === 'string' &&
           typeof task.course === 'string' &&
           typeof task.description === 'string' &&
           (task.dueDate === null || typeof task.dueDate === 'string' || task.dueDate instanceof Date) &&
           typeof task.completed === 'boolean';
  }

  private isValidCourse(course: any): course is Course {
    return typeof course === 'object' &&
           typeof course.id === 'string' &&
           typeof course.name === 'string' &&
           Array.isArray(course.materials);
  }

  uniqueCourses = computed(() => 
    [...new Set(this.courses().map(c => c.name))]
      .sort()
  );

  archiveCompletedTasks() {
    const now = new Date();
    this.tasks.update(tasks => tasks.map(task => 
      task.completed && !task.archived ? { ...task, archived: true, completedAt: now } : task
    ));
  }

  deleteCompletedTasks() {
    this.tasks.update(tasks => tasks.filter(task => !task.completed || !task.archived));
  }
}