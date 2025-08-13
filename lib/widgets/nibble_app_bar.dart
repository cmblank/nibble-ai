import 'package:flutter/material.dart';

/// A consistent Nibble-styled AppBar used across screens for uniform branding.
/// Usage: `NibbleAppBar(title: 'Pantry')` in place of a raw AppBar.
class NibbleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final bool showBack;
  final Color backgroundColor;
  final Color foregroundColor;
  final Widget? leading;
  final double elevation;
  final PreferredSizeWidget? bottom;

  const NibbleAppBar({
    super.key,
    this.title,
    this.actions,
    this.showBack = false,
    this.backgroundColor = Colors.white,
    this.foregroundColor = const Color(0xFF1F2937),
    this.leading,
    this.elevation = 0,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title != null ? Text(
        title!,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: Color(0xFF1F2937),
        ),
      ) : null,
      backgroundColor: backgroundColor,
      elevation: elevation,
      surfaceTintColor: backgroundColor,
      foregroundColor: foregroundColor,
      centerTitle: false,
      leading: leading ?? (showBack ? IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).maybePop(),
      ) : null),
      actions: actions,
      bottom: bottom,
    );
  }
}
