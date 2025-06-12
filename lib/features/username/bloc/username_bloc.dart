import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'username_event.dart';
part 'username_state.dart';

class UsernameBloc extends Bloc<UsernameEvent, UsernameState> {
  UsernameBloc() : super(const UsernameState()) {
    on<UsernameChanged>(_onUsernameChanged);
    on<UsernameSubmitted>(_onUsernameSubmitted);
  }

  Future<void> _onUsernameSubmitted(
    UsernameSubmitted event,
    Emitter<UsernameState> emit,
  ) async {
    if (state.isValid) {
      emit(state.copyWith(submissionStatus: SubmissionStatus.success));
    } else {
      emit(state.copyWith(submissionStatus: SubmissionStatus.failure));
    }
  }

  Future<void> _onUsernameChanged(
    UsernameChanged event,
    Emitter<UsernameState> emit,
  ) async {
    emit(
      state.copyWith(
        username: event.username,
        isValid: event.username.trim().isNotEmpty,
      ),
    );
  }
}
