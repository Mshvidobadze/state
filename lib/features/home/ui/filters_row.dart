import 'package:flutter/material.dart';
import 'package:state/core/constants/regions.dart';

class FiltersRow extends StatelessWidget {
  final String selectedRegion;
  final String selectedSort;
  final ValueChanged<String> onRegionChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onCreatePost;

  const FiltersRow({
    required this.selectedRegion,
    required this.selectedSort,
    required this.onRegionChanged,
    required this.onSortChanged,
    required this.onCreatePost,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const logoColor = Color(0xFF800020);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          FancyDropdown(
            value: selectedRegion,
            items: kRegions,
            icon: Icons.public,
            onChanged: onRegionChanged,
            color: logoColor,
          ),
          const SizedBox(width: 12),
          FancyDropdown(
            value: selectedSort,
            items: const ['hot', 'new'],
            icon: Icons.local_fire_department,
            onChanged: onSortChanged,
            color: logoColor,
            labels: const {'hot': 'Hot', 'new': 'New'},
          ),
          const Spacer(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: logoColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Create'),
            onPressed: onCreatePost,
          ),
        ],
      ),
    );
  }
}

class FancyDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final Color color;
  final Map<String, String>? labels;

  const FancyDropdown({
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
    required this.color,
    this.labels,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: Icon(icon, color: color),
          dropdownColor: Colors.white,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
          items:
              items
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(labels?[item] ?? item),
                    ),
                  )
                  .toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }
}
