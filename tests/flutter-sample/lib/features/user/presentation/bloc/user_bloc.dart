/// GOOD: BLoC pattern implementation
/// GOOD: snake_case file name with _bloc suffix

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

// Events
abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object> get props => [];
}

class LoadUser extends UserEvent {
  final int userId;

  const LoadUser(this.userId);

  @override
  List<Object> get props => [userId];
}

// States
abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final User user;

  const UserLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

class UserError extends UserState {
  final String message;

  const UserError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc() : super(UserInitial()) {
    on<LoadUser>(_onLoadUser);
  }

  Future<void> _onLoadUser(LoadUser event, Emitter<UserState> emit) async {
    emit(UserLoading());
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      emit(const UserLoaded(User(
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
      )));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }
}
