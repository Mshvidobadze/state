class FilterModel {
  final String region;
  final String filterType; // 'new' or 'top'
  final String timeFilter; // Only used when filterType is 'top'

  const FilterModel({
    required this.region,
    required this.filterType,
    required this.timeFilter,
  });

  FilterModel copyWith({
    String? region,
    String? filterType,
    String? timeFilter,
  }) {
    return FilterModel(
      region: region ?? this.region,
      filterType: filterType ?? this.filterType,
      timeFilter: timeFilter ?? this.timeFilter,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilterModel &&
        other.region == region &&
        other.filterType == filterType &&
        other.timeFilter == timeFilter;
  }

  @override
  int get hashCode =>
      region.hashCode ^ filterType.hashCode ^ timeFilter.hashCode;

  @override
  String toString() =>
      'FilterModel(region: $region, filterType: $filterType, timeFilter: $timeFilter)';
}
