import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:tap_to_pay_user/models/transaction.dart';
import 'package:tap_to_pay_user/services/nfc_services.dart';
import 'package:tap_to_pay_user/state/customer_state/customer_state.dart';

class CustomerCubit extends Cubit<CustomerState> {
  final NFCService _nfcService;
  final String customerId;
  final Box<Transaction> _transactionBox;

  CustomerCubit({
    required this.customerId,
    required NFCService nfcService,
    required Box<Transaction> transactionBox,
  })  : _nfcService = nfcService,
        _transactionBox = transactionBox,
        super(CustomerInitial()) {
    loadTransactions();
  }

  Future<void> sendPayment({
    required double amount,
    required String currency,
    String description = 'NFC Payment',
  }) async {
    emit(SendingPayment());

    try {
      // Check NFC availability first
      final isAvailable = await _nfcService.isNFCPaymentAvailable();
      if (!isAvailable) {
        emit(CustomerError('NFC is not available on this device'));
        return;
      }

      final success = await _nfcService.initiatePayment(
        amount.toString(),
        currency,
        customerId,
      );

      if (success) {
        final transaction = Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          merchantId: '', // Will be filled by merchant during processing
          customerId: customerId,
          amount: amount,
          timestamp: DateTime.now(),
          description: description,
          status: TransactionStatus.pending, // Initial status is pending
          currency: currency,
        );

        await _recordTransaction(transaction);
        emit(PaymentSent(transaction));

        // Reload transactions after recording new one
        await loadTransactions();
      } else {
        emit(CustomerError('Payment failed. Please try again.'));
      }
    } catch (e) {
      emit(CustomerError('Failed to send payment: ${e.toString()}'));
    }
  }

  Future<void> loadTransactions() async {
    try {
      final transactions = _transactionBox.values
          .where((transaction) => transaction.customerId == customerId)
          .toList()
        ..sort((a, b) =>
            b.timestamp.compareTo(a.timestamp)); // Sort by newest first

      final totalSpent = transactions.fold(
        0.0,
        (sum, transaction) => sum + transaction.amount,
      );

      emit(TransactionsLoaded(transactions, totalSpent));
    } catch (e) {
      emit(CustomerError('Failed to load transactions: ${e.toString()}'));
    }
  }

  Future<void> _recordTransaction(Transaction transaction) async {
    try {
      await _transactionBox.put(transaction.id, transaction);
    } catch (e) {
      throw Exception('Failed to record transaction: ${e.toString()}');
    }
  }

  // Helper method to check if NFC is available
  Future<bool> isNFCAvailable() async {
    try {
      return await _nfcService.isNFCPaymentAvailable();
    } catch (e) {
      emit(CustomerError('Failed to check NFC availability: ${e.toString()}'));
      return false;
    }
  }
}
