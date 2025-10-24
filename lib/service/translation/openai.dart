import 'dart:convert';

import 'base.dart';
import '../http/http_client.dart';
import '../log/logger.dart';

import '../../utils/extensions.dart';

import '../../models/translation.dart';
import '../../models/types.dart';
import '../../models/api_result.dart';

/// Translator that uses Open AI API for translation
/// Open AI API Documentation:
/// https://platform.openai.com/docs/api-reference/introduction
class OpenAITranslationService extends AbstractTranslationService
    with
        SupportsSimpleTranslationToTargetsList,
        SupportsBulkTranslationToSingleTarget {
  static const String _defaultModel = 'gpt-3.5-turbo';

  final HttpClient _httpClient;
  final Logger logger;
  final String model;

  OpenAITranslationService({
    required String baseUrl,
    required String apiKey,
    required this.logger,
    String? model,
  })  : model = (model == null || model.isEmpty) ? _defaultModel : model,
        _httpClient = HttpClient(
          baseUrl: baseUrl,
          authorizationHeaders: {'Authorization': 'Bearer $apiKey'},
          logger: logger,
        );

  /// Translates given text to specified language
  /// [source] - text which should be translated
  /// [sourceLanguage] - the language in which [source] was given
  /// [target] - language to which [source] should be translated
  @override
  Future<String> translate(
    String source,
    LanguageCode sourceLanguage,
    LanguageCode target,
  ) async {
    logger.info('Translate "$source" from $sourceLanguage to $target');

    final prompt =
        'Translate the following text from $sourceLanguage to $target: $source';

    final apiResult = await _queryCompletions(prompt);

    if (!apiResult.succeeded) {
      logger.warning('Translation failed');
      return source;
    }

    if (apiResult.valueUnsafe.choices.isEmpty) {
      logger.warning('Choices list is empty for prompt: $prompt');
      return source;
    }

    final translatedText = apiResult.valueUnsafe.choices.first.message.content;

    return translatedText.trim();
  }

  /// Translates given text to specified languages
  /// [source] - text which should be translated
  /// [sourceLanguage] - the language in which [source] was given
  /// [targets] - list of languages to which [source] should be translated
  @override
  Future<Translation> translateToTargetsList(
    String source,
    LanguageCode sourceLanguage,
    List<LanguageCode> targets,
  ) async {
    logger
        .info('Translate "$source" from $sourceLanguage to multiple $targets');

    final prompt = '''
Translate the following text from $sourceLanguage to these languages: ${targets.join(', ')}.
Return only the translations, in the same order as the languages listed, one per line.
Do not include the language names, colons, or any extra text—just the translations.
Text: $source
''';

    final apiResult = await _queryCompletions(prompt);

    if (!apiResult.succeeded) {
      logger.warning('Translation failed');
      return Translation(
        source: source,
        sourceLanguage: sourceLanguage,
        translations: targets.map((x) => MapEntry(x, source)).toMap(),
      );
    }

    if (apiResult.valueUnsafe.choices.isEmpty) {
      logger.warning('Choices list is empty for prompt: $prompt');
      return Translation(
        source: source,
        sourceLanguage: sourceLanguage,
        translations: targets.map((x) => MapEntry(x, source)).toMap(),
      );
    }

    final translatedText = apiResult.valueUnsafe.choices.first.message.content;

    final lines = _splitResponseIntoLines(translatedText);
    if (lines.length != targets.length) {
      logger.warning(
          'Expected ${targets.length} translations, got ${lines.length}');
    }

    Map<LanguageCode, String> translations = {};
    for (int i = 0; i < targets.length; i++) {
      translations[targets[i]] = i < lines.length ? lines[i] : source;
    }

    return Translation(
      source: source,
      sourceLanguage: sourceLanguage,
      translations: translations,
    );
  }

  /// Translates given texts to specified language
  /// [sources] - list of text which should be translated
  /// [sourceLanguage] - the language in which [sources] were given
  /// [target] - language to which [sources] should be translated
  @override
  Future<List<String>> translateBulkToSingleTarget(
    List<String> sources,
    LanguageCode sourceLanguage,
    LanguageCode target,
  ) async {
    logger.info(
        'Translate bulk "$sources" from $sourceLanguage to single $target');

    final prompt = '''
Translate the following texts from $sourceLanguage to $target.
Return only the translations, in the same order as the texts listed, one per line.
Do not include the original texts, language names, colons, or any extra text—just the translations.
Texts:
${sources.join('\n')}
''';

    final apiResult = await _queryCompletions(prompt, 2000);

    if (!apiResult.succeeded) {
      logger.warning('Translation failed');
      return sources;
    }

    if (apiResult.valueUnsafe.choices.isEmpty) {
      logger.warning('Choices list is empty for prompt: $prompt');
      return sources;
    }

    final translatedText = apiResult.valueUnsafe.choices.first.message.content;

    final lines = _splitResponseIntoLines(translatedText);
    if (lines.length != sources.length) {
      logger.warning(
          'Expected ${sources.length} translations, got ${lines.length}');
    }

    return List.generate(
      sources.length,
      (i) => i < lines.length ? lines[i] : sources[i],
    );
  }

  static List<String> _splitResponseIntoLines(String text) => text
      .trim()
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  Future<ApiResult<_OpenAIChatCompletionResponse>> _queryCompletions(
    String prompt, [
    int maxTokens = 1000,
  ]) =>
      _httpClient.post<_OpenAIChatCompletionResponse>(
        path: 'v1/chat/completions',
        headers: {
          'Content-Type': 'application/json',
        },
        body: {
          'model': model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'max_tokens': maxTokens,
        },
        decoder: (response) => _OpenAIChatCompletionResponse.fromJson(
            jsonDecode(utf8.decode(response.bodyBytes))),
      );
}

class _OpenAIChatCompletionResponse {
  final List<_OpenAIChatChoice> choices;

  _OpenAIChatCompletionResponse({required this.choices});

  factory _OpenAIChatCompletionResponse.fromJson(Map<String, dynamic> json) {
    return _OpenAIChatCompletionResponse(
      choices: (json['choices'] as List<dynamic>)
          .map((e) => _OpenAIChatChoice.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class _OpenAIChatChoice {
  final _OpenAIChatMessage message;

  _OpenAIChatChoice({required this.message});

  factory _OpenAIChatChoice.fromJson(Map<String, dynamic> json) {
    return _OpenAIChatChoice(
      message:
          _OpenAIChatMessage.fromJson(json['message'] as Map<String, dynamic>),
    );
  }
}

class _OpenAIChatMessage {
  final String content;

  _OpenAIChatMessage({required this.content});

  factory _OpenAIChatMessage.fromJson(Map<String, dynamic> json) {
    return _OpenAIChatMessage(
      content: json['content'] as String,
    );
  }
}
