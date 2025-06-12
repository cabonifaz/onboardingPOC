import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/username_bloc.dart';

class UsernameTextField extends StatelessWidget {
  const UsernameTextField({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsernameBloc, UsernameState>(
      builder: (context, state) {
        return TextFormField(
          initialValue: state.username,
          decoration: const InputDecoration(
            labelText: 'Username',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) =>
              context.read<UsernameBloc>().add(UsernameChanged(value)),
        );
      },
    );
  }
}
