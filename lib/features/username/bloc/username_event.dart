part of 'username_bloc.dart';

abstract class UsernameEvent extends Equatable {
  const UsernameEvent();

  @override
  List<Object> get props => [];
}

class UsernameChanged extends UsernameEvent {
  final String username;

  const UsernameChanged(this.username);

  @override
  List<Object> get props => [username];
}

class UsernameSubmitted extends UsernameEvent {}
