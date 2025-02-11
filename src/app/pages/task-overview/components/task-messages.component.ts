import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';

export const MOTIVATIONAL_MESSAGES = [
  { text: "Alles erledigt! 🎉 Zeit für eine wohlverdiente Pause!", emoji: "🌟" },
  { text: "Wow, du bist heute super organisiert! 🏆 Gönn dir was!", emoji: "✨" },
  { text: "Mission accomplished! 🚀 Du rockst das!", emoji: "💪" },
  { text: "Keine Aufgaben? Das nenn ich mal Effizienz! 🎯", emoji: "🌈" },
  { text: "Heute läuft's rund! 🎨 Zeit zum Chillen!", emoji: "😎" },
  { text: "Du bist der Boss! Alles im Griff! 🎮", emoji: "🌟" },
  { text: "Hausaufgaben-Ninja Level erreicht! 🥷", emoji: "⚡" },
  { text: "Heute ist dein Tag! Genieß ihn! 🌞", emoji: "🎈" },
  { text: "Perfekt! Zeit für Videospiele! 🎮", emoji: "🎯" },
  { text: "Hausaufgaben-Superheld:in des Tages! 🦸‍♂️", emoji: "💫" }
];

export const WARNING_MESSAGES = [
  { text: "ACHTUNG! Die Hausaufgaben-Polizei ist unterwegs! 🚨", emoji: "👮" },
  { text: "Tick Tack... Die Uhr läuft! ⏰ Keine Ausreden mehr!", emoji: "💀" },
  { text: "Houston, wir haben ein Problem! Aufgaben in T-minus JETZT!", emoji: "🚀" },
  { text: "Die Hausaufgaben-Krake wartet nicht ewig! 🐙", emoji: "🌊" },
  { text: "BREAKING NEWS: Schüler:in noch nicht mit Hausaufgaben fertig!", emoji: "📺" },
  { text: "Der Hausaufgaben-Drache wird ungeduldig! 🔥", emoji: "🐉" },
  { text: "Code Rot! Ich wiederhole: CODE ROT! Aufgaben fällig!", emoji: "🚨" },
  { text: "Die Deadline-Ninjas sind in Position! Besser schnell sein!", emoji: "🥷" },
  { text: "WARNUNG: Explodierende Hausaufgaben in 3... 2... 1...", emoji: "💣" },
  { text: "Der Aufgaben-Yeti ist hungrig... und du hast sein Essen! 👹", emoji: "❄️" }
];

@Component({
  selector: 'task-messages',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div *ngIf="hasTasks" class="warning-message">
      <span class="message-emoji">{{message.emoji}}</span>
      <p>{{message.text}}</p>
    </div>
    <div *ngIf="!hasTasks" class="no-tasks">
      <div class="motivational-message">
        <span class="message-emoji">{{message.emoji}}</span>
        <p>{{message.text}}</p>
      </div>
    </div>
  `,
  styles: [`
    .warning-message {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 0.5rem;
      color: #c62828;
      margin-bottom: 1rem;
    }

    .warning-message .message-emoji {
      font-size: 2.5rem;
      animation: shake 0.5s ease-in-out infinite;
    }

    @keyframes shake {
      0%, 100% {
        transform: rotate(0deg);
      }
      25% {
        transform: rotate(-10deg);
      }
      75% {
        transform: rotate(10deg);
      }
    }

    .warning-message p {
      margin: 0;
      font-size: 1.1rem;
      font-weight: 600;
      text-align: center;
      text-shadow: 1px 1px 0 rgba(0,0,0,0.1);
    }

    .motivational-message {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 0.5rem;
      color: #2e7d32;
    }

    .message-emoji {
      font-size: 2rem;
      animation: bounce 1s ease infinite;
    }

    @keyframes bounce {
      0%, 100% {
        transform: translateY(0);
      }
      50% {
        transform: translateY(-10px);
      }
    }

    .motivational-message p {
      margin: 0;
      font-size: 1.1rem;
      font-weight: 500;
    }
  `]
})
export class TaskMessagesComponent {
  @Input() hasTasks = false;
  @Input() message: { text: string, emoji: string } = { text: '', emoji: '' };
}