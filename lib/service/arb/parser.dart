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

      if (fileLine.startsWith('@@')) {
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
    Map<String, ARBAttribute> attributes = {};
    Map<String, dynamic> annotations = {};

    int i = 0;
    for (final json in jsonData.entries) {
      if (json.key.startsWith('@@')) {
        logger.warning('Found attribute ${json.key} - ${json.value}');
        final attributeKey = json.key.substring(2, json.key.length);
        attributes[attributeKey] = ARBAttribute(
          number: i,
          key: attributeKey,
          value: json.value,
        );
        i++;
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

    for (final item in items.values) {
      if (item.annotation != null) {
        continue;
      }

      final allSpecialData = [...item.plurals, ...item.selects];
      final textWithoutSpecialData = _getTextWithoutSpecialData(
        item.value,
        allSpecialData,
      );

      final shouldContainAnnotation = item.hasPlurals ||
          item.hasSelects ||
          _hasCorrectOpenCloseCurlyBraces(textWithoutSpecialData);

      if (!shouldContainAnnotation) {
        continue;
      }

      final allPlaceholders =
          _parsePlaceholdersFromText(textWithoutSpecialData);

      final arbAnnotation = ARBItemAnnotation.fromData(
        allSpecialData,
        allPlaceholders,
      );

      items[item.key] = item.cloneWith(
        annotation: arbAnnotation,
      );
    }

    return ARBContent(
      items.values.toList(),
      attributes: attributes.values.toList(),
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

  bool _hasCorrectOpenCloseCurlyBraces(String str) {
    int openCount = 0;
    bool hasCurlyBraces = false;

    for (int i = 0; i < str.length; i++) {
      final ch = str[i];

      if (ch == '{') {
        openCount++;
        hasCurlyBraces = true;
      } else if (ch == '}') {
        openCount--;
        hasCurlyBraces = true;
      }
    }

    return hasCurlyBraces && openCount == 0;
  }

  String _getTextWithoutSpecialData(
    String text,
    Iterable<ARBItemSpecialData> specialData,
  ) {
    if (specialData.isEmpty) {
      return text;
    }

    String clearText = text;

    for (final item in specialData) {
      clearText = clearText.replaceAll(item.fullText, '');
    }

    return clearText;
  }

  List<String> _parsePlaceholdersFromText(String text) {
    final bracketIndexes = <int>[];

    for (int i = 0; i < text.length; i++) {
      final ch = text[i];

      if (ch == '{' && i <= text.length - 2 && text[i + 1] != '{') {
        bracketIndexes.add(i);
      }
    }

    if (bracketIndexes.isEmpty) {
      return [];
    }

    final result = <String>[];
    for (final startIx in bracketIndexes) {
      final endIndex = text.getClosingBracketIndex(startIx);
      final placeholder = text.substring(startIx + 1, endIndex);
      result.add(placeholder);
    }

    return result;
  }
}
