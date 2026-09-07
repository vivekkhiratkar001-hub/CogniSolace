import 'dart:async';
import 'package:flutter/material.dart';

/// AI Assistant Screen for COGNISOLACE
///
/// Project: AI-Based Cognitive Gaming and Memory Assistance Platform
///          for Elderly Dementia Patients in North Eastern Region (NER)
///
/// Role: Member 1 – Flutter Frontend Developer
///
/// Note: Member 4 and Member 5 will provide the backend LLM/RAG APIs.
/// This file implements the elderly-friendly conversational UI with dummy responses.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // ── Voice UI state ──────────────────────────────────────────────────────
  // [_isListening] drives all voice-related UI changes (color, icon, banner).
  // Set to true when user taps the mic; auto-resets after [_listenTimeout].
  // Member 4 / speech_to_text package will replace _startListening() later.
  bool _isListening = false;
  Timer? _listeningTimer;
  static const Duration _listenTimeout = Duration(seconds: 4);


  // Color constants (Calming forest green and soothing sky blue)
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color assistantBlue = Color(0xFF0277BD);
  static const Color backgroundColor = Color(0xFFF7FAF7);
  static const Color textPrimary = Color(0xFF1A2E22);
  static const Color textSecondary = Color(0xFF37474F);

  // Chat message history initialized with the welcome message
  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': 'Hello! I am your friendly assistant.\nHow can I help you today?',
      'time': 'Just now',
    },
  ];

  @override
  void dispose() {
    _listeningTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Voice Placeholder Methods ────────────────────────────────────────────

  /// Starts the simulated listening session.
  ///
  /// Currently only changes UI state and auto-cancels after [_listenTimeout].
  /// TODO (Member 4): Replace body with speech_to_text plugin call:
  ///   await _speechToText.listen(onResult: _onSpeechResult);
  void _startListening() {
    // Cancel any previous timeout timer before starting a new session
    _listeningTimer?.cancel();

    setState(() {
      _isListening = true;
    });

    // Auto-stop after [_listenTimeout] seconds — prevents UI getting "stuck"
    _listeningTimer = Timer(_listenTimeout, _stopListening);
  }

  /// Stops the listening session and resets the UI.
  ///
  /// TODO (Member 4): Replace body with:
  ///   await _speechToText.stop();
  void _stopListening() {
    _listeningTimer?.cancel();
    if (!mounted) return;

    setState(() {
      _isListening = false;
    });

    _showNotification(
      'Voice support coming soon! Please type your message below.',
    );
  }

  /// Handles the mic button tap — toggles listening on/off.
  void _onMicTapped() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  /// Scrolls the chat list to the newest message at the bottom

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

  /// Shows an accessible, high-contrast SnackBar notification
  void _showNotification(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: assistantBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        margin: const EdgeInsets.all(20.0),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Handles sending user input and returning a dummy response
  void _handleSendMessage([String? prefilledText]) {
    final text = (prefilledText ?? _textController.text).trim();
    if (text.isEmpty) return;

    _textController.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _messages.add({
        'isUser': true,
        'text': text,
        'time': 'Just now',
      });
    });

    _scrollToBottom();

    // Simulated dummy AI response (Member 4 & 5 APIs will replace this later)
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;

      String dummyReply;
      final lower = text.toLowerCase();

      if (lower.contains('medicine') || lower.contains('pill')) {
        dummyReply = 'Yes! Your morning medicine was scheduled with warm water at 8:30 AM.';
      } else if (lower.contains('today') || lower.contains('date') || lower.contains('time')) {
        dummyReply = 'Today is a peaceful, beautiful day in the North Eastern Region. Everything is on schedule.';
      } else if (lower.contains('family') || lower.contains('who') || lower.contains('people')) {
        dummyReply = 'Your family loves you very much and is always thinking of you.';
      } else {
        dummyReply = 'I heard you clearly! I am right here with you. Take all the time you need.';
      }

      setState(() {
        _messages.add({
          'isUser': false,
          'text': dummyReply,
          'time': 'Just now',
        });
      });

      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: backgroundColor,

      // 1. Clear AppBar with Title & Large Back Button
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 2.0,
        toolbarHeight: 72.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 32.0),
          tooltip: 'Back to Home',
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AI Assistant 🤖',
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // Responsive constraint: prevents awkward stretching on wide screens
            constraints: const BoxConstraints(maxWidth: 700.0),
            child: Column(
              children: [
                // 2. Large Chat Messages Area
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 24.0 : 16.0,
                      vertical: 18.0,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message['isUser'] as bool;
                      final text = message['text'] as String;

                      return _buildChatBubble(
                        isUser: isUser,
                        text: text,
                        isTablet: isTablet,
                      );
                    },
                  ),
                ),

                // Quick Prompt Suggestions (Easy for elderly users with tremors)
                _buildQuickSuggestions(isTablet),

                // 🎤 Listening Banner — visible only while mic is active
                if (_isListening) _buildListeningBanner(isTablet),

                // 3. Message Input Area with Microphone and Send Button
                _buildMessageInputBar(isTablet),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a large, readable chat bubble with high contrast
  Widget _buildChatBubble({
    required bool isUser,
    required String text,
    required bool isTablet,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bot Avatar
          if (!isUser) ...[
            Container(
              width: isTablet ? 48.0 : 42.0,
              height: isTablet ? 48.0 : 42.0,
              decoration: const BoxDecoration(
                color: assistantBlue,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: 26.0,
                ),
              ),
            ),
            const SizedBox(width: 10.0),
          ],

          // Bubble Container
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 22.0 : 18.0,
                vertical: 16.0,
              ),
              decoration: BoxDecoration(
                color: isUser ? primaryGreen : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(22.0),
                  topRight: const Radius.circular(22.0),
                  bottomLeft: isUser ? const Radius.circular(22.0) : const Radius.circular(4.0),
                  bottomRight: isUser ? const Radius.circular(4.0) : const Radius.circular(22.0),
                ),
                border: Border.all(
                  color: isUser ? primaryGreen : Colors.grey.shade300,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6.0,
                    offset: const Offset(0, 2.0),
                  ),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: isTablet ? 20.0 : 17.5,
                  fontWeight: isUser ? FontWeight.w600 : FontWeight.w500,
                  color: isUser ? Colors.white : textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ),

          // User Avatar
          if (isUser) ...[
            const SizedBox(width: 10.0),
            Container(
              width: isTablet ? 48.0 : 42.0,
              height: isTablet ? 48.0 : 42.0,
              decoration: const BoxDecoration(
                color: primaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 26.0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Quick-tap suggestion chips for dementia convenience
  Widget _buildQuickSuggestions(bool isTablet) {
    final List<String> suggestions = [
      'What day is today? 📅',
      'Where are my medicines? 💊',
      'Tell me something calm 🌸',
    ];

    return Container(
      height: isTablet ? 54.0 : 48.0,
      margin: const EdgeInsets.only(bottom: 6.0),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 20.0 : 14.0),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8.0),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ActionChip(
            backgroundColor: Colors.white,
            side: BorderSide(color: assistantBlue.withValues(alpha: 0.4), width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
            label: Text(
              suggestion,
              style: TextStyle(
                fontSize: isTablet ? 16.0 : 14.0,
                fontWeight: FontWeight.w600,
                color: assistantBlue,
              ),
            ),
            onPressed: () => _handleSendMessage(suggestion),
          );
        },
      ),
    );
  }

  /// Bottom Message Input Bar — mic button toggles voice listening state.
  ///
  /// Visual behaviour:
  ///   Idle   : orange mic button with mic_rounded icon
  ///   Active : green mic button with mic_none_rounded icon + glowing ring
  ///   Text field is greyed out while listening (disabled)
  Widget _buildMessageInputBar(bool isTablet) {
    // Mic button colors change to signal listening state clearly
    final Color micColor = _isListening
        ? const Color(0xFF2E7D32)  // Forest green = actively listening
        : const Color(0xFFD84315); // Warm orange  = idle / ready to tap

    final IconData micIcon = _isListening
        ? Icons.mic_none_rounded   // Outline icon = recording in progress
        : Icons.mic_rounded;       // Filled icon  = idle / tap to speak

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20.0 : 12.0,
        vertical: 12.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8.0,
            offset: const Offset(0, -3.0),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Large Microphone Button ──────────────────────────────────────
          // Tapping toggles _isListening via _onMicTapped().
          // An animated glowing ring appears around the button when listening.
          // TODO (Member 4): Connect to speech_to_text plugin here.
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: isTablet ? 66.0 : 58.0,
            height: isTablet ? 66.0 : 58.0,
            decoration: BoxDecoration(
              color: micColor,
              borderRadius: BorderRadius.circular(18.0),
              // Glowing border ring — visible only while listening
              border: _isListening
                  ? Border.all(
                      color: const Color(0xFF66BB6A),
                      width: 3.0,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: micColor.withValues(
                    alpha: _isListening ? 0.45 : 0.25,
                  ),
                  blurRadius: _isListening ? 14.0 : 6.0,
                  spreadRadius: _isListening ? 2.0 : 0.0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(18.0),
                onTap: _onMicTapped,
                child: Center(
                  child: Icon(
                    micIcon,
                    color: Colors.white,
                    size: isTablet ? 34.0 : 30.0,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10.0),

          // ── Large Text Input Field ───────────────────────────────────────
          // Disabled (greyed out) while mic is listening so the user knows
          // they should speak — not type — right now.
          Expanded(
            child: TextField(
              controller: _textController,
              enabled: !_isListening,
              style: TextStyle(
                fontSize: isTablet ? 19.0 : 17.0,
                color: _isListening
                    ? textSecondary.withValues(alpha: 0.45)
                    : textPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: _isListening
                    ? 'Listening... speak now 🎤'
                    : 'Type your message here...',
                hintStyle: TextStyle(
                  fontSize: isTablet ? 17.0 : 15.0,
                  color: _isListening
                      ? const Color(0xFF2E7D32).withValues(alpha: 0.7)
                      : textSecondary.withValues(alpha: 0.65),
                  fontWeight:
                      _isListening ? FontWeight.w600 : FontWeight.w400,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18.0,
                  vertical: 16.0,
                ),
                filled: true,
                // Soft green tint while listening, neutral otherwise
                fillColor: _isListening
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFF1F5F2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18.0),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18.0),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18.0),
                  borderSide: const BorderSide(
                    color: Color(0xFF81C784), // Green border while listening
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18.0),
                  borderSide:
                      const BorderSide(color: primaryGreen, width: 2.0),
                ),
              ),
              onSubmitted: (_) => _handleSendMessage(),
            ),
          ),

          const SizedBox(width: 10.0),

          // ── Large Send Button ────────────────────────────────────────────
          // Dimmed while mic is active to guide the user's attention to mic.
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _isListening ? 0.4 : 1.0,
            child: Material(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(18.0),
              elevation: _isListening ? 0.0 : 2.0,
              child: InkWell(
                borderRadius: BorderRadius.circular(18.0),
                onTap: _isListening ? null : () => _handleSendMessage(),
                child: Container(
                  width: isTablet ? 62.0 : 54.0,
                  height: isTablet ? 62.0 : 54.0,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 28.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Listening Banner ─────────────────────────────────────────────────────

  /// A high-contrast banner shown above the input bar while the mic is active.
  ///
  /// Gives elderly users clear, reassuring confirmation that the app is
  /// listening — avoids confusion when the text field is greyed out.
  Widget _buildListeningBanner(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20.0 : 16.0,
        vertical: 10.0,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFE8F5E9), // Soft calming green background
        border: Border(
          top: BorderSide(color: Color(0xFF81C784), width: 1.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Green dot indicator
          Container(
            width: 12.0,
            height: 12.0,
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10.0),
          Text(
            '🎤  Listening... Speak clearly',
            style: TextStyle(
              fontSize: isTablet ? 17.0 : 15.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1B5E20),
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          // Tap to cancel the voice session
          GestureDetector(
            onTap: _stopListening,
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFD84315), // Warm orange = stop / cancel
              ),
            ),
          ),
        ],
      ),
    );
  }
}
