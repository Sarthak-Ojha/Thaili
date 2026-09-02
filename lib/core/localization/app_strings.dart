import 'package:flutter/material.dart';
import '../state/app_state.dart';

class AppStrings {
  // Common
  static String continueButton(AppLanguage lang) =>
      lang == AppLanguage.nepali ? 'अगाडि बढ्नुहोस्' : 'Continue';
  static String back(AppLanguage lang) =>
      lang == AppLanguage.nepali ? 'पछाडि' : 'Back';
  static String skip(AppLanguage lang) =>
      lang == AppLanguage.nepali ? 'छोड्नुहोस्' : 'Skip';

  // Step 1: Currency & Language Screen
  static String step1Progress(AppLanguage lang) =>
      lang == AppLanguage.nepali ? 'चरण १ / २' : 'Step 1 of 2';
  static String chooseCurrencyTitle(AppLanguage lang) =>
      lang == AppLanguage.nepali ? 'आफ्नो मुद्रा छान्नुहोस्' : 'Choose your currency';
  static String chooseCurrencyDesc(AppLanguage lang) => lang == AppLanguage.nepali
      ? 'आफ्नो मुख्य मुद्रा छान्नुहोस्। तपाईं पछि सेटिङ्सबाट अन्य मुद्राहरू पनि थप्न सक्नुहुन्छ।'
      : 'Select your primary currency. You can add more currencies later in settings.';
  static String primaryCurrencySection(AppLanguage lang) =>
      lang == AppLanguage.nepali ? 'मुख्य मुद्रा' : 'Primary Currency';
  static String languageSection(AppLanguage lang) =>
      lang == AppLanguage.nepali ? 'भाषा / Language' : 'Language / भाषा';
  static String englishLabel(AppLanguage lang) => 'English';
  static String englishSubLabel(AppLanguage lang) =>
      lang == AppLanguage.nepali ? 'अंग्रेजी' : 'Default';
  static String nepaliLabel(AppLanguage lang) => 'नेपाली';
  static String nepaliSubLabel(AppLanguage lang) =>
      lang == AppLanguage.nepali ? 'पूर्वनिर्धारित' : 'Nepali';

  // Step 2: Initial Balance Screen
  static String step2Progress(AppLanguage lang) =>
      lang == AppLanguage.nepali ? 'चरण २ / २' : 'Step 2 of 2';
  static String whatsInYourThaili(AppLanguage lang) =>
      lang == AppLanguage.nepali ? 'तपाईंको थैलीमा कति छ?' : "What's in your Thaili?";
  static String startWithBalance(AppLanguage lang) =>
      lang == AppLanguage.nepali ? 'आफ्नो हालको मौज्दातबाट सुरु गर्नुहोस्।' : 'Start with your current balance.';
  static String addLater(AppLanguage lang) =>
      lang == AppLanguage.nepali ? 'म पछि थप्नेछु' : "I'll add this later";

  // Home & Dashboard (Personal Finance Intelligence)
  static String welcomeBackUser(AppLanguage lang, String name) =>
      lang == AppLanguage.nepali ? 'नमस्ते, $name' : 'Welcome back, $name';
  static String availableBalance(AppLanguage lang) =>
      lang == AppLanguage.nepali ? 'उपलब्ध मौज्दात' : 'Available Balance';
  static String myThaili(AppLanguage lang) =>
      lang == AppLanguage.nepali ? 'मेरो थैली' : 'My Thaili';
  static String thisMonth(AppLanguage lang) =>
      lang == AppLanguage.nepali ? 'यस महिना' : 'This Month';
  static String monthlyChangeBadge(AppLanguage lang, String pct) =>
      lang == AppLanguage.nepali ? '$pct यस महिना' : '$pct MoM';
  
  // Quick Actions (Personal Finance, NOT Crypto/Banking)
  static String addExpenseAction(AppLanguage lang) =>
      lang == AppLanguage.nepali ? 'खर्च' : 'Expense';
  static String addIncomeAction(AppLanguage lang) =>
      lang == AppLanguage.nepali ? 'आम्दानी' : 'Income';
  static String transferAction(AppLanguage lang) =>
      lang == AppLanguage.nepali ? 'ट्रान्सफर' : 'Transfer';
  static String budgetsAction(AppLanguage lang) =>
      lang == AppLanguage.nepali ? 'बजेट' : 'Budgets';

  // Transactions & Metrics
  static String recentActivity(AppLanguage lang) =>
      lang == AppLanguage.nepali ? 'हालैका गतिविधिहरू' : 'Recent Activity';
  static String openingBalance(AppLanguage lang) =>
      lang == AppLanguage.nepali ? 'सुरुवाती मौज्दात' : 'Opening Balance';

  // Bottom Navigation Tabs
  static String navHome(AppLanguage lang) =>
      lang == AppLanguage.nepali ? 'गृह' : 'Home';
  static String navTransactions(AppLanguage lang) =>
      lang == AppLanguage.nepali ? 'कारोबार' : 'Transactions';
  static String navBudgets(AppLanguage lang) =>
      lang == AppLanguage.nepali ? 'बजेट' : 'Budgets';
  static String navGoals(AppLanguage lang) =>
      lang == AppLanguage.nepali ? 'लक्ष्य' : 'Goals';
  static String navMore(AppLanguage lang) =>
      lang == AppLanguage.nepali ? 'थप' : 'More';
}

extension BuildContextLocale on BuildContext {
  AppLanguage get currentLanguage => AppStateModel().language;
}
