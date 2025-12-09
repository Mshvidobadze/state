class ReportReason {
  static const String adult = 'Contains sexually explicit or adult content';
  static const String violence = 'Encourages violence or contains threats';

  static const List<String> allReasons = [adult, violence];

  static const Map<String, String> labels = {adult: adult, violence: violence};
}
