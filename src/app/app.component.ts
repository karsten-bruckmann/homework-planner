import { Component } from '@angular/core';
import { RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';
import { Router, NavigationEnd } from '@angular/router';
import { filter } from 'rxjs/operators';
import { animate, group, query, style, transition, trigger } from '@angular/animations';
import { IconComponent } from './shared/components/icons/icon.component';

const crossfadeAnimation = trigger('routeAnimations', [
  transition('* <=> *', [
    query(':enter, :leave', [
      style({
        position: 'absolute',
        width: '100%',
        height: '100%'
      })
    ], { optional: true }),
    group([
      query(':leave', [
        style({ 
          transform: 'scale(1)', 
          opacity: 1 
        }),
        animate('300ms ease-out', 
          style({ 
            transform: 'scale(0.95)',
            opacity: 0
          })
        )
      ], { optional: true }),
      query(':enter', [
        style({ 
          transform: 'scale(0.95)',
          opacity: 0
        }),
        animate('300ms ease-out', 
          style({ 
            transform: 'scale(1)',
            opacity: 1
          })
        )
      ], { optional: true })
    ])
  ])
]);

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterModule, CommonModule, IconComponent],
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css'],
  animations: [crossfadeAnimation]
})
export class AppComponent {
  name = 'Hausaufgaben-Organizer';
  private readonly pageOrder = ['uebersicht', 'stundenplan', 'erledigt', 'faecher', 'einstellungen'];
  showNavigation = true;

  constructor(private router: Router) {
    this.router.events.pipe(
      filter(event => event instanceof NavigationEnd)
    ).subscribe((event) => {
      if (event instanceof NavigationEnd) {
        this.showNavigation = !event.url.includes('/login');
      }
    });
  }

  isPwa(): boolean {
    return window.matchMedia('(display-mode: standalone)').matches ||
           (window.navigator as any).standalone === true;
  }

  reloadPage(): void {
    window.location.reload();
  }

  getRouteState(outlet: any) {
    return outlet.activatedRouteData?.['animation'] || 'default';
  }
}