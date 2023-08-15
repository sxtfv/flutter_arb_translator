import '../log/logger.dart';
import '../translation/base.dart';

import '../../utils/extensions.dart';

import '../../models/types.dart';
import '../../models/arb_content.dart';
import '../../models/arb_content_translated.dart';
import '../../models/translation.dart';

/// Used to split ARB items to sets of items which should be translated
/// to specific languages and items which should be unmodified
class _PreparedTranslationData {
  final Map<ARBItemKey, Map<LanguageCode, ARBItemTranslated>> unmodified;
  final Map<ARBItemKey, List<LanguageCode>> candidates;
  const _PreparedTranslationData(this.unmodified, this.candidates);
}

/// Used to convert ARB items which may contain plural, select, placeholders
/// to clear text. For example, "Welcome {firstName}. {count, plural,
/// zero{You have no new messages} other{You have {count} new messages}}" can
/// be converted to "Welcome {0}. {1}" where {0} is {firstName} and {1}
/// is ArbItemSpecialData
class _ARBItemWithClearText {
  final String clearText;
  final Map<String, String> placeholderReplacements;
  final Map<String, ARBItemSpecialData> pluralReplacements;
  final Map<String, ARBItemSpecialData> selectReplacements;
  final ARBItemKey key;
  final int number;
  final ARBItemAnnotation? annotation;

  const _ARBItemWithClearText({
    required this.clearText,
    required this.placeholderReplacements,
    required this.pluralReplacements,
    required this.selectReplacements,
    required this.key,
    required this.number,
    required this.annotation,
  });

  factory _ARBItemWithClearText.fromArbItem(ARBItem item) {
    String clearText = item.value;
    int replacementId = 0;
    Map<String, ARBItemSpecialData> pluralReplacements = {};
    Map<String, ARBItemSpecialData> selectReplacements = {};
    Map<String, String> placeholderReplacements = {};

    for (final plural in item.plurals) {
      clearText = clearText.replaceAll(
        plural.fullText,
        '{$replacementId}',
      );

      pluralReplacements['{$replacementId}'] = plural;
      replacementId++;
    }

    for (final select in item.selects) {
      clearText = clearText.replaceAll(
        select.fullText,
        '{$replacementId}',
      );

      selectReplacements['{$replacementId}'] = select;
      replacementId++;
    }

    final itemPlaceholders = item.annotation?.placeholders ?? [];
    for (final placeholder in itemPlaceholders) {
      clearText = clearText.replaceAll(
        '{${placeholder.key}}',
        '{$replacementId}',
      );

      placeholderReplacements['{$replacementId}'] = '{${placeholder.key}}';
      replacementId++;
    }

    return _ARBItemWithClearText(
      clearText: clearText,
      pluralReplacements: pluralReplacements,
      selectReplacements: selectReplacements,
      placeholderReplacements: placeholderReplacements,
      number: item.number,
      key: item.key,
      annotation: item.annotation,
    );
  }

  ARBItem toArbItem() {
    String resultText = clearText;

    for (final placeholderReplacement in placeholderReplacements.entries) {
      final replacementKey = placeholderReplacement.key;
      final placeholder = placeholderReplacement.value;
      resultText = resultText.replaceAll(
        replacementKey,
        placeholder,
      );
    }

    for (final selectReplacement in selectReplacements.entries) {
      final replacementKey = selectReplacement.key;
      final select = selectReplacement.value;
      resultText = resultText.replaceAll(
        replacementKey,
        select.fullText,
      );
    }

    for (final pluralReplacement in pluralReplacements.entries) {
      final replacementKey = pluralReplacement.key;
      final plural = pluralReplacement.value;
      resultText = resultText.replaceAll(
        replacementKey,
        plural.fullText,
      );
    }

    return ARBItem(
      number: number,
      key: key,
      value: resultText,
      annotation: annotation,
      plurals: pluralReplacements.values.toList(),
      selects: selectReplacements.values.toList(),
    );
  }

  bool isClearTextContainsOnlyPlaceholders() {
    if (pluralReplacements.isEmpty &&
        selectReplacements.isEmpty &&
        placeholderReplacements.isEmpty) {
      return false;
    }

    String temp = clearText;
    for (final replacement in placeholderReplacements.entries) {
      temp = temp.replaceAll(replacement.key, '');
    }

    for (final replacement in selectReplacements.entries) {
      temp = temp.replaceAll(replacement.key, '');
    }

    for (final replacement in pluralReplacements.entries) {
      temp = temp.replaceAll(replacement.key, '');
    }

    return temp.replaceAll(' ', '').isEmpty;
  }
}

/// Used to convert text like "Hello {firstName} {lastName}!"
/// to "Hello {0} {1}!" and back
class _TextWithoutAnnotation {
  final String clearText;
  final String originalText;
  final Map<String, String> replacements;

  const _TextWithoutAnnotation({
    required this.clearText,
    required this.originalText,
    required this.replacements,
  });

