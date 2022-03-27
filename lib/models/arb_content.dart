import 'types.dart';
import '../utils/extensions.dart';

typedef ARBItemKey = String;
typedef ARBItemPlaceholderKey = String;
typedef ARBItemSpecialDataKey = String;

enum ARBItemSpecialDataType { plural, select }

/// ARB file content model
/// [locale] - optional in ARB file
/// [items] - list of key/value pairs contained by this file
/// each item may contain annotation, plurals and selects
/// [lineBreaks] - list of line breaks in the file
/// used to rebuild file with similar layout
class ARBContent {
  final LanguageCode? locale;
  final List<ARBItem> items;
  final List<int> lineBreaks;

  const ARBContent(
    this.items, {
    this.locale,
    this.lineBreaks = const [],
  });

  factory ARBContent.empty() => ARBContent([]);

  /// Finds ARB item by given key
  ARBItem? findItemByKey(ARBItemKey key) =>
      items.firstWhereOrNull((x) => x.key == key);

  /// Finds ARB item by numeric position in the file
  ARBItem? findItemByNumber(int number) =>
      items.firstWhereOrNull((x) => x.number == number);
}

/// ARB item model
/// Example:
/// ---------------------------------------------------------------------------
/// "pageHomeTitle" : "Welcome {firstName}",
/// "@pageHomeTitle" : {
///   "description" : "Welcome message on the Home screen",
///   "placeholders": {
///     "firstName": {}
///   }
/// }
/// ---------------------------------------------------------------------------
/// [number] - numeric position in the file
/// [key] - "pageHomeTitle" in example
/// [value] - "Welcome {firstName}" in example
/// [plurals] - example doesn't contain plurals
/// [selects] - example doesn't contain selects
/// [annotation] - item annotation (optional) ("@pageHomeTitle" in example)
class ARBItem {
  final int number;
  final ARBItemKey key;
  final String value;
  final List<ARBItemSpecialData> plurals;
  final List<ARBItemSpecialData> selects;
  final ARBItemAnnotation? annotation;

  bool get hasPlaceholders => annotation?.hasPlaceholders ?? false;

  bool get hasPlurals => plurals.isNotEmpty;

  bool get hasSelects => selects.isNotEmpty;

  const ARBItem({
    required this.number,
    required this.key,
    required this.value,
    this.plurals = const [],
    this.selects = const [],
    this.annotation,
  });

  ARBItem cloneWith({
    String? value,
    ARBItemAnnotation? annotation,
    List<ARBItemSpecialData>? plurals,
    List<ARBItemSpecialData>? selects,
  }) {
    return ARBItem(
      key: key,
      number: number,
      value: value ?? this.value,
      annotation: annotation ?? this.annotation,
      plurals: plurals ?? this.plurals,
      selects: selects ?? this.selects,
    );
  }

  /// Finds placeholder by given key
  ARBItemAnnotationPlaceholder? findPlaceholderByKey(ARBItemKey key) =>
      annotation?.findPlaceholderByKey(key);

  /// Finds plural by given key
  ARBItemSpecialData? findPluralByKey(ARBItemSpecialDataKey key) =>
      plurals.firstWhereOrNull((x) => x.key == key);

  /// Finds select by given key
  ARBItemSpecialData? findSelectByKey(ARBItemSpecialDataKey key) =>
      selects.firstWhereOrNull((x) => x.key == key);
}

/// ARB item annotation model
/// Example:
/// ---------------------------------------------------------------------------
/// "@pageHomeTitle" : {
///   "description" : "Welcome message on the Home screen",
///   "placeholders": {
///     "firstName": {}
///   }
/// }
/// ---------------------------------------------------------------------------
/// [description] - optional, "Welcome message on the Home screen" in example
/// [placeholders] - List of placeholders with their metadata, ["firstName"]
/// in example
class ARBItemAnnotation {
  final String? description;
  final List<ARBItemAnnotationPlaceholder> placeholders;

  const ARBItemAnnotation({
    this.description,
    this.placeholders = const [],
  });

  bool get hasPlaceholders => placeholders.isNotEmpty;

  /// Finds placeholder by key
  ARBItemAnnotationPlaceholder? findPlaceholderByKey(
          ARBItemPlaceholderKey key) =>
      placeholders.firstWhereOrNull((x) => x.key == key);

