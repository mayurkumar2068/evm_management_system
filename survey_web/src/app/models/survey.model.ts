import { AreaType } from './location.model';

/** Question row from `GET /api/PSSurvey/survey_questions`. */
export interface SurveyQuestion {
  readonly id: string;
  readonly surveyId: string | null;
  readonly titleHi: string;
  readonly titleEn: string;
  readonly descHi: string | null;
  readonly descEn: string | null;
  readonly photoRequired: boolean;
  readonly sortOrder: number;
  readonly mandatory: boolean;
}

/** Raw API DTO (PascalCase fields). */
export interface SurveyQuestionDto {
  Id: string;
  SurveyId: string | null;
  Q_Hi: string;
  Q_En: string;
  Desc_Hi: string | null;
  Desc_En: string | null;
  IS_PHOTO_REQUIRED: boolean;
  SORT_ORDER: number;
  IS_MANDATORY: boolean;
}

/** `POST /api/PSSurvey/save_survey_answer` request body. */
export interface SaveSurveyAnswerRequest {
  id: string | null;
  questionId: string;
  answerYN: boolean;
  answerText: string;
  remark: string;
  psType: 'R' | 'U';
  psId: string;
  lat: number | null;
  long: number | null;
  userId: string;
  photo: string | null;
}

/** `POST /api/PSSurvey/save_survey_answer` response body. */
export interface SaveSurveyAnswerResponse {
  Success: boolean;
  Id: string;
}

/** A checklist definition item as returned by the legacy mock API. */
export interface SurveyItem {
  readonly surveyId: string;
  readonly title: string;
  /** When true the inspector must attach a photo for the row to be valid. */
  readonly photoRequired?: boolean;
}

/** Server configuration for the legacy checklist mock. */
export interface SurveyConfig {
  readonly items: SurveyItem[];
  /** Maximum number of photos that can be attached across the whole survey. */
  readonly maxImages: number;
}

/**
 * Live, editable state of a single checklist row.
 * `image` holds a base64 data-URL (or `null` when none attached).
 */
export interface SurveyItemState {
  surveyId: string;
  title: string;
  photoRequired: boolean;
  checked: boolean;
  image: string | null;
}

/** Outgoing item shape inside the legacy submit payload. */
export interface SurveySubmitItem {
  surveyId: string;
  checked: boolean;
  image: string | null;
}

/** Full payload posted to the legacy backend on bulk submit. */
export interface SurveySubmitPayload {
  areaType: AreaType;
  /** key → id for every chosen location level (district, body/block, …, booth). */
  location: Record<string, string>;
  latitude: string;
  longitude: string;
  /** Optional free-text remarks / other feedback. */
  remarks?: string;
  surveyItems: SurveySubmitItem[];
}

export interface SurveySubmitResponse {
  success: boolean;
  referenceId?: string;
  message?: string;
}

/** In-memory draft for one question while navigating back/forward. */
export interface SurveyQuestionDraft {
  answerYN: boolean | null;
  remark: string;
  image: string | null;
  savedAnswerId: string | null;
}