  factory _TextWithoutAnnotation.createFromText(
    String text,
    ARBItemAnnotation? annotation,
  ) {
    if (annotation == null) {
      return _TextWithoutAnnotation(
        clearText: text,
        originalText: text,
        replacements: {},
      );
    }

    final originalText = text;
    String clearText = text;

    final placeholders = annotation.placeholders;
    Map<String, String> replacements = {};
    int replacementId = 0;
    for (final placeholder in placeholders) {
      clearText = clearText.replaceAll(
        '{${placeholder.key}}',
        '{$replacementId}',
      );

      replacements['{$replacementId}'] = '{${placeholder.key}}';
      replacementId++;
    }

    return _TextWithoutAnnotation(
      clearText: clearText,
      originalText: originalText,
      replacements: replacements,
    );
  }

  String restorePlaceholders(String text) {
    String result = text;

    for (final replacement in replacements.entries) {
      result = result.replaceAll(
        replacement.key,
        replacement.value,
      );
    }

    return result;
  }
}

/// Public API for translation of ARB file
abstract class ARBTranslator {
  final AbstractTranslationService translationSvc;
  final ARBContent arb;
  final LanguageCode sourceLanguage;
  final Logger logger;

  /// [translationSvc] - API service which will be used for translation of items
  /// [arb] - the file content which should be translated
  /// [sourceLanguage] - the language of [arb]
  ARBTranslator({
    required this.translationSvc,
    required this.arb,
    required this.sourceLanguage,
    required this.logger,
  });

  /// [translationSvc] - API service which will be used for translation of items
  /// [arb] - the file content which should be translated
  /// [sourceLanguage] - the language of [arb]
  factory ARBTranslator.create({
    required AbstractTranslationService translationSvc,
    required ARBContent arb,
    required LanguageCode sourceLanguage,
    required Logger logger,
  }) {
    if (translationSvc is SupportsBulkTranslationToTargetsList) {
      return _ARBTranslatorSupportsBulkTranslationToMultipleTargets(
        translationSvc: translationSvc,
        arb: arb,
        sourceLanguage: sourceLanguage,
        logger: logger,
      );
    } else if (translationSvc is SupportsBulkTranslationToSingleTarget) {
      return _ARBTranslatorSupportsBulkTranslationToSingleTarget(
        translationSvc: translationSvc,
        arb: arb,
        sourceLanguage: sourceLanguage,
        logger: logger,
      );
    } else if (translationSvc is SupportsSimpleTranslationToTargetsList) {
      return _ARBTranslatorSupportsSingleTranslationToTargetsList(
        translationSvc: translationSvc,
        arb: arb,
        sourceLanguage: sourceLanguage,
        logger: logger,
      );
    } else {
      return _SlowestARBTranslator(
        translationSvc: translationSvc,
        arb: arb,
        sourceLanguage: sourceLanguage,
        logger: logger,
      );
    }
  }

  /// Returns Map of translated ARB to given [languages]
  /// [existFiles] - map of exist translations (exist entries can be skipped
  /// from translation
  /// [overrideExistEntries] if true, exist entries in [existFiles] will be
  /// replaced with new translation, otherwise they will be ignored
  /// [keys] list of ARB items keys which only should be translated (other will
  /// be ignored)
  /// [ignoreKeys] list of ARB items keys which should be not translated
  Future<Map<LanguageCode, ARBContentTranslated>> translate({
    required List<LanguageCode> languages,
    required Map<LanguageCode, ARBContent?> existFiles,
    bool overrideExistEntries = false,
    List<ARBItemKey>? keys,
    List<ARBItemKey>? ignoreKeys,
  }) async {
    logger.trace('Started translation from $sourceLanguage to $languages');
    logger.trace('Total entries count: ${arb.items.length}');

    final preparedTranslationData = _prepareTranslations(
      languages,
      existFiles,
      keys,
      ignoreKeys,
      overrideExistEntries: overrideExistEntries,
    );

    logger.trace(
        'Unmodified entries count: ${preparedTranslationData.unmodified.length}');
    logger.trace(
        'To translate entries count: ${preparedTranslationData.candidates.length}');

    final translationResult = await _translateItems(
      preparedTranslationData.candidates,
      existFiles,
    );

    final translations = _mergeTranslationData(
      preparedTranslationData.unmodified,
      translationResult,
    );

    return _convertTranslationToResults(
      translations,
      languages,
      existFiles,
    );
  }

  Future<Map<ARBItemKey, Map<LanguageCode, ARBItemTranslated>>> _translateItems(
    Map<ARBItemKey, List<LanguageCode>> candidates,
    Map<LanguageCode, ARBContent?> existFiles,
  );

