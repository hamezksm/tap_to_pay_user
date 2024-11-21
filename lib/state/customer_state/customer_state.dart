import 'package:tap_to_pay_user/models/transaction.dart';

abstract class CustomerState {}

class CustomerInitial extends CustomerState {}

class SendingPayment extends CustomerState {}

class PaymentSent extends CustomerState {
  final Transaction transaction;
  PaymentSent(this.transaction);
}

class CustomerError extends CustomerState {
  final String message;
  CustomerError(this.message);
}

class TransactionsLoaded extends CustomerState {
  final List<Transaction> transactions;
  final double totalSpent;
  TransactionsLoaded(this.transactions, this.totalSpent);
}
