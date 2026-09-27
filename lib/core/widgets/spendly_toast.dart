import 'package:flutter/material.dart';

enum ToastType { success, error, warning, info }

class SpendlyToast {
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    bool isAboveNavBar = true,
    double? bottomMargin,
  }) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final double computedBottomMargin = bottomMargin ?? (isAboveNavBar ? (96.0 + bottomPadding) : (16.0 + bottomPadding));

    messenger.clearSnackBars();
    messenger.showSnackBar(
      _createSnackBar(
        message: message,
        type: type,
        duration: duration,
        bottomMargin: computedBottomMargin,
      ),
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    bool isAboveNavBar = true,
    double? bottomMargin,
  }) {
    show(
      context,
      message,
      type: ToastType.success,
      duration: duration,
      isAboveNavBar: isAboveNavBar,
      bottomMargin: bottomMargin,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    bool isAboveNavBar = true,
    double? bottomMargin,
  }) {
    show(
      context,
      message,
      type: ToastType.error,
      duration: duration,
      isAboveNavBar: isAboveNavBar,
      bottomMargin: bottomMargin,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    bool isAboveNavBar = true,
    double? bottomMargin,
  }) {
    show(
      context,
      message,
      type: ToastType.warning,
      duration: duration,
      isAboveNavBar: isAboveNavBar,
      bottomMargin: bottomMargin,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    bool isAboveNavBar = true,
    double? bottomMargin,
  }) {
    show(
      context,
      message,
      type: ToastType.info,
      duration: duration,
      isAboveNavBar: isAboveNavBar,
      bottomMargin: bottomMargin,
    );
  }

  static void showWithMessenger(
    ScaffoldMessengerState messenger,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    bool isAboveNavBar = true,
    double bottomPadding = 0,
    double? bottomMargin,
  }) {
    final double computedBottomMargin = bottomMargin ?? (isAboveNavBar ? (96.0 + bottomPadding) : (16.0 + bottomPadding));

    messenger.clearSnackBars();
    messenger.showSnackBar(
      _createSnackBar(
        message: message,
        type: type,
        duration: duration,
        bottomMargin: computedBottomMargin,
      ),
    );
  }

  static SnackBar _createSnackBar({
    required String message,
    required ToastType type,
    required Duration duration,
    required double bottomMargin,
  }) {
    Color bgColor;
    IconData icon;

    switch (type) {
      case ToastType.success:
        bgColor = const Color(0xFF16A34A);
        icon = Icons.check_circle_rounded;
        break;
      case ToastType.error:
        bgColor = const Color(0xFFDC2626);
        icon = Icons.error_outline_rounded;
        break;
      case ToastType.warning:
        bgColor = const Color(0xFFD97706);
        icon = Icons.warning_amber_rounded;
        break;
      case ToastType.info:
        bgColor = const Color(0xFF334155);
        icon = Icons.info_outline_rounded;
        break;
    }

    return SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: -0.1,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: bottomMargin,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: bgColor,
      elevation: 6,
      duration: duration,
      dismissDirection: DismissDirection.horizontal,
    );
  }
}
