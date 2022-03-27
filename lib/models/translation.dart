import 'types.dart';

/// Translation model
/// [source] - original text which was translated
/// [sourceLanguage] - language from which [source] was translated
/// [translations] - map with language as key and translated [source] as value
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
