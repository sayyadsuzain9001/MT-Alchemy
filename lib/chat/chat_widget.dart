import 'package:flutter/material.dart';

import '../theme.dart';
import 'chat_service.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

/// Wraps the app with a floating "Ask Alchemy" assistant available on every
/// screen.
class ChatOverlay extends StatefulWidget {
  const ChatOverlay({super.key, required this.child, this.assistant});
  final Widget child;
  final ChatAssistant? assistant;

  /// Widget tests turn the launcher off so it cannot cover tap targets.
  static bool enabled = !bool.fromEnvironment('DISABLE_CHAT');

  @override
  State<ChatOverlay> createState() => _ChatOverlayState();
}

class _ChatOverlayState extends State<ChatOverlay> {
  bool _open = false;
  late final ChatAssistant _assistant = widget.assistant ?? ChatAssistant();
  final List<ChatMessage> _messages = [];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  bool _thinking = false;

  /// The launcher appears after the first frame so the page's focus scopes
  /// are laid out before the browser reports initial focus.
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    if (!ChatOverlay.enabled) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _ready = true);
      });
    });
  }

  static const _starters = [
    'Which course should I start with?',
    'How do I get a certificate?',
    'What does MT Alchemy offer companies?',
    'Show me the store products',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _focus.requestFocus(),
      );
    }
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _thinking) return;
    if (text.length > 1000) {
      setState(
        () => _messages.add(
          ChatMessage(
            fromUser: false,
            text:
                'That message is a bit long. Please keep it under 1,000 characters.',
            error: true,
          ),
        ),
      );
      return;
    }
    _input.clear();
    setState(() {
      _messages.add(ChatMessage(fromUser: true, text: text));
      _thinking = true;
    });
    _scrollToEnd();
    final reply = await _assistant.reply(List.of(_messages));
    if (!mounted) return;
    setState(() {
      _messages.add(reply);
      _thinking = false;
    });
    _scrollToEnd();
    _focus.requestFocus();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openRoute(String route, bool compact) {
    appNavigatorKey.currentState?.pushNamed(route);
    if (compact) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 600;
    return Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (context) => Stack(
            children: [
              widget.child,
              if (ChatOverlay.enabled && _ready)
                Positioned(
                  right: compact ? 12 : 24,
                  bottom: compact ? 12 : 24,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.92, end: 1.0).animate(animation),
                        alignment: Alignment.bottomRight,
                        child: child,
                      ),
                    ),
                    child: _open
                        ? _panel(context, size, compact)
                        : _launcher(compact),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _launcher(bool compact) => Semantics(
    key: const ValueKey('launcher'),
    container: true,
    button: true,
    excludeSemantics: true,
    label: 'Ask Alchemy assistant',
    onTap: _toggle,
    child: Material(
      color: deepBlue,
      elevation: 6,
      shadowColor: deepBlue.withValues(alpha: 0.4),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: _toggle,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 20,
            vertical: 14,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: softYellow, size: 22),
              if (!compact) ...[
                const SizedBox(width: 10),
                const Text(
                  'Ask Alchemy',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  Widget _panel(BuildContext context, Size size, bool compact) {
    final width = compact ? size.width - 24 : 400.0;
    final height = compact
        ? size.height - 24
        : (size.height - 48).clamp(320.0, 600.0);
    return Material(
      key: const ValueKey('panel'),
      elevation: 12,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          children: [
            _header(),
            Expanded(
              child: SelectionArea(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  children: [
                    _bubble(
                      ChatMessage(
                        fromUser: false,
                        text:
                            'Hi! I\'m the Alchemy Assistant. Ask me about our courses, programmes, store or how to use your account.',
                      ),
                      compact,
                    ),
                    if (_messages.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final s in _starters)
                              ActionChip(
                                label: Text(s),
                                labelStyle: const TextStyle(
                                  fontSize: 13,
                                  color: deepBlue,
                                ),
                                backgroundColor: const Color(0xFFF4F1FB),
                                side: BorderSide.none,
                                onPressed: () => _send(s),
                              ),
                          ],
                        ),
                      ),
                    for (final m in _messages) _bubble(m, compact),
                    if (_thinking) const _TypingIndicator(),
                  ],
                ),
              ),
            ),
            _composer(),
          ],
        ),
      ),
    );
  }

  Widget _header() => Semantics(
    container: true,
    header: true,
    child: Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [deepBlue, royalBlue]),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: softYellow.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: softYellow, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alchemy Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _assistant.usingLlm
                      ? 'AI answers · ${_assistant.engineName}'
                      : 'Quick answers · ${_assistant.engineName}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          if (_messages.isNotEmpty)
            IconButton(
              tooltip: 'New conversation',
              color: Colors.white,
              onPressed: _thinking ? null : () => setState(_messages.clear),
              icon: const Icon(Icons.refresh),
            ),
          IconButton(
            tooltip: 'Close chat',
            color: Colors.white,
            onPressed: _toggle,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    ),
  );

  Widget _bubble(ChatMessage m, bool compact) {
    final user = m.fromUser;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: user
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: user
                    ? deepBlue
                    : m.error
                    ? const Color(0xFFFDECEC)
                    : const Color(0xFFF4F1FB),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(user ? 16 : 4),
                  bottomRight: Radius.circular(user ? 4 : 16),
                ),
              ),
              child: Text.rich(
                user ? TextSpan(text: m.text) : formatAssistantText(m.text),
                style: TextStyle(
                  color: user ? Colors.white : ink,
                  fontSize: 14.5,
                  height: 1.45,
                ),
              ),
            ),
            if (m.actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final a in m.actions)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          visualDensity: VisualDensity.compact,
                          side: const BorderSide(color: Color(0xFFD9D2EE)),
                        ),
                        onPressed: () => _openRoute(a.route, compact),
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: Text(a.label),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _composer() => Container(
    padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0xFFEDEAF4))),
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _input,
            focusNode: _focus,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(
              hintText: 'Ask a question…',
              filled: true,
              fillColor: const Color(0xFFF7F6FB),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        IconButton.filled(
          tooltip: 'Send message',
          onPressed: _thinking ? null : _send,
          style: IconButton.styleFrom(backgroundColor: deepBlue),
          icon: const Icon(Icons.send_rounded, color: Colors.white),
        ),
      ],
    ),
  );
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Assistant is typing',
    child: Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F1FB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: purple.withValues(
                      alpha:
                          0.3 +
                          0.7 *
                              (1 -
                                  ((_controller.value * 3 - i) % 3).clamp(
                                    0.0,
                                    1.0,
                                  )),
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Renders the light Markdown Gemini uses: **bold**, *italic* and bullets.
TextSpan formatAssistantText(String text) {
  final spans = <InlineSpan>[];
  final lines = text.split('\n');
  final pattern = RegExp(r'\*\*(.+?)\*\*|\*(?!\s)(.+?)\*');
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i];
    final bullet = RegExp(r'^\s*[*-]\s+').firstMatch(line);
    if (bullet != null) line = '•  ${line.substring(bullet.end)}';
    line = line.replaceFirst(RegExp(r'^#{1,6}\s*'), '');
    var last = 0;
    for (final m in pattern.allMatches(line)) {
      if (m.start > last) {
        spans.add(TextSpan(text: line.substring(last, m.start)));
      }
      spans.add(
        m.group(1) != null
            ? TextSpan(
                text: m.group(1),
                style: const TextStyle(fontWeight: FontWeight.w700),
              )
            : TextSpan(
                text: m.group(2),
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
      );
      last = m.end;
    }
    if (last < line.length) spans.add(TextSpan(text: line.substring(last)));
    if (i < lines.length - 1) spans.add(const TextSpan(text: '\n'));
  }
  return TextSpan(children: spans);
}
