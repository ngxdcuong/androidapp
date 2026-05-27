import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../main.dart';

class TransactionList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final txs = provider.transactions;

    return txs.isEmpty
        ? const Center(child: Text("Chưa có giao dịch nào."))
        : ListView.builder(
      itemCount: txs.length,
      itemBuilder: (ctx, i) {
        final isExpense = txs[i].type == TransactionType.expense;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: ListTile(
            leading: Icon(
              isExpense ? Icons.remove_circle : Icons.add_circle,
              color: isExpense ? Colors.red : Colors.green,
            ),
            title: Text(txs[i].title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${txs[i].category} | ${txs[i].walletName} | ${DateFormat('dd/MM/yyyy').format(txs[i].date)}"),
            trailing: Text(
              NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(txs[i].amount),
              style: TextStyle(color: isExpense ? Colors.red : Colors.green, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              final homeState = context.findAncestorStateOfType<State<HomeScreen>>();
              if (homeState != null) (homeState as dynamic).showEditForm(context, txs[i]);
            },
            onLongPress: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Xác nhận xóa?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
                    TextButton(
                      onPressed: () { provider.removeTransaction(txs[i].id); Navigator.pop(ctx); },
                      child: const Text("Xóa", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
