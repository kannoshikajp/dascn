class AdminAiReferencedProduct {
  final String id;
  final String sku;
  final String name;
  final int minPrice;
  final int maxPrice;
  final int totalStock;

  const AdminAiReferencedProduct({
    required this.id,
    required this.sku,
    required this.name,
    required this.minPrice,
    required this.maxPrice,
    required this.totalStock,
  });

  factory AdminAiReferencedProduct.fromJson(Map<String, dynamic> json) {
    return AdminAiReferencedProduct(
      id: json['id']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      minPrice: (json['minPrice'] as num?)?.toInt() ?? 0,
      maxPrice: (json['maxPrice'] as num?)?.toInt() ?? 0,
      totalStock: (json['totalStock'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminAiChatResponse {
  final String answer;
  final List<AdminAiReferencedProduct> referencedProducts;
  final List<String> executedTools;

  const AdminAiChatResponse({
    required this.answer,
    this.referencedProducts = const [],
    this.executedTools = const [],
  });

  factory AdminAiChatResponse.fromJson(Map<String, dynamic> json) {
    return AdminAiChatResponse(
      answer: json['answer']?.toString() ?? '',
      referencedProducts: (json['referencedProducts'] as List<dynamic>?)
              ?.map((item) => AdminAiReferencedProduct.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      executedTools: (json['executedTools'] as List<dynamic>?)
              ?.map((t) => t.toString())
              .toList() ??
          const [],
    );
  }
}

class AdminAiChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final List<AdminAiReferencedProduct> referencedProducts;
  final List<String> executedTools;

  AdminAiChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.referencedProducts = const [],
    this.executedTools = const [],
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }
}
