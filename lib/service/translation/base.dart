import '../../models/translation.dart';
import '../../models/types.dart';

abstract class AbstractTranslationService {
  Future<String> translate(
    String source,
    LanguageCode sourceLanguage,
    LanguageCode target,
  );
}

mixin SupportsSimpleTranslationToTargetsList on AbstractTranslationService {
  Future<Translation> translateToTargetsList(
    String source,
    LanguageCode sourceLanguage,
    List<LanguageCode> targets,
  );
}

mixin SupportsBulkTranslationToSingleTarget on AbstractTranslationService {
  Future<List<String>> translateBulkToSingleTarget(
    List<String> sources,
    LanguageCode sourceLanguage,
    LanguageCode target,
  );
}

mixin SupportsBulkTranslationToTargetsList on AbstractTranslationService {
  Future<List<Translation>> translateBulk(
    List<String> sources,
    LanguageCode sourceLanguage,
    List<LanguageCode> targets,
  );
}
