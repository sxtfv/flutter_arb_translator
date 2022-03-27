import 'arb_content.dart';
import 'types.dart';

import '../utils/extensions.dart';

/// Describes how ARB item was changed
enum ARBItemModificationType {
  unmodified,
  added,
  edited,
}

/// ARB file content model with translations
/// [locale] - optional in ARB file
/// [items] - list of key/value pairs contained by this file
/// each item may contain annotation, plurals and selects
/// [lineBreaks] - list of line breaks in the file
/// used to rebuild file with similar layout
class ARBContentTranslated {
  final LanguageCode? locale;
  final List<ARBItemTranslated> items;
  final List<int> lineBreaks;

  const ARBContentTranslated(
    this.items, {
    this.locale,
    this.lineBreaks = const [],
  });

  /// Finds ARB item by given key
  ARBItemTranslated? findItemByKey(String key) =>
      items.firstWhereOrNull((x) => x.key == key);

  /// Finds ARB item by numeric position in file
  ARBItemTranslated? findItemByNumber(int number) =>
      items.firstWhereOrNull((x) => x.number == number);
}

/// Translated ARB item model
/// Most of it's fields are same as [ARBItem] fields
/// but [value] is translated [value] of [ARBItem]
class ARBItemTranslated {
  final int number;
  final String key;
  final String value;
  final String? originalValue;
  final ARBItemModificationType modificationType;
  final List<ARBItemSpecialData> plurals;
  final List<ARBItemSpecialData> selects;
  final ARBItemAnnotation? annotation;

  bool get hasPlaceholders => annotation?.hasPlaceholders ?? false;

  bool get hasPlurals => plurals.isNotEmpty;

  bool get hasSelects => selects.isNotEmpty;

  const ARBItemTranslated({
    required this.number,
    required this.key,
    required this.value,
    required this.originalValue,
    required this.modificationType,
    required this.annotation,
    this.plurals = const [],
    this.selects = const [],
  });

  factory ARBItemTranslated.unmodified(
    ARBItem item, {
    ARBItemAnnotation? annotation1,
    List<ARBItemSpecialData> plurals1 = const [],
    List<ARBItemSpecialData> selects1 = const [],
  }) =>
      ARBItemTranslated(
        number: item.number,
        key: item.key,
        value: item.value,
        originalValue: item.value,
        modificationType: ARBItemModificationType.unmodified,
        annotation: item.annotation ?? annotation1,
        plurals: item.plurals.isEmpty ? plurals1 : item.plurals,
        selects: item.selects.isEmpty ? selects1 : item.selects,
      );

  factory ARBItemTranslated.edited({
    required ARBItemKey key,
    required int number,
    required String value,
    required String originalValue,
    required ARBItemAnnotation? annotation,
    required List<ARBItemSpecialData> plurals,
    required List<ARBItemSpecialData> selects,
  }) =>
      ARBItemTranslated(
        key: key,
        number: number,
        value: value,
        originalValue: originalValue,
        modificationType: ARBItemModificationType.edited,
        annotation: annotation,
        plurals: plurals,
        selects: selects,
      );

  factory ARBItemTranslated.added({
    required ARBItemKey key,
    required int number,
    required String value,
    required ARBItemAnnotation? annotation,
    required List<ARBItemSpecialData> plurals,
    required List<ARBItemSpecialData> selects,
  }) =>
      ARBItemTranslated(
        key: key,
        number: number,
        value: value,
        originalValue: null,
        modificationType: ARBItemModificationType.added,
        annotation: annotation,
        plurals: plurals,
        selects: selects,
      );

  ARBItemAnnotationPlaceholder? findPlaceholderByKey(String key) =>
      annotation?.findPlaceholderByKey(key);

  ARBItemSpecialData? findPluralByKey(String key) =>
      plurals.firstWhereOrNull((x) => x.key == key);

  ARBItemSpecialData? findSelectByKey(String key) =>
      selects.firstWhereOrNull((x) => x.key == key);

  ARBItem toArbItem() {
    return ARBItem(
      key: key,
      number: number,
      value: value,
      annotation: annotation,
      plurals: plurals,
      selects: selects,
    );
  }
}
