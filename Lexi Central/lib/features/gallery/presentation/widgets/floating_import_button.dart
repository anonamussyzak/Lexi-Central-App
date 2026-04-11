import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/bouncy_button.dart';
import '../../domain/providers/gallery_provider.dart';

class FloatingImportButton extends ConsumerWidget {
  const FloatingImportButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final galleryState = ref.watch(galleryProvider);

    return Positioned(
      bottom: 24,
      right: 24,
      child: BouncyButton(
        onTap: () => ref.read(galleryProvider.notifier).importMedia(),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFFB7C5),
                const Color(0xFFFF6B8B),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB7C5).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: galleryState.isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
        ),
      ).animate().scale(delay: 500.ms, duration: 400.ms).then().shimmer(),
    );
  }
}
