import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../app/theme.dart';

/// Chat bubble — user messages on the right (pink), AI on the left (glass).
///
/// Designed to sit inside a constrained-width chat panel (maxWidth ~560px)
/// that lives on the left side of the screen, with the character visible
/// on the right. The maxWidth here is relative to the bubble's parent
/// container, not the full screen — so callers should wrap the ListView
/// in a ConstrainedBox / Align with a maxWidth.
class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final String time;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    // Chat panel is now full-width, so bubbles should be constrained to
    // a comfortable reading width regardless of screen size.
    final bubbleMaxWidth = 440.0;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 15),
          decoration: BoxDecoration(
            gradient: isUser
                ? AppTheme.pinkGradient
                : LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.08),
                      Colors.white.withOpacity(0.04),
                    ],
                  ),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 18),
            ),
            border: isUser
                ? null
                : Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: isUser
                ? [
                    BoxShadow(
                      color: AppTheme.magentaAccent.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              MarkdownBody(
                data: message,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: isUser ? Colors.white : AppTheme.moonWhite,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  color: isUser
                      ? Colors.white.withOpacity(0.7)
                      : AppTheme.textSecondary.withOpacity(0.7),
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
