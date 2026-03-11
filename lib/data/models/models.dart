// ─── Account ─────────────────────────────────────────────

class Account {
  final String accountNumber;
  final String? firebaseToken;
  final String? nostrPubkey;
  final String? authMethod;

  const Account({
    required this.accountNumber,
    this.firebaseToken,
    this.nostrPubkey,
    this.authMethod,
  });

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    accountNumber: json['accountNumber'] ?? '',
    firebaseToken: json['customToken'],
    nostrPubkey: json['nostrPubkey'],
    authMethod: json['authMethod'],
  );
}

// ─── User Stats ──────────────────────────────────────────

class UserStats {
  final String userTier;
  final double feePercent;
  final double cumulativeAmount;
  final int totalTransactions;
  final String? nextTier;
  final double progressPercent;

  const UserStats({
    required this.userTier,
    required this.feePercent,
    required this.cumulativeAmount,
    required this.totalTransactions,
    this.nextTier,
    this.progressPercent = 0,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
    userTier: json['userTier'] ?? 'BRONZE',
    feePercent: (json['feePercent'] ?? 2.2).toDouble(),
    cumulativeAmount: (json['cumulativeAmount'] ?? 0).toDouble(),
    totalTransactions: json['totalTransactions'] ?? 0,
    nextTier: json['nextTier'],
    progressPercent: (json['progressPercent'] ?? 0).toDouble(),
  );
}

// ─── Quote ───────────────────────────────────────────────

class Quote {
  final String quoteId;
  final int sats;
  final String btc;
  final int feeSats;
  final double feePercent;
  final int amountTZS;
  final String userTier;
  final DateTime createdAt;

  const Quote({
    required this.quoteId,
    required this.sats,
    required this.btc,
    required this.feeSats,
    required this.feePercent,
    required this.amountTZS,
    required this.userTier,
    required this.createdAt,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    final youPay = json['youPay'] ?? {};
    final rec = json['recipientReceives'] ?? {};
    return Quote(
      quoteId: json['quoteId'] ?? '',
      sats: (youPay['sats'] ?? 0) as int,
      btc: youPay['btc']?.toString() ?? '0',
      feeSats: (youPay['feeSats'] ?? 0) as int,
      feePercent: (youPay['feePercent'] ?? 0).toDouble(),
      amountTZS: (rec['tzs'] ?? 0) as int,
      userTier: json['userTier'] ?? 'BRONZE',
      createdAt: DateTime.now(),
    );
  }
}

// ─── Invoice ─────────────────────────────────────────────

class Invoice {
  final String invoiceId;
  final String checkoutLink;
  final String bolt11;
  final int sats;
  final String btc;
  final int amountTZS;

  const Invoice({
    required this.invoiceId,
    required this.checkoutLink,
    required this.bolt11,
    required this.sats,
    required this.btc,
    required this.amountTZS,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final youPay = json['youPay'] ?? {};
    return Invoice(
      invoiceId: json['invoiceId'] ?? '',
      checkoutLink: json['checkoutLink'] ?? '',
      bolt11: json['bolt11'] ?? '',
      sats: (youPay['sats'] ?? 0) as int,
      btc: youPay['btc']?.toString() ?? '0',
      amountTZS: (json['recipientReceives']?['tzs'] ?? 0) as int,
    );
  }
}

// ─── Buy Quote ───────────────────────────────────────────

class BuyQuote {
  final String quoteId;
  final int amountTZS;
  final int calculatedSats;
  final double btcPrice;
  final String? priceSource;

  const BuyQuote({
    required this.quoteId,
    required this.amountTZS,
    required this.calculatedSats,
    required this.btcPrice,
    this.priceSource,
  });

  factory BuyQuote.fromJson(Map<String, dynamic> json) => BuyQuote(
    quoteId: json['quoteId'] ?? '',
    amountTZS: (json['amountTZS'] ?? 0) as int,
    calculatedSats: (json['calculatedSats'] ?? 0) as int,
    btcPrice: (json['btcPrice'] ?? 0).toDouble(),
    priceSource: json['priceSource'],
  );
}

// ─── M-Pesa Lookup ───────────────────────────────────────

class MpesaLookup {
  final bool found;
  final int? amount;
  final String? phoneNumber;
  final String? mpesaId;
  final String? senderName;
  final String? messageDateTime;

  const MpesaLookup({
    required this.found,
    this.amount,
    this.phoneNumber,
    this.mpesaId,
    this.senderName,
    this.messageDateTime,
  });

  factory MpesaLookup.fromJson(Map<String, dynamic> json) => MpesaLookup(
    found: json['found'] ?? false,
    amount: json['amount'],
    phoneNumber: json['phoneNumber'],
    mpesaId: json['mpesaId'],
    senderName: json['senderName'],
    messageDateTime: json['messageDateTime'],
  );
}

// ─── Transaction ─────────────────────────────────────────

class Transaction {
  final String id;
  final int amountTZS;
  final int sats;
  final String phoneNumber;
  final String recipientName;
  final String status;
  final String type; // 'remittance', 'airtime', 'buy-sats'
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.amountTZS,
    required this.sats,
    required this.phoneNumber,
    required this.recipientName,
    required this.status,
    required this.type,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'] ?? json['invoiceId'] ?? json['mpesaId'] ?? '',
    amountTZS: (json['amountTZS'] ?? json['amount'] ?? 0) as int,
    sats: (json['sats'] ?? json['totalSats'] ?? json['satsSent'] ?? 0) as int,
    phoneNumber: json['phoneNumber'] ?? '',
    recipientName: json['recipientName'] ?? '',
    status: json['status'] ?? json['payoutStatus'] ?? 'pending',
    type: json['type'] ?? 'remittance',
    createdAt:
    DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
  );

  bool get isSettled => status == 'settled' || status == 'SUCCESS';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';

  String get typeLabel {
    switch (type) {
      case 'airtime':
        return 'Airtime';
      case 'buy-sats':
        return 'Buy Sats';
      default:
        return 'Remittance';
    }
  }
}