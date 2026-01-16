class History {
  final int id;
  final String description;
  final double amount;
  final DateTime createdAt;

  History({
    required this.id,
    required this.description,
    required this.amount,
    required this.createdAt,
  });

  factory History.fromJson(Map<String, dynamic> json) {
    return History(
      id: json['id'],
      description: json['description'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
