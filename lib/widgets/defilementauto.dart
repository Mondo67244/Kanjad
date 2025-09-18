import 'dart:async';
import 'package:flutter/material.dart';

class AutoScrollingImages extends StatefulWidget {
  final List<String> imagePaths;
  const AutoScrollingImages({super.key, required this.imagePaths});

  @override
  _AutoScrollingImagesState createState() => _AutoScrollingImagesState();
}

class _AutoScrollingImagesState extends State<AutoScrollingImages> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    if (widget.imagePaths.length > 1) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _currentPage = (_currentPage + 1) % widget.imagePaths.length;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.imagePaths.length,
      itemBuilder: (context, index) {
        return Image.asset(
          widget.imagePaths[index],
          fit: BoxFit.cover,
        );
      },
    );
  }
}
