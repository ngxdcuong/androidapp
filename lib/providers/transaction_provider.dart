import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';

import '../models/transaction.dart';

class TransactionProvider with ChangeNotifier {
  final List<Transaction> _transactions = [];

  final Map<String, Budget> _budgets = {
    'Ăn uống': Budget(category: 'Ăn uống', limit: 2000000),
    'Di chuyển': Budget(category: 'Di chuyển', limit: 500000),
    'Mua sắm': Budget(category: 'Mua sắm', limit: 1000000),
  };

  // ───────────────── Search ─────────────────
  String _searchQuery = '';

  String get searchQuery => _searchQuery;

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  TransactionProvider() {
    _loadData();
  }

  // ───────────────── Firebase Helpers ─────────────────
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  bool get _isLoggedIn => _uid != null;

  CollectionReference<Map<String, dynamic>> get _txCol =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('transactions');

  DocumentReference<Map<String, dynamic>> get _budgetsDoc =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('settings')
          .doc('budgets');

  // ───────────────── Getters ─────────────────
  List<Transaction> get transactions {
    List<Transaction> list = List.from(_transactions);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();

      list = list.where((tx) {
        return tx.title.toLowerCase().contains(q) ||
            tx.category.toLowerCase().contains(q) ||
            tx.walletName.toLowerCase().contains(q);
      }).toList();
    }

    list.sort((a, b) => b.date.compareTo(a.date));

