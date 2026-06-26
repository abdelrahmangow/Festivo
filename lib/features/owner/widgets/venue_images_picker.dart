import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:festivo/features/owner/theme/owner_colors.dart';

/// Multi-image picker for owner venue forms.
class VenueImagesPicker extends StatelessWidget {
  final List<File> pickedFiles;
  final List<String> existingUrls;
  final VoidCallback onPickImages;
  final ValueChanged<int> onRemovePicked;
  final ValueChanged<int>? onRemoveExisting;
  final int maxImages;
  final bool enabled;

  const VenueImagesPicker({
    super.key,
    required this.pickedFiles,
    this.existingUrls = const [],
    required this.onPickImages,
    required this.onRemovePicked,
    this.onRemoveExisting,
    this.maxImages = 8,
    this.enabled = true,
  });

  int get _totalCount => existingUrls.length + pickedFiles.length;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Venue Photos',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: OwnerColors.textDark,
              ),
            ),
            const Spacer(),
            Text(
              '$_totalCount / $maxImages',
              style: const TextStyle(fontSize: 12, color: OwnerColors.textGrey),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Add photos of your venue. Swipe through them on the details page.',
          style: TextStyle(fontSize: 12, color: OwnerColors.textGrey),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 108,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (enabled && _totalCount < maxImages) _AddTile(onTap: onPickImages),
              ...List.generate(existingUrls.length, (i) {
                return _ImageTile(
                  image: DecorationImage(
                    image: NetworkImage(existingUrls[i]),
                    fit: BoxFit.cover,
                  ),
                  onRemove: onRemoveExisting != null
                      ? () => onRemoveExisting!(i)
                      : null,
                );
              }),
              ...List.generate(pickedFiles.length, (i) {
                return _ImageTile(
                  image: DecorationImage(
                    image: FileImage(pickedFiles[i]),
                    fit: BoxFit.cover,
                  ),
                  onRemove: () => onRemovePicked(i),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: OwnerColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: OwnerColors.pinkBorder, width: 1.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, color: OwnerColors.pink, size: 28),
            SizedBox(height: 4),
            Text(
              'Add',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: OwnerColors.pink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final DecorationImage image;
  final VoidCallback? onRemove;

  const _ImageTile({required this.image, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: image,
        boxShadow: OwnerColors.shadow,
      ),
      child: onRemove == null
          ? null
          : Stack(
              children: [
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Picks multiple images from gallery, respecting [maxImages] total cap.
Future<List<File>> pickVenueImages({
  required int currentCount,
  int maxImages = 8,
}) async {
  final remaining = maxImages - currentCount;
  if (remaining <= 0) return [];

  final picker = ImagePicker();
  final files = await picker.pickMultiImage(imageQuality: 80);
  if (files.isEmpty) return [];

  return files.take(remaining).map((x) => File(x.path)).toList();
}