  factory ARBItemAnnotation.fromJson(Map<String, dynamic> json) {
    final placeholders =
        (json.lookup('placeholders') as Map<String, dynamic>? ?? {})
            .entries
            .map((x) => ARBItemAnnotationPlaceholder.fromJson(x.key, x.value))
            .toList();

    return ARBItemAnnotation(
      description: json.containsKey('description') ? json['description'] : null,
      placeholders: placeholders,
    );
  }
}

/// ARB item annotation placeholder model
/// Example:
/// ---------------------------------------------------------------------------
/// "firstName": {
///   "type": "String",
///   "example": "John Doe"
/// }
/// ---------------------------------------------------------------------------
/// [key] - "firstName" in example
/// [type] - optional, "String" in example
/// [example] - optional, "John Doe" in example
/// [format] - optional, not included in example
class ARBItemAnnotationPlaceholder {
  final ARBItemPlaceholderKey key;
  final String? type;
  final String? example;
  final String? format;

  const ARBItemAnnotationPlaceholder({
    required this.key,
    this.type,
    this.example,
    this.format,
  });

  factory ARBItemAnnotationPlaceholder.fromJson(
    ARBItemPlaceholderKey key,
    Map<String, dynamic> json,
  ) {
    return ARBItemAnnotationPlaceholder(
      key: key,
      type: json.lookup('type'),
      example: json.lookup('example'),
      format: json.lookup('format'),
    );
  }
}

/// Plural or Select data
/// Example:
/// ---------------------------------------------------------------------------
/// {count, plural, zero{0 messages} other{{count} new messages}}
/// ---------------------------------------------------------------------------
/// [key] - plural or select key, "count" in example
/// [type] - type of data [plural/select]
/// [options] - list of options, ["zero","other"] with their metadata in example
class ARBItemSpecialData {
  final ARBItemSpecialDataKey key;
  final ARBItemSpecialDataType type;
  final List<ARBItemSpecialDataOption> options;

  const ARBItemSpecialData({
    required this.key,
    required this.type,
    required this.options,
  });

  String get typeStr =>
      type == ARBItemSpecialDataType.select ? 'select' : 'plural';

  String get fullText {
    final buff = StringBuffer();

    buff.write('{');
    buff.write(key);
    buff.write(', $typeStr, ');

    for (int i = 0; i < options.length; i++) {
      final option = options[i];
      buff.write(option.key);
      buff.write('{');
      buff.write(option.text);
      buff.write('}');

      if (i < options.length - 1) {
        buff.write(' ');
      }
    }

    buff.write('}');

    return buff.toString();
  }

  /// creates new special data from string like:
  /// {sex, select, male{His birthday} female{Her birthday} other{Their birthday}}
  /// {count, plural, zero{You have no new messages} other{You have {count} new messages}}
  factory ARBItemSpecialData.parseFromString(String str) {
    if (!str.contains('plural') && !str.contains('select')) {
      throw Exception('String "$str" does not contain special token');
    }

    if (str[0] != '{' || str[str.length - 1] != '}') {
      throw Exception('"$str" is not valid special data string');
    }

    final key = str.substring(1, str.indexOf(',')).trim();
    final token = str.contains('plural') ? 'plural' : 'select';
    final type = token == 'plural'
        ? ARBItemSpecialDataType.plural
        : ARBItemSpecialDataType.select;
    final tokenEndIndex = str.indexOf(token) + token.length;
    String optionsStr = str.substring(tokenEndIndex, str.length).trim();
    if (optionsStr[0] == ',') {
      optionsStr = optionsStr.substring(1, optionsStr.length).trimLeft();
    }

    List<ARBItemSpecialDataOption> options = [];
    while (optionsStr.indexOf('{') > 0 && optionsStr.indexOf('}') > 0) {
      final openIx = optionsStr.indexOf('{');
      final closeIx = optionsStr.getClosingBracketIndex(openIx);
      final optionKey = optionsStr.substring(0, openIx).trim();
      final optionText = optionsStr.substring(openIx + 1, closeIx).trim();
      options.add(ARBItemSpecialDataOption(optionKey, optionText));
      optionsStr = optionsStr.substring(closeIx + 1, optionsStr.length);
    }

    return ARBItemSpecialData(
      key: key,
      type: type,
      options: options,
    );
  }

  /// Finds option by given key
  ARBItemSpecialDataOption? findOptionByKey(String key) =>
      options.firstWhereOrNull((x) => x.key == key);
}

/// Special data option
/// For plural it can be {zero:"zero messages"},{other:"count of messages"}
class ARBItemSpecialDataOption {
  final String key;
  final String text;
  const ARBItemSpecialDataOption(this.key, this.text);
}
