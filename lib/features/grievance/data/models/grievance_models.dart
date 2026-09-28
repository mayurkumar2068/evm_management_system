class GrievanceSubmission {
  const GrievanceSubmission({
    required this.mobileNo,
    required this.fullName,
    required this.category,
    required this.subject,
    required this.description,
    required this.photoBase64,
    this.latitude,
    this.longitude,
  });

  final String mobileNo;
  final String fullName;
  final String category;
  final String subject;
  final String description;
  final String photoBase64;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'mobileNo': mobileNo,
    'fullName': fullName,
    'category': category,
    'subject': subject,
    'description': description,
    'photoBase64': photoBase64,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };
}

class GrievanceSubmissionResult {
  const GrievanceSubmissionResult({
    required this.referenceNo,
    required this.message,
  });

  final String referenceNo;
  final String message;
}
