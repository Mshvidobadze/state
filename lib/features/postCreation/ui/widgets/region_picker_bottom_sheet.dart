import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:state/core/constants/regions.dart';

class RegionPickerBottomSheet extends StatefulWidget {
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
  State<RegionPickerBottomSheet> createState() =>
      _RegionPickerBottomSheetState();
}

class _RegionPickerBottomSheetState extends State<RegionPickerBottomSheet> {
  String _query = '';

  List<String> get _filteredRegions {
    if (_query.isEmpty) return kRegions;
    final q = _query.toLowerCase();
    return kRegions.where((r) => r.toLowerCase().contains(q)).toList();
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

              // Title + Search
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Region',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        hintText: 'Search regions',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.search, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Regions list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _filteredRegions.length,
                  itemBuilder: (context, index) {
                    final region = _filteredRegions[index];
                    return InkWell(
                      onTap: () => widget.onRegionChanged(region),
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
                                      widget.currentRegion == region
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                  color:
                                      widget.currentRegion == region
                                          ? Colors.black87
                                          : Colors.black54,
                                ),
                              ),
                            ),
                            if (widget.currentRegion == region)
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
