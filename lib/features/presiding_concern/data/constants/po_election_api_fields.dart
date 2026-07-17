/// JSON field names for PO Election API requests and responses.
abstract final class PoElectionRequestFields {
  static const String electionId = 'electionId';
  static const String psId = 'psId';
  static const String poId = 'poId';
  static const String accessToken = 'accessToken';
  static const String male = 'male';
  static const String female = 'female';
  static const String other = 'other';
  static const String total = 'total';
  static const String lat = 'lat';
  static const String long = 'long';
  static const String isDepartedFromHome = 'isDepartedFromHome';
  static const String isReachedToPs = 'isReachedToPS';
  static const String isMaterialReceived = 'isMaterialReceived';
  static const String isMockPollConducted = 'isMockPollConducted';
  static const String isPollStarted = 'isPollStarted';
  static const String isPollEnded = 'isPollEnded';
  static const String isMachineSealed = 'isMachineSealed';
  static const String isMaterialSubmitted = 'isMaterialSubmitted';
}

abstract final class PoElectionResponseFields {
  static const String status = 'Status';
  static const String message = 'Message';
  static const String data = 'Data';
  static const String bodyType = 'BodyType';
  static const String actionDateTime = 'ActionDateTime';
  static const String id = 'Id';
  static const String code = 'Code';

  static const String poll9AmMale = 'Poll9AMMale';
  static const String poll9AmFemale = 'Poll9AMFemale';
  static const String poll9AmOther = 'Poll9AMOther';
  static const String poll9AmUpdateTime = 'Poll9AMUpdateTime';

  static const String poll11AmMale = 'Poll11AMMale';
  static const String poll11AmFemale = 'Poll11AMFemale';
  static const String poll11AmOther = 'Poll11AMOther';
  static const String poll11AmUpdateTime = 'Poll11AMUpdateTime';

  static const String poll1PmMale = 'Poll1PMMale';
  static const String poll1PmFemale = 'Poll1PMFemale';
  static const String poll1PmOther = 'Poll1PMOther';
  static const String poll1PmUpdateTime = 'Poll1PMUpdateTime';

  static const String poll3PmMale = 'Poll3PMMale';
  static const String poll3PmFemale = 'Poll3PMFemale';
  static const String poll3PmOther = 'Poll3PMOther';
  static const String poll3PmUpdateTime = 'Poll3PMUpdateTime';

  static const String poll5PmMale = 'Poll5PMMale';
  static const String poll5PmFemale = 'Poll5PMFemale';
  static const String poll5PmOther = 'Poll5PMOther';
  static const String poll5PmUpdateTime = 'Poll5PMUpdateTime';

  static const String pollLiveMale = 'PollLiveMale';
  static const String pollLiveFemale = 'PollLiveFemale';
  static const String pollLiveOther = 'PollLiveOther';
  static const String pollLiveUpdateTime = 'PollLiveUpdateTime';

  static const String qMale = 'QMale';
  static const String qFemale = 'QFemale';
  static const String qOther = 'QOther';
  static const String qUpdateTime = 'QUpdateTime';

  static const String finalMale = 'FinalMale';
  static const String finalFemale = 'FinalFemale';
  static const String finalOther = 'FinalOther';
  static const String finalUpdateTime = 'FinalUpdateTime';

  static const String isDepartedFromHome = 'IsDepartedFromHome';
  static const String departedFromHomeTime = 'DepartedFromHomeTime';
  static const String isReachedToPollingStation = 'IsReachedToPollingStation';
  static const String reachedToPollingStationTime =
      'ReachedToPollingStationTime';
  static const String isMaterialReceived = 'IsMaterialReceived';
  static const String materialReceivedTime = 'MaterialReceivedTime';
  static const String isMockPollConducted = 'IsMockPollConducted';
  static const String mockPollConductedTime = 'MockPollConductedTime';
  static const String isPollStarted = 'IsPollStarted';
  static const String pollStartedTime = 'PollStartedTime';
  static const String isPollEnded = 'IsPollEnded';
  static const String pollEndedTime = 'PollEndedTime';
  static const String isMachineSealed = 'IsMachineSealed';
  static const String machineSealedTime = 'MachineSealedTime';
  static const String isMaterialSubmitted = 'IsMaterialSubmitted';
  static const String materialSubmittedTime = 'MaterialSubmittedTime';
}

abstract final class PoLoginResponseFields {
  static const String status = 'Status';
  static const String message = 'Message';
  static const String data = 'Data';
  static const String accessToken = 'AccessToken';
  static const String expiration = 'Expiration';
  static const String userId = 'UserId';
  static const String userName = 'UserName';
  static const String electionId = 'ElectionId';
  static const String psId = 'PSID';
  static const String urbanRural = 'UrbanRural';
  static const String psNo = 'PSNo';
  static const String psName = 'PSName';
  static const String distName = 'DistName';
  static const String lat = 'Lat';
  static const String long = 'Long';
}
