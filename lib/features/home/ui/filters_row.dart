import 'package:flutter/material.dart';
import 'package:state/core/constants/regions.dart';
import 'package:state/features/home/data/models/filter_model.dart';
import 'package:state/features/home/ui/widgets/feed_options_bottom_sheet.dart';
import 'package:google_fonts/google_fonts.dart';

class FiltersRow extends StatelessWidget {
  final FilterModel currentFilter;
  final ValueChanged<FilterModel> onFilterChanged;
  final VoidCallback onCreatePost;
  final VoidCallback onSearch;

  const FiltersRow({
    required this.currentFilter,
    required this.onFilterChanged,
    required this.onCreatePost,
    required this.onSearch,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          InkWell(
            onTap: () => _showFeedOptions(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tune, color: Colors.black54, size: 20),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Feed Options',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${currentFilter.region} • ${_getFilterLabel(currentFilter)}',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onCreatePost,
            icon: const Icon(Icons.add, size: 28, color: Colors.black87),
            style: IconButton.styleFrom(padding: const EdgeInsets.all(8)),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onSearch,
            icon: const Icon(Icons.search, size: 24, color: Colors.black54),
            style: IconButton.styleFrom(padding: const EdgeInsets.all(8)),
          ),
        ],
      ),
    );
  }

  void _showFeedOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => FeedOptionsBottomSheet(
            currentFilter: currentFilter,
            onFilterChanged: onFilterChanged,
          ),
    );
  }

  String _getFilterLabel(FilterModel filter) {
    if (filter.filterType == FilterType.newest) {
      return 'New';
    } else {
      return _getTimeFilterLabel(filter.timeFilter);
    }
  }

  String _getTimeFilterLabel(String timeFilter) {
    switch (timeFilter) {
      case 'past_hour':
        return 'Past Hour';
      case 'past_24_hours':
        return 'Past 24 Hours';
      case 'past_week':
        return 'Past Week';
      case 'past_month':
        return 'Past Month';
      case 'past_year':
        return 'Past Year';
      case 'all_time':
        return 'All Time';
      default:
        return 'Past 24 Hours';
    }
  }
}
