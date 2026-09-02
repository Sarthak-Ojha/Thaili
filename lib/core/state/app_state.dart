import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecurringTransaction {
  final String id;
  final String title;
  final String emoji;
  final double amount;
  final String frequency;
  final String category;

  const RecurringTransaction({
    required this.id,
    required this.title,
    required this.emoji,
    required this.amount,
    this.frequency = 'Monthly',
    this.category = 'Bills',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'emoji': emoji,
        'amount': amount,
        'frequency': frequency,
        'category': category,
      };

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) =>
      RecurringTransaction(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        emoji: json['emoji'] as String? ?? '🔄',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        frequency: json['frequency'] as String? ?? 'Monthly',
        category: json['category'] as String? ?? 'Bills',
      );
}

enum AppLanguage { english, nepali }

enum AppCurrency { npr, usd, inr }

enum IncomeFrequency { monthly, weekly, irregular }

enum TransactionType { expense, income }

class TransactionItem {
  final String id;
  final String title;
  final String category;
  final String emoji;
  final double amount;
  final TransactionType type;
  final String date;
  final String paymentMethod;
  final String note;

  const TransactionItem({
    required this.id,
    required this.title,
    required this.category,
    required this.emoji,
    required this.amount,
    required this.type,
    required this.date,
    required this.paymentMethod,
    required this.note,
  });

  TransactionItem copyWith({
    String? id,
    String? title,
    String? category,
    String? emoji,
    double? amount,
    TransactionType? type,
    String? date,
    String? paymentMethod,
    String? note,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      emoji: emoji ?? this.emoji,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'emoji': emoji,
        'amount': amount,
        'type': type.name,
        'date': date,
        'paymentMethod': paymentMethod,
        'note': note,
      };

  factory TransactionItem.fromJson(Map<String, dynamic> json) =>
      TransactionItem(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        category: json['category'] as String? ?? '',
        emoji: json['emoji'] as String? ?? '💰',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        type: json['type'] == 'income'
            ? TransactionType.income
            : TransactionType.expense,
        date: json['date'] as String? ?? '',
        paymentMethod: json['paymentMethod'] as String? ?? 'Cash',
        note: json['note'] as String? ?? '',
      );
}

class BudgetItem {
  final String id;
  final String category;
  final String emoji;
  final double spent;
  final double limit;
  final String period;
  final int alertPercent;

  const BudgetItem({
    required this.id,
    required this.category,
    required this.emoji,
    required this.spent,
    required this.limit,
    this.period = 'Monthly',
    this.alertPercent = 80,
  });

  double get percent => limit > 0 ? (spent / limit) * 100 : 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'emoji': emoji,
        'spent': spent,
        'limit': limit,
        'period': period,
        'alertPercent': alertPercent,
      };

  factory BudgetItem.fromJson(Map<String, dynamic> json) => BudgetItem(
        id: json['id'] as String? ?? '',
        category: json['category'] as String? ?? '',
        emoji: json['emoji'] as String? ?? '📁',
        spent: (json['spent'] as num?)?.toDouble() ?? 0.0,
        limit: (json['limit'] as num?)?.toDouble() ?? 0.0,
        period: json['period'] as String? ?? 'Monthly',
        alertPercent: (json['alertPercent'] as num?)?.toInt() ?? 80,
      );
}

class FinancialGoal {
  final String id;
  final String title;
  final String emoji;
  final double targetAmount;
  final double currentAmount;
  final String estimatedCompletion;

  const FinancialGoal({
    required this.id,
    required this.title,
    required this.emoji,
    required this.targetAmount,
    required this.currentAmount,
    this.estimatedCompletion = 'December 2026',
  });

  int get targetInPaisa => (targetAmount * 100).round();
  int get currentInPaisa => (currentAmount * 100).round();
  int get remainingInPaisa =>
      (targetInPaisa - currentInPaisa).clamp(0, targetInPaisa);

  double get remaining => remainingInPaisa / 100.0;
  double get percent =>
      targetInPaisa > 0 ? (currentInPaisa / targetInPaisa) * 100.0 : 0.0;
  double get progressFactor =>
      targetInPaisa > 0 ? (currentInPaisa / targetInPaisa).clamp(0.0, 1.0) : 0.0;

