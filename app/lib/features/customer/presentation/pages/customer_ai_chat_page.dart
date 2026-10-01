import 'package:flutter/material.dart';

class CustomerAiChatPage extends StatefulWidget {
  const CustomerAiChatPage({
    super.key,
    required this.onBackToHome,
  });

  final VoidCallback onBackToHome;

  @override
  State<CustomerAiChatPage> createState() =>
      _CustomerAiChatPageState();
}

class _CustomerAiChatPageState
    extends State<CustomerAiChatPage> {
  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  final List<_ChatMessage> _messages = [];

  final List<String> _suggestions = [
    'Makan siang di bawah Rp20.000',
    'Yang tidak pedas dan cepat siap',
    'Ada pilihan menu berkuah?',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // =============================================================
  // KIRIM PESAN
  // =============================================================

  Future<void> _sendMessage(String text) async {
    final message = text.trim();

    if (message.isEmpty) {
      return;
    }

    _messageController.clear();

    // Pesan dari user
    setState(() {
      _messages.add(
        _ChatMessage(
          text: message,
          isUser: true,
        ),
      );
    });

    _scrollToBottom();

    // Simulasi proses AI
    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) {
      return;
    }

    // Jawaban AI sementara
    setState(() {
      _messages.add(
        const _ChatMessage(
          text:
              'Maaf, fitur ini akan tersedia di versi selanjutnya',
          isUser: false,
        ),
      );
    });

    _scrollToBottom();
  }

  // =============================================================
  // SCROLL KE PESAN TERBARU
  // =============================================================

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!_scrollController.hasClients) {
          return;
        }

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(
            milliseconds: 250,
          ),
          curve: Curves.easeOut,
        );
      },
    );
  }

  // =============================================================
  // CHAT BARU
  // =============================================================

  void _startNewChat() {
    FocusManager.instance.primaryFocus?.unfocus();

    _messageController.clear();

    setState(() {
      _messages.clear();
    });
  }

  // =============================================================
  // KEMBALI KE HOME
  // =============================================================

  void _backToHome() {
    FocusManager.instance.primaryFocus?.unfocus();

    widget.onBackToHome();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      // Supaya tombol Back Android tidak menutup aplikasi
      // ketika sedang berada di Chat.
      canPop: false,

      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        _backToHome();
      },

      child: SafeArea(
        child: Column(
          children: [
            // =====================================================
            // HEADER
            // =====================================================

            Container(
              padding: const EdgeInsets.fromLTRB(
                8,
                12,
                8,
                12,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color:
                        theme.colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // TOMBOL KEMBALI
                  IconButton(
                    onPressed: _backToHome,
                    icon: const Icon(
                      Icons.arrow_back,
                    ),
                  ),

                  const SizedBox(width: 2),

                  // ICON CHAT
                  Icon(
                    Icons.chat_bubble_outline,
                    color: theme.colorScheme.primary,
                    size: 26,
                  ),

                  const SizedBox(width: 12),

                  // JUDUL
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chat kantin',
                          style:
                              theme.textTheme.titleLarge,
                        ),

                        const SizedBox(height: 2),

                        Text(
                          'Asisten AI untuk memilih menu',
                          style: theme
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                            color: theme
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // CHAT BARU
                  IconButton(
                    onPressed: _startNewChat,
                    tooltip: 'Chat baru',
                    icon: const Icon(
                      Icons.edit_outlined,
                    ),
                  ),
                ],
              ),
            ),

            // =====================================================
            // AREA CHAT
            // =====================================================

            Expanded(
              child: _messages.isEmpty
                  ? _WelcomeContent(
                      suggestions: _suggestions,
                      onSuggestionTap:
                          _sendMessage,
                    )
                  : ListView.builder(
                      controller:
                          _scrollController,
                      padding:
                          const EdgeInsets.fromLTRB(
                        16,
                        20,
                        16,
                        20,
                      ),
                      itemCount:
                          _messages.length,
                      itemBuilder:
                          (context, index) {
                        final message =
                            _messages[index];

                        return _MessageBubble(
                          message: message,
                        );
                      },
                    ),
            ),

            // =====================================================
            // INPUT PESAN
            // =====================================================

            Container(
              padding: const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                8,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color:
                        theme.colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller:
                              _messageController,
                          minLines: 1,
                          maxLines: 4,

                          textInputAction:
                              TextInputAction.send,

                          onSubmitted:
                              _sendMessage,

                          decoration:
                              const InputDecoration(
                            hintText:
                                'Tulis pesan...',
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // TOMBOL KIRIM
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme
                              .colorScheme
                              .primaryContainer,
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                        child: IconButton(
                          onPressed: () {
                            _sendMessage(
                              _messageController
                                  .text,
                            );
                          },
                          icon: Icon(
                            Icons.send_outlined,
                            color: theme
                                .colorScheme
                                .primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Rekomendasi AI · cek detail menu sebelum memesan',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(
                      color: theme
                          .colorScheme
                          .onSurfaceVariant,
                      fontSize: 10,
                    ),
                    textAlign:
                        TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// TAMPILAN SAMBUTAN
// =================================================================

class _WelcomeContent extends StatelessWidget {
  const _WelcomeContent({
    required this.suggestions,
    required this.onSuggestionTap,
  });

  final List<String> suggestions;

  final ValueChanged<String>
      onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        16,
        70,
        16,
        24,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Lagi ingin makan apa?',
            style:
                theme.textTheme.headlineMedium,
          ),

          const SizedBox(height: 16),

          Text(
            'Ceritakan selera, bujet, atau waktu yang kamu punya.',
            style:
                theme.textTheme.bodyLarge?.copyWith(
              color: theme
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 28),

          ...suggestions.map(
            (suggestion) {
              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 10,
                ),
                child: _SuggestionButton(
                  text: suggestion,
                  onTap: () {
                    onSuggestionTap(
                      suggestion,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// =================================================================
// TOMBOL SARAN
// =================================================================

class _SuggestionButton extends StatelessWidget {
  const _SuggestionButton({
    required this.text,
    required this.onTap,
  });

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                theme.colorScheme.outlineVariant,
          ),
          borderRadius:
              BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style:
                    theme.textTheme.bodyLarge,
              ),
            ),

            const SizedBox(width: 8),

            Icon(
              Icons.chevron_right,
              color: theme
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// MODEL PESAN
// =================================================================

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
  });

  final String text;
  final bool isUser;
}

// =================================================================
// BUBBLE PESAN
// =================================================================

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
  });

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // =============================================================
    // PESAN USER
    // =============================================================

    if (message.isUser) {
      return Padding(
        padding:
            const EdgeInsets.only(
          bottom: 16,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.end,
          children: [
            Container(
              constraints:
                  const BoxConstraints(
                maxWidth: 290,
              ),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration:
                  BoxDecoration(
                color: theme
                    .colorScheme
                    .primaryContainer,
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: Text(
                message.text,
                style:
                    theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    // =============================================================
    // PESAN AI
    // =============================================================

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 20,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Asisten Kantin',
            style:
                theme.textTheme.bodySmall?.copyWith(
              color: theme
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 6),

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration:
                    BoxDecoration(
                  color: theme
                      .colorScheme
                      .primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 17,
                  color: theme
                      .colorScheme
                      .primary,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration:
                      BoxDecoration(
                    color: theme
                        .colorScheme
                        .surfaceContainer,
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: theme
                        .textTheme
                        .bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}