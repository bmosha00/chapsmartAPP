import 'package:intl/intl.dart';

class Fmt {
  static final _n = NumberFormat('#,##0', 'en_US');
  static String tzs(num a) => 'TZS ${_n.format(a)}';
  static String sats(num a) => '${_n.format(a)} sats';
  static String btc(String b) => '₿ $b';
  static String pct(double p) => '${p.toStringAsFixed(2)}%';
  static String usd(num a) => '\$${_n.format(a)}';
  static String compact(num a) {
    if (a >= 1000000) return '${(a / 1000000).toStringAsFixed(1)}M';
    if (a >= 1000) return '${(a / 1000).toStringAsFixed(0)}K';
    return _n.format(a);
  }
}
