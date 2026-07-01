import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/auth_controller.dart';
import 'xmltv_service.dart';

/// Index EPG (XMLTV) chargé une fois par session/profil.
final epgIndexProvider = FutureProvider<XmltvIndex>((ref) async {
  final urls = ref.watch(xtreamUrlsProvider);
  if (urls == null) return const XmltvIndex({}, {});
  try {
    return await XmltvService().load(urls.xmltv());
  } catch (_) {
    return const XmltvIndex({}, {});
  }
});
