import '../theme/app_constants.dart';

/// Form and input validation helper for financial transactions and budgets.
class TransactionValidator {
  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an amount';
    }
    final cleanValue = value.replaceAll(',', '').trim();
    final amount = double.tryParse(cleanValue);
    if (amount == null) {
      return 'Please enter a valid number';
    }
    if (amount <= 0) {
      return 'Amount must be greater than zero';
    }
    if (amount > AppConstants.maxTransactionAmount) {
      return 'Amount exceeds maximum limit';
    }
    return null;
  }

  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title cannot be empty';
    }
    final trimmed = value.trim();
    if (trimmed.length > AppConstants.maxTitleLength) {
      return 'Title must be ${AppConstants.maxTitleLength} characters or less';
    }
    return null;
  }

  static String? validateCategory(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select a category';
    }
    return null;
  }

  static String? validateNotes(String? value) {
    if (value != null && value.length > AppConstants.maxNotesLength) {
      return 'Notes must be ${AppConstants.maxNotesLength} characters or less';
    }
    return null;
  }
}