  _PreparedTranslationData _prepareTranslations(
    List<LanguageCode> languages,
    Map<LanguageCode, ARBContent?> existFiles,
    List<ARBItemKey>? keys,
    List<ARBItemKey>? ignoreKeys, {
    bool overrideExistEntries = false,
  }) {
    Map<ARBItemKey, Map<LanguageCode, ARBItemTranslated>> unmodified = {};
    Map<ARBItemKey, List<LanguageCode>> candidates = {};

    for (final arbItem in arb.items) {
      unmodified[arbItem.key] = {};
      candidates[arbItem.key] = [];

      List<String> targets = [...languages];
      for (int i = 0; i < targets.length; i++) {
        final target = targets[i];

        if (keys != null && keys.contains(arbItem.key)) {
          continue;
        }

        final existTranslation =
            existFiles.lookup(target)?.findItemByKey(arbItem.key);

        if (ignoreKeys != null && ignoreKeys.contains(arbItem.key)) {
          targets.removeAt(i);
          i--;

          if (existTranslation != null) {
            unmodified[arbItem.key]![target] = ARBItemTranslated.unmodified(
              existTranslation,
              number: arbItem.number,
              annotation1: arbItem.annotation,
              plurals1: arbItem.plurals,
              selects1: arbItem.selects,
            );
          }

          continue;
        }

        if (!(overrideExistEntries ? false : existTranslation != null)) {
          if (keys != null && !keys.contains(arbItem.key)) {
            targets.removeAt(i);
            i--;
          }

          continue;
        }

        unmodified[arbItem.key]![target] = ARBItemTranslated.unmodified(
          existTranslation,
          number: arbItem.number,
          annotation1: arbItem.annotation,
          selects1: arbItem.selects,
          plurals1: arbItem.plurals,
        );

        targets.removeAt(i);
        i--;
      }

      if (targets.isEmpty) {
        candidates.remove(arbItem.key);
      } else {
        for (final target in targets) {
          candidates[arbItem.key]!.add(target);
        }
      }

      if (unmodified[arbItem.key]!.isEmpty) {
        unmodified.remove(arbItem.key);
      }
    }

    return _PreparedTranslationData(unmodified, candidates);
  }

  Map<ARBItemKey, Map<LanguageCode, ARBItemTranslated>> _mergeTranslationData(
    Map<ARBItemKey, Map<LanguageCode, ARBItemTranslated>> unmodified,
    Map<ARBItemKey, Map<LanguageCode, ARBItemTranslated>> translations,
  ) {
    Map<ARBItemKey, Map<LanguageCode, ARBItemTranslated>> result = {};

    for (final kv in unmodified.entries) {
      final itemKey = kv.key;
      result[itemKey] = {};
      for (final translation in kv.value.entries) {
        final lang = translation.key;
        final val = translation.value;
        result[itemKey]![lang] = val;
      }
    }

    for (final kv in translations.entries) {
      final itemKey = kv.key;
      if (!result.containsKey(itemKey)) {
        result[itemKey] = {};
      }

      for (final translation in kv.value.entries) {
        final lang = translation.key;
        final val = translation.value;
        if (result[itemKey]!.containsKey(lang)) {
          continue;
        }
        result[itemKey]![lang] = val;
      }
    }

    return result;
  }

  Map<LanguageCode, ARBContentTranslated> _convertTranslationToResults(
    Map<ARBItemKey, Map<LanguageCode, ARBItemTranslated>> translations,
    List<LanguageCode> languages,
    Map<LanguageCode, ARBContent?> existFiles,
  ) {
    Map<LanguageCode, ARBContentTranslated> result = {};

    for (final language in languages) {
      List<ARBItemTranslated> items = [];
      for (final item in translations.entries) {
        final arbItemTranslated = item.value.lookup(language);
        if (arbItemTranslated != null) {
          items.add(arbItemTranslated);
        }
      }

      result[language] = ARBContentTranslated(
        items,
        locale: arb.locale == null ? null : language,
        lineBreaks: arb.lineBreaks,
      );
    }

    return result;
  }
}

