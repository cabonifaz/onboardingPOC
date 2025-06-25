import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fractal_onboarding_poc/features/username/bloc/username_bloc.dart';
import 'package:flutter_fractal_onboarding_poc/features/username/widgets/username_button.dart';
import 'package:flutter_fractal_onboarding_poc/features/username/widgets/username_textfield.dart';

class UsernameView extends StatelessWidget {
  const UsernameView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<UsernameBloc>(),
      child: const UsernameBody(),
    );
  }
}

class UsernameBody extends StatelessWidget {
  const UsernameBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingresa tu nombre de usuario')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            UsernameTextField(),
            SizedBox(height: 20),
            UsernameButton(),
          ],
        ),
      ),
    );
  }
}
