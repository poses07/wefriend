import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';

class MatchOverlay extends StatefulWidget {
  final String myAvatarUrl;
  final String theirAvatarUrl;
  final String theirName;
  final VoidCallback onSendMessage;

  const MatchOverlay({
    super.key,
    required this.myAvatarUrl,
    required this.theirAvatarUrl,
    required this.theirName,
    required this.onSendMessage,
  });

  static void show(
    BuildContext context, {
    required String myAvatarUrl,
    required String theirAvatarUrl,
    required String theirName,
    required VoidCallback onSendMessage,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: MatchOverlay(
            myAvatarUrl: myAvatarUrl,
            theirAvatarUrl: theirAvatarUrl,
            theirName: theirName,
            onSendMessage: onSendMessage,
          ),
        );
      },
    );
  }

  @override
  State<MatchOverlay> createState() => _MatchOverlayState();
}

class _MatchOverlayState extends State<MatchOverlay> with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );

    _playSequence();
  }

  void _playSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    HapticFeedback.heavyImpact();
    _animController.forward();
    _confettiController.play();
    
    await Future.delayed(const Duration(milliseconds: 300));
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 300));
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.pink, Colors.red, Colors.purple, Colors.white],
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.2,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: const Text(
                  'IT\'S A MATCH!',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Colors.greenAccent,
                    shadows: [
                      Shadow(color: Colors.green, blurRadius: 20),
                      Shadow(color: Colors.black, blurRadius: 10, offset: Offset(2, 2)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ScaleTransition(
                scale: _scaleAnimation,
                child: Text(
                  'Sen ve ${widget.theirName} birbirinizi beğendiniz.',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ScaleTransition(
                scale: _scaleAnimation,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAvatar(widget.myAvatarUrl, -15),
                    _buildAvatar(widget.theirAvatarUrl, 15),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              ScaleTransition(
                scale: _scaleAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onSendMessage();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 10,
                          shadowColor: Colors.pinkAccent.withValues(alpha: 0.5),
                        ),
                        child: const Text(
                          'MESAJ GÖNDER',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                        ),
                        child: const Text(
                          'KEŞFETMEYE DEVAM ET',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String url, double rotationAngle) {
    return Transform.rotate(
      angle: rotationAngle * 3.1415927 / 180,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.pinkAccent.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 5,
            )
          ],
          image: DecorationImage(
            image: NetworkImage(url.isNotEmpty ? url : 'https://via.placeholder.com/150'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}