class _ARBTranslatorSupportsBulkTranslationToMultipleTargets
    extends ARBTranslator {
  @override
  // ignore: overridden_fields
  final SupportsBulkTranslationToTargetsList translationSvc;

  _ARBTranslatorSupportsBulkTranslationToMultipleTargets({
    required this.translationSvc,
    required ARBContent arb,
    required LanguageCode sourceLanguage,
    required Logger logger,
  }) : super(
          translationSvc: translationSvc,
          arb: arb,
          sourceLanguage: sourceLanguage,
          logger: logger,
        );

  @override
  Future<Map<ARBItemKey, Map<LanguageCode, ARBItemTranslated>>> _translateItems(
    Map<ARBItemKey, List<LanguageCode>> candidates,
    Map<LanguageCode, ARBContent?> existFiles,
  ) async {
    Map<ARBItemKey, Map<LanguageCode, ARBItemTranslated>> result = {};
    if (candidates.isEmpty) {
      return result;
    }

    final keys = candidates.keys.toList();
    final targets = candidates.values.selectMany((x) => x).toSet().toList();
    final items = keys.map((x) => arb.findItemByKey(x)!).toList(
          growable: false,
        );
    logger.info('translate bulk ${candidates.length} items to $targets');
    final toTranslateItems = <ARBItem>[];

    for (final item in items) {
      final clearItem = _ARBItemWithClearText.fromArbItem(item);
      if (clearItem.clearText.isEmpty) {
        _processEmptyItem(result, item, clearItem, targets, existFiles);
      } else {
        toTranslateItems.add(item);
      }
    }

    for (final pack in toTranslateItems.pack(10)) {
      final clearItems = pack.map(_ARBItemWithClearText.fromArbItem).toList();
      final texts = clearItems.map((x) => x.clearText).toList();

      final textTranslations = await translationSvc.translateBulk(
        texts,
        sourceLanguage,
        targets,
      );

      for (int i = 0; i < pack.length; i++) {
        final item = clearItems[i];
        result[item.key] = {};
        final itemTargets = candidates.lookup(item.key)!;

        final itemTextTranslation = item.isClearTextContainsOnlyPlaceholders()
            ? Translation(
                source: item.clearText,
                sourceLanguage: sourceLanguage,
                translations:
                    itemTargets.map((x) => MapEntry(x, item.clearText)).toMap(),
              )
            : textTranslations[i];

        final translatedSelectReplacements =
            await _translateSpecialDataReplacement(
          item,
          item.selectReplacements,
          itemTargets,
          ARBItemSpecialDataType.select,
        );

        final translatedPluralReplacements =
            await _translateSpecialDataReplacement(
          item,
          item.pluralReplacements,
          itemTargets,
          ARBItemSpecialDataType.plural,
        );

        for (final target in itemTargets) {
          final translatedText = itemTextTranslation.translations[target]!;

          final selectReplacements = translatedSelectReplacements.map(
            (k, v) => MapEntry(
              k,
              translatedSelectReplacements[k]!.lookup(target) ?? v[target]!,
            ),
          );

          final pluralReplacements = translatedPluralReplacements.map(
            (k, v) => MapEntry(
              k,
              translatedPluralReplacements[k]!.lookup(target) ?? v[target]!,
            ),
          );

          final placeholderReplacements = item.placeholderReplacements;

          final newItem = _ARBItemWithClearText(
            key: item.key,
            number: item.number,
            annotation: item.annotation,
            clearText: translatedText,
            placeholderReplacements: placeholderReplacements,
            pluralReplacements: pluralReplacements,
            selectReplacements: selectReplacements,
          ).toArbItem();

          final existItem =
              existFiles.lookup(target)?.findItemByKey(newItem.key);

          result[item.key]![target] = existItem == null
              ? ARBItemTranslated.added(
                  key: newItem.key,
                  number: newItem.number,
                  value: newItem.value,
                  annotation: newItem.annotation,
                  plurals: newItem.plurals,
                  selects: newItem.selects,
                )
              : ARBItemTranslated.edited(
                  key: newItem.key,
                  number: newItem.number,
                  value: newItem.value,
                  originalValue: existItem.value,
                  annotation: newItem.annotation,
                  plurals: newItem.plurals,
                  selects: newItem.selects,
                );
        }
      }
    }

    return result;
  }

  void _processEmptyItem(
    Map<ARBItemKey, Map<LanguageCode, ARBItemTranslated>> result,
    ARBItem item,
    _ARBItemWithClearText clearItem,
    List<LanguageCode> targets,
    Map<LanguageCode, ARBContent?> existFiles,
  ) {
    result[item.key] = {};

    for (final target in targets) {
      final newItem = _ARBItemWithClearText(
        key: item.key,
        number: item.number,
        annotation: item.annotation,
        clearText: '',
        placeholderReplacements: clearItem.placeholderReplacements,
        pluralReplacements: clearItem.pluralReplacements,
        selectReplacements: clearItem.selectReplacements,
      ).toArbItem();

      final existItem = existFiles.lookup(target)?.findItemByKey(newItem.key);

      result[item.key]![target] = existItem == null
          ? ARBItemTranslated.added(
              key: newItem.key,
              number: newItem.number,
              value: newItem.value,
              annotation: newItem.annotation,
              plurals: newItem.plurals,
              selects: newItem.selects,
            )
          : ARBItemTranslated.edited(
              key: newItem.key,
              number: newItem.number,
              value: newItem.value,
              originalValue: existItem.value,
              annotation: newItem.annotation,
              plurals: newItem.plurals,
              selects: newItem.selects,
            );
    }
  }

  Future<Map<String, Map<LanguageCode, ARBItemSpecialData>>>
      _translateSpecialDataReplacement(
    _ARBItemWithClearText item,
    Map<String, ARBItemSpecialData> specialDataReplacement,
    List<LanguageCode> targets,
    ARBItemSpecialDataType type,
  ) async {
    Map<String, Map<LanguageCode, ARBItemSpecialData>> result = {};

    for (final replacement in specialDataReplacement.entries) {
      final replacementId = replacement.key;
      final replacementDataKey = replacement.value.key;
      final options = replacement.value.options;

      final optionTextsClear = options
          .map((x) => x.text)
          .map((x) => _TextWithoutAnnotation.createFromText(x, item.annotation))
          .map((x) => MapEntry(x, x.originalText))
          .toMap();

      final emptyOptions =
          optionTextsClear.keys.where((x) => x.clearText.isEmpty).toList();

      final optionTranslations = await translationSvc.translateBulk(
        optionTextsClear.keys
            .where((x) => !emptyOptions.contains(x))
            .map((x) => x.clearText)
            .toList(),
        sourceLanguage,
        targets,
      );

      Map<LanguageCode, List<ARBItemSpecialDataOption>> translatedOptions = {};

      for (final key in emptyOptions) {
        final option =
            options.firstWhere((x) => x.text == optionTextsClear[key]!);

        for (final target in targets) {
          if (!translatedOptions.containsKey(target)) {
            translatedOptions[target] = [];
          }

          translatedOptions[target]!.add(
            ARBItemSpecialDataOption(
              option.key,
              key.restorePlaceholders(''),
            ),
          );
        }
      }

      for (final optionTranslation in optionTranslations) {
        final clearKey = optionTextsClear.keys
            .firstWhere((x) => x.clearText == optionTranslation.source);
        final originalText = optionTextsClear[clearKey]!;
        final option = options.firstWhere((x) => x.text == originalText);

        for (final translation in optionTranslation.translations.entries) {
          if (!translatedOptions.containsKey(translation.key)) {
            translatedOptions[translation.key] = [];
          }

          translatedOptions[translation.key]!.add(
            ARBItemSpecialDataOption(
              option.key,
              clearKey.restorePlaceholders(translation.value),
            ),
          );
        }
      }

      result[replacementId] = translatedOptions.map(
        (key, value) => MapEntry(
          key,
          ARBItemSpecialData(
            key: replacementDataKey,
            type: type,
            options: value,
          ),
        ),
      );
    }

    return result;
  }
}

