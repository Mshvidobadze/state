import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:state/core/constants/regions.dart';

class RegionPickerBottomSheet extends StatelessWidget {
  final String currentRegion;
  final ValueChanged<String> onRegionChanged;

  const RegionPickerBottomSheet({
    super.key,
    required this.currentRegion,
    required this.onRegionChanged,
  });

  static Future<String?> show(
    BuildContext context, {
    required String currentRegion,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder:
          (context) => RegionPickerBottomSheet(
            currentRegion: currentRegion,
            onRegionChanged: (region) {
              Navigator.pop(context, region);
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Region',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),

              // Scrollable Regions list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: kRegions.length,
                  itemBuilder: (context, index) {
                    final region = kRegions[index];
                    return InkWell(
                      onTap: () => onRegionChanged(region),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                region,
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 16,
                                  fontWeight:
                                      currentRegion == region
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                  color:
                                      currentRegion == region
                                          ? Colors.black87
                                          : Colors.black54,
                                ),
                              ),
                            ),
                            if (currentRegion == region)
                              const Icon(
                                Icons.check,
                                color: Colors.black87,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
