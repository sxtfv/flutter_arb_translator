import 'dart:convert';
import 'dart:io';

import '../../models/arb_content.dart';
import '../../models/arb_content_translated.dart';
import '../../models/translation_applying.dart';
import '../../models/types.dart';

import '../../utils/extensions.dart';

import '../../service/log/logger.dart';

class ARBTranslationApplier {
  final ARBContent original;
  final LanguageCode originalLocale;
  final List<LanguageCode> translationTargets;
  final Map<LanguageCode, ARBContentTranslated> translations;
  final Map<LanguageCode, ARBContent?> originals;
  final Logger logger;

  int _currentItemIndex = 0;
  final int _itemsCount;
  final Map<LanguageCode, List<ARBItem>> _resultItems;
  final Map<LanguageCode, List<ARBItemKey>> _visitedKeys;

  ARBTranslationApplier({
    required this.original,
    required this.originalLocale,
    required this.translationTargets,
    required this.translations,
    required this.originals,
    required this.logger,
  })  : _itemsCount = original.items.length,
        _resultItems =
            translationTargets.map((x) => MapEntry(x, <ARBItem>[])).toMap(),
        _visitedKeys =
            translationTargets.map((x) => MapEntry(x, <ARBItemKey>[])).toMap();

  bool get canMoveNext => _currentItemIndex < _itemsCount;

  ARBItem get currentItem => original.items[_currentItemIndex];

  void stdoutCurrentChange() {
    final currentTranslations = _getCurrentTranslations();
    final allUnmodified = currentTranslations.entries
        .where((x) => x.value != null)
        .all((x) =>
            x.value!.modificationType == ARBItemModificationType.unmodified);

    if (currentTranslations.isEmpty || allUnmodified) {
      return;
    }

    const divider =
        '==============================================================';
    const green = '32';
    const yellow = '33';
    const blue = '34';

    final msg = StringBuffer();

    void startColor(String color) => msg.write('\x1B[${color}m');
    void endColor() => msg.write('\x1B[0m');

    msg.writeln(divider);
    msg.writeln(currentItem.key);
    msg.writeln('[$originalLocale] [SRC]: "${currentItem.value}"');

    for (final kv in currentTranslations.entries) {
      final lang = kv.key;
      final translation = kv.value;

      if (translation == null) {
        continue;
      }

      msg.write('[$lang]');
      msg.write(' ');
      final modificationType = translation.modificationType;
      final modificationTypeStr = _formatModificationType(
        modificationType,
      );
      msg.write('[$modificationTypeStr]');
      msg.write(': ');

      switch (modificationType) {
        case ARBItemModificationType.unmodified:
          startColor(blue);
          msg.write('"${translation.value}"');
          endColor();
          break;
        case ARBItemModificationType.edited:
          startColor(yellow);
          msg.write('"${translation.originalValue!}"');
          msg.write(' -> ');
          msg.write('"${translation.value}"');
          endColor();
          break;
        case ARBItemModificationType.added:
          startColor(green);
          msg.write('"${translation.value}"');
          endColor();
      }

      msg.writeln();
    }

    stdout.writeln(msg.toString());
  }

  void processCurrentChange(TranslationApplying applying) {
    switch (applying.type) {
      case TranslationApplyingType.applyAll:
        _applyCurrentChangeFull();
        break;
      case TranslationApplyingType.discardAll:
        _discardCurrentChangeFull();
        break;
      case TranslationApplyingType.selectTranslations:
        final languages = applying.selectedLanguages ?? [];
        _applyCurrentChangeForSelectedLanguages(languages);
        break;
      case TranslationApplyingType.cancel:
        return;
    }
  }

  void _applyCurrentChangeFull() {
    final currentTranslations = _getCurrentTranslations();
    logger.info('Will fully apply current change');

    for (final kv in currentTranslations.entries) {
      final locale = kv.key;
      final translation = kv.value;

      if (translation == null) {
        continue;
      }

      _visitedKeys[locale]!.add(translation.key);
      logger.info('Apply ${translation.key} for $locale');

      _resultItems[locale]!.add(ARBItem(
        key: translation.key,
        number: translation.number,
        value: translation.value,
        annotation: translation.annotation,
        plurals: translation.plurals,
        selects: translation.selects,
      ));
    }
  }

  void _discardCurrentChangeFull() {
    logger.info('Will fully discard current change');
    final itemKey = currentItem.key;

    for (final target in translationTargets) {
      _visitedKeys[target]!.add(itemKey);
      logger.info('Discard $itemKey for $target');

      final original = originals.lookup(target)?.findItemByKey(itemKey);
      if (original == null) {
        continue;
      }

      _resultItems[target]!.add(original);
    }
  }

