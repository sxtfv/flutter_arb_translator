import 'package:flutter_arb_translator/models/translation.dart';
import 'package:flutter_arb_translator/service/translation/base.dart';
import 'package:flutter_arb_translator/utils/extensions.dart';

class FakeTranslationService implements AbstractTranslationService {
  @override
  Future<String> translate(
    String source,
    String sourceLanguage,
    String target,
  ) {
    return Future.value('[$target] $source');
  }
}

class FakeTranslationServiceSupportsTranslationToMultipleTargets
    extends FakeTranslationService with SupportsSimpleTranslationToTargetsList {
  @override
  Future<Translation> translateToTargetsList(
    String source,
    String sourceLanguage,
    List<String> targets,
  ) {
    final translations =
        targets.map((x) => MapEntry(x, '[$x] $source')).toMap();

    return Future.value(Translation(
        source: source,
        sourceLanguage: sourceLanguage,
        translations: translations));
  }
}

class FakeTranslationServiceSupportsBulkTranslationToSingleTarget
    extends FakeTranslationService with SupportsBulkTranslationToSingleTarget {
  @override
  Future<List<String>> translateBulkToSingleTarget(
    List<String> sources,
    String sourceLanguage,
    String target,
  ) {
    return Future.value(sources.map((x) => '[$target] $x').toList());
  }
}

class FakeTranslationServiceSupportsBulkTranslationToMultipleTargets
    extends FakeTranslationService with SupportsBulkTranslationToTargetsList {
  @override
  Future<List<Translation>> translateBulk(
    List<String> sources,
    String sourceLanguage,
    List<String> targets,
  ) {
    List<Translation> result = [];
    for (final source in sources) {
      final translations =
          targets.map((x) => MapEntry(x, '[$x] $source')).toMap();
      result.add(Translation(
        source: source,
        sourceLanguage: sourceLanguage,
        translations: translations,
      ));
    }
    return Future.value(result);
  }
}
