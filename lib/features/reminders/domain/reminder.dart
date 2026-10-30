enum ReminderChannel { whatsapp, sms }

class Reminder {
  const Reminder({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    required this.customerId,
    required this.channel,
    required this.message,
    required this.sentAt,
  });

  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final String customerId;
  final ReminderChannel channel;
  final String message;
  final DateTime sentAt;
}

/// Pure helpers for building reminder text and links.
class ReminderMessage {
  ReminderMessage._();

  /// Replaces {name}, {amount} and {shop} placeholders.
  static String fill(String template, {required String name, required String amount, required String shop}) {
    return template
        .replaceAll('{name}', name)
        .replaceAll('{amount}', amount)
        .replaceAll('{shop}', shop);
  }

  /// https://wa.me/<digits>?text=<message>. Without a number WhatsApp opens
  /// its own contact picker, so reminders still work for customers with no phone.
  static Uri whatsAppUri({String? digits, required String message}) {
    final base = (digits == null || digits.isEmpty) ? 'https://wa.me/' : 'https://wa.me/$digits';
    return Uri.parse('$base?text=${Uri.encodeComponent(message)}');
  }

  static Uri smsUri({String? phone, required String message, bool ios = false}) {
    final separator = ios ? '&' : '?';
    final number = phone ?? '';
    return Uri.parse('sms:$number${separator}body=${Uri.encodeComponent(message)}');
  }
}
