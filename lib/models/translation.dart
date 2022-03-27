import 'types.dart';

class Translation {
  final String source;
  final LanguageCode sourceLanguage;
  final Map<LanguageCode, String> translations;

  const Translation({
    required this.source,
    required this.sourceLanguage,
    required this.translations,
  });
}
