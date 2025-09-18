import 'dart:convert';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kanjad/basicdata/style.dart';
import 'package:kanjad/services/BD/supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KanjadImage extends StatefulWidget {
  final String imageData;
  final String sousCategorie;
  final BoxFit fit;
  final double? width;
  final double? height;

  const KanjadImage({
    super.key,
    required this.imageData,
    required this.sousCategorie,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  State<KanjadImage> createState() => _KanjadImageState();
}

class _KanjadImageState extends State<KanjadImage> {
  String? _resolvedImageUrl;
  Uint8List? _base64ImageBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _resolveImageUrl();
  }

  @override
  void didUpdateWidget(KanjadImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageData != widget.imageData ||
        oldWidget.sousCategorie != widget.sousCategorie) {
      _resolveImageUrl();
    }
  }

  Future<void> _resolveImageUrl() async {
    if (widget.imageData.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    if (widget.imageData.startsWith('http')) {
      setState(() {
        _resolvedImageUrl = widget.imageData;
        _isLoading = false;
      });
      return;
    }

    // Heuristic to differentiate base64 from a filename.
    // Filenames are typically short, base64 strings are long.
    if (widget.imageData.length > 500) {
      try {
        _base64ImageBytes = base64Decode(widget.imageData.split(',').last);
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
        return;
      } catch (e) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        return;
      }
    }

    // Try to resolve the image URL
    try {
      final bucketName = SupabaseService.getBucketName(widget.sousCategorie);
      final resolvedUrl = await _getImageUrl(bucketName, widget.imageData);

      if (mounted) {
        setState(() {
          _resolvedImageUrl = resolvedUrl;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<String> _getImageUrl(String bucketName, String imagePath) async {
    final supabase = Supabase.instance.client;

    // Try treating it as a folder first (since most images are now in folders)
    try {
      final folderContents = await supabase.storage.from(bucketName).list(path: imagePath);
      final imageFiles = folderContents.where((file) {
        final name = file.name.toLowerCase();
        return name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png');
      }).toList();

      if (imageFiles.isNotEmpty) {
        return supabase.storage.from(bucketName).getPublicUrl('$imagePath/${imageFiles.first.name}');
      }
    } catch (e) {
      // If folder listing fails, try the direct path (for backward compatibility)
      try {
        final directUrl = supabase.storage.from(bucketName).getPublicUrl(imagePath);
        return directUrl;
      } catch (e) {
        // If both attempts fail, rethrow the original error
        rethrow;
      }
    }

    // Fallback to direct URL if folder is empty
    return supabase.storage.from(bucketName).getPublicUrl(imagePath);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildPlaceholder();
    }

    // Handle base64 images
    if (_base64ImageBytes != null) {
      return Image.memory(
        _base64ImageBytes!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    }

    if (_hasError || _resolvedImageUrl == null) {
      return _buildErrorWidget();
    }

    return _buildNetworkImage(_resolvedImageUrl!);
  }

  Widget _buildNetworkImage(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Styles.rouge),
        ),
      ),
      errorWidget: (context, url, error) => _buildErrorWidget(),
      fadeInDuration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey.shade400,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.error_outline,
          color: Colors.red.shade400,
          size: 48,
        ),
      ),
    );
  }
}
