import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'profile_sheet.dart';

/// Tabs where the app bar appears.
enum NibbleTab { home, recipes, pantry, planning, more }

/// Context passed to chat from the current screen.
class NibbleChatContext {
  final NibbleTab sourceTab;
  final String? recipeId;
  final DateTime? planDate;
  final int? pantryCount;
  const NibbleChatContext({
    required this.sourceTab,
    this.recipeId,
    this.planDate,
    this.pantryCount,
  });
}

/// A consistent Nibble-styled AppBar used across screens for uniform branding.
/// Usage: `NibbleAppBar(title: 'Pantry')` in place of a raw AppBar.
class NibbleAppBar extends StatelessWidget implements PreferredSizeWidget {
  // Legacy/classic API (kept for backward compatibility)
  final String? title;
  final List<Widget>? actions;
  final bool showBack;
  final Color backgroundColor;
  final Color foregroundColor;
  final Widget? leading;
  final double elevation;
  final PreferredSizeWidget? bottom;

  // Brand layout API (new)
  final NibbleTab? currentTab;
  final bool showAchievements;
  final bool hasNewChat;
  final bool hasNewAchievement;
  final VoidCallback? onWordmarkTap;
  final void Function(NibbleChatContext ctx)? onChatTap;
  final VoidCallback? onAchievementsTap;
  final VoidCallback? onProfileTap;
  final NibbleChatContext? chatContext;

  const NibbleAppBar({
    super.key,
    // legacy/classic
    this.title,
    this.actions,
    this.showBack = false,
    this.backgroundColor = Colors.white,
    this.foregroundColor = const Color(0xFF1F2937),
    this.leading,
    this.elevation = 0,
    this.bottom,
    // brand
    this.currentTab,
    this.showAchievements = false,
    this.hasNewChat = false,
    this.hasNewAchievement = false,
    this.onWordmarkTap,
    this.onChatTap,
    this.onAchievementsTap,
    this.onProfileTap,
    this.chatContext,
  });

  @override
  Size get preferredSize => Size.fromHeight(64 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final useBrandLayout =
        onWordmarkTap != null || onChatTap != null || onProfileTap != null || showAchievements;

  final PreferredSizeWidget? effectiveBottom = bottom; // No default divider to avoid double app bar

    if (!useBrandLayout) {
      // Classic fallback
      return AppBar(
        title: title != null
            ? Text(
                title!,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Color(0xFF1F2937),
                ),
              )
            : null,
        backgroundColor: backgroundColor,
  elevation: elevation,
        surfaceTintColor: backgroundColor,
        foregroundColor: foregroundColor,
        centerTitle: true,
        titleSpacing: 16,
        leading: leading ??
            (showBack
                ? Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  )
                : null),
        actions: [
          if (actions != null) ...actions!,
          const SizedBox(width: 16),
        ],
        bottom: effectiveBottom,
      );
    }

    // Brand layout
    final resolvedContext = chatContext ??
        NibbleChatContext(sourceTab: currentTab ?? NibbleTab.home);

    // Centered title for all tabs except Home (no title on Home per spec)
    String? centerTitle;
    if (currentTab != NibbleTab.home) {
      centerTitle = title;
    }
    centerTitle ??= () {
      switch (currentTab) {
        case NibbleTab.home:
          return null; // No title on Home
        case NibbleTab.recipes:
          return 'Recipes';
        case NibbleTab.pantry:
          return 'Pantry';
        case NibbleTab.planning:
          return 'Planning';
        case NibbleTab.more:
          return 'More';
        default:
          return null;
      }
    }();

    return AppBar(
      toolbarHeight: 64,
      backgroundColor: backgroundColor,
      elevation: 0, // avoid double shadows under app bar
      surfaceTintColor: backgroundColor,
      foregroundColor: foregroundColor,
  // Allow the wordmark to use its natural width instead of the default 56px leading slot
  // Only apply when we're actually showing the wordmark (no custom leading/back button)
  // Keep leading area generous but not oversized; logo itself is fixed to 22px tall
  leadingWidth: (leading == null && !showBack) ? 200 : null,
    centerTitle: true,
      leading: leading ?? (showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Back',
            )
          : Padding(
              padding: const EdgeInsets.only(left: 16),
              child: _Wordmark(onTap: onWordmarkTap),
            )),
      titleSpacing: 16,
    // Place the title in flexibleSpace so it remains perfectly centered
    // horizontally regardless of leading/actions width.
    title: null,
    flexibleSpace: centerTitle != null
      ? _CenteredTitle(text: centerTitle)
      : null,
      actions: [
        if (onChatTap != null)
          _BadgeIconButton(
            assetPath: 'assets/images/icon-chat.png',
            tooltip: 'Open Nibble chat',
            hasBadge: hasNewChat,
            onPressed: () {
              HapticFeedback.lightImpact();
              onChatTap?.call(resolvedContext);
            },
          ),
        if (actions != null) ...actions!,
        _AvatarMenuButton(
          tooltip: 'Profile',
          hasNewAchievement: hasNewAchievement,
          onProfileTap: onProfileTap,
          onAchievementsTap: onAchievementsTap,
        ),
        const SizedBox(width: 16),
      ],
  bottom: effectiveBottom,
    );
  }
}

class _Wordmark extends StatelessWidget {
  final VoidCallback? onTap;
  const _Wordmark({this.onTap});

  @override
  Widget build(BuildContext context) {
    // Force the visual glyphs to exactly 22px tall without extra padding.
    final logo = SizedBox(
      height: 22,
      child: Image.asset(
        'assets/images/nibble_logo-teal.png',
        fit: BoxFit.fitHeight,
        filterQuality: FilterQuality.medium,
        alignment: Alignment.centerLeft,
      ),
    );
    if (onTap == null) {
      return Align(alignment: Alignment.centerLeft, child: logo);
    }
    return Semantics(
      label: 'Go to Home',
      button: true,
      child: Tooltip(
        message: 'Go to Home',
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40), // keep tap target >= 40
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: Align(alignment: Alignment.centerLeft, child: logo),
          ),
        ),
      ),
    );
  }
}

