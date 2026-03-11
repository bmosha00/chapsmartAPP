import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _tzs = NumberFormat('#,##0', 'en_US');
  static final _sats = NumberFormat('#,##0', 'en_US');

  static String tzs(num amount) => 'TZS ${_tzs.format(amount)}';
  static String sats(num amount) => '${_sats.format(amount)} sats';
  static String btc(String btc) => '₿ $btc';
  static String percent(double pct) => '${pct.toStringAsFixed(2)}%';
}
