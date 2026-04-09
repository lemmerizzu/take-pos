import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/update_provider.dart';

class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(updateProvider);

    if (updateState.status == UpdateStatus.idle) {
      return const SizedBox.shrink();
    }

    String message = '';
    Widget? trailing;
    Color color = Colors.blue;

    switch (updateState.status) {
      case UpdateStatus.available:
        message = 'New update available: v${updateState.update?.versionName}';
        trailing = TextButton(
          onPressed: () => ref.read(updateProvider.notifier).downloadAndInstall(),
          child: const Text('Update Now', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        );
        break;
      case UpdateStatus.downloading:
        message = 'Downloading update... ${(updateState.progress * 100).toInt()}%';
        trailing = SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            value: updateState.progress,
            strokeWidth: 2,
            color: Colors.white,
          ),
        );
        break;
      case UpdateStatus.readyToInstall:
        message = 'Update ready to install';
        trailing = TextButton(
          onPressed: () => ref.read(updateProvider.notifier).downloadAndInstall(),
          child: const Text('Install', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        );
        break;
      case UpdateStatus.failed:
        message = 'Update failed: ${updateState.error}';
        color = Colors.red;
        trailing = IconButton(
          icon: const Icon(LucideIcons.refreshCw, color: Colors.white),
          onPressed: () => ref.read(updateProvider.notifier).checkForUpdate(),
        );
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color,
      child: Row(
        children: [
          const Icon(LucideIcons.info, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          trailing,


        ],
      ),
    );
  }
}
