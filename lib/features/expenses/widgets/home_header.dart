import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/providers/state_providers.dart';

class HomeHeaderAppBarTitle extends StatelessWidget {
  final String familyName;
  final ConnectionStatus connection;

  const HomeHeaderAppBarTitle({
    super.key,
    required this.familyName,
    required this.connection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    Color statusColor;
    String statusText;

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
        statusColor = const Color(0xFFF59E0B);
        statusText = 'Offline';
        break;
      case ConnectionStatus.checking:
        statusColor = const Color(0xFF9CA3AF);
        statusText = 'Connecting...';
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          familyName,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainer
                : colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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
