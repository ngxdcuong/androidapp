import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'providers/transaction_provider.dart';
import 'models/transaction.dart';
import 'widgets/transaction_list.dart';
import 'screens/statistic_screen.dart';
import 'services/auth_service.dart';
import 'services/auth_wrapper.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (_) => TransactionProvider(),
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AuthWrapper(),
      ),
    ),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showSearch = false;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _showSearch = !_showSearch);
    if (!_showSearch) {
      _searchCtrl.clear();
      Provider.of<TransactionProvider>(context, listen: false).setSearchQuery('');
    }
  }

  void showTransactionForm(BuildContext context, [Transaction? existingTx]) {
    final isEditing = existingTx != null;
    final titleCtrl = TextEditingController(text: isEditing ? existingTx.title : "");
    final amountCtrl = TextEditingController(
        text: isEditing ? existingTx.amount.toStringAsFixed(0) : "");
    final otherCtrl = TextEditingController();

    final List<String> availableCategories = ['Ăn uống', 'Di chuyển', 'Mua sắm'];

    String category = 'Ăn uống';
    if (isEditing) {
      category = availableCategories.contains(existingTx.category)
          ? existingTx.category
          : 'Khác';
      if (category == 'Khác') otherCtrl.text = existingTx.category;
    }

    bool isOther = category == 'Khác';
    String wallet = isEditing ? existingTx.walletName : 'Tiền mặt';
    TransactionType type =
    isEditing ? existingTx.type : TransactionType.expense;
    DateTime date = isEditing ? existingTx.date : DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(isEditing ? "Sửa giao dịch" : "Thêm giao dịch",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Row(children: [
                const Icon(Icons.calendar_today, color: Colors.blue),
                const SizedBox(width: 10),
                Text(DateFormat('dd/MM/yyyy').format(date)),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2022),
                        lastDate: DateTime.now());
                    if (d != null) setModalState(() => date = d);
                  },
                  child: const Text("Chọn ngày"),
                )
              ]),
              TextField(
                  controller: titleCtrl,
                  decoration:
                  const InputDecoration(labelText: "Tên giao dịch")),
              TextField(
                  controller: amountCtrl,
                  decoration: const InputDecoration(labelText: "Số tiền"),
                  keyboardType: TextInputType.number),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                DropdownButton<String>(
                  value: category,
                  items: [...availableCategories, 'Khác']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setModalState(() {
                    category = v!;
                    isOther = v == 'Khác';
                  }),
                ),
                DropdownButton<TransactionType>(
                  value: type,
                  items: const [
                    DropdownMenuItem(
                        value: TransactionType.expense, child: Text("Chi")),
                    DropdownMenuItem(
                        value: TransactionType.income, child: Text("Thu")),
                  ],
                  onChanged: (v) => setModalState(() => type = v!),
                ),
              ]),
              Row(children: [
                const Text("Nguồn: "),
                DropdownButton<String>(
                  value: wallet,
                  items: ['Tiền mặt', 'ATM']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setModalState(() => wallet = v!),
                )
              ]),
              if (isOther)
                TextField(
                    controller: otherCtrl,
                    decoration: const InputDecoration(
                        labelText: "Tên danh mục tự nhập")),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    isEditing ? Colors.orange : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final amt = double.tryParse(amountCtrl.text) ?? 0;
                    if (titleCtrl.text.isEmpty || amt <= 0) return;
                    final tx = Transaction(
                      id: isEditing ? existingTx.id : null,
                      title: titleCtrl.text,
                      amount: amt,
                      date: date,
                      category: isOther ? otherCtrl.text : category,
                      walletName: wallet,
                      type: type,
                    );
                    final p = Provider.of<TransactionProvider>(context,
                        listen: false);
                    isEditing
                        ? p.updateTransaction(existingTx.id, tx)
                        : p.addTransaction(tx);
                    Navigator.pop(context);
                  },
                  child: Text(isEditing ? "CẬP NHẬT" : "LƯU"),
                ),
              ),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ),
    );
  }

  void showEditForm(BuildContext context, Transaction tx) =>
      showTransactionForm(context, tx);

  void _showEditBudgetDialog(
      BuildContext context, Budget budget, TransactionProvider provider) {
    final ctrl =
    TextEditingController(text: budget.limit.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Ngân sách ${budget.category}"),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration:
          const InputDecoration(labelText: "Hạn mức (VNĐ)"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white),
            onPressed: () {
              final l = double.tryParse(ctrl.text) ?? 0;
              if (l > 0) provider.updateBudgetLimit(budget.category, l);
              Navigator.pop(ctx);
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tài khoản'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.person, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  user?.email ?? 'Khách',
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
            const SizedBox(height: 4),
            const Text(
              'Dữ liệu của bạn được đồng bộ trên cloud.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            icon: const Icon(Icons.logout, size: 16),
            label: const Text('Đăng xuất'),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService().logout();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final warnings = provider.budgetWarnings;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
          controller: _searchCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: 'Tìm tên, danh mục, ví...',
            hintStyle: TextStyle(color: Colors.white60),
            border: InputBorder.none,
          ),
          onChanged: (v) => provider.setSearchQuery(v),
        )
            : const Text("Quản Lý Tài Chính"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: !_showSearch,
        actions: [
          // Nút tìm kiếm
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
            tooltip: _showSearch ? 'Đóng tìm kiếm' : 'Tìm kiếm',
          ),
          // Nút thống kê (ẩn khi đang search)
          if (!_showSearch)
            IconButton(
              icon: const Icon(Icons.pie_chart),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const StatisticScreen()),
              ),
              tooltip: 'Thống kê',
            ),
          // Avatar / đăng xuất
          if (!_showSearch)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _showLogoutDialog(context),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white24,
                  child: Text(
                    (user?.email?.substring(0, 1) ?? '?').toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(children: [
        // Tổng số dư
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(15)),
          child: Column(children: [
            const Text("TỔNG SỐ DƯ",
                style: TextStyle(color: Colors.white70)),
            Text(fmt.format(provider.totalBalance),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
          ]),
        ),

        // Cảnh báo ngân sách (ẩn khi đang search)
        if (!_showSearch && warnings.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              children: warnings.map((msg) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: msg.contains("đã vượt")
                      ? Colors.red.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: msg.contains("đã vượt")
                          ? Colors.red
                          : Colors.orange),
                ),
                child: Row(children: [
                  Icon(Icons.warning_amber_rounded,
                      color: msg.contains("đã vượt")
                          ? Colors.red
                          : Colors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(msg,
                        style: TextStyle(
                            color: msg.contains("đã vượt")
                                ? Colors.red.shade900
                                : Colors.orange.shade900,
                            fontWeight: FontWeight.bold)),
                  ),
                ]),
              )).toList(),
            ),
          ),

        // Ngân sách (ẩn khi đang search)
        if (!_showSearch)
          BudgetSectionWidget(
            onEditBudget: (b) =>
                _showEditBudgetDialog(context, b, provider),
          ),

        // Divider & nhãn danh sách
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            Text(
              _showSearch && _searchCtrl.text.isNotEmpty
                  ? 'Kết quả tìm kiếm'
                  : 'GIAO DỊCH GẦN ĐÂY',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                  fontSize: 12),
            ),
            const Spacer(),
            if (_showSearch && provider.searchQuery.isNotEmpty)
              Text(
                '${provider.transactions.length} kết quả',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ]),
        ),
        const Divider(height: 1),
        Expanded(child: TransactionList()),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showTransactionForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Widget ngân sách — có nút chuyển tháng
