import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/custom_snackbar.dart';

class StoryEditorScreen extends StatefulWidget {
  final String imagePath;

  const StoryEditorScreen({super.key, required this.imagePath});

  @override
  State<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends State<StoryEditorScreen> {
  final GlobalKey _globalKey = GlobalKey();
  bool _isEditingText = false;
  String _storyText = '';
  Offset _textPosition = const Offset(100, 100);
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSaving = false;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _openTextEditor() {
    setState(() {
      _isEditingText = true;
    });
    _textController.text = _storyText;
    // Klavyenin açılması için biraz bekleyip focus yapıyoruz
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }

  void _closeTextEditor() {
    setState(() {
      _isEditingText = false;
      _storyText = _textController.text;
    });
    FocusScope.of(context).unfocus();
    
    // Eğer yeni metin yazıldıysa ve pozisyon başlangıçtaysa ekranın ortasına al
    if (_storyText.isNotEmpty && _textPosition == const Offset(100, 100)) {
      final size = MediaQuery.of(context).size;
      setState(() {
        _textPosition = Offset(size.width / 2 - 50, size.height / 2 - 50);
      });
    }
  }

  Future<void> _saveAndReturn() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      // Eğer metin yoksa direkt orijinal fotoğrafı gönder
      if (_storyText.trim().isEmpty) {
        Navigator.pop(context, widget.imagePath);
        return;
      }

      // RepaintBoundary'i kullanarak ekrandaki görüntüyü al
      RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Yeni görüntüyü geçici bir dosyaya kaydet
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/story_with_text_${DateTime.now().millisecondsSinceEpoch}.png';
      File imgFile = File(imagePath);
      await imgFile.writeAsBytes(pngBytes);

      if (mounted) {
        // Yeni dosya yolunu geri döndür
        Navigator.pop(context, imagePath);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Hikaye hazırlanırken hata oluştu.',
          type: NotificationType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Arka plandaki resim ve üzerine eklenecek yazılar (RepaintBoundary ile sarılı)
          RepaintBoundary(
            key: _globalKey,
            child: Stack(
              children: [
                // Tam Ekran Resim
                Positioned.fill(
                  child: Image.file(
                    File(widget.imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
                
                // Karartma efekti (Yazılar daha net okunsun diye üst kısma)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 150,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Sürükle-bırak metin
                if (!_isEditingText && _storyText.isNotEmpty)
                  Positioned(
                    left: _textPosition.dx,
                    top: _textPosition.dy,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _textPosition = Offset(
                            _textPosition.dx + details.delta.dx,
                            _textPosition.dy + details.delta.dy,
                          );
                        });
                      },
                      onTap: _openTextEditor,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _storyText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(1.0, 1.0),
                                blurRadius: 3.0,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Metin Düzenleme Ekranı (Üst Katman)
          if (_isEditingText)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: SafeArea(
                child: Column(
                  children: [
                    // Bitti Butonu
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextButton(
                          onPressed: _closeTextEditor,
                          child: const Text(
                            'Bitti',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          autofocus: true,
                          textAlign: TextAlign.center,
                          maxLines: null,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Yazmaya başla...',
                            hintStyle: TextStyle(
                              color: Colors.white54,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Normal Ekrandaki Üst Butonlar (Geri ve Metin Ekle)
          if (!_isEditingText)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 32),
                      onPressed: () => Navigator.pop(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.text_fields_rounded, color: Colors.white, size: 32),
                      onPressed: _openTextEditor,
                    ),
                  ],
                ),
              ),
            ),

          // Alt Paylaş Butonu
          if (!_isEditingText)
            Positioned(
              bottom: 40,
              right: 20,
              child: GestureDetector(
                onTap: _saveAndReturn,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Paylaş',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                          ],
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
