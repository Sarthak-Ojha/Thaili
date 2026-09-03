/// Centralized number and currency formatting utility for Thaili.
class NumberFormatter {
  /// Formats a numeric amount with South Asian / Standard comma separator pattern (e.g. 1,00,000 or 1,000)
  static String format(double amount, {bool showDecimals = false}) {
    if (amount.isNaN || amount.isInfinite) return '0';

    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final intVal = absAmount.toInt();
    final digits = intVal.toString();

    String formattedInt;
    if (digits.length <= 3) {
      formattedInt = digits;
    } else {
      final lastThree = digits.substring(digits.length - 3);
      final remaining = digits.substring(0, digits.length - 3);
      final regExp = RegExp(r'\B(?=(\d{2})+(?!\d))');
      final formattedRem = remaining.replaceAll(regExp, ',');
      formattedInt = '$formattedRem,$lastThree';
    }

    String result = formattedInt;
    if (showDecimals) {
      final decimals = (absAmount - intVal).toStringAsFixed(2).substring(2);
      if (decimals != '00') {
        result += '.$decimals';
      }
    }

    return isNegative ? '−$result' : result;
  }

  /// Formats currency with optional symbol (e.g. "Rs. 1,500" or "Rs. -500")
  static String formatCurrency(double amount, {String symbol = '', bool showDecimals = false}) {
    final formatted = format(amount, showDecimals: showDecimals);
    if (symbol.isEmpty) return formatted;
    if (formatted.startsWith('−')) {
      return '− $symbol ${formatted.substring(1)}';
    }
    return '$symbol $formatted';
  }

  /// Formats percentage value with optional decimal places (e.g. "45.5%")
  static String formatPercentage(double value, {int decimalPlaces = 0}) {
    if (value.isNaN || value.isInfinite) return '0%';
    return '${value.toStringAsFixed(decimalPlaces)}%';
  }
}
