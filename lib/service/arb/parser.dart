import 'dart:convert';
import 'dart:io';

import '../log/logger.dart';

import '../../utils/extensions.dart';

import '../../models/arb_content.dart';

/// Reads ARB file and generates [ARBContent] based on it's content
class ARBParser {
  final Logger logger;
  static const _pluralToken = 'plural,';
  static const _selectToken = 'select,';

  const ARBParser({
    required this.logger,
  });

  /// [path] - absolute path to the .arb file
  ARBContent parse(String path) {
    logger.info('Parse file $path');

    final file = File(path);
    if (!file.existsSync()) {
      logger.warning('File $path does not exist');
      return ARBContent.empty();
    }

    final fileLen = file.lengthSync();
    if (fileLen == 0) {
      logger.warning('File $path is empty');
      return ARBContent.empty();
    }

    final fileLines = file.readAsLinesSync();
    final buff = StringBuffer();
    int lineNum = 0;
    List<int> lineBreaks = [];
    for (final fileLine in fileLines) {
      if (fileLine == '{' || fileLine == '}') {
        buff.writeln(fileLine);
        lineNum++;
        continue;
      }

      if (fileLine.contains('@@locale')) {
        lineNum++;
        buff.writeln(fileLine);
        continue;
      }

      if (fileLine.isEmpty) {
        lineBreaks.add(lineNum++);
        continue;
      }

      buff.writeln(fileLine);
      lineNum++;
    }

    if (lineBreaks.isNotEmpty) {
      logger.info('Line breaks at $lineBreaks');
    }

    final fileContent = buff.toString();
    final jsonData = jsonDecode(fileContent) as Map<String, dynamic>;

    logger.info('Found ${jsonData.length} json entries');

    Map<String, ARBItem> items = {};
    Map<String, dynamic> annotations = {};

    String? locale;
    int i = 0;
    for (final json in jsonData.entries) {
      if (json.key == '@@locale') {
        logger.warning('Found locale entry ${json.value}');
        locale = json.value;
        continue;
      }

      if (json.key.contains('@')) {
        annotations[json.key.replaceAll('@', '')] = json.value;
        continue;
      }

      final value = json.value;
      final plurals = _parsePlurals(value);
      final selects = _parseSelects(value);

      final item = ARBItem(
        number: i,
        key: json.key,
        value: json.value,
        plurals: plurals,
        selects: selects,
        annotation: null,
      );

      items[item.key] = item;
      i++;
    }

    for (final annotation in annotations.entries) {
      final exist = items[annotation.key]!;

      final arbAnnotation = ARBItemAnnotation.fromJson(annotation.value);

      items[annotation.key] = exist.cloneWith(
        annotation: arbAnnotation,
      );
    }

    return ARBContent(
      items.values.toList(),
      locale: locale,
      lineBreaks: lineBreaks,
    );
  }

  /// Reads item text, finds all plurals in it and generates a list
  List<ARBItemSpecialData> _parsePlurals(final String text) {
    if (!_containsPluralToken(text)) {
      return [];
    }

    String str = text;
    List<String> parts = [];
    while (_containsPluralToken(str)) {
      final startIndex = _getPluralPartStartIndex(str);
      final endIndex = str.getClosingBracketIndex(startIndex);
      final pluralPart = str.substring(startIndex, endIndex + 1);
      parts.add(pluralPart);
      str = str.replaceAll(pluralPart, '');
    }

    return parts.map((x) => ARBItemSpecialData.parseFromString(x)).toList();
  }

  /// Reads item text, finds all selects in it and generates a list
  List<ARBItemSpecialData> _parseSelects(final String text) {
    if (!_containsSelectToken(text)) {
      return [];
    }

    String str = text;
    List<String> parts = [];
    while (_containsSelectToken(str)) {
      final startIndex = _getSelectPartStartIndex(str);
      final endIndex = str.getClosingBracketIndex(startIndex);
      final pluralPart = str.substring(startIndex, endIndex + 1);
      parts.add(pluralPart);
      str = str.replaceAll(pluralPart, '');
    }

    return parts.map((x) => ARBItemSpecialData.parseFromString(x)).toList();
  }

  bool _containsPluralToken(String str) => str.contains(_pluralToken);

  bool _containsSelectToken(String str) => str.contains(_selectToken);

  int _getPluralPartStartIndex(String str) {
    final tokenStartIndex = str.indexOf(_pluralToken);
    final anythingBefore = str.substring(0, tokenStartIndex);
    return anythingBefore.lastIndexOf('{');
  }

  int _getSelectPartStartIndex(String str) {
    final tokenStartIndex = str.indexOf(_selectToken);
    final anythingBefore = str.substring(0, tokenStartIndex);
    return anythingBefore.lastIndexOf('{');
  }
}
