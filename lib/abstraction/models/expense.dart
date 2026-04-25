import 'package:intl/intl.dart';

class Expense {
  final int? id;
  final double amount;
  final String category;
  final String description;
  final DateTime date;

  Expense({
    this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
  });

  String get formattedAmount =>
      NumberFormat.currency(locale: 'en_US', symbol: '\$').format(amount);
  String get formattedDate => DateFormat('MMM dd, yyyy').format(date);

  /// Convert từ Map (kết quả query SQL Server)
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      description: map['description'] as String,
      date: map['date'] is DateTime
          ? map['date'] as DateTime
          : DateTime.parse(map['date'].toString()),
    );
  }

  /// Convert sang Map để INSERT/UPDATE
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'category': category,
      'description': description,
      'date': DateFormat('yyyy-MM-dd HH:mm:ss').format(date),
    };
  }
}
