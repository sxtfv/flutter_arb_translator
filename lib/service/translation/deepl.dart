import 'dart:convert';

import '../../models/types.dart';
import '../http/http_client.dart';
import '../log/logger.dart';
import 'base.dart';

/// Translator based on DeepL API
/// DeepL translation API documentation:
/// https://www.deepl.com/docs-api/translating-text/
class DeepLTranslationService extends AbstractTranslationService
    with SupportsBulkTranslationToSingleTarget {
  final HttpClient _httpClient;
  final String apiKey;
  final Logger logger;

  DeepLTranslationService({
    required String url,
    required this.apiKey,
    required this.logger,
  }) : _httpClient = HttpClient(
          baseUrl: url,
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

    final apiResult = await _httpClient.post<_DeepLTranslation>(
      path: 'v2/translate',
      headers: {
        'Authorization': 'DeepL-Auth-Key $apiKey',
      },
      parameters: {
        'source_lang': sourceLanguage,
        'target_lang': target,
        'text': Uri.encodeComponent(source),
      },
      decoder: (response) => _decodeTranslationJson(response.body),
      body: {},
    );

    if (!apiResult.succeeded) {
      logger.warning('Translation failed');
      return source;
    }

    return apiResult.valueUnsafe.translations.first.text;
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

    List<MapEntry<String, String>> parameters = [];
    parameters.add(MapEntry('source_lang', sourceLanguage));
    parameters.add(MapEntry('target_lang', target));
    for (final source in sources) {
      parameters.add(MapEntry('text', Uri.encodeComponent(source)));
    }

    final parametersStr =
        parameters.map((x) => '${x.key}=${x.value}').join('&');

    final apiResult = await _httpClient.post<_DeepLTranslation>(
      path: 'v2/translate?$parametersStr',
      headers: {
        'Authorization': 'DeepL-Auth-Key $apiKey',
      },
      decoder: (response) => _decodeTranslationJson(response.body),
      body: {},
    );

    if (!apiResult.succeeded) {
      logger.warning('Translation failed');
      return sources;
    }

    return apiResult.valueUnsafe.translations.map((x) => x.text).toList();
  }

  _DeepLTranslation _decodeTranslationJson(String json) =>
      _DeepLTranslation.fromJson(jsonDecode(json));
}

class _DeepLTranslation {
  final List<_DeepLTranslationItem> translations;
  const _DeepLTranslation(this.translations);

  factory _DeepLTranslation.fromJson(Map<String, dynamic> json) {
    final translationsJson = json['translations'] as List<dynamic>;
    final translations =
        translationsJson.map((x) => _DeepLTranslationItem.fromJson(x)).toList();
    return _DeepLTranslation(translations);
  }
}

class _DeepLTranslationItem {
  final String text;
  const _DeepLTranslationItem(this.text);

  factory _DeepLTranslationItem.fromJson(Map<String, dynamic> json) {
    final text = json['text'] as String;
    try {
      final utf8Text = utf8.decode(text.runes.toList());
      return _DeepLTranslationItem(utf8Text);
    } catch (_) {
      return _DeepLTranslationItem(text);
    }
  }
}
