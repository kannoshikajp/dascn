import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart' as core;
import '../core/theme/app_colors.dart';
import '../models/product.dart';
import '../services/app_api_client.dart';
import '../services/catalog_service.dart';
import 'product_details_screen.dart';

/// Màn hình Trợ lý AI tư vấn phần cứng & Build PC thông minh
/// Gửi prompt lên máy chủ Joppe AI Backend và render giao diện tương tác
class AiAdvisorScreen extends StatefulWidget {
  final String? initialPrompt;

  const AiAdvisorScreen({super.key, this.initialPrompt});

  @override
  State<AiAdvisorScreen> createState() => _AiAdvisorScreenState();
}

class _AiAdvisorScreenState extends State<AiAdvisorScreen> {
  final List<core.CustomerAiChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;

  final List<String> _initialQuickPrompts = [
    'Build PC Gaming 15 triệu',
    'Cấu hình đồ họa 3D / Render',
    'Check nghẽn cổ chai i5 + RTX 4060',
    'Tư vấn nâng cấp RAM & SSD',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(
      core.CustomerAiChatMessage(
        role: 'assistant',
        content:
            'Xin chào! Tôi là Trợ lý AI chuyên gia phần cứng của Joppe.\n\n'
            'Tôi có thể giúp bạn:\n'
            '• Tư vấn cấu hình PC theo ngân sách & nhu cầu\n'
            '• Đánh giá tương thích phần cứng & độ nghẽn (Bottleneck)\n'
            '• Tìm kiếm linh kiện chính hãng đang có sẵn tại Joppe\n\n'
            'Bạn cần hỗ trợ cấu hình nào hôm nay?',
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialPrompt != null && widget.initialPrompt!.trim().isNotEmpty) {
        _sendMessage(widget.initialPrompt!.trim());
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? quickText]) async {
    final text = (quickText ?? _textController.text).trim();
    if (text.isEmpty || _isLoading) return;

    if (quickText == null) {
      _textController.clear();
    }

    final userMessage = core.CustomerAiChatMessage(role: 'user', content: text);
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final aiService = core.CustomerAiService(AppApiClient.instance);
      final history = _messages.where((m) => m != userMessage).toList();

      final response = await aiService.sendMessage(
        text,
        history: history,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _messages.add(
            core.CustomerAiChatMessage(
              role: 'assistant',
              content: response.answer,
              referencedProducts: response.referencedProducts,
              quickReplies: response.quickReplies,
              executedTools: response.executedTools,
            ),
          );
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _messages.add(
            core.CustomerAiChatMessage(
              role: 'assistant',
              content: 'Dạ hiện tại hệ thống AI đang bận hoặc có lỗi kết nối. Bạn vui lòng thử lại sau giây lát nhé! ($e)',
            ),
          );
        });
        _scrollToBottom();
      }
    }
  }

  String _formatVnd(num price) {
    if (price <= 0) return 'Liên hệ';
    final str = price.toStringAsFixed(0);
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return '${str.replaceAllMapped(reg, (m) => '${m[1]}.')} ₫';
  }

  Product _resolveProduct(core.CustomerAiReferencedProduct ref) {
    final cached = CatalogService().allProducts.where((p) => p.id == ref.id || (ref.sku.isNotEmpty && p.specs.any((s) => s.contains(ref.sku)))).firstOrNull;
    if (cached != null) return cached;

    return Product(
      id: ref.id.isNotEmpty ? ref.id : 'ref-${ref.sku}',
      name: ref.name,
      description: 'Linh kiện chính hãng: ${ref.name} (Mã SKU: ${ref.sku})',
      price: ref.minPrice > 0 ? ref.minPrice.toDouble() : ref.maxPrice.toDouble(),
      imageUrl: 'https://images.unsplash.com/photo-1587202372775-e229f172b9d7?auto=format&fit=crop&w=600&q=80',
      category: 'Linh kiện PC',
      brand: 'Joppe Hardware',
      warrantyMonths: 36,
      specs: ['SKU: ${ref.sku}', 'Tồn kho: ${ref.totalStock} cái'],
      inStock: ref.totalStock > 0,
      technicalSpecs: {
        'Mã SKU': ref.sku,
        'Tồn kho': '${ref.totalStock} cái',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.borderLight, width: 1.5)),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.primaryBlue, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trợ Lý AI Joppe',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Tư vấn phần cứng & Tương thích PC',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            tooltip: 'Làm mới cuộc trò chuyện',
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(
                  core.CustomerAiChatMessage(
                    role: 'assistant',
                    content: 'Cuộc trò chuyện đã được làm mới. Hãy cho tôi biết yêu cầu PC hoặc linh kiện bạn cần tìm!',
                  ),
                );
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Dải gợi ý nhanh ban đầu
            if (_messages.length <= 1)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                color: AppColors.surfaceCard,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _initialQuickPrompts.map((prompt) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          backgroundColor: AppColors.surfaceCardLighter,
                          side: const BorderSide(color: AppColors.borderLight),
                          avatar: const Icon(Icons.lightbulb_outline, size: 14, color: AppColors.primaryBlue),
                          label: Text(
                            prompt,
                            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                          ),
                          onPressed: () => _sendMessage(prompt),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            // Danh sách tin nhắn
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageItem(msg);
                },
              ),
            ),

            // Chỉ báo đang xử lý
            if (_isLoading)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Joppe AI đang phân tích dữ liệu kho...',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textMuted.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),

            // Thanh gợi ý tiếp theo từ AI (Quick Replies)
            if (_messages.isNotEmpty && _messages.last.quickReplies.isNotEmpty && !_isLoading)
              Container(
                height: 42,
                margin: const EdgeInsets.only(bottom: 6),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _messages.last.quickReplies.length,
                  itemBuilder: (context, i) {
                    final qr = _messages.last.quickReplies[i];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        backgroundColor: AppColors.surfaceCard,
                        side: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.5)),
                        label: Text(
                          qr,
                          style: const TextStyle(fontSize: 11.5, color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () => _sendMessage(qr),
                      ),
                    );
                  },
                ),
              ),

            // Ô nhập câu hỏi dưới đáy
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(core.CustomerAiChatMessage msg) {
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, size: 16, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Khung tin nhắn
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primaryBlue : AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: isUser ? const Radius.circular(2) : null,
                      bottomLeft: !isUser ? const Radius.circular(2) : null,
                    ),
                    border: isUser ? null : Border.all(color: AppColors.borderLight, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SelectableText(
                    msg.content,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: isUser ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),

                // Danh sách sản phẩm được AI gợi ý kèm trong câu trả lời
                if (msg.referencedProducts.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 14, color: AppColors.primaryBlue),
                        const SizedBox(width: 4),
                        Text(
                          'Linh kiện được AI gợi ý (${msg.referencedProducts.length}):',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: msg.referencedProducts.map((p) => _buildProductRefCard(p)).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 16, color: AppColors.textPrimary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductRefCard(core.CustomerAiReferencedProduct product) {
    final priceStr = product.minPrice > 0 ? _formatVnd(product.minPrice) : _formatVnd(product.maxPrice);

    return InkWell(
      onTap: () {
        final productModel = _resolveProduct(product);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: productModel)),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 10, top: 2, bottom: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.sku.isNotEmpty ? product.sku : 'JOPPE',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  product.totalStock > 0 ? Icons.check_circle : Icons.inventory_2_outlined,
                  size: 13,
                  color: product.totalStock > 0 ? AppColors.wattageSafe : AppColors.textSubtle,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              product.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              priceStr,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  product.totalStock > 0 ? 'Còn ${product.totalStock} cái' : 'Hết hàng',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: product.totalStock > 0 ? AppColors.wattageSafe : AppColors.accentRed,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Xem chi tiết ›',
                  style: TextStyle(fontSize: 10, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.searchFieldBg,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: 3,
                minLines: 1,
                style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Hỏi về cấu hình PC, tương thích, mức giá...',
                  hintStyle: TextStyle(fontSize: 13, color: AppColors.textSubtle),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.primaryBlue,
            shape: const CircleBorder(),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: _isLoading ? null : () => _sendMessage(),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