class _ARBTranslatorSupportsBulkTranslationToSingleTarget
    extends ARBTranslator {
  @override
  // ignore: overridden_fields
  final SupportsBulkTranslationToSingleTarget translationSvc;

  _ARBTranslatorSupportsBulkTranslationToSingleTarget({
    required this.translationSvc,
    required ARBContent arb,
    required LanguageCode sourceLanguage,
    required Logger logger,
  }) : super(
          translationSvc: translationSvc,
          arb: arb,
          sourceLanguage: sourceLanguage,
          logger: logger,
        );

  @override
  Future<Map<ARBItemKey, Map<LanguageCode, ARBItemTranslated>>> _translateItems(
    Map<ARBItemKey, List<LanguageCode>> candidates,
    Map<LanguageCode, ARBContent?> existFiles,
  ) async {
    Map<ARBItemKey, Map<LanguageCode, ARBItemTranslated>> result = {};
    if (candidates.isEmpty) {
      return result;
    }

    final keys = candidates.keys.toList();
    final targets = candidates.values.selectMany((x) => x).toSet().toList();
    final items = keys.map((x) => arb.findItemByKey(x)!).toList(
          growable: false,
        );
    logger.info('translate $keys to $targets by single lang');

    final toTranslateItems = <ARBItem>[];

    for (final item in items) {
      final clearItem = _ARBItemWithClearText.fromArbItem(item);
      if (clearItem.clearText.isEmpty) {
        _processEmptyItem(result, item, clearItem, targets, existFiles);
      } else {
        toTranslateItems.add(item);
      }
    }

    final packs = toTranslateItems.pack(10);
    for (final target in targets) {
      for (int i = 0; i < packs.length; i++) {
        final pack = packs[i];
        final clearItems = pack.map(_ARBItemWithClearText.fromArbItem).toList();
        final texts = clearItems.map((x) => x.clearText).toList();

        final textTranslations =
            await translationSvc.translateBulkToSingleTarget(
          texts,
          sourceLanguage,
          target,
        );

        for (int j = 0; j < pack.length; j++) {
          final item = clearItems[j];
          final itemTargets = candidates.lookup(item.key)!;

          if (!itemTargets.contains(target)) {
            logger.info('Item ${item.key} should not be translated to $target');
            continue;
          }

          final textTranslation = item.isClearTextContainsOnlyPlaceholders()
              ? item.clearText
              : textTranslations[j];

          if (!result.containsKey(item.key)) {
            result[item.key] = {};
          }

          final translatedSelectReplacements =
              await _translateItemSpecialDataReplacement(
            item,
            item.selectReplacements,
            target,
            ARBItemSpecialDataType.select,
          );

          final translatedPluralReplacements =
              await _translateItemSpecialDataReplacement(
            item,
            item.pluralReplacements,
            target,
            ARBItemSpecialDataType.plural,
          );

          final placeholderReplacements = item.placeholderReplacements;

          final newItem = _ARBItemWithClearText(
            key: item.key,
            number: item.number,
            annotation: item.annotation,
            clearText: textTranslation,
            placeholderReplacements: placeholderReplacements,
            pluralReplacements: translatedPluralReplacements,
            selectReplacements: translatedSelectReplacements,
          ).toArbItem();

          final existItem =
              existFiles.lookup(target)?.findItemByKey(newItem.key);

          result[item.key]![target] = existItem == null
              ? ARBItemTranslated.added(
                  key: newItem.key,
                  number: newItem.number,
                  value: newItem.value,
                  annotation: newItem.annotation,
                  plurals: newItem.plurals,
                  selects: newItem.selects,
                )
              : ARBItemTranslated.edited(
                  key: newItem.key,
                  number: newItem.number,
                  value: newItem.value,
                  originalValue: existItem.value,
                  annotation: newItem.annotation,
                  plurals: newItem.plurals,
                  selects: newItem.selects,
                );
        }
      }
    }

    return result;
  }

  void _processEmptyItem(
    Map<ARBItemKey, Map<LanguageCode, ARBItemTranslated>> result,
    ARBItem item,
    _ARBItemWithClearText clearItem,
    List<LanguageCode> targets,
    Map<LanguageCode, ARBContent?> existFiles,
  ) {
    result[item.key] = {};

    for (final target in targets) {
      final newItem = _ARBItemWithClearText(
        key: item.key,
        number: item.number,
        annotation: item.annotation,
        clearText: '',
        placeholderReplacements: clearItem.placeholderReplacements,
        pluralReplacements: clearItem.pluralReplacements,
        selectReplacements: clearItem.selectReplacements,
      ).toArbItem();

      final existItem = existFiles.lookup(target)?.findItemByKey(newItem.key);

      result[item.key]![target] = existItem == null
          ? ARBItemTranslated.added(
              key: newItem.key,
              number: newItem.number,
              value: newItem.value,
              annotation: newItem.annotation,
              plurals: newItem.plurals,
              selects: newItem.selects,
            )
          : ARBItemTranslated.edited(
              key: newItem.key,
              number: newItem.number,
              value: newItem.value,
              originalValue: existItem.value,
              annotation: newItem.annotation,
              plurals: newItem.plurals,
              selects: newItem.selects,
            );
    }
  }

  Future<Map<String, ARBItemSpecialData>> _translateItemSpecialDataReplacement(
    _ARBItemWithClearText item,
    Map<String, ARBItemSpecialData> specialDataReplacement,
    LanguageCode target,
    ARBItemSpecialDataType type,
  ) async {
    Map<String, ARBItemSpecialData> result = {};

    for (final replacement in specialDataReplacement.entries) {
      final replacementId = replacement.key;
      final replacementDataKey = replacement.value.key;
      final options = replacement.value.options;

      final optionTextsClear = options
          .map((x) => x.text)
          .map((x) => _TextWithoutAnnotation.createFromText(x, item.annotation))
          .map((x) => MapEntry(x, x.originalText))
          .toMap();

      final emptyOptions =
          optionTextsClear.keys.where((x) => x.clearText.isEmpty).toList();

      final clearTexts = optionTextsClear.keys
          .where((x) => !emptyOptions.contains(x))
          .map((x) => x.clearText)
          .toList();

      final optionTranslations =
          await translationSvc.translateBulkToSingleTarget(
        clearTexts,
        sourceLanguage,
        target,
      );

      List<ARBItemSpecialDataOption> translatedOptions = [];

      for (final key in emptyOptions) {
        final option =
            options.firstWhere((x) => x.text == optionTextsClear[key]!);

        translatedOptions.add(
          ARBItemSpecialDataOption(
            option.key,
            key.restorePlaceholders(''),
          ),
        );
      }

      for (int i = 0; i < optionTranslations.length; i++) {
        final translation = optionTranslations[i];
        final clearText = clearTexts[i];
        final clearKey =
            optionTextsClear.keys.firstWhere((x) => x.clearText == clearText);
        final originalText = optionTextsClear[clearKey]!;
        final option = options.firstWhere((x) => x.text == originalText);

        translatedOptions.add(
          ARBItemSpecialDataOption(
            option.key,
            clearKey.restorePlaceholders(translation),
          ),
        );
      }

      result[replacementId] = ARBItemSpecialData(
        key: replacementDataKey,
        type: type,
        options: translatedOptions,
      );
    }

    return result;
  }
}

