import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with TickerProviderStateMixin {
  late AnimationController _flowerController;
  late AnimationController _textController;

  @override
  void initState() {
    super.initState();
    
    _flowerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _startAnimations();
  }

  @override
  void dispose() {
    _flowerController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _startAnimations() {
    _flowerController.repeat(reverse: true);
    _textController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Top flower with animation
            AnimatedBuilder(
              animation: _flowerController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_flowerController.value * 0.2),
                  child: const Text(
                    '🌸',
                    style: TextStyle(fontSize: 48),
                  ),
                );
              },
            ).animate().scale(delay: 200.ms, duration: 600.ms),
            
            const SizedBox(height: 20),
            
            // Main title with fade-in
            AnimatedBuilder(
              animation: _textController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _textController,
                  child: const Text(
                    'Lexi Central',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFF6B8B),
                    ),
                  ),
                );
              },
            ).animate().fadeIn(delay: 400.ms),
            
            const SizedBox(height: 20),
            
            // Bottom flower with animation
            AnimatedBuilder(
              animation: _flowerController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_flowerController.value * 0.2),
                  child: const Text(
                    '🌸',
                    style: TextStyle(fontSize: 48),
                  ),
                );
              },
            ).animate().scale(delay: 600.ms, duration: 600.ms),
            
            const SizedBox(height: 40),
            
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFB7C5)),
              strokeWidth: 3,
            ).animate().fadeIn(delay: 800.ms),
            
            const SizedBox(height: 20),
            
            // Loading text
            Text(
              'Loading your magical experience...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ).animate().fadeIn(delay: 1000.ms),
            
            // Floating flowers around the main content
            Positioned.fill(
              child: Stack(
                children: [
                  // Top left flower
                  Positioned(
                    top: 100,
                    left: 50,
                    child: _buildFloatingFlower(0),
                  ),
                  // Top right flower
                  Positioned(
                    top: 100,
                    right: 50,
                    child: _buildFloatingFlower(1),
                  ),
                  // Bottom left flower
                  Positioned(
                    bottom: 100,
                    left: 50,
                    child: _buildFloatingFlower(2),
                  ),
                  // Bottom right flower
                  Positioned(
                    bottom: 100,
                    right: 50,
                    child: _buildFloatingFlower(3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingFlower(int index) {
    final delay = [200, 400, 600, 800][index];
    final flower = ['🌸', '🌺', '🌼', '🌷'][index];
    
    return AnimatedBuilder(
      animation: _flowerController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            -20 + (_flowerController.value * 40),
          ),
          child: Opacity(
            opacity: 0.3 + (_flowerController.value * 0.3),
            child: Text(
              flower,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        );
      },
    ).animate().scale(delay: delay.ms, duration: 1000.ms).then().shimmer();
  }
}
