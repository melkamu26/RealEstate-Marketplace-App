import 'package:url_launcher/url_launcher.dart';

class CalendarUtils {
  static Future<void> addToGoogleCalendar({
    required String title,
    required DateTime start,
    required DateTime end,
    required String location,
  }) async {
    final url =
        "https://calendar.google.com/calendar/render?action=TEMPLATE"
        "&text=${Uri.encodeComponent(title)}"
        "&dates=${_format(start)}/${_format(end)}"
        "&location=${Uri.encodeComponent(location)}";

    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  static Future<void> addToICal({
    required String title,
    required DateTime start,
    required DateTime end,
    required String location,
  }) async {
    final url =
        "data:text/calendar;charset=utf8,"
        "BEGIN:VCALENDAR\n"
        "VERSION:2.0\n"
        "BEGIN:VEVENT\n"
        "SUMMARY:$title\n"
        "DTSTART:${_format(start)}\n"
        "DTEND:${_format(end)}\n"
        "LOCATION:$location\n"
        "END:VEVENT\n"
        "END:VCALENDAR";

    await launchUrl(Uri.parse(url));
  }

  static String _format(DateTime dt) {
    return dt.toUtc().toIso8601String().replaceAll("-", "").replaceAll(":", "").split(".")[0] + "Z";
  }
}