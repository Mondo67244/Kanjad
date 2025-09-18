
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';

// Widget principal qui charge les données et gère le défilement
class PromotionsColumn extends StatefulWidget {
  final String position;
  const PromotionsColumn({super.key, required this.position});

  @override
  State<PromotionsColumn> createState() => _PromotionsColumnState();
}

class _PromotionsColumnState extends State<PromotionsColumn> {
  late final Future<List<Map<String, dynamic>>> _promotionsFuture;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _promotionsFuture = _fetchPromotions();
  }

  Future<List<Map<String, dynamic>>> _fetchPromotions() async {
    try {
      final List<dynamic> result = await _supabase.rpc(
        'get_random_promotions',
        params: {'p_position': widget.position, 'p_limit': 3},
      );
      // La RPC renvoie une List<dynamic>, nous la convertissons
      return result.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      // Gérer l'erreur, par exemple en loggant ou en affichant un message
      print('Erreur lors de la récupération des promotions: $e');
      return []; // Retourner une liste vide en cas d'erreur
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _promotionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Icon(Icons.hide_image_outlined, color: Colors.grey, size: 40));
        }

        final promotions = snapshot.data!;
        return AutoScrollingPromotions(promotions: promotions);
      },
    );
  }
}

// Widget qui gère l'affichage et le défilement automatique (PageView)
class AutoScrollingPromotions extends StatefulWidget {
  final List<Map<String, dynamic>> promotions;
  const AutoScrollingPromotions({super.key, required this.promotions});

  @override
  State<AutoScrollingPromotions> createState() => _AutoScrollingPromotionsState();
}

class _AutoScrollingPromotionsState extends State<AutoScrollingPromotions> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    if (widget.promotions.length > 1) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _currentPage = (_currentPage + 1) % widget.promotions.length;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
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
      itemCount: widget.promotions.length,
      itemBuilder: (context, index) {
        final promo = widget.promotions[index];
        final fileType = promo['file_type'];
        final url = promo['image_url'];

        if (fileType == 'video') {
          return VideoPlayerWidget(videoUrl: url);
        } else {
          return CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          );
        }
      },
    );
  }
}

// Widget dédié à l'affichage d'une vidéo
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
            _controller.setVolume(0); // Vidéos en sourdine par défaut
            _controller.setLooping(true);
            _controller.play();
            setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : const Center(child: CircularProgressIndicator());
  }
}
