import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../app/theme.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final String time;

  const ChatBubble({super.key, required this.message, required this.isUser, required this.time});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          gradient: isUser ? AppTheme.primaryGradient : LinearGradient(colors: [AppTheme.surfaceLight, AppTheme.surfaceLight]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            MarkdownBody(
              data: message,
              selectable: true,
              styleSheet: MarkdownStyleSheet(p: TextStyle(color: isUser ? Colors.white : AppTheme.textPrimary, fontSize: 15)),
            ),
            const SizedBox(height: 4),
            Text(time, style: TextStyle(color: isUser ? Colors.white70 : AppTheme.textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
