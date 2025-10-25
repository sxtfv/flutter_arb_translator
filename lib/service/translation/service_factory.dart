import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'base.dart';
import 'azure_cognitive_services.dart';
import 'yandex.dart';
import 'google_cloud.dart';
import 'deepl.dart';
import 'amazon_translate.dart';
import 'libretranslate.dart';

import '../log/logger.dart';

import '../../utils/extensions.dart';

enum TranslationServiceType {
  azureCognitiveServices,
  yandex,
  googleCloud,
  deepL,
  amazonTranslate,
  libreTranslate,
}

/// Creates and configures specific translation API services
class TranslationServiceFactory {
  final Logger logger;

  TranslationServiceFactory({
    required this.logger,
  });

  static String getConfigurationFilePath() {
    return path.absolute('dev_assets/flutter_arb_translator_config.json');
  }

  static bool checkConfigurationFileExists() {
    final filePath = getConfigurationFilePath();
    return File(filePath).existsSync();
  }

  /// [type] - type of service which should be created and initialized
  Future<AbstractTranslationService> create(TranslationServiceType type) async {
    try {
      final configuration = await _parseConfiguration();

      switch (type) {
        case TranslationServiceType.azureCognitiveServices:
          return _createAzureCognitiveServicesTranslator(configuration);
        case TranslationServiceType.yandex:
          return _createYandexTranslator(configuration);
        case TranslationServiceType.googleCloud:
          return await _createGoogleCloudTranslator(configuration);
        case TranslationServiceType.deepL:
          return _createDeepLTranslator(configuration);
        case TranslationServiceType.amazonTranslate:
          return _createAmazonTranslateTranslator(configuration);
        case TranslationServiceType.libreTranslate:
          return _createLibreTranslateTranslator(configuration);
      }
    } on Exception catch (error) {
      logger.error('Failed to initialize translator service', error);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _parseConfiguration() async {
    final configFilePath = getConfigurationFilePath();
    final f = File(configFilePath);
    if (!await f.exists()) {
      throw Exception('File dev_assets/translator_config.json does not exist');
    }
    final fileContent = await f.readAsString();
    return jsonDecode(fileContent);
  }

  AzureCognitiveServicesTranslationService
      _createAzureCognitiveServicesTranslator(
    Map<String, dynamic> configuration,
  ) {
    final serviceKey = 'AzureCognitiveServices';
    final subscriptionIdKey = 'SubscriptionKey';
    final regionKey = 'Region';

    final subscriptionKey = configuration.lookupNested(
      '$serviceKey:$subscriptionIdKey',
    );

    if (subscriptionKey == null) {
      throw Exception('$serviceKey:$subscriptionIdKey is not defined');
    }

    final region = configuration.lookupNested('$serviceKey:$regionKey');

    return AzureCognitiveServicesTranslationService(
      subscriptionKey: subscriptionKey,
      region: region,
      logger: logger,
    );
  }

  YandexTranslationService _createYandexTranslator(
    Map<String, dynamic> configuration,
  ) {
    final serviceKey = 'YandexCloud';
    final serviceAuthKey = 'APIKey';

    final apiKey = configuration.lookupNested(
      '$serviceKey:$serviceAuthKey',
    );

    if (apiKey == null) {
      throw Exception('$serviceKey:$serviceAuthKey is not defined');
    }

    return YandexTranslationService(
      apiKey: apiKey,
      logger: logger,
    );
  }

  Future<GoogleCloudTranslationService> _createGoogleCloudTranslator(
    Map<String, dynamic> configuration,
  ) async {
    final serviceKey = 'GoogleCloud';
    final clientEmailKey = 'ClientEmail';
    final privateKeyKey = 'PrivateKey';
    final projectIdKey = 'ProjectId';

    final clientEmail = configuration.lookupNested(
      '$serviceKey:$clientEmailKey',
    );

    final privateKey = configuration.lookupNested(
      '$serviceKey:$privateKeyKey',
    );

    final projectId = configuration.lookupNested(
      '$serviceKey:$projectIdKey',
    );

    if (clientEmail == null) {
      throw Exception('$serviceKey:$clientEmail is not defined');
    }

    if (privateKey == null) {
      throw Exception('$serviceKey:$privateKey is not defined');
    }

    if (projectId == null) {
      throw Exception('$serviceKey:$projectIdKey is not defined');
    }

    final accessToken = await GoogleCloudAuthorizationProvider(
      email: clientEmail,
      privateKey: privateKey,
      scopes: ['https://www.googleapis.com/auth/cloud-translation'],
      logger: logger,
    ).getAccessToken();

    return GoogleCloudTranslationService(
      projectId: projectId,
      accessToken: accessToken,
      logger: logger,
    );
  }

  DeepLTranslationService _createDeepLTranslator(
    Map<String, dynamic> configuration,
  ) {
    final serviceKey = 'DeepL';
    final urlKey = 'Url';
    final apiKeyKey = 'ApiKey';

    final url = configuration.lookupNested('$serviceKey:$urlKey');

    final apiKey = configuration.lookupNested('$serviceKey:$apiKeyKey');

    if (url == null) {
      throw Exception('$serviceKey:$urlKey is not defined');
    }

    if (apiKey == null) {
      throw Exception('$serviceKey$apiKeyKey is not defined');
    }

    return DeepLTranslationService(
      url: url,
      apiKey: apiKey,
      logger: logger,
    );
  }

  Future<AmazonTranslateService> _createAmazonTranslateTranslator(
    Map<String, dynamic> configuration,
  ) async {
    final serviceKey = 'AmazonTranslate';
    final regionKey = 'Region';
    final accessKeyIdKey = 'AccessKeyId';
    final secretAccessKeyKey = 'SecretAccessKey';

    final region = configuration.lookupNested(
      '$serviceKey:$regionKey',
    );

    final accessKeyId = configuration.lookupNested(
      '$serviceKey:$accessKeyIdKey',
    );

    final secretAccessKey = configuration.lookupNested(
      '$serviceKey:$secretAccessKeyKey',
    );

    if (region == null) {
      throw Exception('$serviceKey:$regionKey is not defined');
    }

    if (accessKeyId == null) {
      throw Exception('$serviceKey:$accessKeyIdKey is not defined');
    }

    if (secretAccessKey == null) {
      throw Exception('$serviceKey:$secretAccessKeyKey is not defined');
    }

    return AmazonTranslateService(
      region: region,
      accessKeyId: accessKeyId,
      secretAccessKey: secretAccessKey,
      logger: logger,
    );
  }

  LibreTranslateTranslationService _createLibreTranslateTranslator(
      Map<String, dynamic> configuration,
      ) {
    final serviceKey = 'LibreTranslate';
    final urlKey = 'Url';
    final apiKeyKey = 'ApiKey';

    final url = configuration.lookupNested('$serviceKey:$urlKey');

    final apiKey = configuration.lookupNested('$serviceKey:$apiKeyKey');

    if (url == null) {
      throw Exception('$serviceKey:$urlKey is not defined');
    }

    return LibreTranslateTranslationService(
      baseUrl: url,
      apiKey: apiKey,
      logger: logger,
    );
  }
}
