import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'base.dart';
import 'azure_cognitive_services.dart';
import 'yandex.dart';
import 'google_cloud.dart';

import '../log/logger.dart';

import '../../utils/extensions.dart';

enum TranslationServiceType {
  azureCognitiveServices,
  yandex,
  googleCloud,
}

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
}