class _ARBTranslatorSupportsSingleTranslationToTargetsList
    extends ARBTranslator {
  @override
  // ignore: overridden_fields
  final SupportsSimpleTranslationToTargetsList translationSvc;

  _ARBTranslatorSupportsSingleTranslationToTargetsList({
    required this.translationSvc,
    required ARBContent arb,
    required LanguageCode sourceLanguage,
    required Logger logger,
  }) : super(
          translationSvc: translationSvc,
          arb: arb,
          sourceLanguage: sourceLanguage,
          logger: logger,
        );

  @override
  Future<Map<ARBItemKey, Map<LanguageCode, ARBItemTranslated>>> _translateItems(
    Map<ARBItemKey, List<LanguageCode>> candidates,
    Map<LanguageCode, ARBContent?> existFiles,
  ) async {
    Map<ARBItemKey, Map<LanguageCode, ARBItemTranslated>> result = {};
    if (candidates.isEmpty) {
      return result;
    }

    final keys = candidates.keys.toList();
    final items = keys.map((x) => arb.findItemByKey(x)!).toList();
    final clearItems = items.map(_ARBItemWithClearText.fromArbItem).toList();
    logger.info('Translate $keys by simple to targets list');

    for (final item in clearItems) {
      result[item.key] = {};
      final itemTargets = candidates.lookup(item.key)!;
      logger.info('Translate ${item.key} to $itemTargets');

      final itemTextTranslation =
          item.isClearTextContainsOnlyPlaceholders() || item.clearText.isEmpty
              ? Translation(
                  source: item.clearText,
                  sourceLanguage: sourceLanguage,
                  translations: itemTargets
                      .map((x) => MapEntry(x, item.clearText))
                      .toMap(),
                )
              : await translationSvc.translateToTargetsList(
                  item.clearText,
                  sourceLanguage,
                  itemTargets,
                );

      final translatedSelectReplacements =
          await _translateItemSpecialDataReplacement(
        item,
        item.selectReplacements,
        itemTargets,
        ARBItemSpecialDataType.select,
      );

      final translatedPluralReplacements =
          await _translateItemSpecialDataReplacement(
        item,
        item.pluralReplacements,
        itemTargets,
        ARBItemSpecialDataType.plural,
      );

      for (final target in itemTargets) {
        final translatedText = itemTextTranslation.translations[target]!;

        final selectReplacements = translatedSelectReplacements.map(
          (k, v) => MapEntry(
            k,
            translatedSelectReplacements[k]!.lookup(target) ?? v[target]!,
          ),
        );

        final pluralReplacements = translatedPluralReplacements.map(
          (k, v) => MapEntry(
            k,
            translatedPluralReplacements[k]!.lookup(target) ?? v[target]!,
          ),
        );

        final placeholderReplacements = item.placeholderReplacements;

        final newItem = _ARBItemWithClearText(
          clearText: translatedText,
          placeholderReplacements: placeholderReplacements,
          pluralReplacements: pluralReplacements,
          selectReplacements: selectReplacements,
          number: item.number,
          key: item.key,
          annotation: item.annotation,
        ).toArbItem();

        final existItem = existFiles.lookup(target)?.findItemByKey(newItem.key);

        result[item.key]![target] = existItem == null
            ? ARBItemTranslated.added(
                key: newItem.key,
                number: newItem.number,
                value: newItem.value,
                annotation: newItem.annotation,
                plurals: newItem.plurals,
                selects: newItem.selects,
              )
            : ARBItemTranslated.edited(
                key: newItem.key,
                number: newItem.number,
                value: newItem.value,
                originalValue: existItem.value,
                annotation: newItem.annotation,
                plurals: newItem.plurals,
                selects: newItem.selects,
              );
      }
    }

    return result;
  }

  Future<Map<String, Map<LanguageCode, ARBItemSpecialData>>>
      _translateItemSpecialDataReplacement(
    _ARBItemWithClearText item,
    Map<String, ARBItemSpecialData> specialDataReplacement,
    List<LanguageCode> targets,
    ARBItemSpecialDataType type,
  ) async {
    Map<String, Map<LanguageCode, ARBItemSpecialData>> result = {};

    for (final replacement in specialDataReplacement.entries) {
      final replacementId = replacement.key;
      final replacementDataKey = replacement.value.key;
      final options = replacement.value.options;

      final optionTextsClear = options
          .map((x) => x.text)
          .map((x) => _TextWithoutAnnotation.createFromText(x, item.annotation))
          .map((x) => MapEntry(x, x.originalText))
          .toMap();

      final clearTexts = optionTextsClear.keys.map((x) => x.clearText).toList();

      List<Translation> optionTranslations = [];
      for (final optionClearText in clearTexts) {
        if (optionClearText.isEmpty) {
          optionTranslations.add(Translation.forEmptySource(
            sourceLanguage,
            targets,
          ));
          continue;
        }

        final translation = await translationSvc.translateToTargetsList(
          optionClearText,
          sourceLanguage,
          targets,
        );
        optionTranslations.add(translation);
      }

      Map<LanguageCode, List<ARBItemSpecialDataOption>> translatedOptions = {};

      for (final optionTranslation in optionTranslations) {
        final clearKey = optionTextsClear.keys
            .firstWhere((x) => x.clearText == optionTranslation.source);
        final originalText = optionTextsClear[clearKey]!;
        final option = options.firstWhere((x) => x.text == originalText);

        for (final translation in optionTranslation.translations.entries) {
          if (!translatedOptions.containsKey(translation.key)) {
            translatedOptions[translation.key] = [];
          }

          translatedOptions[translation.key]!.add(
            ARBItemSpecialDataOption(
              option.key,
              clearKey.restorePlaceholders(translation.value),
            ),
          );
        }
      }

      result[replacementId] = translatedOptions.map(
        (key, value) => MapEntry(
          key,
          ARBItemSpecialData(
            key: replacementDataKey,
            type: type,
            options: value,
          ),
        ),
      );
    }

    return result;
  }
}

