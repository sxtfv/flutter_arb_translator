import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'package:intl/intl.dart';

import '../../models/api_result.dart';
import '../../models/types.dart';
import '../http/http_client.dart';
import '../log/logger.dart';
import 'base.dart';

/// Translator based on Amazon translate API
/// Amazon Translate API Documentation:
/// https://docs.aws.amazon.com/translate/latest/APIReference/welcome.html
class AmazonTranslateService extends AbstractTranslationService with SupportsBulkTranslationToSingleTarget {
  final _AmazonTranslateClient client;
  final Logger logger;

  /// [accessKeyID] - AWS Access Key Id, read mode here:
  /// https://docs.aws.amazon.com/IAM/latest/UserGuide/security-creds.html
  /// [secretAccessKey] - AWS Secret Access Key, read mode here:
  /// https://docs.aws.amazon.com/IAM/latest/UserGuide/security-creds.html
  /// [region] - AWS Service Endpoint Region, read more here:
  /// https://docs.aws.amazon.com/general/latest/gr/rande.html
  AmazonTranslateService({
    required String accessKeyId,
    required String secretAccessKey,
    required String region,
    required this.logger,
  }) : client = _AmazonTranslateClient.create(
          accessKeyId: accessKeyId,
          secretAccessKey: secretAccessKey,
          region: region,
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

    final apiResult = await client.translate(
      logger: logger,
      messages: [source],
      sourceLanguageCode: sourceLanguage,
      targetLanguageCode: target,
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
    logger.info('Translate ${sources.length} texts from $sourceLanguage to $target');

    final apiResult = await client.translate(
      logger: logger,
      messages: sources,
      sourceLanguageCode: sourceLanguage,
      targetLanguageCode: target,
    );

    if (!apiResult.succeeded) {
      logger.warning('Translation failed');
      return sources;
    }

    return apiResult.valueUnsafe.translations.map((e) => e.translatedText).toList();
  }
}

/// Client for Amazon Translate API
/// Generates signed request and sends it to Amazon Translate API
/// [accessKeyId] - AWS Access Key Id, read mode here:
/// https://docs.aws.amazon.com/IAM/latest/UserGuide/security-creds.html
/// [secretAccessKey] - AWS Secret Access Key, read mode here:
/// https://docs.aws.amazon.com/IAM/latest/UserGuide/security-creds.html
/// [region] - AWS Service Endpoint Region, read more here:
/// https://docs.aws.amazon.com/general/latest/gr/rande.html
/// [service] - AWS Service Name, in this case it is "translate"
class _AmazonTranslateClient {
  final String accessKeyId;
  final String secretAccessKey;
  final String region;
  final String service;

  _AmazonTranslateClient._({
    required this.accessKeyId,
    required this.secretAccessKey,
    required this.region,
    required this.service,
  });

  factory _AmazonTranslateClient.create({
    required String accessKeyId,
    required String secretAccessKey,
    required String region,
  }) =>
      _AmazonTranslateClient._(
        accessKeyId: accessKeyId,
        secretAccessKey: secretAccessKey,
        region: region,
        service: "translate",
      );

  String get host => "$service.$region.amazonaws.com";

  String get endpoint => 'https://' + host;

  String get target => 'AWSShineFrontendService_20170701.TranslateText';

  String get credentialScope => "$date/$region/$service/aws4_request";

  String get contentType => 'application/x-amz-json-1.1; charset=utf-8';

  String get signedHeaders => 'content-type;host;x-amz-date;x-amz-target';

  String get amzDateTime => DateFormat("yyyyMMddTHHmm00'Z'").format(DateTime.now().toUtc());

  String get date => DateFormat("yyyyMMdd").format(DateTime.now().toUtc());

  String get algorithm => 'AWS4-HMAC-SHA256';

  HttpClient _buildClient(Logger logger, String message) {
    final String credentials = '$accessKeyId/$credentialScope';
    final List<int> signatureKey = _calculateSigningKey();
    final String stringToSign = _getStringToSign(message);
    final String signature = _calculateSignature(signatureKey, stringToSign);

    final Map<String, String> headers = {
      'Content-Type': contentType,
      'X-Amz-Target': target,
      'X-Amz-Date': amzDateTime,
      'Authorization': "$algorithm Credential=$credentials, SignedHeaders=$signedHeaders, Signature=$signature",
    };

    return HttpClient(
      baseUrl: endpoint,
      authorizationHeaders: headers,
      logger: logger,
    );
  }

