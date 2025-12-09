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
  String _regionQuery = '';

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.currentFilter;
  }

  @override
  Widget build(BuildContext context) {
    // Use larger size only when showing regions (long list)
    final isShowingRegions = _selectedOption == 'region';
    final isShowingTime = _selectedOption == 'time';

    return DraggableScrollableSheet(
      key: ValueKey(_selectedOption), // Force rebuild when option changes
      initialChildSize:
          isShowingRegions
              ? 0.6
              : isShowingTime
              ? 0.5
              : 0.35,
      minChildSize: 0.2,
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
                  'Feed Options',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),

              // Scrollable content
              Expanded(child: _buildContent(scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(ScrollController scrollController) {
    if (_selectedOption == null) {
      // Main options
      return ListView(
        controller: scrollController,
        children: [
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
                timeFilter: '', // Clear time filter for "New"
              );
              widget.onFilterChanged(newFilter);
              Navigator.pop(context);
            },
          ),
          _buildOptionItem(
            icon: Icons.trending_up,
            title: 'Top',
            subtitle:
                TimeFilter.timeFilterLabels[_currentFilter.timeFilter] ?? '',
            isSelected: _currentFilter.filterType == FilterType.top,
            onTap: () => setState(() => _selectedOption = 'time'),
          ),
        ],
      );
    } else if (_selectedOption == 'region') {
      // Region sub-options with search
      final filtered =
          _regionQuery.isEmpty
              ? kRegions
              : kRegions
                  .where(
                    (r) => r.toLowerCase().contains(_regionQuery.toLowerCase()),
                  )
                  .toList();

      return Column(
        children: [
          _buildBackButton(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _regionQuery = v),
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
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final region = filtered[index];
                return _buildSubOptionItem(
                  title: region,
                  isSelected: _currentFilter.region == region,
                  onTap: () {
                    final newFilter = _currentFilter.copyWith(region: region);
                    widget.onFilterChanged(newFilter);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      );
    } else {
      // Time filter sub-options
      return ListView(
        controller: scrollController,
        children: [
          _buildBackButton(),
          ...TimeFilter.allTimeFilters.map(
            (timeFilter) => _buildSubOptionItem(
              title: TimeFilter.timeFilterLabels[timeFilter] ?? timeFilter,
              isSelected:
                  _currentFilter.filterType == FilterType.top &&
                  _currentFilter.timeFilter == timeFilter,
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
      );
    }
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
                  if (subtitle.isNotEmpty)
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
