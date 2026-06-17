import '../ai/ai_provider_registry.dart';
import '../utils/logger.dart';
import 'command_registry.dart';

/// AI-powered commands that delegate to the active AI provider's
/// rawCompletion method. These bypass the companion persona system —
/// they use a neutral task-focused system prompt so the output is
/// functional (translation, summary, draft) rather than in-character.
class SummarizeCommand extends AssistantCommand {
  @override
  String get name => 'summarize';
  @override
  String get description => 'Summarize a block of text';
  @override
  String get usage => '/summarize <text>';

  @override
  Future<CommandResult> execute(String args) async {
    if (args.trim().isEmpty) {
      return const CommandResult(
        displayText: 'Usage: /summarize <text to summarize>',
        isError: true,
      );
    }
    try {
      final response = await AiProviderRegistry.active.rawCompletion(
        systemPrompt:
            'You are a summarisation assistant. Produce a concise summary '
            'of the user\'s text in 2-3 sentences. Do not add commentary.',
        messages: [
          {'role': 'user', 'content': args},
        ],
        temperature: 0.3,
        maxTokens: 256,
      );
      return CommandResult(
        displayText: response.isEmpty ? '(empty)' : 'Summary:\n$response',
      );
    } catch (e) {
      AppLogger.error('Summarize command failed', e);
      return CommandResult(displayText: 'Summarize failed: $e', isError: true);
    }
  }
}

class TranslateCommand extends AssistantCommand {
  @override
  String get name => 'translate';
  @override
  String get description => 'Translate text. Example: /translate Spanish Hello friend';
  @override
  String get usage => '/translate <language> <text>';

  @override
  Future<CommandResult> execute(String args) async {
    final parts = args.split(' ');
    if (parts.length < 2) {
      return const CommandResult(
        displayText:
            'Usage: /translate <language> <text>\nExample: /translate Spanish Hello friend',
        isError: true,
      );
    }
    final language = parts.first;
    final text = parts.skip(1).join(' ');
    try {
      final response = await AiProviderRegistry.active.rawCompletion(
        systemPrompt:
            'You are a translation assistant. Translate the user\'s text '
            'into $language. Reply with only the translation — no preamble.',
        messages: [
          {'role': 'user', 'content': text},
        ],
        temperature: 0.2,
        maxTokens: 512,
      );
      return CommandResult(
        displayText: '→ $language:\n$response',
      );
    } catch (e) {
      AppLogger.error('Translate command failed', e);
      return CommandResult(displayText: 'Translate failed: $e', isError: true);
    }
  }
}

class DraftCommand extends AssistantCommand {
  @override
  String get name => 'draft';
  @override
  String get description => 'Draft a reply to a message';
  @override
  String get usage => '/draft <message to reply to>';

  @override
  Future<CommandResult> execute(String args) async {
    if (args.trim().isEmpty) {
      return const CommandResult(
        displayText: 'Usage: /draft <message you want to reply to>',
        isError: true,
      );
    }
    try {
      final response = await AiProviderRegistry.active.rawCompletion(
        systemPrompt:
            'You are a message drafting assistant. The user gives you a '
            'message they received; draft a thoughtful reply. Reply with '
            'only the draft — no preamble, no quotation of the original.',
        messages: [
          {'role': 'user', 'content': 'Reply to this message:\n\n$args'},
        ],
        temperature: 0.6,
        maxTokens: 512,
      );
      return CommandResult(
        displayText: 'Draft reply:\n$response',
      );
    } catch (e) {
      AppLogger.error('Draft command failed', e);
      return CommandResult(displayText: 'Draft failed: $e', isError: true);
    }
  }
}