  int monthsToReachGoal(double monthlySavingsRate) {
    if (monthlySavingsRate <= 0) return 0;
    return (remaining / monthlySavingsRate).ceil();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'emoji': emoji,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'estimatedCompletion': estimatedCompletion,
      };

  factory FinancialGoal.fromJson(Map<String, dynamic> json) => FinancialGoal(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        emoji: json['emoji'] as String? ?? '🎯',
        targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0.0,
        currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
        estimatedCompletion:
            json['estimatedCompletion'] as String? ?? 'December 2026',
      );
}

class CurrencyData {
  final AppCurrency currency;
  final String code;
  final String symbol;
  final String nameEn;
  final String nameNe;
  final String subtextEn;
  final String subtextNe;

  const CurrencyData({
    required this.currency,
    required this.code,
    required this.symbol,
    required this.nameEn,
    required this.nameNe,
    required this.subtextEn,
    required this.subtextNe,
  });

  String getName(AppLanguage lang) =>
      lang == AppLanguage.nepali ? nameNe : nameEn;
  String getSubtext(AppLanguage lang) =>
      lang == AppLanguage.nepali ? subtextNe : subtextEn;
}

class AppStateModel extends ChangeNotifier {
  static final AppStateModel _instance = AppStateModel._internal();
  factory AppStateModel() => _instance;
  AppStateModel._internal();

  bool _isOnboarded = false;
  AppLanguage _language = AppLanguage.english;
  AppCurrency _currency = AppCurrency.npr;
  double _initialBalance = 0.0;
  double _monthlyIncome = 0.0;
  IncomeFrequency _incomeFrequency = IncomeFrequency.monthly;
  String _userName = '';
  ThemeMode _themeMode = ThemeMode.system;

  // Security Toggles
  bool _appLockEnabled = true;

  // Sync & Offline State
  bool _isOffline = false;
  int _pendingSyncChanges = 0;
  String _lastSyncedTime = 'Today, 10:42 AM';

  // Goals List
  final List<FinancialGoal> _goals = [];

  // Budgets List
  final List<BudgetItem> _budgets = [];

  // Transactions List
  final List<TransactionItem> _transactions = [];

  // Recurring Transactions List
  final List<RecurringTransaction> _recurring = [];

  bool get isOnboarded => _isOnboarded;
  AppLanguage get language => _language;
  AppCurrency get currency => _currency;
  double get initialBalance => _initialBalance;
  double get monthlyIncome => _monthlyIncome;
  IncomeFrequency get incomeFrequency => _incomeFrequency;
  List<FinancialGoal> get goals => List.unmodifiable(_goals);
  FinancialGoal? get goal => _goals.isNotEmpty ? _goals.first : null;
  List<BudgetItem> get budgets => List.unmodifiable(_budgets);
  List<TransactionItem> get transactions => List.unmodifiable(_transactions);
  List<RecurringTransaction> get recurring => List.unmodifiable(_recurring);
  String get userName => _userName;
  ThemeMode get themeMode => _themeMode;

  bool get appLockEnabled => _appLockEnabled;
  bool get isOffline => _isOffline;
  int get pendingSyncChanges => _pendingSyncChanges;
  String get lastSyncedTime => _lastSyncedTime;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isOnboarded = prefs.getBool('isOnboarded') ?? false;
      _userName = prefs.getString('userName') ?? '';
      _initialBalance = prefs.getDouble('initialBalance') ?? 0.0;
      _monthlyIncome = prefs.getDouble('monthlyIncome') ?? 0.0;

      final langStr = prefs.getString('language');
      if (langStr == 'nepali') {
        _language = AppLanguage.nepali;
      } else {
        _language = AppLanguage.english;
      }

      final currStr = prefs.getString('currency');
      if (currStr == 'usd') {
        _currency = AppCurrency.usd;
      } else if (currStr == 'inr') {
        _currency = AppCurrency.inr;
      } else {
        _currency = AppCurrency.npr;
      }

