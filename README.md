# Flutter ARB Translator

A command line tool which simplifies translation of Flutter ARB files. You can simply choose a service from supported list: Azure Cognitive Services, Yandex, Google Cloud, DeepL and flexibly adjust translation options. [Get it on pub.dev](https://pub.dev/packages/flutter_arb_translator)

# Installing
Add `flutter_arb_translator` to your `dev_dependencies`:
```
...
dev_dependencies:
  ...
  flutter_arb_translator: ^1.0.3
  ...
...
```

# Guide
1. Set up the configuration file

In your project root directory create a `dev_assets` folder and create `flutter_arb_translator_config.json` there. The content of file contains optional JSON objects, see the full file example:
```
{
  "AzureCognitiveServices": {
    "SubscriptionKey": "<required>",
    "Region": "<optional>"
  },
  "YandexCloud": {
    "APIKey": "<required>"
  },
  "GoogleCloud": {
    "ProjectId": "<required>",
    "PrivateKey": "<required>",
    "ClientEmail": "<required>"
  },
  "DeepL": {
    "Url": "https://api.deepl.com",
    "ApiKey": "<required>"
  }
}
```
Optional JSON objects means that if you are going to use Azure translation service - only `AzureCognitiveServices` block is required in configuration file while YandexCloud, GoogleCloud and DeepL blocks can be dismissed.

2. Set up translation service configuration

- Azure

Azure Cognitive Services translation service uses [Subscription Key](https://docs.microsoft.com/en-us/azure/cognitive-services/authentication?tabs=powershell) for authorization in Azure API. See how to create or find your Subscription key [here](https://docs.microsoft.com/en-us/azure/cognitive-services/authentication?tabs=powershell#prerequisites). Once you got it, put it into `dev_assets/flutter_arb_translator_config.json` `AzureCognitiveServices` JSON block

- Yandex

Yandex translation service uses API key for authorization in Yandex API. See [here](https://cloud.yandex.com/en-ru/docs/iam/operations/api-key/create) how to create an API key. Once you got it, put it into `dev_assets/flutter_arb_translator_config.json` `YandexCloud` JSON block.

- Google Cloud

Google Cloud translation service uses [Service Account](https://cloud.google.com/iam/docs/service-accounts) for authorization in Google Cloud API. You will need to create a new account or use existing one and export it's Private Key in JSON format. Then put `project_id`, `private_key` and `client_email` into `dev_assets/flutter_arb_translator_config.json` `GoogleCloud` block. The only Google Cloud API scope used by this project is: [https://www.googleapis.com/auth/cloud-translation]

- DeepL

DeepL translation service uses Api Key for authorization in DeepL API. You will need to create a new DeepL account [here](https://www.deepl.com/pro-api?cta=header-pro-api) or use existing one. Once you got it, put it into `dev_assets/flutter_arb_translator_config.json` `DeepL` JSON block. If you are going to use free DeepL api key update the `Url` value of `DeepL` configuration.

# Example
Assuming you store ARB files in `lib/l10n` folder and want to translate `app_en.arb` into Spanish and Italian using Azure Cognitive Services translator. Run the following command:
```
flutter pub run flutter_arb_translator:main --from en --to es --to it --service azure
```
When command will complete, it will write `lib/l10n/app_es.arb` and `lib/l10n/app_it.arb` files containing translation. That's it, if you want to see all available options type `flutter pub run flutter_arb_translator:main -h`