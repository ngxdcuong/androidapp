import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List _expenses = [];
  double _total = 0;
  Map<String, double> _byCategory = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // 🔥 LOAD DATA
  Future<void> loadData() async {
    try {
      setState(() => _loading = true);

      final data = await ApiService.getExpenses();

      double total = 0;
      Map<String, double> category = {};

      for (var e in data) {
        double amount =
            double.tryParse(e['amount'].toString()) ?? 0;

        total += amount;

        category[e['category']] =
            (category[e['category']] ?? 0) + amount;
      }

      if (!mounted) return;

      setState(() {
        _expenses = data;
        _total = total;
        _byCategory = category;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      print("ERROR: $e");
    }
  }

  // 🔥 DELETE + UPDATE UI NGAY
  Future<void> _deleteExpense(int id) async {
    try {
      await ApiService.deleteExpense(id);

      setState(() {
        _expenses.removeWhere((e) => e['id'] == id);
      });

      loadData(); // reload lại tổng + category
    } catch (e) {
      print("DELETE ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
          // HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.indigo],
              ),
            ),
            child: const Center(
              child: Text(
                "Dashboard",
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text("Quick Summary",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildCard(
                          "Total Expenses",
                          NumberFormat.currency(symbol: "\$")
                              .format(_total),
                          Icons.trending_down,
                          Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCard(
                          "Categories",
                          _byCategory.length.toString(),
                          Icons.pie_chart,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Text("Expenses by Category"),
                  const SizedBox(height: 10),

                  ..._byCategory.entries
                      .map((e) => _buildCategory(e.key, e.value)),

                  const SizedBox(height: 20),

                  const Text("Recent Transactions",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 10),

                  if (_expenses.isEmpty)
                    const Center(child: Text("No data"))
                  else
                    ..._expenses.map((e) => Dismissible(
                      key: Key(e['id'].toString()),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete,
                            color: Colors.white),
                      ),
                      onDismissed: (_) =>
                          _deleteExpense(int.parse(e['id'].toString())),
                      child: _buildTransaction(e),
                    )),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.2), blurRadius: 6)
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildCategory(String name, double value) {
    double percent = _total == 0 ? 0 : value / _total;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(name)),
          Expanded(
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.grey[300],
            ),
          ),
          const SizedBox(width: 10),
          Text("\$${value.toInt()}"),
        ],
      ),
    );
  }

  Widget _buildTransaction(dynamic e) {
    DateTime date = DateTime.tryParse(e['date']) ?? DateTime.now();

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.orange,
        child: Text(e['category'][0]),
      ),
      title: Text(e['description'] ?? "No description"),
      subtitle: Text(
        "${e['category']} • ${DateFormat('dd/MM/yyyy').format(date)}",
      ),
      trailing: Text(
        "\$${e['amount']}",
        style: const TextStyle(
            color: Colors.red, fontWeight: FontWeight.bold),
      ),
    );
  }
}