import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:kanjad/basicdata/style.dart';

class AnimatedLoadingBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0

  const AnimatedLoadingBar({super.key, required this.progress});

  // Helper to determine the current icon based on progress
  IconData _getCurrentIcon(double progress) {
    if (progress < 0.5) {
      return FluentIcons.search_24_regular;
    } else if (progress < 0.8) {
      return FluentIcons.shopping_bag_24_regular;
    } else {
      return FluentIcons.heart_24_regular;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth * 0.8;
        // Increased sizes as requested
        const iconSize = 44.0;
        const barHeight = 12.0;

        // Calculate the position for the single translating icon
        final double iconPosition = (barWidth * progress) - (iconSize / 2);

        return SizedBox(
          width: barWidth,
          height: iconSize, // Height is now just the icon size
          child: Stack(
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.none, // Allow icon to overflow slightly
            children: [
              // The progress bar track
              Container(
                height: barHeight,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(barHeight / 2),
                ),
              ),
              // The progress bar fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 2500),
                curve: Curves.easeOutCubic,
                height: barHeight,
                width: barWidth * progress,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(barHeight / 2),
                ),
              ),
              // The single, translating icon
              AnimatedPositioned(
                duration: const Duration(milliseconds: 2500),
                curve: Curves.easeOutCubic,
                left: iconPosition.clamp(0, barWidth - iconSize),
                child: Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Styles.bleu,
                      border: Border.all(color: Styles.rouge, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ]),
                  child: Icon(
                    _getCurrentIcon(progress),
                    color: Colors.white,
                    size: iconSize * 0.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
