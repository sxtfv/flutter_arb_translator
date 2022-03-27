import 'dart:convert';

import 'base.dart';
import '../http/http_client.dart';
import '../log/logger.dart';

import '../../models/types.dart';

/// Translator based on Yandex API
/// Yandex API Documentation:
/// https://cloud.yandex.com/en-ru/docs/translate/operations/translate
class YandexTranslationService extends AbstractTranslationService
    with SupportsBulkTranslationToSingleTarget {
  final HttpClient _httpClient;
  final Logger logger;

  /// [apiKey] - Yandex api key
  YandexTranslationService({
    required String apiKey,
    required this.logger,
  }) : _httpClient = HttpClient(
          baseUrl: 'https://translate.api.cloud.yandex.net',
          authorizationHeaders: {
            'Authorization': 'Api-Key $apiKey',
          },
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

    final apiResult = await _httpClient.post<_YandexTranslation>(
      path: 'translate/v2/translate',
      decoder: (response) => _decodeJson(response.body),
      parameters: {
        'sourceLanguageCode': sourceLanguage,
        'targetLanguageCode': target,
      },
      body: {
        'texts': [
          source,
        ],
      },
      headers: {
        'Content-Type': 'application/json',
      },
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

    final apiResult = await _httpClient.post<_YandexTranslation>(
      path: 'translate/v2/translate',
      decoder: (response) => _decodeJson(response.body),
      parameters: {
        'sourceLanguageCode': sourceLanguage,
        'targetLanguageCode': target,
      },
      body: {
        'texts': sources,
      },
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (!apiResult.succeeded) {
      logger.warning('Translation failed');
      return sources;
    }

    return apiResult.valueUnsafe.translations.map((x) => x.text).toList();
  }

  _YandexTranslation _decodeJson(String json) =>
      _YandexTranslation.fromJson(jsonDecode(json));
}

class _YandexTranslation {
  final List<_YandexTranslationItem> translations;

  _YandexTranslation(this.translations);

  factory _YandexTranslation.fromJson(Map<String, dynamic> json) {
    final translationsJson = json['translations'] as List<dynamic>;
    final translations = translationsJson
        .map((x) => _YandexTranslationItem.fromJson(x))
        .toList();
    return _YandexTranslation(translations);
  }
}

class _YandexTranslationItem {
  final String text;

  _YandexTranslationItem(this.text);

  factory _YandexTranslationItem.fromJson(Map<String, dynamic> json) {
    final text = json['text'] as String;
    final utf8Text = utf8.decode(text.runes.toList());
    return _YandexTranslationItem(utf8Text);
  }
}
