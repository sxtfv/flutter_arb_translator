import '../../models/translation.dart';
import '../../models/types.dart';

/// Very simple translator
abstract class AbstractTranslationService {
  /// Translates given text to specified language
  /// [source] - text which should be translated
  /// [sourceLanguage] - the language in which [source] was given
  /// [target] - language to which [source] should be translated
  Future<String> translate(
    String source,
    LanguageCode sourceLanguage,
    LanguageCode target,
  );
}

/// Translator which supports translation to multiple languages of
/// one text at a time
mixin SupportsSimpleTranslationToTargetsList on AbstractTranslationService {
  /// Translates given text to specified languages
  /// [source] - text which should be translated
  /// [sourceLanguage] - the language in which [source] was given
  /// [targets] - list of languages to which [source] should be translated
  Future<Translation> translateToTargetsList(
    String source,
    LanguageCode sourceLanguage,
    List<LanguageCode> targets,
  );
}

/// Translator which supports translation of multiple texts to single
/// language at a time
mixin SupportsBulkTranslationToSingleTarget on AbstractTranslationService {
  /// Translates given texts to specified language
  /// [sources] - list of text which should be translated
  /// [sourceLanguage] - the language in which [sources] were given
  /// [target] - language to which [sources] should be translated
  Future<List<String>> translateBulkToSingleTarget(
    List<String> sources,
    LanguageCode sourceLanguage,
    LanguageCode target,
  );
}

/// Translator which supports translation of multiple texts to multiple
/// languages at a time
mixin SupportsBulkTranslationToTargetsList on AbstractTranslationService {
  /// Translates given texts to specified languages
  /// [sources] - list of texts which should be translated
  /// [sourceLanguage] - the language in which [sources] were given
  /// [targets] - list of languages to which [sources] should be translated
  Future<List<Translation>> translateBulk(
    List<String> sources,
    LanguageCode sourceLanguage,
    List<LanguageCode> targets,
  );
}
