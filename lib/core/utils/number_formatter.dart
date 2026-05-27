class NumberFormatter {
  static String formatNumber(int? number) {
    if (number == null) return '0';
    if (number >= 1000000) {
      final double val = number / 1000000;
      return '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)}M';
    } else if (number >= 1000) {
      final double val = number / 1000;
      return '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)}K';
    }
    return number.toString();
  }
}
