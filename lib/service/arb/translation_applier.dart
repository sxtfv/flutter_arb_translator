import 'dart:io';

import '../../models/arb_content.dart';
import '../../models/arb_content_translated.dart';

import '../../utils/extensions.dart';

class ARBTranslationApplier {
  final ARBContent original;
  final String originalLocale;
  final List<String> translationTargets;
  final Map<String, ARBContentTranslated> translations;
  final Map<String, ARBContent?> originals;

  int _currentItemIndex = 0;
  final int _itemsCount;
  Map<String, List<ARBItem>> _resultItems;
  Map<String, List<String>> _visitedKeys;

  ARBTranslationApplier({
    required this.original,
    required this.originalLocale,
    required this.translationTargets,
    required this.translations,
    required this.originals,
  })  : _itemsCount = original.items.length,
        _resultItems =
            translationTargets.map((x) => MapEntry(x, <ARBItem>[])).toMap(),
        _visitedKeys =
            translationTargets.map((x) => MapEntry(x, <String>[])).toMap();

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

  /// if targetLocales is specified only their translations will apply
  /// other locales translations will be unchanged
  void applyCurrentChange({List<String>? targetLocales}) {
    final currentTranslations = _getCurrentTranslations();
    bool applySpecificLocales = targetLocales != null;
    final specificLocales = targetLocales ?? [];

    for (final kv in currentTranslations.entries) {
      final locale = kv.key;
      final translation = kv.value;

      if (translation == null) {
        continue;
      }

      _visitedKeys[locale]!.add(translation.key);

      if (applySpecificLocales && !specificLocales.contains(locale)) {
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
      } else {
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
  }

  void discardCurrentChange() {
    final itemKey = currentItem.key;

    for (final target in translationTargets) {
      _visitedKeys[target]!.add(itemKey);
      final item = originals.lookup(target)?.findItemByKey(itemKey);

      if (item == null) {
        continue;
      }

      _resultItems[target]!.add(item);
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
