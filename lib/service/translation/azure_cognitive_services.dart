import 'dart:convert';

import 'base.dart';
import '../http/http_client.dart';
import '../log/logger.dart';

import '../../utils/extensions.dart';

import '../../models/translation.dart';
import '../../models/types.dart';

/// Translator based on Azure Cognitive Services API
/// Azure Cognitive Services API Documentation:
/// https://docs.microsoft.com/en-us/azure/cognitive-services/translator/quickstart-translator?tabs=csharp
class AzureCognitiveServicesTranslationService
    extends AbstractTranslationService
    with
        SupportsSimpleTranslationToTargetsList,
        SupportsBulkTranslationToSingleTarget,
        SupportsBulkTranslationToTargetsList {
  final HttpClient _httpClient;
  final Logger logger;

  /// [subscriptionKey] - Azure Subscription Key, read mode here:
  /// https://docs.microsoft.com/en-us/azure/cognitive-services/authentication?tabs=powershell
  /// [region] - Azure Subscription Region, read more here:
  /// https://docs.microsoft.com/en-us/azure/cognitive-services/authentication?tabs=powershell
  AzureCognitiveServicesTranslationService({
    required String subscriptionKey,
    String? region,
    required this.logger,
  }) : _httpClient = HttpClient(
          baseUrl: 'https://api.cognitive.microsofttranslator.com',
          authorizationHeaders: {
            'Ocp-Apim-Subscription-Key': subscriptionKey,
            'Ocp-Apim-Subscription-Region': region ?? ''
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

    final apiResult = await _httpClient.post<List<_AzureTranslation>>(
      path: 'translate',
      decoder: (response) => _decodeJson(response.body),
      parameters: {
        'api-version': '3.0',
        'from': sourceLanguage,
        'to': target,
      },
      headers: {
        'Content-Type': 'application/json',
      },
      body: [
        {
          'Text': source,
        },
      ],
    );

    if (!apiResult.succeeded) {
      logger.warning('Translation failed');
      return source;
    }

    final result = apiResult.valueUnsafe.first.translations.first.text;

    return result;
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

    final targetsQueryParam = targets.map((x) => 'to=$x').join('&');
    final apiResult = await _httpClient.post<List<_AzureTranslation>>(
      path: 'translate?api-version=3.0&from=$sourceLanguage&$targetsQueryParam',
      decoder: (response) => _decodeJson(response.body),
      headers: {
        'Content-Type': 'application/json',
      },
      body: [
        {
          'Text': source,
        },
      ],
    );

    if (!apiResult.succeeded) {
      logger.warning('Translation failed');
      return Translation(
        source: source,
        sourceLanguage: sourceLanguage,
        translations: targets.map((x) => MapEntry(x, source)).toMap(),
      );
    }

    Map<LanguageCode, String> translations = {};
    for (final translationItem in apiResult.valueUnsafe.first.translations) {
      translations[translationItem.to] = translationItem.text;
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

    final apiResult = await _httpClient.post<List<_AzureTranslation>>(
      path: 'translate',
      decoder: (response) => _decodeJson(response.body),
      parameters: {
        'api-version': '3.0',
        'from': sourceLanguage,
        'to': target,
      },
      headers: {
        'Content-Type': 'application/json',
      },
      body: sources.map((x) => {'Text': x}).toList(),
    );

    if (!apiResult.succeeded) {
      logger.warning('Translation failed');
      return sources;
    }

    return apiResult.valueUnsafe.map((x) => x.translations.first.text).toList();
  }

  /// Translates given texts to specified languages
  /// [sources] - list of texts which should be translated
  /// [sourceLanguage] - the language in which [sources] were given
  /// [targets] - list of languages to which [sources] should be translated
  @override
  Future<List<Translation>> translateBulk(
    List<String> sources,
    LanguageCode sourceLanguage,
    List<LanguageCode> targets,
  ) async {
    logger.info(
        'Translate bulk "$sources" from $sourceLanguage to multiple $targets');

    final targetsQueryParam = targets.map((x) => 'to=$x').join('&');
    final apiResult = await _httpClient.post<List<_AzureTranslation>>(
      path: 'translate?api-version=3.0&from=$sourceLanguage&$targetsQueryParam',
      decoder: (response) => _decodeJson(response.body),
      headers: {
        'Content-Type': 'application/json',
      },
      body: sources.map((x) => {'Text': x}).toList(),
    );

    if (!apiResult.succeeded) {
      logger.warning('Translation failed');

      return sources
          .map((x) => Translation(
                source: x,
                sourceLanguage: sourceLanguage,
                translations: targets.map((y) => MapEntry(x, y)).toMap(),
              ))
          .toList();
    }

    int i = 0;
    List<Translation> result = [];

    for (final translation in apiResult.valueUnsafe) {
      Map<LanguageCode, String> translations = {};

      for (final translationItem in translation.translations) {
        translations[translationItem.to] = translationItem.text;
      }

      result.add(Translation(
        source: sources[i],
        sourceLanguage: sourceLanguage,
        translations: translations,
      ));

      i++;
    }

    return result;
  }

  List<_AzureTranslation> _decodeJson(String json) {
    return (jsonDecode(json) as List<dynamic>)
        .map((x) => _AzureTranslation.fromJson(x))
        .toList();
  }
}

class _AzureTranslation {
  final List<_AzureTranslationItem> translations;

  _AzureTranslation(this.translations);

  factory _AzureTranslation.fromJson(Map<String, dynamic> json) {
    final translationsJson = json['translations'] as List<dynamic>;
    final translations =
        translationsJson.map((x) => _AzureTranslationItem.fromJson(x)).toList();
    return _AzureTranslation(translations);
  }
}

class _AzureTranslationItem {
  final String text;
  final String to;

  const _AzureTranslationItem(this.text, this.to);

  factory _AzureTranslationItem.fromJson(Map<String, dynamic> json) =>
      _AzureTranslationItem(json['text'], json['to']);
}
