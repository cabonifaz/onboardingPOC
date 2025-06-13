import 'dart:io';

import 'package:flutter_fractal_onboarding_poc/features/app/face_pose/exceptions/face_pose_exceptions.dart';
import 'package:flutter_fractal_onboarding_poc/features/app/face_pose/models/face_pose_images.dart';
import 'package:flutter_fractal_onboarding_poc/features/app/face_pose/service/face_pose_storage.dart';

class FacePoseRepository {
  const FacePoseRepository({required this.storageService});

  final FacePoseStorageService storageService;

  /// Guarda la imagen frontal y devuelve las imágenes actualizadas
  Future<FacePoseImages> saveFrontImage(String imagePath) async {
    try {
      await _validateImageFile(imagePath);
      final currentImages = await storageService.getFacePoseImages();
      final updatedImages = currentImages.copyWith(frontImagePath: imagePath);
      try {
        await storageService.saveFacePoseImages(updatedImages);
        return updatedImages;
      } catch (e, stackTrace) {
        throw ImageSaveException(
          imagePath,
          poseType: 'imagen frontal',
          cause: e,
        )..stackTrace = stackTrace;
      }
    } on FacePoseException {
      rethrow;
    } catch (e, stackTrace) {
      throw ImageSaveException(
        imagePath,
        poseType: 'imagen frontal',
        cause: e,
      )..stackTrace = stackTrace;
    }
  }

  /// Guarda la imagen de perfil derecho y devuelve las imágenes actualizadas
  Future<FacePoseImages> saveRightImage(String imagePath) async {
    try {
      await _validateImageFile(imagePath);
      final currentImages = await storageService.getFacePoseImages();
      final updatedImages = currentImages.copyWith(rightImagePath: imagePath);
      try {
        await storageService.saveFacePoseImages(updatedImages);
        return updatedImages;
      } catch (e, stackTrace) {
        throw ImageSaveException(
          imagePath,
          poseType: 'imagen de perfil derecho',
          cause: e,
        )..stackTrace = stackTrace;
      }
    } on FacePoseException {
      rethrow;
    } catch (e, stackTrace) {
      throw ImageSaveException(
        imagePath,
        poseType: 'imagen de perfil derecho',
        cause: e,
      )..stackTrace = stackTrace;
    }
  }

  /// Guarda la imagen de perfil izquierdo y devuelve las imágenes actualizadas
  Future<FacePoseImages> saveLeftImage(String imagePath) async {
    try {
      await _validateImageFile(imagePath);
      final currentImages = await storageService.getFacePoseImages();
      final updatedImages = currentImages.copyWith(leftImagePath: imagePath);
      try {
        await storageService.saveFacePoseImages(updatedImages);
        return updatedImages;
      } catch (e, stackTrace) {
        throw ImageSaveException(
          imagePath,
          poseType: 'imagen de perfil izquierdo',
          cause: e,
        )..stackTrace = stackTrace;
      }
    } on FacePoseException {
      rethrow;
    } catch (e, stackTrace) {
      throw ImageSaveException(
        imagePath,
        poseType: 'imagen de perfil izquierdo',
        cause: e,
      )..stackTrace = stackTrace;
    }
  }

  /// Obtiene todas las imágenes guardadas
  /// Devuelve el estado actual de las imágenes, incluso si no están todas completas
  Future<FacePoseImages> getAllImages() async {
    try {
      return await storageService.getFacePoseImages();
    } catch (e, stackTrace) {
      throw StorageException(
        'No se pudieron obtener las imágenes guardadas',
        e,
      )..stackTrace = stackTrace;
    }
  }

  /// Verifica si todas las imágenes requeridas han sido guardadas
  Future<bool> areAllImagesSaved() async {
    try {
      final images = await storageService.getFacePoseImages();
      return images.isComplete;
    } catch (e, stackTrace) {
      throw StorageException(
        'Error al verificar el estado de las imágenes',
        e,
      )..stackTrace = stackTrace;
    }
  }

  /// Verifica si todas las imágenes requeridas están presentes
  /// Lanza una [IncompleteImagesException] si faltan imágenes
  Future<FacePoseImages> verifyAllImages() async {
    final images = await getAllImages();
    if (!images.isComplete) {
      final missing = <String>[];
      if (images.frontImagePath == null) missing.add('frente');
      if (images.rightImagePath == null) missing.add('perfil derecho');
      if (images.leftImagePath == null) missing.add('perfil izquierdo');
      throw IncompleteImagesException(missing);
    }
    return images;
  }

  /// Limpia todas las imágenes guardadas
  Future<void> clearAllImages() async {
    try {
      await storageService.clearAllPaths();
    } catch (e, stackTrace) {
      throw StorageException(
        'No se pudieron limpiar las imágenes',
        e,
      )..stackTrace = stackTrace;
    }
  }

  /// Valida que el archivo de imagen exista
  Future<void> _validateImageFile(String imagePath) async {
    try {
      final file = File(imagePath);
      final exists = await file.exists();
      if (!exists) {
        throw ImageNotFoundException(imagePath);
      }
    } on FileSystemException catch (e) {
      throw ImageNotFoundException(
        imagePath,
        'No se pudo acceder al archivo: ${e.message}',
      );
    } on Exception catch (e) {
      throw ImageNotFoundException(
        imagePath,
        'Error al validar el archivo: $e',
      );
    }
  }
}