class _SlowestARBTranslator extends ARBTranslator {
  _SlowestARBTranslator({
    required AbstractTranslationService translationSvc,
    required ARBContent arb,
    required LanguageCode sourceLanguage,
    required Logger logger,
  }) : super(
          translationSvc: translationSvc,
          arb: arb,
          sourceLanguage: sourceLanguage,
          logger: logger,
        );

  @override
  Future<Map<ARBItemKey, Map<LanguageCode, ARBItemTranslated>>> _translateItems(
    Map<ARBItemKey, List<LanguageCode>> candidates,
    Map<LanguageCode, ARBContent?> existFiles,
  ) async {
    Map<ARBItemKey, Map<LanguageCode, ARBItemTranslated>> result = {};
    if (candidates.isEmpty) {
      return result;
    }

    final keys = candidates.keys.toList();
    final items = keys.map((x) => arb.findItemByKey(x)!).toList();
    final clearItems = items.map(_ARBItemWithClearText.fromArbItem).toList();
    logger.info('Translate $keys using slowest translator');

    for (final item in clearItems) {
      result[item.key] = {};
      final itemTargets = candidates.lookup(item.key)!;
      logger.info('Translate ${item.key} to $itemTargets');

      final itemTextTranslation =
          item.isClearTextContainsOnlyPlaceholders() || item.clearText.isEmpty
              ? Translation(
                  source: item.clearText,
                  sourceLanguage: sourceLanguage,
                  translations: itemTargets
                      .map((x) => MapEntry(x, item.clearText))
                      .toMap(),
                )
              : await _translateText(
                  item.clearText,
                  sourceLanguage,
                  itemTargets,
                );

      final translatedSelectReplacements =
          await _translateItemSpecialDataReplacement(
        item,
        item.selectReplacements,
        itemTargets,
        ARBItemSpecialDataType.select,
      );

      final translatedPluralReplacements =
          await _translateItemSpecialDataReplacement(
        item,
        item.pluralReplacements,
        itemTargets,
        ARBItemSpecialDataType.plural,
      );

      for (final target in itemTargets) {
        final translatedText = itemTextTranslation.translations[target]!;

        final selectReplacements = translatedSelectReplacements.map(
          (k, v) => MapEntry(
            k,
            translatedSelectReplacements[k]!.lookup(target) ?? v[target]!,
          ),
        );

        final pluralReplacements = translatedPluralReplacements.map(
          (k, v) => MapEntry(
            k,
            translatedPluralReplacements[k]!.lookup(target) ?? v[target]!,
          ),
        );

        final placeholderReplacements = item.placeholderReplacements;

        final newItem = _ARBItemWithClearText(
          clearText: translatedText,
          placeholderReplacements: placeholderReplacements,
          pluralReplacements: pluralReplacements,
          selectReplacements: selectReplacements,
          number: item.number,
          key: item.key,
          annotation: item.annotation,
        ).toArbItem();

        final existItem = existFiles.lookup(target)?.findItemByKey(newItem.key);

        result[item.key]![target] = existItem == null
            ? ARBItemTranslated.added(
                key: newItem.key,
                number: newItem.number,
                value: newItem.value,
                annotation: newItem.annotation,
                plurals: newItem.plurals,
                selects: newItem.selects,
              )
            : ARBItemTranslated.edited(
                key: newItem.key,
                number: newItem.number,
                value: newItem.value,
                originalValue: existItem.value,
                annotation: newItem.annotation,
                plurals: newItem.plurals,
                selects: newItem.selects,
              );
      }
    }

    return result;
  }

