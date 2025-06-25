import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fractal_onboarding_poc/features/face_pose/view/face_pose_view.dart';
import '../bloc/username_bloc.dart';

class UsernameButton extends StatelessWidget {
  const UsernameButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<UsernameBloc, UsernameState>(
      listenWhen: (prev, curr) =>
          prev.submissionStatus != curr.submissionStatus,
      listener: (context, state) {
        if (state.submissionStatus == SubmissionStatus.success) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const FacePoseView()),
          );
        } else if (state.submissionStatus == SubmissionStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username cannot be empty')),
          );
        }
      },
      child: ElevatedButton(
        onPressed: () {
          context.read<UsernameBloc>().add(UsernameSubmitted());
        },
        child: const Text('Continue'),
      ),
    );
  }
}
