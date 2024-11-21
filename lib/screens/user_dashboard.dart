import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tap_to_pay_user/models/transaction.dart';
import 'package:tap_to_pay_user/state/customer_state/customer_cubit.dart';
import 'package:tap_to_pay_user/state/customer_state/customer_state.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _currencyFormatter = NumberFormat.currency(symbol: '\$');

  @override
  void initState() {
    super.initState();
    _checkNFCAvailability();
  }

  Future<void> _checkNFCAvailability() async {
    final isAvailable = await context.read<CustomerCubit>().isNFCAvailable();
    if (!isAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('NFC is not available on this device'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tap to Pay'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<CustomerCubit>().loadTransactions(),
          ),
        ],
      ),
      body: BlocConsumer<CustomerCubit, CustomerState>(
        listener: (context, state) {
          if (state is PaymentSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Payment of ${_currencyFormatter.format(state.transaction.amount)} sent successfully',
                ),
                backgroundColor: Colors.green,
              ),
            );
            _amountController.clear();
          }
          if (state is CustomerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildPaymentForm(context, state),
                ),
              ),
              if (state is TransactionsLoaded) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildTotalSpent(state.totalSpent),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: _TransactionList(transactions: state.transactions),
                ),
              ],
              if (state is SendingPayment)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentForm(BuildContext context, CustomerState state) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '\$',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enabled: state is! SendingPayment,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an amount';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) {
                return 'Please enter a valid amount';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: state is SendingPayment
                ? null
                : () {
                    if (_formKey.currentState?.validate() ?? false) {
                      final amount = double.parse(_amountController.text);
                      context.read<CustomerCubit>().sendPayment(
                            amount: amount,
                            currency: 'USD',
                          );
                    }
                  },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: state is SendingPayment
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Tap to Pay'),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSpent(double totalSpent) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Spent',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              _currencyFormatter.format(totalSpent),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  final List<Transaction> transactions;

  const _TransactionList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final transaction = transactions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getStatusColor(transaction.status),
                child: Icon(
                  _getStatusIcon(transaction.status),
                  color: Colors.white,
                ),
              ),
              title: Text(
                NumberFormat.currency(symbol: '\$').format(transaction.amount),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${transaction.description}\n${DateFormat.yMMMd().add_jm().format(transaction.timestamp)}',
              ),
              isThreeLine: true,
            ),
          );
        },
        childCount: transactions.length,
      ),
    );
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.failed:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return Icons.check;
      case TransactionStatus.pending:
        return Icons.access_time;
      case TransactionStatus.failed:
        return Icons.error_outline;
    }
  }
}
