import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';

class StatisticScreen extends StatelessWidget {
  const StatisticScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Thống Kê Tài Chính"),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: "CHI TIÊU", icon: Icon(Icons.upload_rounded)),
              Tab(text: "THU NHẬP", icon: Icon(Icons.download_rounded)),
            ],
            indicatorColor: Colors.white,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: const TabBarView(
          children: [
            ChartPageView(type: TransactionType.expense),
            ChartPageView(type: TransactionType.income),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Tab Chi tiêu / Thu nhập — chuyển tháng được
// ─────────────────────────────────────────────
class ChartPageView extends StatefulWidget {
  final TransactionType type;
  const ChartPageView({super.key, required this.type});

  @override
  State<ChartPageView> createState() => _ChartPageViewState();
}

class _ChartPageViewState extends State<ChartPageView> {
  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
  }

  void _prevMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year--;
      } else {
        _month--;
      }
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    // Không cho chuyển sang tháng tương lai
    if (_year > now.year || (_year == now.year && _month >= now.month)) return;
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year++;
      } else {
        _month++;
      }
    });
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month == now.month && _year == now.year;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    final data = widget.type == TransactionType.expense
        ? provider.expenseByCategoryForMonth(_month, _year)
        : provider.incomeByCategoryForMonth(_month, _year);

    final List<Color> colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange,
      Colors.purple, Colors.teal, Colors.pink, Colors.amber,
    ];

    final double total = data.values.fold(0, (sum, v) => sum + v);

    final monthLabel =
        '${_month.toString().padLeft(2, '0')}/$_year';
    final typeLabel =
    widget.type == TransactionType.expense ? 'chi' : 'thu';
    final titleLabel = widget.type == TransactionType.expense
        ? 'CƠ CẤU CHI TIÊU'
        : 'NGUỒN THU NHẬP';

    return Column(
      children: [
        // ── Bộ chọn tháng ──
        Container(
          color: Colors.blueAccent.withOpacity(0.08),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _prevMonth,
                icon: const Icon(Icons.chevron_left, size: 28),
                color: Colors.blueAccent,
                splashRadius: 22,
              ),
              GestureDetector(
                onTap: () => _pickMonthYear(context),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month,
                          size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Tháng $_month/$_year',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: _isCurrentMonth ? null : _nextMonth,
                icon: Icon(
                  Icons.chevron_right,
                  size: 28,
                  color: _isCurrentMonth
                      ? Colors.grey.shade300
                      : Colors.blueAccent,
                ),
                splashRadius: 22,
              ),
            ],
          ),
        ),

        // ── Nội dung ──
        Expanded(
          child: data.isEmpty
              ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined,
                    size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'Tháng $monthLabel\nchưa có dữ liệu $typeLabel.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15, color: Colors.grey, height: 1.6),
                ),
              ],
            ),
          )
              : Column(
            children: [
              const SizedBox(height: 16),
              Text(
                '$titleLabel — $monthLabel',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 16),

              // PieChart
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: data.entries
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) {
                      final i = entry.key;
                      final val = entry.value;
                      final pct = (val.value / total) * 100;
                      return PieChartSectionData(
                        color: colors[i % colors.length],
                        value: val.value,
                        title: '${pct.toStringAsFixed(0)}%',
                        radius: 54,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Text(
                'Tổng $typeLabel: ${fmt.format(total)}',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: widget.type == TransactionType.expense
                      ? Colors.red
                      : Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),

              // Danh sách danh mục
              Expanded(
                child: ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (ctx, i) {
                    final category = data.keys.elementAt(i);
                    final amount = data.values.elementAt(i);
                    final pct = (amount / total) * 100;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colors[i % colors.length],
                        radius: 8,
                      ),
                      title: Text(category,
                          style: const TextStyle(fontSize: 14)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            fmt.format(amount),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: widget.type ==
                                  TransactionType.expense
                                  ? Colors.redAccent
                                  : Colors.green,
                            ),
                          ),
                          Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Dialog chọn nhanh tháng/năm
  Future<void> _pickMonthYear(BuildContext context) async {
    final now = DateTime.now();
    int tempMonth = _month;
    int tempYear = _year;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('Chọn tháng / năm'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Chọn năm
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Năm:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => setInner(() => tempYear--),
                        color: Colors.blueAccent,
                      ),
                      Text('$tempYear',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: tempYear < now.year
                            ? () => setInner(() => tempYear++)
                            : null,
                        color: Colors.blueAccent,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Lưới 12 tháng
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1.6,
                children: List.generate(12, (i) {
                  final m = i + 1;
                  final isFuture = tempYear == now.year && m > now.month;
                  final isSelected = m == tempMonth && tempYear == _year;
                  return GestureDetector(
                    onTap: isFuture
                        ? null
                        : () {
                      setInner(() => tempMonth = m);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blueAccent
                            : isFuture
                            ? Colors.grey.shade100
                            : Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'T$m',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : isFuture
                              ? Colors.grey.shade400
                              : Colors.blueAccent,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Huỷ'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white),
              onPressed: () {
                setState(() {
                  _month = tempMonth;
                  _year = tempYear;
                });
                Navigator.pop(ctx);
              },
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
  }
}