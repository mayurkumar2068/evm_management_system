/** `POST /api/Account/login-survey-pass` response `Data` block. */
export interface SurveyLoginData {
  AccessToken: string;
  Expiration: string;
  UserId: string;
  UserName: string;
  ElectionId: string | number | null;
  PSID: string | null;
  UrbanRural?: string | null;
  DistID?: string | null;
  BodyID?: string | null;
  DistName?: string | null;
  UBName?: string | null;
  Name?: string | null;
  /** Newly added on login response (PS / user coordinates). */
  Lat?: number | string | null;
  Long?: number | string | null;
  lat?: number | string | null;
  long?: number | string | null;
}

export interface SurveyLoginRequest {
  userName: string;
  password: string;
}

/** Session context resolved from Flutter URL params or survey login. */
export interface SurveySession {
  userId: string;
  districtId: string;
  bodyId: string;
  urbanRural: 'U' | 'R' | null;
  electionId: number | null;
  psId: string;
  lat: number | null;
  long: number | null;
}
