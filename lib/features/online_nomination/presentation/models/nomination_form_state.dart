enum NominationDocumentUploadStatus { idle, uploading, uploaded, error }

class NominationDocumentUploadState {
  const NominationDocumentUploadState({
    this.status = NominationDocumentUploadStatus.idle,
    this.fileName,
    this.filePath,
    this.errorMessage,
  });

  final NominationDocumentUploadStatus status;
  final String? fileName;
  final String? filePath;
  final String? errorMessage;

  NominationDocumentUploadState copyWith({
    NominationDocumentUploadStatus? status,
    String? fileName,
    String? filePath,
    String? errorMessage,
    bool clearFileName = false,
    bool clearFilePath = false,
    bool clearErrorMessage = false,
  }) {
    return NominationDocumentUploadState(
      status: status ?? this.status,
      fileName: clearFileName ? null : (fileName ?? this.fileName),
      filePath: clearFilePath ? null : (filePath ?? this.filePath),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}