  void _applyCurrentChangeForSelectedLanguages(List<String> languages) {
    final currentTranslations = _getCurrentTranslations();
    logger.info('Will apply current change for languages $languages');

    for (final kv in currentTranslations.entries) {
      final locale = kv.key;
      final translation = kv.value;

      if (translation == null) {
        continue;
      }

      _visitedKeys[locale]!.add(translation.key);

      if (languages.contains(locale)) {
        logger.info('Apply translation for ${translation.key} to $locale');
        _resultItems[locale]!.add(ARBItem(
          key: translation.key,
          number: translation.number,
          value: translation.value,
          annotation: translation.annotation,
          plurals: translation.plurals,
          selects: translation.selects,
        ));
      } else {
        logger.info('Discard translation for ${translation.key} to $locale');

        final original =
            originals.lookup(locale)?.findItemByKey(translation.key);

        if (original == null) {
          continue;
        }

        _resultItems[locale]!.add(ARBItem(
          key: original.key,
          number: original.number,
          value: original.value,
          annotation: original.annotation,
          plurals: original.plurals,
          selects: original.selects,
        ));
      }
    }
  }

  void requestApplyCurrentTranslationConfirmation() {
    stdout.writeln('Would you like to apply this translation? [Y/N/S/C]');
    stdout.writeln('[Y] - yes, apply all');
    stdout.writeln('[N] - no, discard all (default)');
    stdout.writeln('[S] - select translations to apply. Example: S es,it');
    stdout.writeln('[C] - cancel all, all changes will be discarded and files '
        'will be not modified');
  }

  TranslationApplying readTranslationApplyFromConsole() {
    final line = stdin.readLineSync(encoding: Encoding.getByName('utf-8')!);

    if (line == null || line.isEmpty) {
      logger.warning('Line is empty. Will discard current translation '
          '${currentItem.key}');

      return TranslationApplying(
        TranslationApplyingType.discardAll,
      );
    }

    final firstChar = line[0].toLowerCase();

    switch (firstChar) {
      case 'y':
        return TranslationApplying(
          TranslationApplyingType.applyAll,
        );
      case 'n':
        return TranslationApplying(
          TranslationApplyingType.discardAll,
        );
      case 's':
        final selectedLanguagesStr = line.replaceFirst(firstChar, '').trim();
        final selectedLanguages =
            selectedLanguagesStr.split(',').map((x) => x.trim()).toList();
        if (selectedLanguages.isEmpty) {
          logger.warning('Select mode but language list is empty $line '
              '${currentItem.key}');
        }
        return TranslationApplying(
          TranslationApplyingType.selectTranslations,
          selectedLanguages: selectedLanguages,
        );
      case 'c':
        return TranslationApplying(
          TranslationApplyingType.cancel,
        );
      default:
        logger.warning('Unsupported apply mode $line');
        return TranslationApplying(
          TranslationApplyingType.discardAll,
        );
    }
  }

  void moveNext() {
    if (!canMoveNext) {
      return;
    }

    _currentItemIndex++;
  }

  Map<String, ARBContent> getResults() {
    for (final target in translationTargets) {
      final originalARB = originals[target];
      if (originalARB == null) {
        continue;
      }

      for (final item in originalARB.items) {
        if (!_visitedKeys[target]!.contains(item.key)) {
          _resultItems[target]!.add(ARBItem(
            number: item.number,
            key: item.key,
            value: item.value,
            annotation: item.annotation,
            plurals: item.plurals,
            selects: item.selects,
          ));
          _visitedKeys[target]!.add(item.key);
        }
      }
    }

    Map<String, ARBContent> result = {};
    for (final target in translationTargets) {
      final items = _resultItems[target]!;
      final translatedARB = translations.lookup(target);
      final originalARB = originals.lookup(target);
      final lineBreaks = translatedARB == null
          ? originalARB == null
              ? original.lineBreaks
              : originalARB.lineBreaks
          : translatedARB.lineBreaks;
      result[target] = ARBContent(
        items,
        lineBreaks: lineBreaks,
        locale: original.locale == null ? null : translatedARB?.locale,
      );
    }

    return result;
  }

  Map<String, ARBItemTranslated?> _getCurrentTranslations() {
    final itemKey = currentItem.key;
    Map<String, ARBItemTranslated?> result = {};
    for (final lang in translationTargets) {
      result[lang] = translations.lookup(lang)?.findItemByKey(itemKey);
    }
    return result;
  }

  String _formatModificationType(ARBItemModificationType type) {
    switch (type) {
      case ARBItemModificationType.added:
        return 'ADD';
      case ARBItemModificationType.edited:
        return 'EDT';
      case ARBItemModificationType.unmodified:
        return 'UMD';
    }
  }
}
