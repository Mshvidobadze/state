import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsAcceptanceDialog extends StatefulWidget {
  const TermsAcceptanceDialog({super.key});

  @override
  State<TermsAcceptanceDialog> createState() => _TermsAcceptanceDialogState();
}

class _TermsAcceptanceDialogState extends State<TermsAcceptanceDialog> {
  bool _checked = false;

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } else {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        'Community Guidelines',
        style: TextStyle(
          color: Color(0xFF111418),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'To continue, please agree to our Terms. There is no tolerance for:',
              style: TextStyle(
                color: Color(0xFF111418),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            SizedBox(height: 8),
            _Bullet('Illegal content or activity'),
            _Bullet('Nudity or sexually explicit content'),
            _Bullet('Political misinformation'),
            SizedBox(height: 12),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            Checkbox(
              value: _checked,
              onChanged: (v) => setState(() => _checked = v ?? false),
            ),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _checked = !_checked),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'I agree to the Terms of Service and community guidelines.',
                    style: TextStyle(color: Color(0xFF111418), fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed:
                  () => _launch('https://stateapp.net/terms-and-conditions'),
              child: const Text(
                'View Terms',
                style: TextStyle(color: Color(0xFF74182f)),
              ),
            ),
            TextButton(
              onPressed: () => _launch('https://stateapp.net/privacy-policy'),
              child: const Text(
                'Privacy Policy',
                style: TextStyle(color: Color(0xFF74182f)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed:
                    _checked ? () => Navigator.of(context).pop(true) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF74182f),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Accept and Continue'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Sign out',
              style: TextStyle(color: Color(0xFF637488)),
            ),
          ),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•  ',
            style: TextStyle(fontSize: 16, color: Color(0xFF111418)),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF111418),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
