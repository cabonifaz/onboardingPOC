import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pose.dart';

class FaceEnrollmentService {
  static const String _baseUrl =
      'https://configsrfbackendstaging-dpdbdyahdtenbecr.canadacentral-01.azurewebsites.net/srf/rostro/enrolamiento/registrar';

  final http.Client _client;

  FaceEnrollmentService({http.Client? client})
      : _client = client ?? http.Client();

  Future<bool> enrollFaces({
    required String username,
    required List<Pose> poses,
  }) async {
    try {
      final url = Uri.parse(_baseUrl);
      final request = FaceEnrollmentRequest(
        descripcion: username,
        lstFotos: poses,
      );

      print('[FaceEnrollmentService] Enrolling faces: ${request.toJson()}');
      return true;
      // final response = await _client.post(
      //   url,
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Accept': 'application/json',
      //   },
      //   body: jsonEncode(request.toJson()),
      // );

      // if (response.statusCode == 200) {
      //   print('[FaceEnrollmentService] Enrollment successful');
      //   return true;
      // } else {
      //   print(
      //       '[FaceEnrollmentService] Enrollment failed: ${response.statusCode}');
      //   throw Exception('Error en el servidor: ${response.statusCode}');
      // }
    } catch (e) {
      throw Exception('Error al enviar las imágenes: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
