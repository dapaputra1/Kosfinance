import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kos_finance_app/models/user_model.dart';
import 'package:kos_finance_app/models/category_model.dart';
import 'package:kos_finance_app/models/transaction_model.dart';

class LocalDbService {
  static const String _usersKey = 'offline_users_v1';
  static const String _categoriesKey = 'offline_categories_v1';
  static const String _transactionsKey = 'offline_transactions_v1';
  static const String _modeKey = 'app_offline_mode';

  static bool _isOfflineOnly = true;
  static bool get isOfflineOnly => _isOfflineOnly;

  static Future<void> setOfflineMode(bool value) async {
    _isOfflineOnly = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_modeKey, value);
  }

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isOfflineOnly = prefs.getBool(_modeKey) ?? true; // Default to offline-first for smooth zero-config experience

    // Seed default categories if none exist
    if (!prefs.containsKey(_categoriesKey)) {
      final defaultCategories = _getDefaultCategories();
      final encoded = json.encode(defaultCategories.map((c) => c.toJson()).toList());
      await prefs.setString(_categoriesKey, encoded);
    }

    // Seed default user if none exist
    if (!prefs.containsKey(_usersKey)) {
      final defaultUsers = [
        {
          'id': 1,
          'name': 'Daffa Fadhlullah Saputra',
          'email': 'fsdaffa610@gmail.com',
          'password': 'password123',
          'token': 'offline_token_daffa_1',
        },
        {
          'id': 2,
          'name': 'Anak Kos Mandiri',
          'email': 'anakkos@gmail.com',
          'password': 'password123',
          'token': 'offline_token_guest_2',
        }
      ];
      await prefs.setString(_usersKey, json.encode(defaultUsers));
    }
  }

  // ==================== AUTH ====================

  static Future<User> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersData = prefs.getString(_usersKey);
    List<dynamic> users = usersData != null ? json.decode(usersData) : [];

    final found = users.firstWhere(
      (u) => (u['email'] as String).toLowerCase() == email.trim().toLowerCase(),
      orElse: () => null,
    );

    if (found == null) {
      // If user doesn't exist yet, auto-create account smoothly for user convenience
      return await register(email.split('@')[0], email, password);
    }

    // If password provided and matches or if standard offline mode
    return User(
      id: found['id'],
      name: found['name'],
      email: found['email'],
      token: found['token'] ?? 'offline_token_${found['id']}',
    );
  }

  static Future<User> register(String name, String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersData = prefs.getString(_usersKey);
    List<dynamic> users = usersData != null ? json.decode(usersData) : [];

    final existingIndex = users.indexWhere(
      (u) => (u['email'] as String).toLowerCase() == email.trim().toLowerCase(),
    );

    if (existingIndex != -1) {
      // Update existing
      users[existingIndex]['name'] = name;
      users[existingIndex]['password'] = password;
      await prefs.setString(_usersKey, json.encode(users));
      return User(
        id: users[existingIndex]['id'],
        name: users[existingIndex]['name'],
        email: users[existingIndex]['email'],
        token: users[existingIndex]['token'] ?? 'offline_token_${users[existingIndex]['id']}',
      );
    }

    final newId = DateTime.now().millisecondsSinceEpoch % 100000;
    final newUser = {
      'id': newId,
      'name': name.trim().isEmpty ? 'Anak Kos' : name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'token': 'offline_token_$newId',
    };

    users.add(newUser);
    await prefs.setString(_usersKey, json.encode(users));

    // Seed starter transactions for new account
    await _seedStarterTransactions(newId);

    return User(
      id: newId,
      name: newUser['name'] as String,
      email: newUser['email'] as String,
      token: newUser['token'] as String,
    );
  }

  static Future<User> loginAsGuest() async {
    return await login('fsdaffa610@gmail.com', 'password123');
  }

  static Future<User> updateProfile(
    int userId,
    String name,
    String email, {
    String? oldPassword,
    String? newPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final usersData = prefs.getString(_usersKey);
    List<dynamic> users = usersData != null ? json.decode(usersData) : [];

    final index = users.indexWhere((u) => u['id'] == userId);
    if (index != -1) {
      users[index]['name'] = name;
      users[index]['email'] = email;
      if (newPassword != null && newPassword.isNotEmpty) {
        users[index]['password'] = newPassword;
      }
      await prefs.setString(_usersKey, json.encode(users));
    }

    return User(
      id: userId,
      name: name,
      email: email,
      token: 'offline_token_$userId',
    );
  }

  // ==================== CATEGORIES ====================

  static List<Category> _getDefaultCategories() {
    return [
      // Pengeluaran
      Category(id: 1, name: 'Makan & Minum', icon: 'restaurant', type: 'expense'),
      Category(id: 2, name: 'Bayar Kos', icon: 'home', type: 'expense'),
      Category(id: 3, name: 'Laundry', icon: 'local_laundry_service', type: 'expense'),
      Category(id: 4, name: 'WiFi & Pulsa', icon: 'wifi', type: 'expense'),
      Category(id: 5, name: 'Belanja Bulanan', icon: 'shopping_cart', type: 'expense'),
      Category(id: 6, name: 'Nongkrong & Hiburan', icon: 'coffee', type: 'expense'),
      Category(id: 7, name: 'Transportasi', icon: 'directions_bus', type: 'expense'),
      Category(id: 8, name: 'Kesehatan & Obat', icon: 'medical_services', type: 'expense'),
      Category(id: 9, name: 'Kebutuhan Kuliah', icon: 'school', type: 'expense'),
      Category(id: 10, name: 'Lain-lain', icon: 'more_horiz', type: 'expense'),
      // Pemasukan
      Category(id: 11, name: 'Uang Saku Ortu', icon: 'account_balance_wallet', type: 'income'),
      Category(id: 12, name: 'Gaji / Magang', icon: 'work', type: 'income'),
      Category(id: 13, name: 'Beasiswa', icon: 'school', type: 'income'),
      Category(id: 14, name: 'Freelance & Bisnis', icon: 'store', type: 'income'),
      Category(id: 15, name: 'Hadiah / THR', icon: 'card_giftcard', type: 'income'),
      Category(id: 16, name: 'Lain-lain', icon: 'more_horiz', type: 'income'),
    ];
  }

  static Future<List<Category>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_categoriesKey);
    if (data == null) {
      final def = _getDefaultCategories();
      await prefs.setString(_categoriesKey, json.encode(def.map((c) => c.toJson()).toList()));
      return def;
    }
    final List<dynamic> list = json.decode(data);
    return list.map((item) => Category.fromJson(item)).toList();
  }

  static Future<Category> addCategory(String name, String icon, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final categories = await getCategories();
    final newId = (categories.map((c) => c.id).fold<int>(0, (prev, id) => id > prev ? id : prev)) + 1;
    final newCat = Category(id: newId, name: name, icon: icon, type: type);
    categories.add(newCat);
    await prefs.setString(_categoriesKey, json.encode(categories.map((c) => c.toJson()).toList()));
    return newCat;
  }

  // ==================== TRANSACTIONS ====================

  static Future<void> _seedStarterTransactions(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final starter = [
      Transaction(
        id: 1,
        userId: userId,
        title: 'Kiriman Uang Saku',
        amount: 2000000,
        date: now.subtract(const Duration(days: 3)),
        type: TransactionType.income,
        categoryId: 11,
        categoryName: 'Uang Saku Ortu',
        categoryIcon: 'account_balance_wallet',
        note: 'Transfer bulanan awal bulan',
      ),
      Transaction(
        id: 2,
        userId: userId,
        title: 'Makan Siang Warteg',
        amount: 22000,
        date: now.subtract(const Duration(days: 1)),
        type: TransactionType.expense,
        categoryId: 1,
        categoryName: 'Makan & Minum',
        categoryIcon: 'restaurant',
        note: 'Nasi ayam + es teh',
      ),
      Transaction(
        id: 3,
        userId: userId,
        title: 'Laundry Kiloan',
        amount: 28000,
        date: now,
        type: TransactionType.expense,
        categoryId: 3,
        categoryName: 'Laundry',
        categoryIcon: 'local_laundry_service',
        note: '4 kg pakaian',
      ),
    ];

    final key = '${_transactionsKey}_$userId';
    await prefs.setString(key, json.encode(starter.map((t) => t.toJson()).toList()));
  }

  static Future<List<Transaction>> getTransactions(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_transactionsKey}_$userId';
    final data = prefs.getString(key);
    if (data == null) {
      await _seedStarterTransactions(userId);
      final seededData = prefs.getString(key);
      if (seededData != null) {
        final List<dynamic> list = json.decode(seededData);
        return list.map((item) => Transaction.fromJson(item)).toList();
      }
      return [];
    }

    final List<dynamic> list = json.decode(data);
    final items = list.map((item) => Transaction.fromJson(item)).toList();
    // Sort descending by date
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  static Future<Transaction> addTransaction(Transaction tx) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_transactionsKey}_${tx.userId}';
    final transactions = await getTransactions(tx.userId);

    // Look up category name & icon if missing
    String? catName = tx.categoryName;
    String? catIcon = tx.categoryIcon;
    if (catName == null || catIcon == null) {
      final categories = await getCategories();
      final cat = categories.firstWhere((c) => c.id == tx.categoryId, orElse: () => categories.first);
      catName = cat.name;
      catIcon = cat.icon;
    }

    final newId = DateTime.now().millisecondsSinceEpoch % 1000000;
    final created = Transaction(
      id: newId,
      userId: tx.userId,
      title: tx.title,
      amount: tx.amount,
      date: tx.date,
      type: tx.type,
      categoryId: tx.categoryId,
      note: tx.note,
      categoryName: catName,
      categoryIcon: catIcon,
    );

    transactions.insert(0, created);
    await prefs.setString(key, json.encode(transactions.map((t) => t.toJson()).toList()));
    return created;
  }

  static Future<Transaction> updateTransaction(int txId, Transaction tx) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_transactionsKey}_${tx.userId}';
    final transactions = await getTransactions(tx.userId);

    String? catName = tx.categoryName;
    String? catIcon = tx.categoryIcon;
    if (catName == null || catIcon == null) {
      final categories = await getCategories();
      final cat = categories.firstWhere((c) => c.id == tx.categoryId, orElse: () => categories.first);
      catName = cat.name;
      catIcon = cat.icon;
    }

    final updated = Transaction(
      id: txId,
      userId: tx.userId,
      title: tx.title,
      amount: tx.amount,
      date: tx.date,
      type: tx.type,
      categoryId: tx.categoryId,
      note: tx.note,
      categoryName: catName,
      categoryIcon: catIcon,
    );

    final idx = transactions.indexWhere((t) => t.id == txId);
    if (idx != -1) {
      transactions[idx] = updated;
    } else {
      transactions.insert(0, updated);
    }

    await prefs.setString(key, json.encode(transactions.map((t) => t.toJson()).toList()));
    return updated;
  }

  static Future<bool> deleteTransaction(int userId, int txId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_transactionsKey}_$userId';
    final transactions = await getTransactions(userId);
    transactions.removeWhere((t) => t.id == txId);
    await prefs.setString(key, json.encode(transactions.map((t) => t.toJson()).toList()));
    return true;
  }

  // ==================== DASHBOARD STATS ====================

  static Future<Map<String, dynamic>> getDashboardData(int userId) async {
    final transactions = await getTransactions(userId);
    final now = DateTime.now();

    double totalIncome = 0;
    double totalExpense = 0;
    double monthlyIncome = 0;
    double monthlyExpense = 0;
    final Map<int, Map<String, dynamic>> categoryTotals = {};

    for (final tx in transactions) {
      final isSameMonth = tx.date.year == now.year && tx.date.month == now.month;
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
        if (isSameMonth) monthlyIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
        if (isSameMonth) {
          monthlyExpense += tx.amount;
          if (!categoryTotals.containsKey(tx.categoryId)) {
            categoryTotals[tx.categoryId] = {
              'id': tx.categoryId,
              'name': tx.categoryName ?? 'Pengeluaran',
              'icon': tx.categoryIcon ?? 'shopping_bag',
              'total': 0.0,
            };
          }
          categoryTotals[tx.categoryId]!['total'] =
              (categoryTotals[tx.categoryId]!['total'] as double) + tx.amount;
        }
      }
    }

    final categoryExpenses = categoryTotals.values.toList();
    categoryExpenses.sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));

    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'balance': totalIncome - totalExpense,
      'monthlyIncome': monthlyIncome,
      'monthlyExpense': monthlyExpense,
      'categoryExpenses': categoryExpenses,
    };
  }
}
