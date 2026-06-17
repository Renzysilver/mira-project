
/// Result of executing a slash command.
class CommandResult {
  /// The text to display to the user (as a system message in chat).
  /// Null if the command shouldn't produce a chat message (e.g. it
  /// triggered a side effect like scheduling a reminder).
  final String? displayText;

  /// True if this is an error message (renders in red).
  final bool isError;

  /// Optional side-effect callback (e.g. navigate, schedule, copy).
  /// Useful when the command needs to do something other than just
  /// return text.
  final Future<void> Function()? sideEffect;

  const CommandResult({
    this.displayText,
    this.isError = false,
    this.sideEffect,
  });
}

/// A slash command handler.
abstract class AssistantCommand {
  /// The command name without the slash, e.g. 'help', 'time'.
  String get name;

  /// Short description shown in /help.
  String get description;

  /// Usage example, e.g. '/remind 5m Call mom'.
  String get usage;

  /// Execute the command with the raw args string (everything after
  /// the command name + space). Returns the result.
  Future<CommandResult> execute(String args);
}

/// Parses a chat message and dispatches to the right command.
///
/// Usage:
///   if (CommandRegistry.isCommand(text)) {
///     final result = await CommandRegistry.execute(text);
///     // display result.displayText as a system message
///   }
class CommandRegistry {
  CommandRegistry._();

  static final Map<String, AssistantCommand> _commands = {};

  /// Register a command. Called at app startup.
  static void register(AssistantCommand cmd) {
    _commands[cmd.name] = cmd;
  }

  /// True if [text] starts with '/' and matches a registered command.
  static bool isCommand(String text) {
    final trimmed = text.trim();
    if (!trimmed.startsWith('/')) return false;
    final name = trimmed.substring(1).split(' ').first;
    return _commands.containsKey(name);
  }

  /// Execute the command. Returns null result if command not found.
  static Future<CommandResult> execute(String text) async {
    final trimmed = text.trim();
    final parts = trimmed.substring(1).split(' ');
    final name = parts.first;
    final args = parts.skip(1).join(' ');

    final cmd = _commands[name];
    if (cmd == null) {
      return const CommandResult(
        displayText: "Unknown command. Type /help for a list.",
        isError: true,
      );
    }
    try {
      return await cmd.execute(args);
    } catch (e) {
      return CommandResult(
        displayText: 'Error running /$name: $e',
        isError: true,
      );
    }
  }

  /// All registered commands, for /help and the picker UI.
  static List<AssistantCommand> get all => _commands.values.toList();
}
