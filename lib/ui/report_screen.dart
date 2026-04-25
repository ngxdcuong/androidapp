import 'package:expense_tracker/services/api_service.dart';
import 'package:expense_tracker/abstraction/models/expense.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;

  Map<String, double> _expensesByCategory = {};
  List<Map<String, dynamic>> _dailyData = [];

  DateTime _selectedMonth = DateTime.now();

  double _total = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      final data = await ApiService.getExpenses();

      final expenses = data.map<Expense>((e) {
        return Expense(
          id: int.tryParse(e['id'].toString()),
          amount: double.tryParse(e['amount'].toString()) ?? 0,
          category: e['category'] ?? '',
          description: e['description'] ?? '',
          date: DateTime.parse(e['date']),
        );
      }).toList();

      // ✅ FILTER THEO THÁNG
      final filtered = expenses.where((e) =>
      e.date.year == _selectedMonth.year &&
          e.date.month == _selectedMonth.month).toList();

      _total = filtered.fold(0, (sum, e) => sum + e.amount);

      final byCategory = _getExpensesByCategory(filtered);
      final daily = _groupByDay(filtered);

      setState(() {
        _expensesByCategory = byCategory;
        _dailyData = daily;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Map<String, double> _getExpensesByCategory(List<Expense> expenses) {
    final map = <String, double>{};
    for (var e in expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  List<Map<String, dynamic>> _groupByDay(List<Expense> expenses) {
    final map = <DateTime, double>{};

    for (var e in expenses) {
      final day = DateTime(e.date.year, e.date.month, e.date.day);
      map[day] = (map[day] ?? 0) + e.amount;
    }

    final keys = map.keys.toList()..sort();

    return keys.map((d) => {
      'date': d,
      'amount': map[d]!,
    }).toList();
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + offset);
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          children: [
            // ✅ HEADER CHỌN THÁNG
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ],
              ),
            ),

            // ✅ TOTAL
            Center(
              child: Text(
                NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                    .format(_total),
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo),
              ),
            ),

            const SizedBox(height: 10),

            _buildPie(),
            _buildLine(),
          ],
        ),
      ),
    );
  }

  Widget _buildPie() {
    if (_expensesByCategory.isEmpty) {
      return const Center(child: Text("No data"));
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: SizedBox(
        height: 200,
        child: PieChart(
          PieChartData(
            sections: _expensesByCategory.entries.map((e) {
              return PieChartSectionData(
                value: e.value,
                color: _getCategoryColor(e.key),
                title: "${e.key}\n${e.value.toInt()}",
                radius: 50,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLine() {
    if (_dailyData.length < 2) return const SizedBox();

    return Card(
      margin: const EdgeInsets.all(16),
      child: SizedBox(
        height: 250,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((e) {
                    final date = _dailyData[e.x.toInt()]['date'];
                    return LineTooltipItem(
                      "${DateFormat('dd/MM').format(date)}\n${e.y.toInt()} ₫",
                      const TextStyle(color: Colors.white),
                    );
                  }).toList();
                },
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: _dailyData.asMap().entries.map((e) {
                  return FlSpot(
                    e.key.toDouble(),
                    e.value['amount'],
                  );
                }).toList(),
                isCurved: true,
                color: Colors.indigo,
                barWidth: 3,
                dotData: FlDotData(show: true),
              ),
            ],
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: (_dailyData.length / 6).ceilToDouble(),
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= _dailyData.length) return Container();

                    final step = (_dailyData.length / 6).ceil();
                    if (index % step != 0) return Container();

                    final date = _dailyData[index]['date'];
                    return Text(
                      DateFormat('dd/MM').format(date),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.orange;
      case 'Transport':
        return Colors.blue;
      case 'Shopping':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}