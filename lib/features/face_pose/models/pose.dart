class Pose {
  final int idTipoPerfil;
  final String foto64;

  Pose({
    required this.idTipoPerfil,
    required this.foto64,
  });

  Map<String, dynamic> toJson() => {
        'idTipoPerfil': idTipoPerfil,
        'foto64': foto64,
      };
}

class FaceEnrollmentRequest {
  final String descripcion;
  final List<Pose> lstFotos;

  FaceEnrollmentRequest({
    required this.descripcion,
    required this.lstFotos,
  });

  Map<String, dynamic> toJson() => {
        'descripcion': descripcion,
        'lstFotos': lstFotos.map((pose) => pose.toJson()).toList(),
      };
}
