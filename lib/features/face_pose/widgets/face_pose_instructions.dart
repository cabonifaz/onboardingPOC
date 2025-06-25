import 'package:flutter/material.dart';
import 'package:flutter_fractal_onboarding_poc/features/face_pose/bloc/face_pose_bloc.dart';

class FacePoseInstructions extends StatelessWidget {
  final FacePoseState state;

  const FacePoseInstructions({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        color: Colors.black54,
        child: Column(
          children: [
            Text(
              state.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Mantén la posición hasta que se tome la foto',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
