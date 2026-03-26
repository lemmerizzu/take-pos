import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_update.dart';
import '../services/update_service.dart';

enum UpdateStatus { idle, checking, available, downloading, readyToInstall, failed }

class UpdateState {
  final UpdateStatus status;
  final AppUpdate? update;
  final double progress;
  final String? localApkPath;
  final String? error;

  UpdateState({
    this.status = UpdateStatus.idle,
    this.update,
    this.progress = 0.0,
    this.localApkPath,
    this.error,
  });

  UpdateState copyWith({
    UpdateStatus? status,
    AppUpdate? update,
    double? progress,
    String? localApkPath,
    String? error,
  }) {
    return UpdateState(
      status: status ?? this.status,
      update: update ?? this.update,
      progress: progress ?? this.progress,
      localApkPath: localApkPath ?? this.localApkPath,
      error: error ?? this.error,
    );
  }
}

class UpdateNotifier extends Notifier<UpdateState> {
  final UpdateService _service = UpdateService();

  @override
  UpdateState build() {
    return UpdateState();
  }

  Future<void> checkForUpdate() async {
    state = state.copyWith(status: UpdateStatus.checking);
    final update = await _service.checkForUpdate();
    if (update != null) {
      state = state.copyWith(status: UpdateStatus.available, update: update);
    } else {
      state = state.copyWith(status: UpdateStatus.idle);
    }
  }

  Future<void> downloadAndInstall() async {
    if (state.update == null) return;
    
    state = state.copyWith(status: UpdateStatus.downloading, progress: 0);
    
    final path = await _service.downloadUpdate(
      state.update!, 
      (p) => state = state.copyWith(progress: p),
    );

    if (path != null) {
      state = state.copyWith(status: UpdateStatus.readyToInstall, localApkPath: path);
      await _service.installUpdate(path);
    } else {
      state = state.copyWith(status: UpdateStatus.failed, error: 'Download failed');
    }
  }
}

final updateProvider = NotifierProvider<UpdateNotifier, UpdateState>(UpdateNotifier.new);
