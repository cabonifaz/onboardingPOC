import 'dart:convert';
import 'dart:developer';
import 'package:flutter_fractal_onboarding_poc/features/face_pose/models/face_pose_images.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FacePoseStorageService {
  static const String _storageKey = 'face_pose_images';

  // Guardar las rutas de las imágenes
  Future<void> saveFacePoseImages(FacePoseImages images) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(images.toJson()));

    final savedImages = await getFacePoseImages();
    log('[FacePoseStorageService] saved images: ${savedImages.toJson()}');
  }

  // Obtener las rutas de las imágenes
  Future<FacePoseImages> getFacePoseImages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null) {
      return const FacePoseImages();
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return FacePoseImages.fromJson(json);
    } catch (e) {
      // En caso de error al parsear, devolver un objeto vacío
      return const FacePoseImages();
    }
  }

  // Limpiar todas las rutas guardadas
  Future<void> clearAllPaths() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
