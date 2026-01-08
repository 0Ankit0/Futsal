import 'package:flutter_bloc/flutter_bloc.dart';
import 'profile_event.dart';
import 'profile_state.dart';
import '../data/repository/profile_repository.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileBloc({required ProfileRepository profileRepository})
    : _profileRepository = profileRepository,
      super(const ProfileInitial()) {
    on<LoadUserInfo>(_onLoadUserInfo);
  }

  Future<void> _onLoadUserInfo(
    LoadUserInfo event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    try {
      final userInfo = await _profileRepository.getUserInfo();
      emit(ProfileLoaded(userInfo));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
