const List<String> kRegions = ['Global', 'Europe', 'USA'];

class TimeFilter {
  static const String pastHour = 'past_hour';
  static const String past24Hours = 'past_24_hours';
  static const String pastWeek = 'past_week';
  static const String pastMonth = 'past_month';
  static const String pastYear = 'past_year';
  static const String allTime = 'all_time';

  static const List<String> allTimeFilters = [
    pastHour,
    past24Hours,
    pastWeek,
    pastMonth,
    pastYear,
    allTime,
  ];

  static const Map<String, String> timeFilterLabels = {
    pastHour: 'Past Hour',
    past24Hours: 'Past 24 Hours',
    pastWeek: 'Past Week',
    pastMonth: 'Past Month',
    pastYear: 'Past Year',
    allTime: 'All Time',
  };

  static const Map<String, Duration> timeFilterDurations = {
    pastHour: Duration(hours: 1),
    past24Hours: Duration(hours: 24),
    pastWeek: Duration(days: 7),
    pastMonth: Duration(days: 30),
    pastYear: Duration(days: 365),
    allTime: Duration.zero,
  };
}
