import 'package:flutter/material.dart';

/// Figma-styled Toggle (56x32) with animated thumb and hover/disabled states.
///
/// Colors derived from the provided spec:
/// - On rest:  #37AE8B
/// - On hover: #319B7B
/// - Off rest: #8390A0
/// - Off hover:#616F7F
class Toggle extends StatefulWidget {
  const Toggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged; // null-safe handling when disabled
  final bool enabled;
  final String? semanticLabel;

  @override
  State<Toggle> createState() => _ToggleState();
}

class _ToggleState extends State<Toggle> with SingleTickerProviderStateMixin {
  static const _w = 56.0;
  static const _h = 32.0;
  static const _thumb = 32.0; // visual spec
  static const _pad = 4.0; // thumb inner padding per Figma
  static const _duration = Duration(milliseconds: 220);
  static const _curve = Curves.easeInOutCubic;

  bool _hovered = false;
  bool get _enabled => widget.enabled && widget.onChanged != null;

  Color get _trackColor {
    if (widget.value) {
      return _hovered ? const Color(0xFF319B7B) : const Color(0xFF37AE8B);
    } else {
      return _hovered ? const Color(0xFF616F7F) : const Color(0xFF8390A0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double opacity = _enabled ? 1.0 : 0.5;
    final Color track = _trackColor;

    // Thumb border tracks the current track color (spec)
    final BorderSide thumbBorder = BorderSide(color: track, width: 2);

    void toggle() {
      if (!_enabled) return;
      widget.onChanged?.call(!widget.value);
    }

    return Semantics(
      label: widget.semanticLabel ?? 'Toggle',
      checked: widget.value,
      button: true,
      enabled: _enabled,
      child: FocusableActionDetector(
        enabled: _enabled,
        onShowFocusHighlight: (_) {},
        onShowHoverHighlight: (h) => setState(() => _hovered = h),
        mouseCursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
            toggle();
            return null;
          }),
        },
        child: Opacity(
          opacity: opacity,
          child: GestureDetector(
            onTap: toggle,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: _duration,
              curve: _curve,
              width: _w,
              height: _h,
              decoration: ShapeDecoration(
                color: track,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: _duration,
                    curve: _curve,
                    alignment: widget.value ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: _thumb,
                      height: _thumb,
                      padding: const EdgeInsets.all(_pad),
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: thumbBorder,
                          borderRadius: BorderRadius.circular(48),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
