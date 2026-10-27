import 'package:url_launcher/url_launcher.dart';

/// Opens Messages with the saved number + message body. iOS still requires Send.
Future<bool> openParkingSms({
  required String number,
  required String body,
}) async {
  final n = number.trim();
  final b = body.trim();
  if (n.isEmpty) return false;
  // encodeComponent uses %20 — queryParameters would turn spaces into +,
  // which iOS Messages shows literally.
  final uri = Uri.parse(
    b.isEmpty
        ? 'sms:$n'
        : 'sms:$n?body=${Uri.encodeComponent(b)}',
  );
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri);
}
