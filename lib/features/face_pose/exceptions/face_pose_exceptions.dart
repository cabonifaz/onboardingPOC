/// Base exception for face pose related errors
class FacePoseException implements Exception {
  /// A message describing the error.
  final String message;

  /// The underlying exception that caused this error, if any.
  final Object? cause;

  /// Stack trace for debugging purposes
  StackTrace? stackTrace;

  FacePoseException(this.message, [this.cause]);

  @override
  String toString() =>
      'FacePoseException: $message${cause != null ? '\nCaused by: $cause' : ''}';
}

/// Exception thrown when an image file is not found.
class ImageNotFoundException extends FacePoseException {
  final String imagePath;

  ImageNotFoundException(this.imagePath, [Object? cause])
      : super('Image not found at path: $imagePath', cause);
}

/// Exception thrown when there's an error saving an image.
class ImageSaveException extends FacePoseException {
  final String imagePath;
  final String? poseType;

  ImageSaveException(this.imagePath, {this.poseType, Object? cause})
      : super(
          'Failed to save ${poseType ?? 'image'} at path: $imagePath',
          cause,
        );
}

/// Exception thrown when required images are missing.
class IncompleteImagesException extends FacePoseException {
  final List<String> missingPoses;

  IncompleteImagesException({required this.missingPoses, Object? cause})
      : super(
          'Missing required images for poses: ${missingPoses.join(', ')}',
          cause,
        );
}

/// Exception thrown when there's a problem with the storage service.
class StorageException extends FacePoseException {
  StorageException(String message, [Object? cause])
      : super('Storage error: $message', cause);
}
