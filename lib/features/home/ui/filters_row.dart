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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          FancyDropdown(
            value: selectedRegion,
            items: kRegions,
            icon: Icons.public,
            onChanged: onRegionChanged,
          ),
          const SizedBox(width: 12),
          FancyDropdown(
            value: selectedSort,
            items: const ['hot', 'new'],
            icon: Icons.local_fire_department,
            onChanged: onSortChanged,
            labels: const {'hot': 'Hot', 'new': 'New'},
          ),
          const Spacer(),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.add, size: 20),
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
  final Map<String, String>? labels;

  const FancyDropdown({
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
    this.labels,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: Icon(icon, color: Colors.black54, size: 20),
          dropdownColor: Colors.white,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
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
