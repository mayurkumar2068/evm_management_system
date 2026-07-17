import { Routes } from '@angular/router';

import { SURVEY_ROUTES } from './survey.routes';

export const APP_ROUTES: Routes = [
  {
    path: '',
    children: SURVEY_ROUTES,
  },
  { path: '**', redirectTo: '' },
];
