import 'package:flutter/material.dart';

import 'package:festivo/core/constants/app_colors.dart';

/// Swipeable venue image carousel with dot indicators.
/// Falls back to gradient + emoji when [imageUrls] is empty.
class VenueImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final String fallbackEmoji;
  final double height;
  final bool dark;

  const VenueImageCarousel({
    super.key,
    required this.imageUrls,
    required this.fallbackEmoji,
    this.height = 260,
    this.dark = false,
  });

  @override
  State<VenueImageCarousel> createState() => _VenueImageCarouselState();
}

class _VenueImageCarouselState extends State<VenueImageCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(VenueImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrls.length != widget.imageUrls.length) {
      _currentPage = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls.where((u) => u.trim().isNotEmpty).toList();

    if (urls.isEmpty) {
      return _FallbackHeader(
        height: widget.height,
        emoji: widget.fallbackEmoji,
        dark: widget.dark,
      );
    }

    if (urls.length == 1) {
      return SizedBox(
        height: widget.height,
        width: double.infinity,
        child: _NetworkImage(url: urls.first, fit: BoxFit.cover),
      );
    }

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: urls.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => _NetworkImage(url: urls[i], fit: BoxFit.cover),
          ),
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(urls.length, (i) {
                final active = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 10 : 7,
                  height: active ? 10 : 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? Colors.white
                        : Colors.white.withOpacity(0.45),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackHeader extends StatelessWidget {
  final double height;
  final String emoji;
  final bool dark;

  const _FallbackHeader({
    required this.height,
    required this.emoji,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent(dark), AppColors.accent2(dark)],
        ),
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 80)),
      ),
    );
  }
}

class _NetworkImage extends StatelessWidget {
  final String url;
  final BoxFit fit;

  const _NetworkImage({required this.url, required this.fit});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.glightBg,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: (_, _, _) => Container(
        color: AppColors.glightBg,
        child: const Center(
          child: Icon(Icons.broken_image_outlined, size: 48, color: AppColors.textLight),
        ),
      ),
    );
  }
}
