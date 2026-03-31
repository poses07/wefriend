import 'package:flutter/material.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'story_editor_screen.dart';

class FullScreenCameraScreen extends StatelessWidget {
  const FullScreenCameraScreen({super.key});

  Future<void> _pickFromGallery(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && context.mounted) {
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => StoryEditorScreen(imagePath: image.path),
        ),
      );

      if (result != null && context.mounted) {
        Navigator.pop(context, result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CameraAwesomeBuilder.awesome(
        saveConfig: SaveConfig.photo(
          pathBuilder: (sensors) async {
            // Geçici bir dosya yolu oluştur
            final Directory extDir = await Directory.systemTemp.createTemp();
            final testDir = await Directory(
              '${extDir.path}/test',
            ).create(recursive: true);
            final String filePath =
                '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
            return SingleCaptureRequest(filePath, sensors.first);
          },
        ),
        onMediaTap: (mediaCapture) {
          if (mediaCapture.status == MediaCaptureStatus.success) {
            mediaCapture.captureRequest.when(
              single: (single) async {
                // Fotoğraf çekildiğinde geri dönmek yerine StoryEditorScreen'e git
                if (single.file != null) {
                  final result = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              StoryEditorScreen(imagePath: single.file!.path),
                    ),
                  );

                  // Eğer StoryEditorScreen'den bir sonuç döndüyse (başarıyla kaydedildiyse)
                  // bu sonucu da geldiğimiz yere (HomeScreen) iletelim.
                  if (result != null && context.mounted) {
                    Navigator.pop(context, result);
                  }
                }
              },
              multiple: (multiple) {},
            );
          }
        },
        topActionsBuilder:
            (state) => AwesomeTopActions(
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
        bottomActionsBuilder:
            (state) => AwesomeBottomActions(
              state: state,
              left: AwesomeCameraSwitchButton(state: state),
              right: IconButton(
                icon: const Icon(
                  Icons.photo_library_rounded,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () => _pickFromGallery(context),
              ),
            ),
      ),
    );
  }
}
