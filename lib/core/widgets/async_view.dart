import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';

/// Rend un AsyncValue en états loading / error / (vide) / data — DRY pour les écrans.
class AsyncView<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget Function()? emptyBuilder;
  final bool Function(T data)? isEmpty;

  const AsyncView({super.key, required this.value, required this.data, this.emptyBuilder, this.isEmpty});

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => Center(child: CircularProgressIndicator(color: KtvColors.accent)),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Erreur : $e', style: const TextStyle(color: KtvColors.muted), textAlign: TextAlign.center),
        ),
      ),
      data: (d) {
        final empty = isEmpty?.call(d) ?? (d is List && d.isEmpty);
        if (empty && emptyBuilder != null) return emptyBuilder!();
        return data(d);
      },
    );
  }
}
