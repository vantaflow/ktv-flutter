import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Élément navigable à la télécommande (Android TV) : focusable au D-pad,
/// halo accent + léger zoom quand focalisé, activation par OK/Entrée.
/// Reste cliquable à la souris/tactile sur desktop/mobile.
class TvFocusable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final BorderRadius borderRadius;
  final bool scaleOnFocus;
  final bool autofocus;
  const TvFocusable({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.scaleOnFocus = true,
    this.autofocus = false,
  });

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      autofocus: widget.autofocus,
      mouseCursor: SystemMouseCursors.click,
      onShowFocusHighlight: (f) {
        if (f != _focused) setState(() => _focused = f);
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
          widget.onTap();
          return null;
        }),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _focused && widget.scaleOnFocus ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              border: Border.all(
                color: _focused ? KtvColors.accent : Colors.transparent,
                width: 3,
              ),
              boxShadow: _focused
                  ? [BoxShadow(color: KtvColors.accent.withValues(alpha: 0.45), blurRadius: 16, spreadRadius: 1)]
                  : null,
            ),
            child: ClipRRect(borderRadius: widget.borderRadius, child: widget.child),
          ),
        ),
      ),
    );
  }
}