      final freqStr = prefs.getString('incomeFrequency');
      if (freqStr == 'weekly') {
        _incomeFrequency = IncomeFrequency.weekly;
      } else if (freqStr == 'irregular') {
        _incomeFrequency = IncomeFrequency.irregular;
      } else {
        _incomeFrequency = IncomeFrequency.monthly;
      }

      _appLockEnabled = prefs.getBool('appLockEnabled') ?? true;

      final themeIdx = prefs.getInt('themeMode');
      if (themeIdx != null &&
          themeIdx >= 0 &&
          themeIdx < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[themeIdx];
      }

      final txJson = prefs.getString('transactions');
      if (txJson != null && txJson.isNotEmpty) {
        final List list = jsonDecode(txJson);
        _transactions.clear();
        _transactions.addAll(
            list.map((e) => TransactionItem.fromJson(e as Map<String, dynamic>)));
      }

      final bgJson = prefs.getString('budgets');
      if (bgJson != null && bgJson.isNotEmpty) {
        final List list = jsonDecode(bgJson);
        _budgets.clear();
        _budgets.addAll(
            list.map((e) => BudgetItem.fromJson(e as Map<String, dynamic>)));
      }

      final goalJson = prefs.getString('goals');
      if (goalJson != null && goalJson.isNotEmpty) {
        final List list = jsonDecode(goalJson);
        _goals.clear();
        _goals.addAll(
            list.map((e) => FinancialGoal.fromJson(e as Map<String, dynamic>)));
      }

      final recJson = prefs.getString('recurring');
      if (recJson != null && recJson.isNotEmpty) {
        final List list = jsonDecode(recJson);
        _recurring.clear();
        _recurring.addAll(list
            .map((e) => RecurringTransaction.fromJson(e as Map<String, dynamic>)));
      }

