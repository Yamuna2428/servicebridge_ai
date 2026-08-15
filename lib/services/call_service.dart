import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CallService {
  // Singleton pattern
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  /// Opens the device dialer with the given phone number.
  /// Does not directly make a call; the user must press the call button in their dialer.
  Future<void> makePhoneCall(BuildContext context, String phoneNumber) async {
    if (phoneNumber.trim().isEmpty) {
      _showErrorSnackBar(context, 'Worker phone number is not available.');
      return;
    }

    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        // Fallback: show dialog if dialer cannot be opened
        if (context.mounted) {
          _showPhoneNumberDialog(context, phoneNumber);
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showPhoneNumberDialog(context, phoneNumber);
      }
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showPhoneNumberDialog(BuildContext context, String phoneNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Worker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Could not open the dialer automatically. You can copy the number below:'),
            const SizedBox(height: 16),
            SelectableText(
              phoneNumber,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: phoneNumber));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Phone number copied to clipboard.')),
              );
            },
            child: const Text('Copy Number'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
