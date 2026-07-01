import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/providers.dart';

enum DownloadStatus { queued, downloading, done, error, canceled }

class DownloadJob {
  final String id;
  final String name;
  final String url;
  final String ext;
  final DownloadStatus status;
  final double progress; // 0..1
  final String? filePath;

  const DownloadJob({
    required this.id,
    required this.name,
    required this.url,
    required this.ext,
    this.status = DownloadStatus.queued,
    this.progress = 0,
    this.filePath,
  });

  DownloadJob copyWith({DownloadStatus? status, double? progress, String? filePath}) => DownloadJob(
        id: id,
        name: name,
        url: url,
        ext: ext,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        filePath: filePath ?? this.filePath,
      );
}

/// File de téléchargements séquentielle (1 connexion fournisseur à la fois).
class DownloadController extends Notifier<List<DownloadJob>> {
  final _dio = Dio();
  CancelToken? _current;
  bool _running = false;
  int _seq = 0;

  @override
  List<DownloadJob> build() => [];

  String _sanitize(String s) => s.replaceAll(RegExp(r'[^\w\-. À-ÿ]'), '_').trim();

  void enqueue({required String name, required String url, required String ext}) {
    final job = DownloadJob(id: 'dl${++_seq}', name: name, url: url, ext: ext);
    state = [...state, job];
    _pump();
  }

  Future<void> _pump() async {
    if (_running) return;
    final next = state.where((j) => j.status == DownloadStatus.queued).firstOrNull;
    if (next == null) return;
    _running = true;
    _update(next.id, status: DownloadStatus.downloading);
    try {
      final custom = ref.read(prefsProvider).settingStr('downloadsDir');
      final folder = custom.isNotEmpty
          ? (Directory(custom)..createSync(recursive: true))
          : (Directory('${(await getApplicationDocumentsDirectory()).path}/KTV Téléchargements')..createSync(recursive: true));
      final path = '${folder.path}/${_sanitize(next.name)}.${next.ext}';
      _current = CancelToken();
      await _dio.download(next.url, path, cancelToken: _current, onReceiveProgress: (r, t) {
        if (t > 0) _update(next.id, progress: r / t);
      });
      _update(next.id, status: DownloadStatus.done, progress: 1, filePath: path);
    } on DioException catch (e) {
      _update(next.id, status: e.type == DioExceptionType.cancel ? DownloadStatus.canceled : DownloadStatus.error);
    } catch (_) {
      _update(next.id, status: DownloadStatus.error);
    } finally {
      _running = false;
      _current = null;
      _pump(); // enchaîne le suivant
    }
  }

  void cancelCurrent() => _current?.cancel();

  void _update(String id, {DownloadStatus? status, double? progress, String? filePath}) {
    state = [
      for (final j in state)
        if (j.id == id) j.copyWith(status: status, progress: progress, filePath: filePath) else j
    ];
  }
}

final downloadControllerProvider = NotifierProvider<DownloadController, List<DownloadJob>>(DownloadController.new);

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
