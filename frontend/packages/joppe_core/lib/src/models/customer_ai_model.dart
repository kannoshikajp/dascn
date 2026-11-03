class CustomerAiReferencedProduct {
  final String id;
  final String sku;
  final String name;
  final int minPrice;
  final int maxPrice;
  final int totalStock;

  const CustomerAiReferencedProduct({
    required this.id,
    required this.sku,
    required this.name,
    required this.minPrice,
    required this.maxPrice,
    required this.totalStock,
  });

  factory CustomerAiReferencedProduct.fromJson(Map<String, dynamic> json) {
    return CustomerAiReferencedProduct(
      id: json['id']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      minPrice: (json['minPrice'] as num?)?.toInt() ?? 0,
      maxPrice: (json['maxPrice'] as num?)?.toInt() ?? 0,
      totalStock: (json['totalStock'] as num?)?.toInt() ?? 0,
    );
  }
}

class CustomerAiChatResponse {
  final String answer;
  final List<CustomerAiReferencedProduct> referencedProducts;
  final List<String> quickReplies;
  final List<String> executedTools;

  const CustomerAiChatResponse({
    required this.answer,
    this.referencedProducts = const [],
    this.quickReplies = const [],
    this.executedTools = const [],
  });

  factory CustomerAiChatResponse.fromJson(Map<String, dynamic> json) {
    return CustomerAiChatResponse(
      answer: json['answer']?.toString() ?? '',
      referencedProducts: (json['referencedProducts'] as List<dynamic>?)
              ?.map((item) => CustomerAiReferencedProduct.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      quickReplies: (json['quickReplies'] as List<dynamic>?)
              ?.map((t) => t.toString())
              .toList() ??
          const [],
      executedTools: (json['executedTools'] as List<dynamic>?)
              ?.map((t) => t.toString())
              .toList() ??
          const [],
    );
  }
}

class CustomerAiChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final List<CustomerAiReferencedProduct> referencedProducts;
  final List<String> quickReplies;
  final List<String> executedTools;

  CustomerAiChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.referencedProducts = const [],
    this.quickReplies = const [],
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
