export interface PoApiResponse<T> {
  Status: boolean;
  Message: string;
  Data: T;
}

export interface PoLoginRequest {
  userName: string;
  password: string;
}

export interface PoLoginData {
  AccessToken: string;
  Expiration: string;
  UserId: string;
  UserName: string;
  ElectionId: string | number;
  PSID: string;
  UrbanRural?: string | null;
}

export interface PoStatusData {
  ElectionId: number;
  PSId: string;
  BodyType?: string | null;
  IsDepartedFromHome?: boolean | null;
  DepartedFromHomeTime?: string | null;
  IsReachedToPollingStation?: boolean | null;
  ReachedToPollingStationTime?: string | null;
  IsMaterialReceived?: boolean | null;
  MaterialReceivedTime?: string | null;
  IsMockPollConducted?: boolean | null;
  MockPollConductedTime?: string | null;
  IsPollStarted?: boolean | null;
  PollStartedTime?: string | null;
  IsPollEnded?: boolean | null;
  PollEndedTime?: string | null;
  IsMachineSealed?: boolean | null;
  MachineSealedTime?: string | null;
  IsMaterialSubmitted?: boolean | null;
  MaterialSubmittedTime?: string | null;
}

export interface PoActionRequest {
  electionId: number;
  psId: string;
  lat: number | null;
  long: number | null;
  isDepartedFromHome?: boolean;
  isReachedToPollingStation?: boolean;
  isMaterialReceived?: boolean;
  isMockPollConducted?: boolean;
  isPollStarted?: boolean;
  isPollEnded?: boolean;
  isMachineSealed?: boolean;
  isMaterialSubmitted?: boolean;
}

export interface PoCountRequest {
  electionId: number;
  psId: string;
  male: number;
  female: number;
  other: number;
  lat: number | null;
  long: number | null;
}

export interface PoPollLiveRequest {
  electionId: number;
  psId: string;
  male?: number;
  female?: number;
  other?: number;
  lat: number | null;
  long: number | null;
}

export interface PoActionResponse {
  Id: number;
  ActionDateTime: string;
}

export interface PoContext {
  userId: string;
  electionId: number;
  psId: string;
}
