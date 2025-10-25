import 'dart:convert';

import 'base.dart';
import '../http/http_client.dart';
import '../log/logger.dart';

import '../../models/types.dart';

/// Translator that uses LibreTranslate API for translation
/// LibreTranslate API Documentation
/// https://docs.libretranslate.com/guides/api_usage
class LibreTranslateTranslationService extends AbstractTranslationService {
  final HttpClient _httpClient;
  final Logger logger;
  final String? apiKey;

  LibreTranslateTranslationService({
    required String baseUrl,
    this.apiKey,
    required this.logger,
  }) : _httpClient = HttpClient(
          baseUrl: baseUrl,
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

    final apiResult = await _httpClient.post<_LibreTranslateResponse>(
      path: '/translate',
      headers: {
        'Content-Type': 'application/json',
      },
      body: {
        'q': source,
        'source': sourceLanguage,
        'target': target,
        'api_key': (apiKey ?? '').isEmpty ? null : apiKey,
      },
      decoder: (response) => _LibreTranslateResponse.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)),
      ),
    );

    if (!apiResult.succeeded) {
      logger.warning('Translation failed');
      return source;
    }

    if (apiResult.valueUnsafe.translatedText.isEmpty) {
      logger.warning('Translation is empty. Source: $source; Target: $target');
      return source;
    }

    return apiResult.valueUnsafe.translatedText;
  }
}

class _LibreTranslateResponse {
  final String translatedText;

  _LibreTranslateResponse({
    required this.translatedText,
  });

  factory _LibreTranslateResponse.fromJson(Map<String, dynamic> json) {
    return _LibreTranslateResponse(
      translatedText: json['translatedText'] as String,
    );
  }
}