class _BadgeIconButton extends StatelessWidget {
  final String? assetPath;
  final String tooltip;
  final bool hasBadge;
  final VoidCallback? onPressed;
  const _BadgeIconButton({
    this.assetPath,
    required this.tooltip,
    required this.hasBadge,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    const double visualSize = 24; // unify visual size
    const constraints = BoxConstraints(minWidth: 40, minHeight: 40); // unify tap target
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            constraints: constraints,
            padding: const EdgeInsets.all(8),
            icon: assetPath != null
                ? SizedBox(
                    width: visualSize,
                    height: visualSize,
                    child: Image.asset(
                      assetPath!,
                      fit: BoxFit.contain,
                    ),
                  )
                : const SizedBox.shrink(),
            tooltip: tooltip,
            onPressed: onPressed,
          ),
          if (hasBadge)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarMenuButton extends StatelessWidget {
  final String tooltip;
  final bool hasNewAchievement;
  final VoidCallback? onProfileTap;
  final VoidCallback? onAchievementsTap;

  const _AvatarMenuButton({
    required this.tooltip,
    required this.hasNewAchievement,
    this.onProfileTap,
    this.onAchievementsTap,
  });

  @override
  Widget build(BuildContext context) {
    const double visualSize = 28; // avatar is slightly larger
    return Tooltip(
      message: tooltip,
      child: PopupMenuButton<String>(
        tooltip: tooltip,
        onSelected: (value) {
          HapticFeedback.lightImpact();
          switch (value) {
            case 'profile':
              if (onProfileTap != null) {
                onProfileTap!.call();
              } else {
                // Default behavior: open the full profile sheet menu
                showProfileSheet(context);
              }
              break;
            case 'achievements':
              onAchievementsTap?.call();
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem<String>(
            value: 'profile',
            child: Text('Profile & Settings'),
          ),
          if (onAchievementsTap != null)
            PopupMenuItem<String>(
              value: 'achievements',
              child: Row(
                children: [
                  const Expanded(child: Text('Achievements')),
                  if (hasNewAchievement)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
        ],
        child: SizedBox(
          width: visualSize,
          height: visualSize,
          child: ClipOval(
            child: Image.asset(
              'assets/images/Avatar-nib.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

/// Sliver variant of the Nibble app bar that hides on scroll down and reappears on scroll up.
class NibbleSliverAppBar extends StatelessWidget {
  // Accept a subset of NibbleAppBar's API for consistency
  final NibbleTab? currentTab;
  final bool showAchievements;
  final bool hasNewChat;
  final bool hasNewAchievement;
  final VoidCallback? onWordmarkTap;
  final void Function(NibbleChatContext ctx)? onChatTap;
  final VoidCallback? onAchievementsTap;
  final VoidCallback? onProfileTap;
  final NibbleChatContext? chatContext;

  final Color backgroundColor;
  final Color foregroundColor;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;

  const NibbleSliverAppBar({
    super.key,
    this.currentTab,
    this.showAchievements = false,
    this.hasNewChat = false,
    this.hasNewAchievement = false,
    this.onWordmarkTap,
    this.onChatTap,
    this.onAchievementsTap,
    this.onProfileTap,
    this.chatContext,
    this.backgroundColor = Colors.white,
    this.foregroundColor = const Color(0xFF1F2937),
    this.bottom,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedContext = chatContext ??
        NibbleChatContext(sourceTab: currentTab ?? NibbleTab.home);

  String? centerTitle;
  centerTitle = () {
      switch (currentTab) {
        case NibbleTab.home:
      return null; // No title on Home
        case NibbleTab.recipes:
          return 'Recipes';
        case NibbleTab.pantry:
          return 'Pantry';
        case NibbleTab.planning:
          return 'Planning';
        case NibbleTab.more:
          return 'More';
        default:
          return null;
      }
    }();

    return SliverAppBar(
      toolbarHeight: 64,
      backgroundColor: backgroundColor,
      surfaceTintColor: backgroundColor,
      foregroundColor: foregroundColor,
  floating: true,
  snap: true,
      pinned: false,
  // Allow wider wordmark area than the default leading slot when showing the wordmark
  // Keep room for wordmark while preventing unintentional stretching
  leadingWidth: 200,
      elevation: 0,
      titleSpacing: 16,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: _Wordmark(onTap: onWordmarkTap),
      ),
      title: null,
      flexibleSpace: centerTitle != null
          ? _CenteredTitle(text: centerTitle)
          : null,
      actions: [
        if (onChatTap != null)
          _BadgeIconButton(
            assetPath: 'assets/images/icon-chat.png',
            tooltip: 'Open Nibble chat',
            hasBadge: hasNewChat,
            onPressed: () {
              HapticFeedback.lightImpact();
              onChatTap?.call(resolvedContext);
            },
          ),
        if (actions != null) ...actions!,
        _AvatarMenuButton(
          tooltip: 'Profile',
          hasNewAchievement: hasNewAchievement,
          onProfileTap: onProfileTap,
          onAchievementsTap: onAchievementsTap,
        ),
        const SizedBox(width: 16),
      ],
      bottom: bottom,
    );
  }
}

class _CenteredTitle extends StatelessWidget {
  final String text;
  const _CenteredTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true, // ensure taps pass through to toolbar buttons
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Color(0xFF1F2937),
          ),
        ),
      ),
    );
  }
}