    return list;
  }

  Map<String, Budget> get budgets => _budgets;

  List<String> get budgetWarnings {
    List<String> warnings = [];

    _budgets.forEach((category, budget) {
      if (budget.limit > 0) {
        double percentage = budget.spent / budget.limit;

        if (percentage >= 1.0) {
          warnings.add("Danh mục '$category' đã vượt hạn mức!");
        } else if (percentage >= 0.8) {
          warnings.add("Danh mục '$category' sắp chạm hạn mức!");
        }
      }
    });

    return warnings;
  }

  double get totalBalance {
    double total = 0;

    for (Transaction tx in _transactions) {
      total +=
      tx.type == TransactionType.income ? tx.amount : -tx.amount;
    }

    return total;
  }

  Map<String, double> expenseByCategoryForMonth(
      int month,
      int year,
      ) {
    Map<String, double> data = {};

    for (Transaction tx in _transactions) {
      if (tx.type == TransactionType.expense &&
          tx.date.month == month &&
          tx.date.year == year) {
        data[tx.category] =
            (data[tx.category] ?? 0) + tx.amount;
      }
    }

    return data;
  }

  Map<String, double> incomeByCategoryForMonth(
      int month,
      int year,
      ) {
    Map<String, double> data = {};

    for (Transaction tx in _transactions) {
      if (tx.type == TransactionType.income &&
          tx.date.month == month &&
          tx.date.year == year) {
        data[tx.category] =
            (data[tx.category] ?? 0) + tx.amount;
      }
    }

    return data;
  }

  Map<String, double> get expenseByCategory {
    final now = DateTime.now();

    return expenseByCategoryForMonth(
      now.month,
      now.year,
    );
  }

  Map<String, double> get incomeByCategory {
    final now = DateTime.now();

    return incomeByCategoryForMonth(
      now.month,
      now.year,
    );
  }

  Map<String, double> spentByCategoryForMonth(
      int month,
      int year,
      ) {
    final Map<String, double> result = {};

    for (Transaction tx in _transactions) {
      if (tx.type == TransactionType.expense &&
          tx.date.month == month &&
          tx.date.year == year) {
        result[tx.category] =
            (result[tx.category] ?? 0) + tx.amount;
      }
    }

    return result;
  }

  // ───────────────── Load / Save ─────────────────
  Future<void> _loadData() async {
    if (_isLoggedIn) {
      await _loadFromFirestore();
    } else {
      await _loadFromLocal();
    }

    _refreshSpentAmount();

    notifyListeners();
  }

  Future<void> onUserLogin() async {
    await _loadFromFirestore();

    _refreshSpentAmount();

    notifyListeners();
  }

  Future<void> onUserLogout() async {
    _transactions.clear();

    _budgets.forEach((k, v) {
      v.limit =
      k == 'Ăn uống'
          ? 2000000
          : k == 'Di chuyển'
          ? 500000
          : 1000000;

      v.spent = 0;
    });

    await _loadFromLocal();

    _refreshSpentAmount();

    notifyListeners();
  }

  Future<void> _loadFromFirestore() async {
    try {
      final snap = await _txCol
          .orderBy('date', descending: true)
          .get();

      _transactions.clear();

      _transactions.addAll(
        snap.docs.map(
              (d) => Transaction.fromJson(d.data()),
        ),
      );

      final bSnap = await _budgetsDoc.get();

      if (bSnap.exists) {
        final data = bSnap.data();

        if (data != null) {
          data.forEach((key, value) {
            final limit = (value as num).toDouble();

            if (_budgets.containsKey(key)) {
              _budgets[key]!.limit = limit;
            } else {
              _budgets[key] = Budget(
                category: key,
                limit: limit,
              );
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Firestore load error: $e');

      await _loadFromLocal();
    }
  }

  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();

    final budgetsStr = prefs.getString('budgets_data');

    if (budgetsStr != null) {
      final Map<String, dynamic> decoded =
      json.decode(budgetsStr);

      decoded.forEach((key, value) {
        final limit = (value as num).toDouble();

        if (_budgets.containsKey(key)) {
          _budgets[key]!.limit = limit;
        } else {
          _budgets[key] = Budget(
            category: key,
            limit: limit,
          );
        }
      });
    }

    final txStr = prefs.getString('transactions_data');

    if (txStr != null) {
      final List<dynamic> decoded =
      json.decode(txStr);

      _transactions.clear();

      _transactions.addAll(
        decoded.map<Transaction>(
              (e) => Transaction.fromJson(
            Map<String, dynamic>.from(e),
          ),
        ),
      );
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'transactions_data',
      json.encode(
        _transactions
            .map((tx) => tx.toJson())
            .toList(),
      ),
    );
  }

  Future<void> _saveBudgetsLocal() async {
    final prefs = await SharedPreferences.getInstance();

    Map<String, double> limitsMap = {};

    _budgets.forEach((key, value) {
      limitsMap[key] = value.limit;
    });

    await prefs.setString(
      'budgets_data',
      json.encode(limitsMap),
    );
  }

  void _refreshSpentAmount() {
    final now = DateTime.now();

    for (Budget b in _budgets.values) {
      b.spent = 0;
    }

    for (Transaction tx in _transactions) {
      if (tx.type == TransactionType.expense &&
          tx.date.month == now.month &&
          tx.date.year == now.year &&
          _budgets.containsKey(tx.category)) {
        _budgets[tx.category]!.spent += tx.amount;
      }
    }
  }

  // ───────────────── CRUD ─────────────────
  Future<void> addTransaction(Transaction tx) async {
    _transactions.add(tx);

    _refreshSpentAmount();

    notifyListeners();

    await _saveData();

    if (_isLoggedIn) {
      try {
        await _txCol.doc(tx.id).set(tx.toJson());
      } catch (e) {
        debugPrint('Firestore add error: $e');
      }
    }
  }

  Future<void> removeTransaction(String id) async {
    _transactions.removeWhere(
          (tx) => tx.id == id,
    );

    _refreshSpentAmount();

    notifyListeners();

    await _saveData();

    if (_isLoggedIn) {
      try {
        await _txCol.doc(id).delete();
      } catch (e) {
        debugPrint('Firestore delete error: $e');
      }
    }
  }

  Future<void> updateTransaction(
      String id,
      Transaction newTx,
      ) async {
    final index = _transactions.indexWhere(
          (tx) => tx.id == id,
    );

    if (index != -1) {
      _transactions[index] = newTx;

      _refreshSpentAmount();

      notifyListeners();

      await _saveData();

      if (_isLoggedIn) {
        try {
          await _txCol.doc(id).set(
            newTx.toJson(),
          );
        } catch (e) {
          debugPrint('Firestore update error: $e');
        }
      }
    }
  }

  Future<void> updateBudgetLimit(
      String category,
      double newLimit,
      ) async {
    if (_budgets.containsKey(category)) {
      _budgets[category]!.limit = newLimit;
    } else {
      _budgets[category] = Budget(
        category: category,
        limit: newLimit,
      );
    }

    notifyListeners();

    await _saveBudgetsLocal();

    if (_isLoggedIn) {
      try {
        Map<String, double> limitsMap = {};

        _budgets.forEach((key, value) {
          limitsMap[key] = value.limit;
        });

        await _budgetsDoc.set(limitsMap);
      } catch (e) {
        debugPrint('Firestore budget save error: $e');
      }
    }
  }
}
