import 'dart:io';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../models/app_update.dart';

class UpdateService {
  final Dio _dio = Dio();
  
  // TODO: The user should replace this with their actual hosting URL
  static const String updateUrl = 'https://raw.githubusercontent.com/user/repo/main/version.json';

  Future<AppUpdate?> checkForUpdate() async {
    try {
      final response = await _dio.get(updateUrl);
      if (response.statusCode == 200) {
        final update = AppUpdate.fromJson(response.data);
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 0;

        if (update.versionCode > currentVersionCode) {
          return update;
        }
      }
    } catch (e) {
      print('Update check failed: $e');
    }
    return null;
  }

  Future<String?> downloadUpdate(AppUpdate update, Function(double) onProgress) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/app-update.apk';
      
      // Delete old file if exists
      final file = File(savePath);
      if (await file.exists()) {
        await file.delete();
      }

      await _dio.download(
        update.url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );
      
      return savePath;
    } catch (e) {
       print('Download failed: $e');
    }
    return null;
  }

  Future<void> installUpdate(String apkPath) async {
    await OpenFilex.open(apkPath);
  }
}
