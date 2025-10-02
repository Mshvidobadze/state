import 'package:flutter/material.dart';
import 'package:state/core/constants/regions.dart';
import 'package:state/features/home/data/models/filter_model.dart';
import 'package:google_fonts/google_fonts.dart';

class FeedOptionsBottomSheet extends StatefulWidget {
  final FilterModel currentFilter;
  final ValueChanged<FilterModel> onFilterChanged;

  const FeedOptionsBottomSheet({
    required this.currentFilter,
    required this.onFilterChanged,
    super.key,
  });

  @override
  State<FeedOptionsBottomSheet> createState() => _FeedOptionsBottomSheetState();
}

class _FeedOptionsBottomSheetState extends State<FeedOptionsBottomSheet> {
  late FilterModel _currentFilter;
  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.currentFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
              'Feed Options',
              style: GoogleFonts.beVietnamPro(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),

          // Options list
          if (_selectedOption == null) ...[
            // Main options
            _buildOptionItem(
              icon: Icons.public,
              title: 'Region',
              subtitle: _currentFilter.region,
              onTap: () => setState(() => _selectedOption = 'region'),
            ),
            _buildOptionItem(
              icon: Icons.new_releases,
              title: 'New',
              subtitle: 'Latest posts',
              isSelected: _currentFilter.filterType == FilterType.newest,
              onTap: () {
                final newFilter = _currentFilter.copyWith(
                  filterType: FilterType.newest,
                );
                widget.onFilterChanged(newFilter);
                Navigator.pop(context);
              },
            ),
            _buildOptionItem(
              icon: Icons.trending_up,
              title: 'Top',
              subtitle:
                  TimeFilter.timeFilterLabels[_currentFilter.timeFilter] ??
                  'Past 24 Hours',
              isSelected: _currentFilter.filterType == FilterType.top,
              onTap: () => setState(() => _selectedOption = 'time'),
            ),
          ] else if (_selectedOption == 'region') ...[
            // Region sub-options
            _buildBackButton(),
            ...kRegions.map(
              (region) => _buildSubOptionItem(
                title: region,
                isSelected: _currentFilter.region == region,
                onTap: () {
                  final newFilter = _currentFilter.copyWith(region: region);
                  widget.onFilterChanged(newFilter);
                  Navigator.pop(context);
                },
              ),
            ),
          ] else if (_selectedOption == 'time') ...[
            // Time filter sub-options
            _buildBackButton(),
            ...TimeFilter.allTimeFilters.map(
              (timeFilter) => _buildSubOptionItem(
                title: TimeFilter.timeFilterLabels[timeFilter] ?? timeFilter,
                isSelected: _currentFilter.timeFilter == timeFilter,
                onTap: () {
                  final newFilter = _currentFilter.copyWith(
                    filterType: FilterType.top,
                    timeFilter: timeFilter,
                  );
                  widget.onFilterChanged(newFilter);
                  Navigator.pop(context);
                },
              ),
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black87 : Colors.black54,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: Colors.black87, size: 20)
            else
              const Icon(Icons.chevron_right, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _buildSubOptionItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.black87 : Colors.black54,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: Colors.black87, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return InkWell(
      onTap: () => setState(() => _selectedOption = null),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.arrow_back, color: Colors.black54, size: 20),
            const SizedBox(width: 12),
            Text(
              'Back',
              style: GoogleFonts.beVietnamPro(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
