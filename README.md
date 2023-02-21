<p align="center">
    <a href="https://pub.dev/packages/flutter_arb_translator"><img src="https://img.shields.io/pub/v/flutter_arb_translator.svg" alt="Pub.dev Badge"></a>
    <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-green.svg" alt="MIT License Badge"></a>
</p>

# Flutter ARB Translator

A command line tool which simplifies translation of Flutter ARB files. You can simply choose a service from supported list: Azure Cognitive Services, Yandex, Google Cloud, DeepL and flexibly adjust translation options. [Get it on pub.dev](https://pub.dev/packages/flutter_arb_translator)

# Installing
Add `flutter_arb_translator` to your `dev_dependencies`:
```yaml
dev_dependencies:
  flutter_arb_translator: ^1.0.5
```

# Example

Using this package you can translate ARB files which contain annotations, plurals and placeholders. For example, translation of this file:
```json
{
  "appName" : "Demo app",

  "pageHomeTitle" : "Welcome {firstName}",
  "@pageHomeTitle" : {
    "description" : "Welcome message on the Home screen",
    "placeholders": {
      "firstName": {
        "type": "String",
        "example": "John Doe"
      }
    }
  },

  "pageHomeInboxCount" : "{count, plural, zero{You have no new messages} one{You have 1 new message} other{You have {count} new messages}}",
  "@pageHomeInboxCount" : {
    "description" : "New messages count on the Home screen",
    "placeholders": {
      "count": {}
    }
  },

  "pageHomeBirthday": "{sex, select, male{His birthday} female{Her birthday} other{Their birthday}}",
  "@pageHomeBirthday": {
    "description": "Birthday message on the Home screen",
    "placeholders": {
      "sex": {}
    }
  }
}
```
to Spanish will look like this (exact text depends on selected translation API):
```json
{
  "appName": "Aplicación de demostración",

  "pageHomeTitle": "Bienvenidos {firstName}",
  "@pageHomeTitle": {
    "description": "Welcome message on the Home screen",
    "placeholders": {
      "firstName": {
        "type": "String",
        "example": "John Doe"
      }
    }
  },

  "pageHomeInboxCount": "{count, plural, zero{No tienes mensajes nuevos} one{Tienes 1 mensaje nuevo} other{Has {count} nuevos mensajes}}",
  "@pageHomeInboxCount": {
    "description": "New messages count on the Home screen",
    "placeholders": {
      "count": {}
    }
  },

  "pageHomeBirthday": "{sex, select, male{Su cumpleaños} female{Su cumpleaños} other{Su cumpleaños}}",
  "@pageHomeBirthday": {
    "description": "Birthday message on the Home screen",
    "placeholders": {
      "sex": {}
    }
  }
}
```

# Guide
1. Set up the configuration file

In your project root directory create a `dev_assets` folder and create `flutter_arb_translator_config.json` there. The content of file contains optional JSON objects, see the full file example:
```json
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
Optional JSON objects means that if you are going to use Azure translation service - only `AzureCognitiveServices` block is required in configuration file while YandexCloud, GoogleCloud and DeepL objects can be dismissed.

2. Set up translation service configuration

- Azure

Azure Cognitive Services translation service uses [Subscription Key](https://docs.microsoft.com/en-us/azure/cognitive-services/authentication?tabs=powershell) for authorization in Azure API. See how to create or find your Subscription key [here](https://docs.microsoft.com/en-us/azure/cognitive-services/authentication?tabs=powershell#prerequisites). Once you got it, put it into `dev_assets/flutter_arb_translator_config.json` `AzureCognitiveServices` JSON object

- Yandex

Yandex translation service uses API key for authorization in Yandex API. See [here](https://cloud.yandex.com/en-ru/docs/iam/operations/api-key/create) how to create an API key. Once you got it, put it into `dev_assets/flutter_arb_translator_config.json` `YandexCloud` JSON object.

- Google Cloud

Google Cloud translation service uses [Service Account](https://cloud.google.com/iam/docs/service-accounts) for authorization in Google Cloud API. You will need to create a new account or use existing one and export it's Private Key in JSON format. Then put `project_id`, `private_key` and `client_email` into `dev_assets/flutter_arb_translator_config.json` `GoogleCloud` object. The only Google Cloud API scope used by this project is: [https://www.googleapis.com/auth/cloud-translation]

- DeepL

DeepL translation service uses Api Key for authorization in DeepL API. You will need to create a new DeepL account [here](https://www.deepl.com/pro-api?cta=header-pro-api) or use existing one. Once you got it, put API key into `dev_assets/flutter_arb_translator_config.json` `DeepL` JSON object. If you are going to use free DeepL API key update the `Url` value of `DeepL` configuration.

# Usage
Assuming you store ARB files in `lib/l10n` folder and want to translate `app_en.arb` into Spanish and Italian using Azure Cognitive Services translator. Run the following command:
```shell
flutter pub run flutter_arb_translator:main --from en --to es --to it --service azure
```
When command will complete, it will write `lib/l10n/app_es.arb` and `lib/l10n/app_it.arb` files containing translation. That's it, if you want to see all available options type `flutter pub run flutter_arb_translator:main -h`

### Command Line Options
Option       | Description
-------------| -------------
dir          | (optional) Directory containing .arb files. By default it is set to `lib/l10n`
service      | (required) Translation service which will be used. [`azure`, `yandex`, `google`, `deepl`]
from         | (required) Main language, ARB will be translated from this language to targets. Example usage: `--from en`
to           | (required) List of languages to which ARB should be translated. At least 1 language required. Example usage: `--to es,pt` or `--to es --to pt`
key          | (optional) If defined, only items with given keys will be translated. Example usage: `-k key1 -k key2`
ignore       | (optional) If defined, items with given keys will be skipped from translation. Example usage: `--ignore key1,key2`
override     | (optional) If true and if ARB file with defined target language already exist all items will be replaced with new translation. Otherwise, they will be not modified. By default it is set to `false`
interactive  | (optional) You will be prompted before applying translation. By default it is set to `false`
