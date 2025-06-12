part of 'username_bloc.dart';

enum SubmissionStatus { initial, success, failure }

class UsernameState extends Equatable {
  final String username;
  final bool isValid;
  final SubmissionStatus submissionStatus;

  const UsernameState({
    this.username = '',
    this.isValid = false,
    this.submissionStatus = SubmissionStatus.initial,
  });

  UsernameState copyWith({
    String? username,
    bool? isValid,
    SubmissionStatus? submissionStatus,
  }) {
    return UsernameState(
      username: username ?? this.username,
      isValid: isValid ?? this.isValid,
      submissionStatus: submissionStatus ?? this.submissionStatus,
    );
  }

  @override
  List<Object> get props => [username, isValid, submissionStatus];
}
