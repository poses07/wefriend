import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HeartExplosionOverlay extends StatefulWidget {
  final bool isSuperLike;
  
  const HeartExplosionOverlay({super.key, this.isSuperLike = false});

  static void show(BuildContext context, {bool isSuperLike = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => HeartExplosionOverlay(isSuperLike: isSuperLike),
    );
  }

  @override
  State<HeartExplosionOverlay> createState() => _HeartExplosionOverlayState();
}

class _HeartExplosionOverlayState extends State<HeartExplosionOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.5).chain(CurveTween(curve: Curves.elasticOut)), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 2.0).chain(CurveTween(curve: Curves.easeIn)), weight: 40),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    _play();
  }

  void _play() async {
    HapticFeedback.heavyImpact();
    await _controller.forward();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSuperLike ? Colors.amberAccent : Colors.pinkAccent;
    final icon = widget.isSuperLike ? Icons.star_rounded : Icons.favorite_rounded;
    
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    icon,
                    size: 150,
                    color: color,
                    shadows: [
                      Shadow(color: color.withValues(alpha: 0.8), blurRadius: 40, offset: const Offset(0, 0)),
                      Shadow(color: color.withValues(alpha: 0.5), blurRadius: 80, offset: const Offset(0, 0)),
                    ],
                  ),
                  if (widget.isSuperLike)
                    const Positioned(
                      bottom: 20,
                      child: Text(
                        'SUPER LIKE!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black, blurRadius: 5)],
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}