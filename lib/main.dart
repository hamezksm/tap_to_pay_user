import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tap_to_pay_user/models/transaction.dart';
import 'package:tap_to_pay_user/screens/user_dashboard.dart';
import 'package:tap_to_pay_user/services/nfc_services.dart';
import 'package:tap_to_pay_user/state/customer_state/customer_cubit.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());
  await Hive.openBox<Transaction>('transactions');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Customer Payment App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (context) => CustomerCubit(
          customerId: 'customerId', // Replace with actual customerId
          nfcService: NFCService(),
          transactionBox: Hive.box<Transaction>('transactions'),
        ),
        child: const CustomerDashboard(),
      ),
    );
  }
}
