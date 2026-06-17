import 'dart:math';
import 'command_registry.dart';

// ── Local commands (no API call needed) ──────────────────────────────

class HelpCommand extends AssistantCommand {
  @override
  String get name => 'help';
  @override
  String get description => 'List all available commands';
  @override
  String get usage => '/help';

  @override
  Future<CommandResult> execute(String args) async {
    final buf = StringBuffer('Available commands:\n\n');
    for (final cmd in CommandRegistry.all) {
      buf.writeln('  ${cmd.usage}');
      buf.writeln('    ${cmd.description}');
      buf.writeln();
    }
    return CommandResult(displayText: buf.toString().trim());
  }
}

class TimeCommand extends AssistantCommand {
  @override
  String get name => 'time';
  @override
  String get description => 'Show the current time';
  @override
  String get usage => '/time';

  @override
  Future<CommandResult> execute(String args) async {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return CommandResult(displayText: 'It\'s $time right now.');
  }
}

class DateCommand extends AssistantCommand {
  @override
  String get name => 'date';
  @override
  String get description => 'Show today\'s date';
  @override
  String get usage => '/date';

  @override
  Future<CommandResult> execute(String args) async {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return CommandResult(
        displayText:
            'Today is ${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}.');
  }
}

class JokeCommand extends AssistantCommand {
  static const _jokes = [
    "Why don't skeletons fight each other? They don't have the guts.",
    "I told my wife she was drawing her eyebrows too high. She looked surprised.",
    "Why did the scarecrow win an award? Because he was outstanding in his field.",
    "I'm reading a book about anti-gravity. It's impossible to put down.",
    "Why don't scientists trust atoms? Because they make up everything!",
    "I would tell you a UDP joke, but you might not get it.",
    "Why did the developer go broke? Because he used up all his cache.",
    "Parallel lines have so much in common. It's a shame they'll never meet.",
    "I'm on a seafood diet. I see food and I eat it.",
    "Why did the coffee file a police report? It got mugged.",
  ];

  @override
  String get name => 'joke';
  @override
  String get description => 'Tell a random joke';
  @override
  String get usage => '/joke';

  @override
  Future<CommandResult> execute(String args) async {
    final rng = Random();
    return CommandResult(displayText: _jokes[rng.nextInt(_jokes.length)]);
  }
}

class QuoteCommand extends AssistantCommand {
  static const _quotes = [
    "The only way to do great work is to love what you do. — Steve Jobs",
    "Stay hungry, stay foolish. — Stewart Brand",
    "The future belongs to those who believe in the beauty of their dreams. — Eleanor Roosevelt",
    "In the middle of difficulty lies opportunity. — Albert Einstein",
    "Be yourself; everyone else is already taken. — Oscar Wilde",
    "The only impossible journey is the one you never begin. — Tony Robbins",
    "What we think, we become. — Buddha",
    "Whether you think you can or you think you can't, you're right. — Henry Ford",
    "The best time to plant a tree was 20 years ago. The second best time is now. — Chinese proverb",
    "Life is what happens when you're busy making other plans. — John Lennon",
  ];

  @override
  String get name => 'quote';
  @override
  String get description => 'Share an inspirational quote';
  @override
  String get usage => '/quote';

  @override
  Future<CommandResult> execute(String args) async {
    final rng = Random();
    return CommandResult(displayText: _quotes[rng.nextInt(_quotes.length)]);
  }
}
