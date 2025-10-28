Add `flutter_arb_translator` as dev dependency to your pubspec.yaml

```yaml
dev_dependencies:
  flutter_arb_translator: ^1.0.22
```

Add `dev_assets/flutter_arb_translator_config.json` to the root of your project
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
and set configuration values for service you are going to use

Run `flutter_arb_translator` tool:

```shell
flutter pub run flutter_arb_translator:main --from [sourceLanguage] --to [targetLanguage] --service [azure,yandex,google,deepl]
```
