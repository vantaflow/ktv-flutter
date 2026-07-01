import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import 'trakt_service.dart';

final traktServiceProvider = Provider<TraktService>((ref) => TraktService(ref.read(prefsProvider)));
