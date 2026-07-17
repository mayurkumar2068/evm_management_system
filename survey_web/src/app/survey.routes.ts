import { Routes } from '@angular/router';

/**
 * Survey feature routes. Both screens are lazily loaded as standalone
 * components to keep the initial WebView bundle small.
 */
export const SURVEY_ROUTES: Routes = [
  { path: '', pathMatch: 'full', redirectTo: 'location' },
  {
    path: 'location',
    title: 'मतदान केंद्र चयन',
    loadComponent: () =>
      import('./pages/location-selection/location-selection.component').then(
        (m) => m.LocationSelectionComponent,
      ),
  },
  {
    path: 'checklist',
    title: 'मतदान केंद्र चेकलिस्ट',
    loadComponent: () =>
      import('./pages/survey-checklist/survey-checklist.component').then(
        (m) => m.SurveyChecklistComponent,
      ),
  },
];
