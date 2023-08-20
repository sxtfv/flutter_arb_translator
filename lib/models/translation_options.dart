import 'arb_content.dart';

/// Specifies how specific ARB items should be processed by translator
class TranslationOptions {
  // if set to true target file entries which are equal to source file entries
  // should be translated
  final bool translateEqualToSource;
  // if set to true exist file entries in target file should be translated
  final bool overrideExistEntries;
  // if not null - only items specified in this list should be translated
  final List<ARBItemKey>? keys;
  // if not null - items specified in this list should be ignored
  final List<ARBItemKey>? ignoreKeys;

  const TranslationOptions({
    this.translateEqualToSource = false,
    this.overrideExistEntries = false,
    this.keys,
    this.ignoreKeys,
  });

  /// Shortcut
  factory TranslationOptions.createDefault() {
    return TranslationOptions();
  }

  /// Overrides default key list
  TranslationOptions withKeys(List<ARBItemKey> keyList) {
    return TranslationOptions(
      translateEqualToSource: translateEqualToSource,
      overrideExistEntries: overrideExistEntries,
      keys: keyList,
      ignoreKeys: ignoreKeys,
    );
  }

  /// Overrides default ignore key list
  TranslationOptions withIgnoreKeys(List<ARBItemKey> ignoreKeyList) {
    return TranslationOptions(
      translateEqualToSource: translateEqualToSource,
      overrideExistEntries: overrideExistEntries,
      keys: keys,
      ignoreKeys: ignoreKeyList,
    );
  }

  /// Overrides default flags
  TranslationOptions withFlags({bool? translateEqual, bool? overrideExist}) {
    return TranslationOptions(
      translateEqualToSource: translateEqual ?? translateEqualToSource,
      overrideExistEntries: overrideExist ?? overrideExistEntries,
      keys: keys,
      ignoreKeys: ignoreKeys,
    );
  }
}
