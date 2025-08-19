class FilterModel {
  final String region;
  final String timeFilter;

  const FilterModel({required this.region, required this.timeFilter});

  FilterModel copyWith({String? region, String? timeFilter}) {
    return FilterModel(
      region: region ?? this.region,
      timeFilter: timeFilter ?? this.timeFilter,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilterModel &&
        other.region == region &&
        other.timeFilter == timeFilter;
  }

  @override
  int get hashCode => region.hashCode ^ timeFilter.hashCode;

  @override
  String toString() => 'FilterModel(region: $region, timeFilter: $timeFilter)';
}
