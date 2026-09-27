import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class LauncherService {
  /// Cleans phone number by removing spaces, dashes, parentheses and leading plus
  static String cleanPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Launch Phone Dialer directly
  static Future<bool> makePhoneCall(String phoneNumber) async {
    // If phone has a format like '+91 98765 43210', format as tel:+919876543210
    final sanitized = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final Uri callUri = Uri(
      scheme: 'tel',
      path: sanitized.startsWith('+') ? sanitized : '+$sanitized',
    );

    try {
      if (await canLaunchUrl(callUri)) {
        return await launchUrl(callUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback for some platforms
        return await launchUrl(callUri);
      }
    } catch (e) {
      debugPrint('Could not launch phone call: $e');
      return false;
    }
  }

  /// Launch WhatsApp directly with optional prefilled message
  static Future<bool> openWhatsApp({
    required String phoneNumber,
    String message = 'Hello, I found your profile on KaamSetu app and need your service.',
  }) async {
    // Format number to international format without + (e.g. 919876543210)
    String cleanNumber = cleanPhoneNumber(phoneNumber);
    if (!cleanNumber.startsWith('91') && cleanNumber.length == 10) {
      cleanNumber = '91$cleanNumber';
    }

    final String encodedMsg = Uri.encodeComponent(message);
    final Uri waUri = Uri.parse('https://wa.me/$cleanNumber?text=$encodedMsg');

    try {
      if (await canLaunchUrl(waUri)) {
        return await launchUrl(waUri, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(waUri);
      }
    } catch (e) {
      debugPrint('Could not launch WhatsApp: $e');
      return false;
    }
  }
}
