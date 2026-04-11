import 'package:flutter/material.dart';

class KirbyBackground extends StatelessWidget {
  final Widget child;
  final double opacity;

  const KirbyBackground({
    required this.child,
    this.opacity = 0.08,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFFF5F7),
                const Color(0xFFB8F2E6).withOpacity(0.1),
                const Color(0xFFFFF5B7).withOpacity(0.1),
                const Color(0xFFFFF5F7),
              ],
            ),
          ),
        ),
        
        // Kirby GIF background
        Positioned.fill(
          child: Opacity(
            opacity: opacity,
            child: Image.asset(
              'assets/kirby.gif',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to a static image if GIF fails
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.0,
                      colors: [
                        const Color(0xFFFFB7C5).withOpacity(0.1),
                        const Color(0xFFB8F2E6).withOpacity(0.05),
                        const Color(0xFFFFF5F7),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        
        // Main content
        child,
      ],
    );
  }
}