  Future<Map<String, Map<LanguageCode, ARBItemSpecialData>>>
      _translateItemSpecialDataReplacement(
    _ARBItemWithClearText item,
    Map<String, ARBItemSpecialData> specialDataReplacement,
    List<LanguageCode> targets,
    ARBItemSpecialDataType type,
  ) async {
    Map<String, Map<LanguageCode, ARBItemSpecialData>> result = {};

    for (final replacement in specialDataReplacement.entries) {
      final replacementId = replacement.key;
      final replacementDataKey = replacement.value.key;
      final options = replacement.value.options;

      final optionTextsClear = options
          .map((x) => x.text)
          .map((x) => _TextWithoutAnnotation.createFromText(x, item.annotation))
          .map((x) => MapEntry(x, x.originalText))
          .toMap();

      final clearTexts = optionTextsClear.keys.map((x) => x.clearText).toList();

      List<Translation> optionTranslations = [];
      for (final optionClearText in clearTexts) {
        if (optionClearText.isEmpty) {
          optionTranslations.add(Translation.forEmptySource(
            sourceLanguage,
            targets,
          ));
          continue;
        }

        final translation = await _translateText(
          optionClearText,
          sourceLanguage,
          targets,
        );
        optionTranslations.add(translation);
      }

      Map<LanguageCode, List<ARBItemSpecialDataOption>> translatedOptions = {};

      for (final optionTranslation in optionTranslations) {
        final clearKey = optionTextsClear.keys
            .firstWhere((x) => x.clearText == optionTranslation.source);
        final originalText = optionTextsClear[clearKey]!;
        final option = options.firstWhere((x) => x.text == originalText);

        for (final translation in optionTranslation.translations.entries) {
          if (!translatedOptions.containsKey(translation.key)) {
            translatedOptions[translation.key] = [];
          }

          translatedOptions[translation.key]!.add(
            ARBItemSpecialDataOption(
              option.key,
              clearKey.restorePlaceholders(translation.value),
            ),
          );
        }
      }

      result[replacementId] = translatedOptions.map(
        (key, value) => MapEntry(
          key,
          ARBItemSpecialData(
            key: replacementDataKey,
            type: type,
            options: value,
          ),
        ),
      );
    }

    return result;
  }

  Future<Translation> _translateText(
    String source,
    LanguageCode sourceLanguage,
    List<LanguageCode> targets,
  ) async {
    Map<LanguageCode, String> translations = {};

    for (final target in targets) {
      translations[target] = await translationSvc.translate(
        source,
        sourceLanguage,
        target,
      );
    }

    return Translation(
      source: source,
      sourceLanguage: sourceLanguage,
      translations: translations,
    );
  }
}
