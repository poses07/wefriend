import 'package:flutter/material.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'dart:io';

class FullScreenCameraScreen extends StatelessWidget {
  const FullScreenCameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CameraAwesomeBuilder.awesome(
        saveConfig: SaveConfig.photo(
          pathBuilder: (sensors) async {
            // Geçici bir dosya yolu oluştur
            final Directory extDir = await Directory.systemTemp.createTemp();
            final testDir = await Directory('${extDir.path}/test').create(recursive: true);
            final String filePath = '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
            return SingleCaptureRequest(filePath, sensors.first);
          },
        ),
        onMediaTap: (mediaCapture) {
          if (mediaCapture.status == MediaCaptureStatus.success) {
            mediaCapture.captureRequest.when(
              single: (single) {
                // Fotoğraf çekildiğinde geri dön ve dosya yolunu ilet
                if (single.file != null) {
                  Navigator.pop(context, single.file!.path);
                }
              },
              multiple: (multiple) {},
            );
          }
        },
        topActionsBuilder: (state) => AwesomeTopActions(
          padding: EdgeInsets.zero,
          state: state,
          children: [
            AwesomeFlashButton(state: state),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
