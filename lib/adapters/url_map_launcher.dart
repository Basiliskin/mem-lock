import 'package:url_launcher/url_launcher.dart';

import '../domain/geo.dart';
import '../ports/ports.dart';

class UrlMapLauncher implements MapLauncher {
  @override
  Future<bool> open(GeoPoint p) => launchUrl(
    Uri.parse('geo:${p.lat},${p.lng}?q=${p.lat},${p.lng}'),
    mode: LaunchMode.externalApplication,
  );
}
