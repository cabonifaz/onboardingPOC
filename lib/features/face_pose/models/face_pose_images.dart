import 'package:equatable/equatable.dart';

class FacePoseImages extends Equatable {
  final String? frontImagePath;
  final String? rightImagePath;
  final String? leftImagePath;

  const FacePoseImages({
    this.frontImagePath,
    this.rightImagePath,
    this.leftImagePath,
  });

  // Crea una copia con los campos actualizados
  FacePoseImages copyWith({
    String? frontImagePath,
    String? rightImagePath,
    String? leftImagePath,
  }) {
    return FacePoseImages(
      frontImagePath: frontImagePath ?? this.frontImagePath,
      rightImagePath: rightImagePath ?? this.rightImagePath,
      leftImagePath: leftImagePath ?? this.leftImagePath,
    );
  }

  // Convierte el objeto a un mapa
  Map<String, dynamic> toJson() {
    return {
      'frontImagePath': frontImagePath,
      'rightImagePath': rightImagePath,
      'leftImagePath': leftImagePath,
    };
  }

  // Crea una instancia a partir de un mapa
  factory FacePoseImages.fromJson(Map<String, dynamic> json) {
    return FacePoseImages(
      frontImagePath: json['frontImagePath'],
      rightImagePath: json['rightImagePath'],
      leftImagePath: json['leftImagePath'],
    );
  }

  // Verifica si todas las imágenes están presentes
  bool get isComplete =>
      frontImagePath != null && rightImagePath != null && leftImagePath != null;

  @override
  List<Object?> get props => [frontImagePath, rightImagePath, leftImagePath];
}
