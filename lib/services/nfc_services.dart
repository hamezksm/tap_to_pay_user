import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;

// 🔄 Changed class name to indicate user-side functionality
class NFCService {
  // 🔄 New method to format payment data
  String _formatPaymentData(String amount, String currency, String userId) {
    return '$userId|$amount|$currency|${DateTime.now().millisecondsSinceEpoch}';
  }

  // 🔄 Removed reader functionality since users only send payments
  // 🆕 New method to initiate payment
  Future<bool> initiatePayment(
      String amount, String currency, String userId) async {
    try {
      // Check NFC availability
      var availability = await FlutterNfcKit.nfcAvailability;
      if (availability != NFCAvailability.available) {
        throw Exception('NFC not available on this device');
      }

      // 🆕 Format payment data
      String paymentData = _formatPaymentData(amount, currency, userId);

      // 🆕 Create payment record with specific payment type identifier
      var record = ndef.UriRecord.fromString(
        'pay://${paymentData}',
        // Using URI format to ensure compatibility with payment terminals
      );

      // Start NFC session
      await FlutterNfcKit.poll(
        timeout: Duration(seconds: 30), // 🔄 Increased timeout for payment
        iosMultipleTagMessage: "Multiple payment terminals detected",
        // 🔄 Changed alert message to be payment-specific
        iosAlertMessage: "Hold your phone near the payment terminal",
      );

      // 🆕 Send payment data
      await FlutterNfcKit.writeNDEFRecords([record]);

      // Complete NFC session
      await FlutterNfcKit.finish(iosAlertMessage: "Payment sent successfully!");
      return true;
    } catch (e) {
      print('Payment failed: $e');
      await FlutterNfcKit.finish(
          iosErrorMessage: "Payment failed. Please try again.");
      return false;
    }
  }

  // 🆕 Method to check if device supports NFC payments
  Future<bool> isNFCPaymentAvailable() async {
    try {
      var availability = await FlutterNfcKit.nfcAvailability;
      return availability == NFCAvailability.available;
    } catch (e) {
      print('Error checking NFC availability: $e');
      return false;
    }
  }
}

/* Key Differences from Merchant Version:
 * 1. Focused on sending payments only (removed reading functionality)
 * 2. Added payment-specific data formatting
 * 3. Uses URI record type for better payment terminal compatibility
 * 4. Enhanced error handling with payment-specific messages
 * 5. Added NFC availability check method
 * 6. Increased timeout duration for payment processing
 * 7. Payment-specific user messages
 */