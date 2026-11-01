import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../localization/dashboard_localizations.dart';

class AiAssistantView extends StatefulWidget {
  final AdminAiService aiService;
  final ValueChanged<int>? onNavigateToDestination;

  const AiAssistantView({
    super.key,
    required this.aiService,
    this.onNavigateToDestination,
  });

  @override
  State<AiAssistantView> createState() => _AiAssistantViewState();
}

class _AiAssistantViewState extends State<AiAssistantView> {
  final List<AdminAiChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_messages.isEmpty && mounted) {
        final l10n = context.l10n;
        setState(() {
          _messages.add(AdminAiChatMessage(
            role: 'assistant',
            content: l10n.aiWelcomePrompt,
          ));
        });
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

    final userMessage = AdminAiChatMessage(role: 'user', content: text);
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await widget.aiService.sendMessage(
        text,
        history: _messages.where((m) => m != userMessage).toList(),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _messages.add(AdminAiChatMessage(
            role: 'assistant',
            content: response.answer,
            referencedProducts: response.referencedProducts,
            executedTools: response.executedTools,
          ));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _messages.add(AdminAiChatMessage(
            role: 'assistant',
            content: 'Đã xảy ra lỗi khi trao đổi với AI gateway: $e',
          ));
        });
        _scrollToBottom();
      }
    }
  }

  String _formatVnd(num price) {
    if (price <= 0) return '0 ₫';
    final str = price.toStringAsFixed(0);
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return '${str.replaceAllMapped(reg, (m) => '${m[1]}.')} ₫';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // 1. Top Header Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: JoppeSpacing.lg, vertical: JoppeSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withAlpha(80))),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.auto_awesome, color: colorScheme.primary, size: 24),
              ),
              const SizedBox(width: JoppeSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.aiAssistantTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.aiAssistantSubtitle,
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton.outlined(
                tooltip: 'Xóa phiên chat',
                icon: const Icon(Icons.refresh_rounded, size: 20),
                onPressed: () {
                  setState(() {
                    _messages.clear();
                    _messages.add(AdminAiChatMessage(
                      role: 'assistant',
                      content: l10n.aiWelcomePrompt,
                    ));
                  });
                },
              ),
            ],
          ),
        ),

        // 2. Quick Action Prompt Pills
        Container(
          padding: const EdgeInsets.symmetric(horizontal: JoppeSpacing.lg, vertical: 8),
          color: colorScheme.surfaceContainerHighest.withAlpha(40),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.inventory_2_outlined, size: 16),
                  label: Text(l10n.aiQuickPrompt1, style: const TextStyle(fontSize: 12)),
                  onPressed: () => _sendMessage(l10n.aiQuickPrompt1),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.analytics_outlined, size: 16),
                  label: Text(l10n.aiQuickPrompt2, style: const TextStyle(fontSize: 12)),
                  onPressed: () => _sendMessage(l10n.aiQuickPrompt2),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.memory_rounded, size: 16),
                  label: Text(l10n.aiQuickPrompt3, style: const TextStyle(fontSize: 12)),
                  onPressed: () => _sendMessage(l10n.aiQuickPrompt3),
                ),
              ],
            ),
          ),
        ),

        // 3. Chat Messages Timeline
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: JoppeSpacing.lg, vertical: JoppeSpacing.md),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return _buildMessageBubble(context, msg);
            },
          ),
        ),

        // 4. Loading indicator
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: JoppeSpacing.lg, vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
                ),
                const SizedBox(width: 8),
                Text(
                  '9Router đang gọi công cụ & xử lý câu hỏi...',
                  style: TextStyle(fontSize: 12, color: colorScheme.primary, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),

        // 5. Bottom Input Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: JoppeSpacing.lg, vertical: JoppeSpacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(top: BorderSide(color: colorScheme.outlineVariant.withAlpha(80))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: l10n.aiInputHint,
                    hintStyle: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant.withAlpha(160)),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withAlpha(60),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: colorScheme.outlineVariant.withAlpha(100)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: colorScheme.outlineVariant.withAlpha(100)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: JoppeSpacing.sm),
              FilledButton(
                style: FilledButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(14),
                ),
                onPressed: _isLoading ? null : () => _sendMessage(),
                child: const Icon(Icons.arrow_upward_rounded, size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(BuildContext context, AdminAiChatMessage msg) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: JoppeSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: const Icon(Icons.auto_awesome, size: 16),
            ),
            const SizedBox(width: JoppeSpacing.sm),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Text bubble
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest.withAlpha(120),
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: isUser ? const Radius.circular(2) : null,
                      bottomLeft: !isUser ? const Radius.circular(2) : null,
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: colorScheme.outlineVariant.withAlpha(60)),
                  ),
                  child: SelectableText(
                    msg.content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
                    ),
                  ),
                ),

                // Tool badges
                if (msg.executedTools.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: msg.executedTools.map((tool) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.tertiaryContainer.withAlpha(120),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.tertiary.withAlpha(60)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.build_circle_outlined, size: 12, color: colorScheme.onTertiaryContainer),
                            const SizedBox(width: 4),
                            Text(
                              tool,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Referenced Products Cards
                if (msg.referencedProducts.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.aiReferencedProducts,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: msg.referencedProducts.map((p) {
                      return _buildProductCard(context, p);
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: JoppeSpacing.sm),
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
              child: const Icon(Icons.person, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, AdminAiReferencedProduct product) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLowStock = product.totalStock <= 10;

    return Container(
      width: 260,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  product.sku.isNotEmpty ? product.sku : 'SKU',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isLowStock ? colorScheme.errorContainer : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Tồn: ${product.totalStock}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isLowStock ? colorScheme.onErrorContainer : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          if (product.minPrice > 0) ...[
            const SizedBox(height: 4),
            Text(
              product.minPrice == product.maxPrice || product.maxPrice <= 0
                  ? _formatVnd(product.minPrice)
                  : '${_formatVnd(product.minPrice)} - ${_formatVnd(product.maxPrice)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
