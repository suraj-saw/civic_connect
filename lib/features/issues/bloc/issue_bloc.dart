// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:equatable/equatable.dart';
// import 'package:civic_connect/features/issues/models/issue.dart';
// import 'package:civic_connect/features/issues/repositories/issue_repository.dart';
//
// // Events
// abstract class IssueEvent extends Equatable {
//   const IssueEvent();
//
//   @override
//   List<Object?> get props => [];
// }
//
// class SubmitIssueEvent extends IssueEvent {
//   final Issue issue;
//
//   const SubmitIssueEvent(this.issue);
//
//   @override
//   List<Object?> get props => [issue];
// }
//
// class LoadIssuesEvent extends IssueEvent {
//   final String? citizenId;
//
//   const LoadIssuesEvent({this.citizenId});
//
//   @override
//   List<Object?> get props => [citizenId];
// }
//
// class RefreshIssuesEvent extends IssueEvent {
//   final String? citizenId;
//
//   const RefreshIssuesEvent({this.citizenId});
//
//   @override
//   List<Object?> get props => [citizenId];
// }
//
// // States
// abstract class IssueState extends Equatable {
//   const IssueState();
//
//   @override
//   List<Object?> get props => [];
// }
//
// class IssueInitial extends IssueState {}
//
// class IssueSubmitting extends IssueState {}
//
// class IssueSubmitted extends IssueState {
//   final Issue issue;
//
//   const IssueSubmitted(this.issue);
//
//   @override
//   List<Object?> get props => [issue];
// }
//
// class IssueLoading extends IssueState {}
//
// class IssuesLoaded extends IssueState {
//   final List<Issue> issues;
//
//   const IssuesLoaded(this.issues);
//
//   @override
//   List<Object?> get props => [issues];
// }
//
// class IssueError extends IssueState {
//   final String message;
//
//   const IssueError(this.message);
//
//   @override
//   List<Object?> get props => [message];
// }
//
// // Bloc
// class IssueBloc extends Bloc<IssueEvent, IssueState> {
//   final IssueRepository repository;
//
//   IssueBloc({required this.repository}) : super(IssueInitial()) {
//     on<SubmitIssueEvent>(_onSubmitIssue);
//     on<LoadIssuesEvent>(_onLoadIssues);
//     on<RefreshIssuesEvent>(_onRefreshIssues);
//   }
//
//   Future<void> _onSubmitIssue(
//       SubmitIssueEvent event,
//       Emitter<IssueState> emit,
//       ) async {
//     emit(IssueSubmitting());
//
//     try {
//       await repository.submitIssue(event.issue);
//       emit(IssueSubmitted(event.issue));
//
//       // Automatically reset to initial state after a short delay
//       await Future.delayed(const Duration(milliseconds: 100));
//       emit(IssueInitial());
//     } catch (e) {
//       emit(IssueError(e.toString()));
//
//       // Reset to initial state after showing error
//       await Future.delayed(const Duration(seconds: 2));
//       emit(IssueInitial());
//     }
//   }
//
//   Future<void> _onLoadIssues(
//       LoadIssuesEvent event,
//       Emitter<IssueState> emit,
//       ) async {
//     emit(IssueLoading());
//
//     try {
//       final issues = await repository.getIssues(citizenId: event.citizenId);
//       emit(IssuesLoaded(issues));
//     } catch (e) {
//       emit(IssueError(e.toString()));
//     }
//   }
//
//   Future<void> _onRefreshIssues(
//       RefreshIssuesEvent event,
//       Emitter<IssueState> emit,
//       ) async {
//     try {
//       final issues = await repository.getIssues(citizenId: event.citizenId);
//       emit(IssuesLoaded(issues));
//     } catch (e) {
//       emit(IssueError(e.toString()));
//     }
//   }
// }