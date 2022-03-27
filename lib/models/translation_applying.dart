import 'types.dart';

/// The type of applying which user selected in interactive mode
/// if application is running in non-interactive mode it's applyAll by default
enum TranslationApplyingType {
  applyAll,
  discardAll,
  selectTranslations,
  cancel,
}

/// Models how translation should be applied to given ARBItem
/// [type] - apply/discard/select
/// [selectedLanguages] - if [type] = selectTranslations, [selectTranslations]
/// will contain selected languages
class TranslationApplying {
  final TranslationApplyingType type;
  final List<LanguageCode>? selectedLanguages;

  const TranslationApplying(
    this.type, {
    this.selectedLanguages,
  });
}
