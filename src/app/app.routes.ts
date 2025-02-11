import { Routes } from '@angular/router';
import { TaskOverviewComponent } from './pages/task-overview/task-overview.component';
import { TimetableComponent } from './pages/timetable/timetable.component';
import { CompletedTasksComponent } from './pages/completed-tasks/completed-tasks.component';
import { CoursesComponent } from './pages/courses/courses.component';
import { SettingsComponent } from './pages/settings/settings.component';

export const routes: Routes = [
  { 
    path: '', 
    redirectTo: '/uebersicht', 
    pathMatch: 'full' 
  },
  { 
    path: 'uebersicht', 
    component: TaskOverviewComponent,
    data: { animation: 'uebersicht' }
  },
  { 
    path: 'erledigt', 
    component: CompletedTasksComponent,
    data: { animation: 'erledigt' }
  },
  { 
    path: 'stundenplan', 
    component: TimetableComponent,
    data: { animation: 'stundenplan' }
  },
  { 
    path: 'faecher', 
    component: CoursesComponent,
    data: { animation: 'faecher' }
  },
  {
    path: 'einstellungen',
    component: SettingsComponent,
    data: { animation: 'einstellungen' }
  }
];