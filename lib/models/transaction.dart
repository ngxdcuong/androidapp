import 'package:uuid/uuid.dart';

enum TransactionType { income, expense }

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final String walletName;
  final TransactionType type;

  Transaction({
    String? id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.walletName,
    required this.type,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'walletName': walletName,
      'type': type == TransactionType.income ? 'income' : 'expense',
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      title: json['title'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
      category: json['category'],
      walletName: json['walletName'],
      type: json['type'] == 'income' ? TransactionType.income : TransactionType.expense,
    );
  }
}

class Budget {
  final String category;
  double limit;
  double spent;

  Budget({required this.category, required this.limit, this.spent = 0});
}
