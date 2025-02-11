import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { IconComponent } from '../../shared/components/icons/icon.component';

@Component({
  selector: 'app-settings',
  standalone: true,
  imports: [CommonModule, IconComponent],
  template: `
    <div class="settings-sections">
      <div class="settings-section">
        <h3>App-Version</h3>
        <p>1.0.0</p>
        
        <div *ngIf="isPwa()" class="pwa-controls">
          <button class="reload-button" (click)="reloadApp()">
            <app-icon name="refresh"></app-icon>
            App neu laden
          </button>
          <p class="pwa-hint">
            Lade die App neu, um Aktualisierungen zu erhalten.
          </p>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .settings-sections {
      display: flex;
      flex-direction: column;
      gap: 2rem;
      padding: 20px;
    }

    .settings-section {
      padding: 1rem;
      background-color: white;
      border: 1px solid #ddd;
      border-radius: 8px;
    }

    .settings-section h3 {
      margin-top: 0;
      margin-bottom: 1rem;
      color: #333;
    }

    .pwa-controls {
      margin-top: 1rem;
      padding-top: 1rem;
      border-top: 1px solid #ddd;
    }

    .reload-button {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.5rem 1rem;
      background-color: #1976d2;
      color: white;
      border: none;
      border-radius: 4px;
      cursor: pointer;
      font-size: 1rem;
      transition: background-color 0.2s;
    }

    .reload-button:hover {
      background-color: #1565c0;
    }

    .pwa-hint {
      margin: 0.5rem 0 0 0;
      font-size: 0.875rem;
      color: #666;
    }
  `]
})
export class SettingsComponent {
  isPwa(): boolean {
    return window.matchMedia('(display-mode: standalone)').matches ||
           (window.navigator as any).standalone === true;
  }

  reloadApp(): void {
    window.location.reload();
  }
}