      if (_userName.isNotEmpty) {
        _isOnboarded = true;
      }
    } catch (e) {
      debugPrint('Error loading app state from SharedPreferences: $e');
    }
  }

  Future<void> saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isOnboarded', _isOnboarded);
      await prefs.setString('userName', _userName);
      await prefs.setDouble('initialBalance', _initialBalance);
      await prefs.setDouble('monthlyIncome', _monthlyIncome);
      await prefs.setString('language', _language.name);
      await prefs.setString('currency', _currency.name);
      await prefs.setString('incomeFrequency', _incomeFrequency.name);
      await prefs.setBool('appLockEnabled', _appLockEnabled);
      await prefs.setInt('themeMode', _themeMode.index);

      final txJson = jsonEncode(_transactions.map((t) => t.toJson()).toList());
      await prefs.setString('transactions', txJson);

      final bgJson = jsonEncode(_budgets.map((b) => b.toJson()).toList());
      await prefs.setString('budgets', bgJson);

      final goalJson = jsonEncode(_goals.map((g) => g.toJson()).toList());
      await prefs.setString('goals', goalJson);

      final recJson = jsonEncode(_recurring.map((r) => r.toJson()).toList());
      await prefs.setString('recurring', recJson);
    } catch (e) {
      debugPrint('Error saving app state to SharedPreferences: $e');
    }
  }

  void completeOnboarding() {
    _isOnboarded = true;
    saveToPrefs();
    notifyListeners();
  }

  void toggleAppLock(bool value) {
    _appLockEnabled = value;
    saveToPrefs();
    notifyListeners();
  }

  void toggleOfflineMode(bool value) {
    _isOffline = value;
    notifyListeners();
  }

  void syncNow() {
    _pendingSyncChanges = 0;
    _lastSyncedTime = 'Just now';
    notifyListeners();
  }

  double get totalBudgetSpent => _budgets.fold(0.0, (sum, b) => sum + b.spent);
  double get totalBudgetLimit => _budgets.fold(0.0, (sum, b) => sum + b.limit);

  void addRecurring(RecurringTransaction item) {
    _recurring.add(item);
    saveToPrefs();
    notifyListeners();
  }

  void deleteRecurring(String id) {
    _recurring.removeWhere((r) => r.id == id);
    saveToPrefs();
    notifyListeners();
  }

  // Transactions CRUD
  void addTransaction(TransactionItem item) {
    _transactions.insert(0, item);
    if (item.type == TransactionType.expense) {
      _initialBalance -= item.amount;
    } else {
      _initialBalance += item.amount;
    }
    saveToPrefs();
    notifyListeners();
  }

  void editTransaction(TransactionItem item) {
    final index = _transactions.indexWhere((t) => t.id == item.id);
    if (index != -1) {
      final old = _transactions[index];
      // Revert old effect
      if (old.type == TransactionType.expense) {
        _initialBalance += old.amount;
      } else {
        _initialBalance -= old.amount;
      }
      // Apply new effect
      if (item.type == TransactionType.expense) {
        _initialBalance -= item.amount;
      } else {
        _initialBalance += item.amount;
      }

      _transactions[index] = item;
      saveToPrefs();
      notifyListeners();
    }
  }

  void deleteTransaction(String id) {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      final item = _transactions[index];
      if (item.type == TransactionType.expense) {
        _initialBalance += item.amount;
      } else {
        _initialBalance -= item.amount;
      }

      _transactions.removeAt(index);
      saveToPrefs();
      notifyListeners();
    }
  }

  // Budgets CRUD
  void addBudget(BudgetItem item) {
    _budgets.add(item);
    saveToPrefs();
    notifyListeners();
  }

  void deleteBudget(String id) {
    _budgets.removeWhere((b) => b.id == id);
    saveToPrefs();
    notifyListeners();
  }

  // Goals CRUD
  void addGoal(FinancialGoal goal) {
    _goals.insert(0, goal);
    saveToPrefs();
    notifyListeners();
  }

  static const List<CurrencyData> supportedCurrencies = [
    CurrencyData(
      currency: AppCurrency.npr,
      code: 'NPR',
      symbol: 'रु',
      nameEn: 'NPR — Nepali Rupee',
      nameNe: 'NPR — नेपाली रुपैयाँ',
      subtextEn: 'Default • Nepali Rupee',
      subtextNe: 'पूर्वनिर्धारित • नेपाली मुद्रा',
    ),
    CurrencyData(
      currency: AppCurrency.usd,
      code: 'USD',
      symbol: '\$',
      nameEn: 'USD — US Dollar',
      nameNe: 'USD — अमेरिकी डलर',
      subtextEn: 'Global • Dollar',
      subtextNe: 'अन्तर्राष्ट्रिय • डलर',
    ),
    CurrencyData(
      currency: AppCurrency.inr,
      code: 'INR',
      symbol: '₹',
      nameEn: 'INR — Indian Rupee',
      nameNe: 'INR — भारतीय रुपैयाँ',
      subtextEn: 'Regional • Indian Rupee',
      subtextNe: 'क्षेत्रीय • भारतीय मुद्रा',
    ),
  ];

  CurrencyData get currentCurrencyData {
    return supportedCurrencies.firstWhere(
      (c) => c.currency == _currency,
      orElse: () => supportedCurrencies[0],
    );
  }

  void setLanguage(AppLanguage newLanguage) {
    if (_language != newLanguage) {
      _language = newLanguage;
      saveToPrefs();
      notifyListeners();
    }
  }

  void setCurrency(AppCurrency newCurrency) {
    if (_currency != newCurrency) {
      _currency = newCurrency;
      saveToPrefs();
      notifyListeners();
    }
  }

  void setInitialBalance(double balance) {
    _initialBalance = balance;
    saveToPrefs();
    notifyListeners();
  }

  void setMonthlyIncome(double income, IncomeFrequency frequency) {
    _monthlyIncome = income;
    _incomeFrequency = frequency;
    saveToPrefs();
    notifyListeners();
  }

  void setGoal(FinancialGoal goal) {
    if (_goals.isEmpty) {
      _goals.add(goal);
    } else {
      _goals[0] = goal;
    }
    saveToPrefs();
    notifyListeners();
  }

  static String _capitalizeWords(String input) {
    if (input.trim().isEmpty) return '';
    return input.trim().split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return '';
      if (word.length == 1) return word.toUpperCase();
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  void setUserName(String name) {
    _userName = _capitalizeWords(name);
    if (_userName.isNotEmpty) {
      _isOnboarded = true;
    }
    saveToPrefs();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    saveToPrefs();
    notifyListeners();
  }
}
