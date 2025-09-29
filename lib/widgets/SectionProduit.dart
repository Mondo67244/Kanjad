import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/produit.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/widgets/carteproduit.dart';

class ProductSection extends StatefulWidget {
  final String title;
  final List<Produit> allProduits;
  final int initialLimit;
  final bool isWideScreen;
  final Function(Produit) onTogglePanier;
  final Function(Produit) onTap;
  final List<String> idsPanier;
  final IconData? icon;
  final String? subtitle;
  final VoidCallback? onVoirPlus;

  const ProductSection({
    super.key,
    required this.title,
    required this.allProduits,
    required this.initialLimit,
    required this.isWideScreen,
    required this.onTogglePanier,
    required this.onTap,
    required this.idsPanier,
    this.icon,
    this.subtitle,
    this.onVoirPlus,
  });

  @override
  State<ProductSection> createState() => _ProductSectionState();
}

class _ProductSectionState extends State<ProductSection> {
  late final ScrollController _scrollController;
  Timer? _autoScrollTimer;
  bool _isUserInteracting = false;
  int _scrollCycles = 0;

  late List<Produit> _displayedProduits;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeDisplayedProducts();

    if (widget.allProduits.length > widget.initialLimit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeDisplayedProducts() {
    final shuffled = List<Produit>.from(widget.allProduits)..shuffle();
    _displayedProduits = shuffled.take(widget.initialLimit).toList();
  }

  void _refreshDisplayedProducts() {
    if (!mounted) return;

    setState(() {
      final shuffled = List<Produit>.from(widget.allProduits)..shuffle();
      _displayedProduits = shuffled.take(widget.initialLimit).toList();
      _scrollCycles = 0;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    });
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_isUserInteracting && mounted && _scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;
        final cardWidth = widget.isWideScreen ? 230.0 : 210.0;

        if (currentScroll + cardWidth > maxScroll) {
          _scrollCycles++;
          if (_scrollCycles >= 2) {
            _refreshDisplayedProducts();
          } else {
            _scrollController.animateTo(0, duration: const Duration(milliseconds: 800), curve: Curves.easeInOut);
          }
        } else {
          _scrollController.animateTo(currentScroll + cardWidth, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
        }
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
  }

  void _scrollManually(int direction) {
    _stopAutoScroll();
    final cardWidth = widget.isWideScreen ? 230.0 : 210.0;
    final scrollAmount = cardWidth * 2 * direction;
    final targetScroll = (_scrollController.offset + scrollAmount).clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(targetScroll, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) _startAutoScroll();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.allProduits.isEmpty) return const SizedBox.shrink();

    final double cardWidth = widget.isWideScreen ? 200 : 180;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: widget.isWideScreen ? 100 : 80,
                height: widget.isWideScreen ? 100 : 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Styles.rouge.withOpacity(0.8), Styles.rouge.withOpacity(0.6)],
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Icon(widget.icon ?? Icons.category, color: Colors.white, size: widget.isWideScreen ? 48 : 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: TextStyle(fontSize: widget.isWideScreen ? 24 : 20, fontWeight: FontWeight.w700, color: Colors.black87)),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(widget.subtitle!, style: TextStyle(fontSize: widget.isWideScreen ? 16 : 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                    ],
                  ],
                ),
              ),
              if (widget.onVoirPlus != null)
                TextButton(
                  onPressed: widget.onVoirPlus,
                  child: const Text('Voir plus', style: TextStyle(color: Styles.rouge, fontSize: 14, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: widget.isWideScreen ? 338 : 320,
              child: Listener(
                onPointerDown: (_) {
                  setState(() => _isUserInteracting = true);
                  _stopAutoScroll();
                },
                onPointerUp: (_) {
                  setState(() => _isUserInteracting = false);
                  Future.delayed(const Duration(seconds: 5), () {
                    if (mounted) _startAutoScroll();
                  });
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 700),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: ListView.builder(
                    key: ValueKey(_displayedProduits.hashCode),
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: _displayedProduits.length,
                    itemBuilder: (context, index) {
                      final produit = _displayedProduits[index];
                      final bool isPanier = widget.idsPanier.contains(produit.idproduit);
                      return Padding(
                        padding: const EdgeInsets.all(9),
                        child: SizedBox(
                          width: cardWidth + 30,
                          child: ProductCard(
                            produit: produit,
                            isPanier: isPanier,
                            isWideScreen: widget.isWideScreen,
                            onTogglePanier: () => widget.onTogglePanier(produit),
                            onTap: () => widget.onTap(produit),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (widget.allProduits.length > 3)
              Positioned(
                left: 0,
                child: _navButton(icon: Icons.arrow_back_ios_new, onPressed: () => _scrollManually(-1)),
              ),
            if (widget.allProduits.length > 3)
              Positioned(
                right: 0,
                child: _navButton(icon: Icons.arrow_forward_ios, onPressed: () => _scrollManually(1)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _navButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.2 * 255).round()), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 18),
        onPressed: onPressed,
      ),
    );
  }
}