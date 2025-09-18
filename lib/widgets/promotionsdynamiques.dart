import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/promotion.dart';
import 'package:kanjad/services/promotion/servicepromotion.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DynamicPromotionImages extends StatefulWidget {
  final String cote; // 'gauche' ou 'droite'
  final PromotionService promotionService;

  const DynamicPromotionImages({
    super.key,
    required this.cote,
    required this.promotionService,
  });

  @override
  State<DynamicPromotionImages> createState() => _DynamicPromotionImagesState();
}

class _DynamicPromotionImagesState extends State<DynamicPromotionImages> {
  List<Promotion>? _promotions;
  bool _isLoading = true;
  String? _errorMessage;
  late PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadPromotions();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    if (_promotions == null || _promotions!.length <= 1) return;

    _pageController.addListener(() {
      if (mounted) {
        setState(() {
          _currentPage = _pageController.page?.round() ?? 0;
        });
      }
    });

    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && _promotions != null && _promotions!.isNotEmpty) {
        final nextPage = (_currentPage + 1) % _promotions!.length;
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  Future<void> _loadPromotions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final toutesPromotions = await widget.promotionService.getPromotionsActives(widget.cote);
      final promotionsSelectionnees = widget.promotionService.selectionAleatoire(toutesPromotions);

      if (mounted) {
        setState(() {
          _promotions = promotionsSelectionnees;
          _isLoading = false;
        });
        _startAutoPlay();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur de chargement des promotions: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate dynamic height based on screen size
    final screenSize = MediaQuery.of(context).size;
    final containerHeight = screenSize.height > 800
        ? screenSize.height * 0.4  // Large screens: 40% of height
        : screenSize.height > 600
            ? screenSize.height * 0.35  // Medium screens: 35% of height
            : screenSize.height * 0.25;  // Small screens: 25% of height

    if (_isLoading) {
      return Container(
        height: containerHeight,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Container(
        height: containerHeight,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadPromotions,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_promotions == null || _promotions!.isEmpty) {
      return Container(
        height: containerHeight,
        alignment: Alignment.center,
        child: const Text('Aucune promotion disponible'),
      );
    }

    return SizedBox(
      height: containerHeight,
      child: _promotions!.length == 1
          ? _buildSinglePromotion(_promotions!.first)
          : _buildMultiplePromotions(),
    );
  }

  Widget _buildSinglePromotion(Promotion promotion) {
    if (promotion.videoUrl != null && promotion.videoUrl!.isNotEmpty) {
      return VideoPlayerWidget(videoUrl: promotion.videoUrl!);
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CachedNetworkImage(
          imageUrl: promotion.imageUrl,
          fit: BoxFit.scaleDown,
          width: double.infinity,
          height: double.infinity,
          errorWidget: (context, url, error) {
            return Container(
              color: Colors.grey[300],
              alignment: Alignment.center,
              child: const Icon(Icons.error),
            );
          },
        ),
      );
    }
  }

  Widget _buildMultiplePromotions() {
    return PageView.builder(
      controller: _pageController,
      itemCount: _promotions!.length,
      itemBuilder: (context, index) {
        final promotion = _promotions![index];

        Widget mediaWidget;
        if (promotion.videoUrl != null && promotion.videoUrl!.isNotEmpty) {
          mediaWidget = VideoPlayerWidget(videoUrl: promotion.videoUrl!);
        } else {
          mediaWidget = CachedNetworkImage(
            imageUrl: promotion.imageUrl,
            fit: BoxFit.scaleDown, // Changed to cover full height
            width: double.infinity,
            height: double.infinity,
            errorWidget: (context, url, error) {
              return Container(
                color: Colors.grey[300],
                alignment: Alignment.center,
                child: const Icon(Icons.error),
              );
            },
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: mediaWidget,
          ),
        );
      },
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
              _hasError = false;
            });
            _controller.setVolume(0);
            _controller.setLooping(true);
            _controller.play();
          }
        }).catchError((error) {
          if (mounted) {
            setState(() {
              _isInitialized = false;
              _hasError = true;
            });
          }
        });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      if (_hasError) {
        return Container(
          color: Colors.grey[300],
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off, color: Colors.grey, size: 50),
              const SizedBox(height: 8),
              const Text('Vidéo indisponible', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        );
      }
      return Container(
        color: Colors.grey[300],
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}
