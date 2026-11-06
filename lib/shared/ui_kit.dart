import 'package:flutter/material.dart';

import '../theme.dart';

/// Shared visual building blocks: image banners, stat tiles, photo cards and
/// dashboard sections, so every page follows the same structure.

const stockImages = (
  teamDiscussion: 'assets/images/stock/team_discussion.jpg',
  teamLaughing: 'assets/images/stock/team_laughing.jpg',
  collaboration: 'assets/images/stock/collaboration_top.jpg',
  coaching: 'assets/images/stock/coaching_conversation.jpg',
  facilitator: 'assets/images/stock/facilitator.jpg',
  meditation: 'assets/images/stock/meditation.jpg',
  balance: 'assets/images/stock/balance_stones.jpg',
  onlineLearning: 'assets/images/stock/online_learning.jpg',
  analytics: 'assets/images/stock/analytics.jpg',
  journal: 'assets/images/stock/journal.jpg',
  reflection: 'assets/images/stock/reflection.jpg',
  planning: 'assets/images/stock/planning.jpg',
  handshake: 'assets/images/stock/handshake.jpg',
  wellbeing: 'assets/images/stock/wellbeing_class.jpg',
  learner: 'assets/images/stock/learner.jpg',
  leadership: 'assets/images/stock/leadership.jpg',
  community: 'assets/images/stock/community.jpg',
);

/// Full-width photo banner with a brand gradient, used at the top of pages.
class ImageBanner extends StatelessWidget {
  const ImageBanner({
    super.key,
    required this.image,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.height = 300,
    this.actions = const [],
  });
  final String image;
  final String eyebrow;
  final String title;
  final String? subtitle;
  final double height;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 700;
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: narrow ? height * 0.8 : height),
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage(image), fit: BoxFit.cover),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              deepBlue.withValues(alpha: 0.94),
              deepBlue.withValues(alpha: narrow ? 0.85 : 0.55),
              deepBlue.withValues(alpha: narrow ? 0.75 : 0.15),
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: narrow ? 20 : 40,
                vertical: narrow ? 36 : 56,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        eyebrow.toUpperCase(),
                        style: const TextStyle(
                          color: softYellow,
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: narrow ? 30 : 40,
                          height: 1.12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            height: 1.5,
                          ),
                        ),
                      ],
                      if (actions.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        Wrap(spacing: 12, runSpacing: 12, children: actions),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Photo card with title, text and an optional link, for services/features.
class PhotoFeatureCard extends StatefulWidget {
  const PhotoFeatureCard({
    super.key,
    required this.image,
    required this.title,
    required this.text,
    this.icon,
    this.onTap,
    this.cta = 'Learn more',
    this.imageHeight = 170,
  });
  final String image;
  final String title;
  final String text;
  final IconData? icon;
  final VoidCallback? onTap;
  final String cta;
  final double imageHeight;

  @override
  State<PhotoFeatureCard> createState() => _PhotoFeatureCardState();
}

class _PhotoFeatureCardState extends State<PhotoFeatureCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E5F0)),
        boxShadow: [
          BoxShadow(
            color: deepBlue.withValues(alpha: _hover ? 0.12 : 0.05),
            blurRadius: _hover ? 26 : 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Image.asset(
                    widget.image,
                    height: widget.imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  if (widget.icon != null)
                    Positioned(
                      left: 16,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: softYellow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(widget.icon, color: deepBlue, size: 22),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(widget.text, style: const TextStyle(height: 1.5)),
                    if (widget.onTap != null) ...[
                      const SizedBox(height: 14),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.cta,
                            style: const TextStyle(
                              color: royalBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          AnimatedSlide(
                            duration: const Duration(milliseconds: 180),
                            offset: Offset(_hover ? 0.25 : 0, 0),
                            child: const Icon(
                              Icons.arrow_forward,
                              size: 18,
                              color: royalBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Key figure with an icon, used on every dashboard.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color = purple,
    this.caption,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final String? caption;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE8E5F0)),
    ),
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: deepBlue,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54),
              ),
              if (caption != null)
                Text(
                  caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Lays out children in an even grid that collapses on narrow screens.
class TileGrid extends StatelessWidget {
  const TileGrid({
    super.key,
    required this.children,
    this.maxColumns = 4,
    this.minTileWidth = 220,
    this.spacing = 16,
    this.minColumns = 1,
  });

  /// Keeps at least this many columns on phones (e.g. 2 for stat tiles).
  final int minColumns;
  final List<Widget> children;
  final int maxColumns;
  final double minTileWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final cols = (box.maxWidth / minTileWidth).floor().clamp(
        box.maxWidth >= 300 ? minColumns : 1,
        maxColumns,
      );
      final w = (box.maxWidth - (cols - 1) * spacing) / cols;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [for (final c in children) SizedBox(width: w, child: c)],
      );
    },
  );
}

/// White panel with a title row, used for dashboard sections.
class DashboardPanel extends StatelessWidget {
  const DashboardPanel({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.action,
    this.subtitle,
  });
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? action;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE8E5F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: purple, size: 22),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: deepBlue,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            ?action,
          ],
        ),
        const SizedBox(height: 16),
        // ListTiles inside need a Material for ink effects.
        Material(type: MaterialType.transparency, child: child),
      ],
    ),
  );
}

/// Greeting header for role dashboards: photo, greeting and quick actions.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.image,
    this.actions = const [],
  });
  final String eyebrow;
  final String title;
  final String subtitle;
  final String image;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 860;
    final text = Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: const TextStyle(
              color: softYellow,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 15.5),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 18),
            Wrap(spacing: 10, runSpacing: 10, children: actions),
          ],
        ],
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [deepBlue, royalBlue]),
        ),
        child: wide
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 3, child: text),
                    Expanded(
                      flex: 2,
                      child: ShaderMask(
                        shaderCallback: (r) => const LinearGradient(
                          colors: [Colors.transparent, Colors.black],
                          stops: [0, 0.35],
                        ).createShader(r),
                        blendMode: BlendMode.dstIn,
                        child: Image.asset(image, fit: BoxFit.cover),
                      ),
                    ),
                  ],
                ),
              )
            : text,
      ),
    );
  }
}

/// Small pill button used in dark headers.
class HeaderButton extends StatelessWidget {
  const HeaderButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) => primary
      ? FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: softYellow,
            foregroundColor: deepBlue,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
        )
      : OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white54),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
        );
}

/// Large choice card for "I'm browsing as".
class PathChoiceCard extends StatefulWidget {
  const PathChoiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String text;
  final VoidCallback onTap;

  @override
  State<PathChoiceCard> createState() => _PathChoiceCardState();
}

class _PathChoiceCardState extends State<PathChoiceCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: _hover ? Colors.white : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _hover ? softYellow : Colors.white.withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: softYellow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon, color: deepBlue),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: _hover ? deepBlue : Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.text,
                        style: TextStyle(
                          color: _hover ? Colors.black54 : Colors.white70,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  color: _hover ? deepBlue : Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
