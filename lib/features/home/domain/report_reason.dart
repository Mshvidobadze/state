/// Report reasons for posts
class ReportReason {
  static const adultContent = 'adult_content';
  static const violenceThreat = 'violence_threat';

  static const Map<String, String> labels = {
    adultContent: 'Contains sexually explicit or adult content',
    violenceThreat:
        'Encourages violence or contains threats to individuals or groups',
  };

  static const List<String> allReasons = [adultContent, violenceThreat];
}
