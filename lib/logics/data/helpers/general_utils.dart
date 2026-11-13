import 'dart:math';
import 'package:arcane/arcane.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flutter_highlight/themes/gradient-dark.dart';
import '../../../packages/config/configs.dart';
import '../../../packages/widget/blocks/leaf/code_block.dart';
import '../../../packages/widget/blocks/leaf/heading.dart';
import '../../../packages/widget/blocks/leaf/horizontal_rules.dart';
import '../../../packages/widget/blocks/leaf/paragraph.dart';
import '../../../packages/widget/inlines/code.dart';
import '../global_logics.dart';

class Toolkit {
  static double radius = 6;
  static double borderWidth = 1;
  static Color getSubtleColor(BuildContext context) =>
      Theme.of(context).colorScheme.card;
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 840;

  static int calculateTotalPages(int totalItems, int pageSize) {
    if (pageSize <= 0) {
      throw ArgumentError("Page size must be greater than zero.");
    }
    return (totalItems / pageSize).ceil();
  }

  static String camelToSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (Match match) => '${match.group(1)}_${match.group(2)}',
        )
        .toLowerCase();
  }

  static bool urlValidator(text) {
    final regex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_+.~#?&//=]*)',
    );
    return regex.hasMatch(text);
  }

  static bool passwordValidator(text) {
    final regex = RegExp(
      r"^(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z])(?=.*\W)(?!.* ).{8,16}$",
    );
    return regex.hasMatch(text);
  }

  static bool phoneNumberValidator(text) {
    final regex = RegExp(r"^(\+|00)[1-9][0-9 \-\()\.]{3,32}$");
    return regex.hasMatch(text);
  }

  static bool isMorning() {
    DateTime now = DateTime.now();
    int hour = now.hour;

    return hour >= 6 && hour < 12;
  }

  static bool isAfternoon() {
    DateTime now = DateTime.now();
    int hour = now.hour;

    return hour >= 12 && hour < 18;
  }

  static Color pastelColor() {
    final random = Random();
    return Color.fromRGBO(
      200 + random.nextInt(56), // 200-255
      200 + random.nextInt(56), // 200-255
      200 + random.nextInt(56), // 200-255
      1,
    );
  }

  static Color pastelColorLight() {
    final random = Random();
    return Color.fromRGBO(
      150 + random.nextInt(56), // 150-205
      150 + random.nextInt(56), // 150-205
      150 + random.nextInt(56), // 150-205
      1,
    );
  }

  static String removeEmojis(String input) {
    return input;
  }

  static String printGreeting() {
    final int currentHour = DateTime.now().hour;
    if (currentHour >= 5 && currentHour < 12) {
      return 'Good morning';
    } else if (currentHour >= 12 && currentHour < 17) {
      return 'Good afternoon';
    } else if (currentHour >= 17 && currentHour < 22) {
      return 'Good evening';
    } else {
      return 'Good night';
    }
  }

  static String numToEng(int num) {
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)} mil';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}k';
    } else {
      return num.toString();
    }
  }

  static Color getTextColor() {
    final int currentHour = DateTime.now().hour;
    if (currentHour >= 18 || currentHour < 6) {
      return Colors.white;
    } else {
      return Colors.black.withAlpha(100);
    }
  }

  static Color randomOpaqueColor() {
    return Color(Random().nextInt(0xffffffff)).withAlpha(0xff);
  }

  static String formatDuration(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;

    String hoursStr = hours > 0 ? hours.toString() : "";
    String minutesStr = minutes.toString().padLeft(2, '0');
    String secondsStr = remainingSeconds.toString().padLeft(2, '0');

    if (hours > 0) {
      return "$hoursStr:$minutesStr:$secondsStr";
    } else {
      return "$minutesStr:$secondsStr";
    }
  }

  static String numToEngDouble(double num) {
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)} mil';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}k';
    } else {
      return num.toString();
    }
  }

  static String dateTimeToWords(String dateTimeStr) {
    var dateTime = DateTime.parse(dateTimeStr);
    var formatter = DateFormat('MMMM d, y');
    return formatter.format(dateTime.toLocal());
  }

  static String dateTimeToWordsW(DateTime time) {
    var formatter = DateFormat('MMMM d, y');
    return formatter.format(time.toLocal());
  }

  static String formatTimeAgo(int dateTimeStr) {
    var dateTime = DateTime.fromMillisecondsSinceEpoch(dateTimeStr);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'min' : 'minutes'}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'h' : 'h'}';
    } else if (difference.inDays < 30) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'd' : 'd'}';
    } else if (difference.inDays < 365) {
      final weeks = difference.inDays ~/ 7;
      return '$weeks ${weeks == 1 ? 'w' : 'w'}';
    } else {
      final years = (difference.inDays / 365).round();
      return '$years ${years == 1 ? 'y' : 'y'}';
    }
  }
  static String formatFileSize(int bytes) {
    const kb = 1024;
    const mb = kb * 1024;
    const gb = mb * 1024;

    if (bytes >= gb) return "${(bytes / gb).toStringAsFixed(2)} GB";
    if (bytes >= mb) return "${(bytes / mb).toStringAsFixed(2)} MB";
    if (bytes >= kb) return "${(bytes / kb).toStringAsFixed(2)} KB";
    return "$bytes B";
  }

  static String formatTimeAgoFull(int dateTimeStr) {
    var dateTime = DateTime.fromMillisecondsSinceEpoch(dateTimeStr);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 30) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).round();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).round();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  static String formatDate(int dateTimeStr) {
    var dateTime = DateTime.fromMillisecondsSinceEpoch(dateTimeStr);

    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final day = dateTime.day;
    final month = months[dateTime.month - 1];
    final year = dateTime.year;
    return '$day $month, $year';
  }

  static MarkdownConfig getMarkdownConfig(
    BuildContext context, {
    Color? color,
  }) {
    final baseConfigs = [
      H1Config(style: Theme.of(context).typography.h4),
      H2Config(style: Theme.of(context).typography.h4),
      H3Config(style: Theme.of(context).typography.h4),
      H4Config(style: Theme.of(context).typography.h4),
      H5Config(style: Theme.of(context).typography.p),
      H6Config(style: Theme.of(context).typography.small),
      PreConfig(
        theme: gradientDarkTheme,
        margin: EdgeInsets.zero,
        textStyle: Theme.of(context).typography.mono,
        styleNotMatched: Theme.of(context).typography.mono,
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: Theme.of(context).borderRadiusMd,
        ),
      ),
      CodeConfig(
        style: Theme.of(context).typography.mono,
      ),
      HrConfig(
        color: Theme.of(context).colorScheme.border
      )
    ];

    if (DataConstants.currentTheme == ThemeMode.light) {
      return MarkdownConfig.defaultConfig.copy(
        configs: [
          ...baseConfigs,
          PConfig(textStyle: Theme.of(context).typography.p),
        ],
      );
    }

    return MarkdownConfig.darkConfig.copy(
      configs: [
        ...baseConfigs,
        PConfig(textStyle: Theme.of(context).typography.p),
      ],
    );
  }

  static String getOSName() {
    if(kIsWeb){
      return "Web";
    }
    if (Platform.isAndroid) return "Android";
    if (Platform.isIOS) return "iOS";
    if (Platform.isLinux) return "Linux";
    if (Platform.isMacOS) return "macOS";
    if (Platform.isWindows) return "Windows";
    if (Platform.isFuchsia) return "Fuchsia";
    return "Unknown";
  }

}

extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