// ─────────────────────────────────────────────
class BudgetSectionWidget extends StatefulWidget {
  final void Function(Budget) onEditBudget;
  const BudgetSectionWidget({super.key, required this.onEditBudget});

  @override
  State<BudgetSectionWidget> createState() => _BudgetSectionWidgetState();
}

class _BudgetSectionWidgetState extends State<BudgetSectionWidget> {
  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
  }

  void _prevMonth() => setState(() {
    if (_month == 1) {
      _month = 12;
      _year--;
    } else {
      _month--;
    }
  });

  void _nextMonth() {
    final now = DateTime.now();
    if (_year > now.year ||
        (_year == now.year && _month >= now.month)) return;
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
    final spentMap = provider.spentByCategoryForMonth(_month, _year);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text("NGÂN SÁCH",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const Spacer(),
            IconButton(
              onPressed: _prevMonth,
              icon: const Icon(Icons.chevron_left, size: 22),
              color: Colors.blueAccent,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 18,
            ),
            GestureDetector(
              onTap: () => _pickMonthYear(context),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'T$_month/$_year',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            IconButton(
              onPressed: _isCurrentMonth ? null : _nextMonth,
              icon: Icon(Icons.chevron_right,
                  size: 22,
                  color: _isCurrentMonth
                      ? Colors.grey.shade300
                      : Colors.blueAccent),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 18,
            ),
          ]),
          const SizedBox(height: 4),
          ...provider.budgets.values.map((b) {
            final spent = spentMap[b.category] ?? 0;
            final p = b.limit > 0 ? spent / b.limit : 0.0;
            final Color c = p >= 1.0
                ? Colors.red
                : (p >= 0.8 ? Colors.orange : Colors.green);
            return Column(children: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => widget.onEditBudget(b),
                      child: Row(children: [
                        Text(b.category),
                        const Icon(Icons.edit, size: 14, color: Colors.blue),
                      ]),
                    ),
                    Text(
                      "${fmt.format(spent)} / ${fmt.format(b.limit)}",
                      style: TextStyle(
                          color: c,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ]),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: p > 1 ? 1 : p.toDouble(),
                  color: c,
                  backgroundColor: Colors.grey.shade300,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
            ]);
          }).toList(),
        ],
      ),
    );
  }

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Năm:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(children: [
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
                  ]),
                ],
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1.6,
                children: List.generate(12, (i) {
                  final m = i + 1;
                  final isFuture =
                      tempYear == now.year && m > now.month;
                  final isSelected = m == tempMonth;
                  return GestureDetector(
                    onTap: isFuture
                        ? null
                        : () => setInner(() => tempMonth = m),
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
                child: const Text('Huỷ')),
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
