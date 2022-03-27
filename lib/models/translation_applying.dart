import 'types.dart';

enum TranslationApplyingType {
  applyAll,
  discardAll,
  selectTranslations,
  cancel,
}

class TranslationApplying {
  final TranslationApplyingType type;
  final List<LanguageCode>? selectedLanguages;

  const TranslationApplying(
    this.type, {
    this.selectedLanguages,
  });
}