  List<int> _hash(List<int> value) {
    return sha256.convert(value).bytes;
  }

  String _hashPayload(String payload) {
    return hex.encode(_hash(utf8.encode(payload)));
  }

  List<int> _sign(List<int> key, String messageToSign) {
    final Hmac hmac = Hmac(sha256, key);
    final Digest digest = hmac.convert(utf8.encode(messageToSign));

    return digest.bytes;
  }

  /// Calculates signing key for request
  /// Read more: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_aws-signing.html
  List<int> _calculateSigningKey() {
    final List<int> dateSigned = _sign(utf8.encode("AWS4$secretAccessKey"), date);
    final List<int> regionSigned = _sign(dateSigned, region);
    final List<int> serviceSigned = _sign(regionSigned, service);
    final List<int> signingKey = _sign(serviceSigned, 'aws4_request');

    return signingKey;
  }

  String _getCanonicalRequest(String message) {
    final String canonicalUri = '/';
    final String canonicalQueryString = '';
    final String hashedPayload = _hashPayload(message);
    final String canonicalHeaders = [
      "content-type:$contentType",
      "host:$host",
      "x-amz-date:$amzDateTime",
      "x-amz-target:$target\n",
    ].join("\n");
    final String canonicalRequest = [
      "POST",
      canonicalUri,
      canonicalQueryString,
      canonicalHeaders,
      signedHeaders,
      hashedPayload,
    ].join("\n");

    return canonicalRequest;
  }

  /// Builds string to sign for HTTP request
  String _getStringToSign(String message) {
    final String canonicalRequest = _getCanonicalRequest(message);
    final String hashedCanonicalRequest = _hashPayload(canonicalRequest);

    final String stringToSign = [
      algorithm,
      amzDateTime,
      credentialScope,
      hashedCanonicalRequest,
    ].join("\n");

    return stringToSign;
  }

  /// Creates signature for HTTP request
  /// https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
  String _calculateSignature(List<int> signingKey, String stringToSign) {
    final List<int> signature = _sign(signingKey, stringToSign);
    return hex.encode(signature);
  }

  Future<ApiResult<_AmazonTranslation>> translate({
    required Logger logger,
    required List<String> messages,
    required String sourceLanguageCode,
    required String targetLanguageCode,
  }) async {
    logger.info('Translate ${messages.length} texts from $sourceLanguageCode to $targetLanguageCode');

    final List<String> escapedMessages = messages.map((message) => message.replaceAll('\n', '|')).toList();
    final _SourceData body = _SourceData(
      sourceLanguageCode: sourceLanguageCode,
      targetLanguageCode: targetLanguageCode,
      text: escapedMessages.join("\n"),
    );

    final String jsonBody = body.toJson;

    return await _buildClient(logger, jsonBody).post<_AmazonTranslation>(
      path: '/',
      decoder: (response) => _decodeJson(logger, response.body),
      body: body.toMap,
    );
  }

  _AmazonTranslation _decodeJson(Logger logger, String json) {
    final String utf8 = Utf8Decoder().convert(json.codeUnits);

    return _AmazonTranslation.fromJson(jsonDecode(utf8));
  }
}

class _SourceData {
  final String sourceLanguageCode;
  final String targetLanguageCode;
  final String text;

  _SourceData({
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
    required this.text,
  });

  String get toJson => jsonEncode(toMap);

  Map<String, String> get toMap {
    return <String, String>{
      'SourceLanguageCode': sourceLanguageCode,
      'TargetLanguageCode': targetLanguageCode,
      'Text': text,
    };
  }
}

class _AmazonTranslation {
  final List<_AmazonTranslationItem> translations;

  _AmazonTranslation(this.translations);

  factory _AmazonTranslation.fromJson(Map<String, dynamic> json) {
    final String translation = json['TranslatedText'] as String;
    final List<_AmazonTranslationItem> translations = translation
        .split("\n")
        .map((x) => _AmazonTranslationItem(x.replaceAll('|', '\n')))
        .toList();
    return _AmazonTranslation(translations);
  }
}

class _AmazonTranslationItem {
  final String translatedText;

  _AmazonTranslationItem(this.translatedText);
}
