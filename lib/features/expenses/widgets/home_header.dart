import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/services/sync_service.dart';

class FamilyHeader extends ConsumerWidget {
  final String familyName;
  final ConnectionStatus connection;
  final VoidCallback? onTap;

  const FamilyHeader({
    super.key,
    required this.familyName,
    required this.connection,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Real-time sync state from SyncService
    final isSyncing = ref.watch(syncStateProvider);

    Color statusColor;
    String statusText;

    if (isSyncing) {
      statusColor = const Color(0xFFF59E0B);
      statusText = 'Syncing…';
    } else {
      switch (connection) {
        case ConnectionStatus.online:
          statusColor = const Color(0xFF22C55E);
          statusText = 'Online';
          break;
        case ConnectionStatus.sandbox:
          statusColor = const Color(0xFF3B82F6);
          statusText = 'Sandbox';
          break;
        case ConnectionStatus.offline:
          statusColor = const Color(0xFFEF4444);
          statusText = 'Offline';
          break;
        case ConnectionStatus.checking:
          statusColor = const Color(0xFF9CA3AF);
          statusText = 'Connecting…';
          break;
      }
    }

    final initial = familyName.trim().isNotEmpty
        ? familyName.trim()[0].toUpperCase()
        : 'S';

    final displayName = familyName.trim().isNotEmpty
        ? (familyName.toLowerCase().endsWith('family')
            ? familyName
            : '$familyName Family')
        : 'Spendly Family';

    return Semantics(
      button: true,
      label: '$displayName, $statusText. Tap to open family profile.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => context.go('/profile'),
          borderRadius: BorderRadius.circular(100),
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
            constraints: const BoxConstraints(
              minHeight: 44,
              maxWidth: 320,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainer.withValues(alpha: 0.8)
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isDark
                    ? colorScheme.outline.withValues(alpha: 0.4)
                    : colorScheme.outline.withValues(alpha: 0.8),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : colorScheme.shadow.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Family Avatar / Initial
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 2. Family Name & Dynamic Connection Status
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.2,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _StatusDot(color: statusColor, isPulsing: isSyncing || connection == ConnectionStatus.online),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              statusText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // 3. Chevron Indicating Interactive Profile
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatefulWidget {
  final Color color;
  final bool isPulsing;

  const _StatusDot({
    required this.color,
    required this.isPulsing,
  });

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _animation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _StatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing != oldWidget.isPulsing) {
      if (widget.isPulsing) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPulsing) {
      return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _animation.value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _animation.value * 0.4),
                blurRadius: 3,
                offset: const Offset(0, 0),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HomeGreetingSection extends StatelessWidget {
  final String displayName;

  const HomeGreetingSection({
    super.key,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formattedDate = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, $displayName! 👋',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          formattedDate,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
