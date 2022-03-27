import 'dart:convert';

import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';

import 'base.dart';
import '../http/http_client.dart';
import '../log/logger.dart';

import '../../models/types.dart';

/// Translator based on Google Cloud translation API
/// Google Cloud translation API Documentation:
/// https://cloud.google.com/translate/docs/reference/rest/v3/projects/translateText
class GoogleCloudTranslationService extends AbstractTranslationService
    with SupportsBulkTranslationToSingleTarget {
  final String projectId;
  final Logger logger;
  final HttpClient _httpClient;

  /// For more details on arguments see Google Service Accounts documentation:
  /// https://cloud.google.com/iam/docs/service-accounts
  /// [projectId] - "project_id" field of exported Private Key in JSON
  /// [accessToken] - Service Account access token
  GoogleCloudTranslationService({
    required this.projectId,
    required String accessToken,
    required this.logger,
  }) : _httpClient = HttpClient(
          baseUrl: 'https://translate.googleapis.com',
          authorizationHeaders: {
            'Authorization': 'Bearer $accessToken',
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

    final apiResult = await _httpClient.post<_GoogleCloudTranslation>(
      path: 'v3/projects/$projectId:translateText',
      decoder: (response) => _decodeTranslationJson(response.body),
      body: {
        'sourceLanguageCode': sourceLanguage,
        'targetLanguageCode': target,
        'contents': [
          source,
        ]
      },
    );

    if (!apiResult.succeeded) {
      logger.warning('Translation failed');
      return source;
    }

    return apiResult.valueUnsafe.translations.first.translatedText;
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

    final apiResult = await _httpClient.post<_GoogleCloudTranslation>(
      path: 'v3/projects/$projectId:translateText',
      decoder: (response) => _decodeTranslationJson(response.body),
      body: {
        'sourceLanguageCode': sourceLanguage,
        'targetLanguageCode': target,
        'contents': sources
      },
    );

    if (!apiResult.succeeded) {
      logger.warning('Translation failed');
      return sources;
    }

    return apiResult.valueUnsafe.translations
        .map((x) => x.translatedText)
        .toList();
  }

  _GoogleCloudTranslation _decodeTranslationJson(String json) =>
      _GoogleCloudTranslation.fromJson(jsonDecode(json));
}

/// Creates JWT based on Service Account credentials
/// and obtains access token
/// see here on building authorization documentation:
/// https://cloud.google.com/iot/docs/how-tos/credentials/jwts
class GoogleCloudAuthorizationProvider {
  final String email;
  final String privateKey;
  final List<String> scopes;
  final Logger logger;
  final HttpClient _httpClient;

  /// [email] - Service account email
  /// [privateKey] - exported to JSON service account private key data
  /// [scopes] - scopes which will be used with generated access token
  GoogleCloudAuthorizationProvider({
    required this.email,
    required this.privateKey,
    required this.scopes,
    required this.logger,
  }) : _httpClient = HttpClient(
          baseUrl: 'https://oauth2.googleapis.com',
          logger: logger,
        );

  /// Builds JWT and exchanges it with service account access token
  Future<String> getAccessToken() async {
    final jwt = _createJWT();

    final apiResult = await _httpClient.post<_GoogleCloudAuthResponse>(
        path: 'token',
        decoder: (response) => _GoogleCloudAuthResponse.fromJson(
              jsonDecode(response.body),
            ),
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': jwt,
        });

    if (!apiResult.succeeded) {
      logger.error('Failed to get Google Cloud token', apiResult.error!);
      throw apiResult.error!;
    }

    return apiResult.valueUnsafe.accessToken;
  }

  String _createJWT() {
    final nowUtc = DateTime.now().toUtc();
    final secondsSinceEpoch = (nowUtc.millisecondsSinceEpoch / 1000).round();

    final jwtHeader = {'alg': 'RS256', 'typ': 'JWT'};
    final jwtHeaderBase64 = _base64urlEncodeJson(jwtHeader);

    final claimSet = {
      'iss': email,
      'scope': scopes.join(' '),
      'aud': 'https://oauth2.googleapis.com/token',
      'exp': secondsSinceEpoch + 3600,
      'iat': secondsSinceEpoch,
    };
    final jwtClaimSetBase64 = _base64urlEncodeJson(claimSet);
    final jwtSignatureInput = '$jwtHeaderBase64.$jwtClaimSetBase64';

    final signer = Signer(
      RSASigner(
        RSASignDigest.SHA256,
        privateKey: RSAKeyParser().parse(privateKey) as RSAPrivateKey,
      ),
    );

    final signatureBase64 = signer.sign(jwtSignatureInput).base64;

    return '$jwtSignatureInput.$signatureBase64';
  }

  String _base64urlEncodeJson(Map<String, dynamic> json) =>
      base64UrlEncode(utf8.encode(jsonEncode(json)));
}

class _GoogleCloudAuthResponse {
  final String accessToken;
  final int expiresIn;
  final String tokenType;

  _GoogleCloudAuthResponse({
    required this.accessToken,
    required this.expiresIn,
    required this.tokenType,
  });

  factory _GoogleCloudAuthResponse.fromJson(Map<String, dynamic> json) =>
      _GoogleCloudAuthResponse(
        accessToken: json['access_token'],
        expiresIn: json['expires_in'],
        tokenType: json['token_type'],
      );
}

class _GoogleCloudTranslation {
  final List<_GoogleCloudTranslationItem> translations;

  _GoogleCloudTranslation(this.translations);

  factory _GoogleCloudTranslation.fromJson(Map<String, dynamic> json) {
    final translationsJson = json['translations'] as List<dynamic>;
    final translations = translationsJson
        .map((x) => _GoogleCloudTranslationItem.fromJson(x))
        .toList();
    return _GoogleCloudTranslation(translations);
  }
}

class _GoogleCloudTranslationItem {
  final String translatedText;

  _GoogleCloudTranslationItem(this.translatedText);

  factory _GoogleCloudTranslationItem.fromJson(Map<String, dynamic> json) =>
      _GoogleCloudTranslationItem(json['translatedText']);
}
