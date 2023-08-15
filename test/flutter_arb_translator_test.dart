import 'dart:io';

import 'package:test/test.dart';
import 'package:path/path.dart' as path;

import 'package:flutter_arb_translator/service/arb/parser.dart';
import 'package:flutter_arb_translator/service/arb/writer.dart';
import 'package:flutter_arb_translator/service/log/logger.dart';
import 'package:flutter_arb_translator/service/arb/translation_applier.dart';
import 'package:flutter_arb_translator/service/translation/base.dart';
import 'package:flutter_arb_translator/service/arb/translator.dart';

import 'package:flutter_arb_translator/models/arb_content.dart';
import 'package:flutter_arb_translator/models/arb_content_translated.dart';
import 'package:flutter_arb_translator/models/translation_applying.dart';

import 'fake_translators.dart';

void main() {
  final logLevel = LogLevel.none;

  group('arb parsing and writing', () {
    final sampleFilePath = path.absolute('test_assets/app_en.arb');

    test('parser', () {
      final parser = ARBParser(
        logger: Logger<ARBParser>(logLevel),
      );
      final arbContent = parser.parse(sampleFilePath);
      assert((arbContent.locale ?? '') == 'en');

      assert(arbContent.items.length == 8);

      final appNameItem = arbContent.findItemByKey('appName')!;
      assert(appNameItem.value == 'Demo app');
      assert(appNameItem.annotation == null);

      final pageLoginUsernameItem =
          arbContent.findItemByKey('pageLoginUsername')!;
      assert(pageLoginUsernameItem.value == 'Your username');
      assert(pageLoginUsernameItem.annotation != null);
      assert(pageLoginUsernameItem.annotation!.description == null);
      assert(pageLoginUsernameItem.annotation!.placeholders.isEmpty);

      final pageLoginPasswordItem =
          arbContent.findItemByKey('pageLoginPassword')!;
      assert(pageLoginPasswordItem.value == 'Your password');
      assert(pageLoginPasswordItem.annotation != null);
      assert(pageLoginPasswordItem.annotation!.description == null);
      assert(pageLoginPasswordItem.annotation!.placeholders.isEmpty);

      final pageHomeTitleItem = arbContent.findItemByKey('pageHomeTitle')!;
      assert(pageHomeTitleItem.value == 'Welcome {firstName}');
      assert(pageHomeTitleItem.annotation != null);
      assert(pageHomeTitleItem.annotation!.description ==
          'Welcome message on the Home screen');
      assert(pageHomeTitleItem.annotation!.hasPlaceholders);
      assert(pageHomeTitleItem.annotation!.placeholders.length == 1);
      final pageHomeTitleItemFirstNamePlaceholder =
          pageHomeTitleItem.findPlaceholderByKey('firstName')!;
      assert(pageHomeTitleItemFirstNamePlaceholder.example == null);
      assert(pageHomeTitleItemFirstNamePlaceholder.type == null);
      assert(pageHomeTitleItemFirstNamePlaceholder.format == null);

      final pageHomeInboxCountItem =
          arbContent.findItemByKey('pageHomeInboxCount')!;
      assert(pageHomeInboxCountItem.value ==
          '{count, plural, zero{You have no new messages} one{You have 1 new message} other{You have {count} new messages}}');
      assert(pageHomeInboxCountItem.annotation != null);
      assert(pageHomeInboxCountItem.annotation!.description ==
          'New messages count on the Home screen');
      assert(pageHomeInboxCountItem.hasPlaceholders);
      assert(pageHomeInboxCountItem.hasPlurals);
      final pageHomeInboxCountItemCountPlaceholder =
          pageHomeInboxCountItem.findPlaceholderByKey('count')!;
      assert(pageHomeInboxCountItemCountPlaceholder.format == null);
      assert(pageHomeInboxCountItemCountPlaceholder.type == null);
      assert(pageHomeInboxCountItemCountPlaceholder.example == null);
      final pageHomeInboxCountItemCountPlural =
          pageHomeInboxCountItem.findPluralByKey('count')!;
      assert(pageHomeInboxCountItemCountPlural.fullText ==
          '{count, plural, zero{You have no new messages} one{You have 1 new message} other{You have {count} new messages}}');
      assert(pageHomeInboxCountItemCountPlural.options.length == 3);
      assert(pageHomeInboxCountItemCountPlural.findOptionByKey('zero')!.text ==
          'You have no new messages');
      assert(pageHomeInboxCountItemCountPlural.findOptionByKey('one')!.text ==
          'You have 1 new message');
      assert(pageHomeInboxCountItemCountPlural.findOptionByKey('other')!.text ==
          'You have {count} new messages');

      final pageHomeBirthdayItem =
          arbContent.findItemByKey('pageHomeBirthday')!;
      assert(pageHomeBirthdayItem.value ==
          '{sex, select, male{His birthday} female{Her birthday} other{Their birthday}}');
      assert(pageHomeBirthdayItem.annotation != null);
      assert(pageHomeBirthdayItem.annotation!.description ==
          'Birthday message on the Home screen');
      assert(pageHomeBirthdayItem.hasPlaceholders);
      assert(pageHomeBirthdayItem.hasPlurals == false);
      assert(pageHomeBirthdayItem.hasSelects);
      final pageHomeBirthdayItemSexPlaceholder =
          pageHomeBirthdayItem.findPlaceholderByKey('sex')!;
      assert(pageHomeBirthdayItemSexPlaceholder.format == null);
      assert(pageHomeBirthdayItemSexPlaceholder.type == null);
      assert(pageHomeBirthdayItemSexPlaceholder.example == null);
      final pageHomeBirthdayItemSexSelect =
          pageHomeBirthdayItem.findSelectByKey('sex')!;
      assert(pageHomeBirthdayItemSexSelect.fullText ==
          '{sex, select, male{His birthday} female{Her birthday} other{Their birthday}}');
      assert(pageHomeBirthdayItemSexSelect.options.length == 3);
      assert(pageHomeBirthdayItemSexSelect.findOptionByKey('male')!.text ==
          'His birthday');
      assert(pageHomeBirthdayItemSexSelect.findOptionByKey('female')!.text ==
          'Her birthday');
      assert(pageHomeBirthdayItemSexSelect.findOptionByKey('other')!.text ==
          'Their birthday');

      final commonVehicleTypeItem =
          arbContent.findItemByKey('commonVehicleType')!;
      assert(commonVehicleTypeItem.value ==
          '{vehicleType, select, sedan{Sedan} cabriolet{Solid roof cabriolet} truck{16 wheel truck} other{Other}}');
      assert(commonVehicleTypeItem.annotation != null);
      assert(commonVehicleTypeItem.annotation!.description == 'Vehicle type');
      assert(commonVehicleTypeItem.hasPlaceholders);
      assert(commonVehicleTypeItem.hasPlurals == false);
      assert(commonVehicleTypeItem.hasSelects);
      final commonVehicleTypeItemVehicleTypePlaceholder =
          commonVehicleTypeItem.findPlaceholderByKey('vehicleType')!;
      assert(commonVehicleTypeItemVehicleTypePlaceholder.format == null);
      assert(commonVehicleTypeItemVehicleTypePlaceholder.type == null);
      assert(commonVehicleTypeItemVehicleTypePlaceholder.example == null);
      final commonVehicleTypeItemVehicleTypeSelect =
          commonVehicleTypeItem.findSelectByKey('vehicleType')!;
      assert(commonVehicleTypeItemVehicleTypeSelect.fullText ==
          '{vehicleType, select, sedan{Sedan} cabriolet{Solid roof cabriolet} truck{16 wheel truck} other{Other}}');
      assert(commonVehicleTypeItemVehicleTypeSelect.options.length == 4);
      assert(commonVehicleTypeItemVehicleTypeSelect
              .findOptionByKey('sedan')!
              .text ==
          'Sedan');
      assert(commonVehicleTypeItemVehicleTypeSelect
              .findOptionByKey('cabriolet')!
              .text ==
          'Solid roof cabriolet');
      assert(commonVehicleTypeItemVehicleTypeSelect
              .findOptionByKey('truck')!
              .text ==
          '16 wheel truck');
      assert(commonVehicleTypeItemVehicleTypeSelect
              .findOptionByKey('other')!
              .text ==
          'Other');

      final complexItem = arbContent.findItemByKey('complexEntry')!;
      assert(complexItem.value ==
          'Hello {firstName}, your car is {vehicleType, select, sedan{Sedan} cabriolet{Solid roof cabriolet} truck{16 wheel truck} other{Other}}. You have {count, plural, zero{no new messages} one{1 new message} other{{count} new messages}}');
      assert(complexItem.annotation != null);
      assert(
          complexItem.annotation!.description == 'complex entry description');
      assert(complexItem.hasPlaceholders);
      assert(complexItem.hasPlurals);
      assert(complexItem.hasSelects);
      final complexItemFirstNamePlaceholder =
          complexItem.findPlaceholderByKey('firstName')!;
      assert(complexItemFirstNamePlaceholder.type == 'String');
      assert(complexItemFirstNamePlaceholder.example == 'John Doe');
      assert(complexItemFirstNamePlaceholder.format == null);
      final complexItemVehicleTypePlaceholder =
          complexItem.findPlaceholderByKey('vehicleType')!;
      assert(complexItemVehicleTypePlaceholder.type == null);
      assert(complexItemVehicleTypePlaceholder.example == null);
      assert(complexItemVehicleTypePlaceholder.format == null);
      final complexItemCountPlaceholder =
          complexItem.findPlaceholderByKey('count')!;
      assert(complexItemCountPlaceholder.type == 'int');
      assert(complexItemCountPlaceholder.example == '1');
      assert(complexItemCountPlaceholder.format == null);
      final complexItemVehicleTypeSelect =
          complexItem.findSelectByKey('vehicleType')!;
      assert(complexItemVehicleTypeSelect.fullText ==
          '{vehicleType, select, sedan{Sedan} cabriolet{Solid roof cabriolet} truck{16 wheel truck} other{Other}}');
      assert(complexItemVehicleTypeSelect.options.length == 4);
      assert(complexItemVehicleTypeSelect.findOptionByKey('sedan')!.text ==
          'Sedan');
      assert(complexItemVehicleTypeSelect.findOptionByKey('cabriolet')!.text ==
          'Solid roof cabriolet');
      assert(complexItemVehicleTypeSelect.findOptionByKey('truck')!.text ==
          '16 wheel truck');
      assert(complexItemVehicleTypeSelect.findOptionByKey('other')!.text ==
          'Other');
      final complexItemCountPlural = complexItem.findPluralByKey('count')!;
      assert(complexItemCountPlural.fullText ==
          '{count, plural, zero{no new messages} one{1 new message} other{{count} new messages}}');
      assert(complexItemCountPlural.options.length == 3);
      assert(complexItemCountPlural.findOptionByKey('zero')!.text ==
          'no new messages');
      assert(complexItemCountPlural.findOptionByKey('one')!.text ==
          '1 new message');
      assert(complexItemCountPlural.findOptionByKey('other')!.text ==
          '{count} new messages');
    });

    test('writer', () {
      final newFilePath = path.absolute('test_assets/writer_test_app_en.arb');
      final f = File(newFilePath);
      if (f.existsSync()) {
        f.deleteSync();
      }

      final arb = ARBParser(
        logger: Logger<ARBParser>(logLevel),
      ).parse(sampleFilePath);

      final writer = ARBWriter(
        arb,
        logger: Logger<ARBWriter>(logLevel),
      );
      writer.writeToFile(newFilePath);

      final originalFileContent = File(sampleFilePath)
          .readAsStringSync()
          .replaceAll(' ', '')
          .replaceAll('\r\n', '\n');
      final newFileContent = File(newFilePath)
          .readAsStringSync()
          .replaceAll(' ', '')
          .replaceAll('\r\n', '\n');
      assert(originalFileContent.length == newFileContent.length);
      assert(originalFileContent == newFileContent);

      File(newFilePath).deleteSync();
    });

    test('parser. placeholder detection', () {
      final sampleFilePathWithoutAnnotation =
          path.absolute('test_assets/without_annotation_en.arb');

      final parser = ARBParser(
        logger: Logger<ARBParser>(logLevel),
      );

      final arbContent = parser.parse(sampleFilePathWithoutAnnotation);
      assert((arbContent.locale ?? '') == 'en');

      assert(arbContent.items.length == 8);

      final appNameItem = arbContent.findItemByKey('appName')!;
      assert(appNameItem.value == 'Demo app');
      assert(appNameItem.annotation == null);

      final pageLoginUsernameItem =
          arbContent.findItemByKey('pageLoginUsername')!;
      assert(pageLoginUsernameItem.value == 'Your username');
      assert(pageLoginUsernameItem.annotation != null);
      assert(pageLoginUsernameItem.annotation!.description == null);
      assert(pageLoginUsernameItem.annotation!.placeholders.isEmpty);

      final pageLoginPasswordItem =
          arbContent.findItemByKey('pageLoginPassword')!;
      assert(pageLoginPasswordItem.value == 'Your password');
      assert(pageLoginPasswordItem.annotation != null);
      assert(pageLoginPasswordItem.annotation!.description == null);
      assert(pageLoginPasswordItem.annotation!.placeholders.isEmpty);

      final pageHomeTitleItem = arbContent.findItemByKey('pageHomeTitle')!;
      assert(pageHomeTitleItem.value == 'Welcome {firstName}');
      assert(pageHomeTitleItem.annotation != null);
      assert(pageHomeTitleItem.annotation!.hasPlaceholders);
      assert(pageHomeTitleItem.annotation!.placeholders.length == 1);
      final pageHomeTitleItemFirstNamePlaceholder =
          pageHomeTitleItem.findPlaceholderByKey('firstName')!;
      assert(pageHomeTitleItemFirstNamePlaceholder.example == null);
      assert(pageHomeTitleItemFirstNamePlaceholder.type == null);
      assert(pageHomeTitleItemFirstNamePlaceholder.format == null);

      final pageHomeInboxCountItem =
          arbContent.findItemByKey('pageHomeInboxCount')!;
      assert(pageHomeInboxCountItem.value ==
          '{count, plural, zero{You have no new messages} one{You have 1 new message} other{You have {count} new messages}}');
      assert(pageHomeInboxCountItem.annotation != null);
      assert(pageHomeInboxCountItem.hasPlaceholders);
      assert(pageHomeInboxCountItem.hasPlurals);
      final pageHomeInboxCountItemCountPlaceholder =
          pageHomeInboxCountItem.findPlaceholderByKey('count')!;
      assert(pageHomeInboxCountItemCountPlaceholder.format == null);
      assert(pageHomeInboxCountItemCountPlaceholder.type == null);
      assert(pageHomeInboxCountItemCountPlaceholder.example == null);
      final pageHomeInboxCountItemCountPlural =
          pageHomeInboxCountItem.findPluralByKey('count')!;
      assert(pageHomeInboxCountItemCountPlural.fullText ==
          '{count, plural, zero{You have no new messages} one{You have 1 new message} other{You have {count} new messages}}');
      assert(pageHomeInboxCountItemCountPlural.options.length == 3);
      assert(pageHomeInboxCountItemCountPlural.findOptionByKey('zero')!.text ==
          'You have no new messages');
      assert(pageHomeInboxCountItemCountPlural.findOptionByKey('one')!.text ==
          'You have 1 new message');
      assert(pageHomeInboxCountItemCountPlural.findOptionByKey('other')!.text ==
          'You have {count} new messages');

      final pageHomeBirthdayItem =
          arbContent.findItemByKey('pageHomeBirthday')!;
      assert(pageHomeBirthdayItem.value ==
          '{sex, select, male{His birthday} female{Her birthday} other{Their birthday}}');
      assert(pageHomeBirthdayItem.annotation != null);
      assert(pageHomeBirthdayItem.hasPlaceholders);
      assert(pageHomeBirthdayItem.hasPlurals == false);
      assert(pageHomeBirthdayItem.hasSelects);
      final pageHomeBirthdayItemSexPlaceholder =
          pageHomeBirthdayItem.findPlaceholderByKey('sex')!;
      assert(pageHomeBirthdayItemSexPlaceholder.format == null);
      assert(pageHomeBirthdayItemSexPlaceholder.type == null);
      assert(pageHomeBirthdayItemSexPlaceholder.example == null);
      final pageHomeBirthdayItemSexSelect =
          pageHomeBirthdayItem.findSelectByKey('sex')!;
      assert(pageHomeBirthdayItemSexSelect.fullText ==
          '{sex, select, male{His birthday} female{Her birthday} other{Their birthday}}');
      assert(pageHomeBirthdayItemSexSelect.options.length == 3);
      assert(pageHomeBirthdayItemSexSelect.findOptionByKey('male')!.text ==
          'His birthday');
      assert(pageHomeBirthdayItemSexSelect.findOptionByKey('female')!.text ==
          'Her birthday');
      assert(pageHomeBirthdayItemSexSelect.findOptionByKey('other')!.text ==
          'Their birthday');

      final commonVehicleTypeItem =
          arbContent.findItemByKey('commonVehicleType')!;
      assert(commonVehicleTypeItem.value ==
          '{vehicleType, select, sedan{Sedan} cabriolet{Solid roof cabriolet} truck{16 wheel truck} other{Other}}');
      assert(commonVehicleTypeItem.annotation != null);
      assert(commonVehicleTypeItem.hasPlaceholders);
      assert(commonVehicleTypeItem.hasPlurals == false);
      assert(commonVehicleTypeItem.hasSelects);
      final commonVehicleTypeItemVehicleTypePlaceholder =
          commonVehicleTypeItem.findPlaceholderByKey('vehicleType')!;
      assert(commonVehicleTypeItemVehicleTypePlaceholder.format == null);
      assert(commonVehicleTypeItemVehicleTypePlaceholder.type == null);
      assert(commonVehicleTypeItemVehicleTypePlaceholder.example == null);
      final commonVehicleTypeItemVehicleTypeSelect =
          commonVehicleTypeItem.findSelectByKey('vehicleType')!;
      assert(commonVehicleTypeItemVehicleTypeSelect.fullText ==
          '{vehicleType, select, sedan{Sedan} cabriolet{Solid roof cabriolet} truck{16 wheel truck} other{Other}}');
      assert(commonVehicleTypeItemVehicleTypeSelect.options.length == 4);
      assert(commonVehicleTypeItemVehicleTypeSelect
              .findOptionByKey('sedan')!
              .text ==
          'Sedan');
      assert(commonVehicleTypeItemVehicleTypeSelect
              .findOptionByKey('cabriolet')!
              .text ==
          'Solid roof cabriolet');
      assert(commonVehicleTypeItemVehicleTypeSelect
              .findOptionByKey('truck')!
              .text ==
          '16 wheel truck');
      assert(commonVehicleTypeItemVehicleTypeSelect
              .findOptionByKey('other')!
              .text ==
          'Other');

      final complexItem = arbContent.findItemByKey('complexEntry')!;
      assert(complexItem.value ==
          'Hello {firstName}, your car is {vehicleType, select, sedan{Sedan} cabriolet{Solid roof cabriolet} truck{16 wheel truck} other{Other}}. You have {count, plural, zero{no new messages} one{1 new message} other{{count} new messages}}');
      assert(complexItem.annotation != null);
      assert(complexItem.hasPlaceholders);
      assert(complexItem.hasPlurals);
      assert(complexItem.hasSelects);
      final complexItemVehicleTypeSelect =
          complexItem.findSelectByKey('vehicleType')!;
      assert(complexItemVehicleTypeSelect.fullText ==
          '{vehicleType, select, sedan{Sedan} cabriolet{Solid roof cabriolet} truck{16 wheel truck} other{Other}}');
      assert(complexItemVehicleTypeSelect.options.length == 4);
      assert(complexItemVehicleTypeSelect.findOptionByKey('sedan')!.text ==
          'Sedan');
      assert(complexItemVehicleTypeSelect.findOptionByKey('cabriolet')!.text ==
          'Solid roof cabriolet');
      assert(complexItemVehicleTypeSelect.findOptionByKey('truck')!.text ==
          '16 wheel truck');
      assert(complexItemVehicleTypeSelect.findOptionByKey('other')!.text ==
          'Other');
      final complexItemCountPlural = complexItem.findPluralByKey('count')!;
      assert(complexItemCountPlural.fullText ==
          '{count, plural, zero{no new messages} one{1 new message} other{{count} new messages}}');
      assert(complexItemCountPlural.options.length == 3);
      assert(complexItemCountPlural.findOptionByKey('zero')!.text ==
          'no new messages');
      assert(complexItemCountPlural.findOptionByKey('one')!.text ==
          '1 new message');
      assert(complexItemCountPlural.findOptionByKey('other')!.text ==
          '{count} new messages');
    });
  });

  group('translations', () {
    final allTranslators = [
      FakeTranslationService(),
      FakeTranslationServiceSupportsBulkTranslationToMultipleTargets(),
      FakeTranslationServiceSupportsBulkTranslationToSingleTarget(),
      FakeTranslationServiceSupportsTranslationToMultipleTargets(),
    ];

    Future<void> runOnAllTranslators(
      Future<void> Function(AbstractTranslationService) f,
    ) async {
      for (final svc in allTranslators) {
        await f(svc);
      }
    }

    test('simple translation', () async {
      final arb = ARBContent([
        ARBItem(
          key: 'hello_world',
          value: 'Hello world',
          number: 0,
        ),
      ], locale: 'en');

      await runOnAllTranslators((svc) async {
        final arbTranslator = ARBTranslator.create(
          translationSvc: svc,
          arb: arb,
          sourceLanguage: 'en',
          logger: Logger<ARBTranslator>(logLevel),
        );

        final translationResult = await arbTranslator.translate(
          languages: ['es'],
          existFiles: {},
        );

        final result = translationResult['es']!;
        assert(result.locale == 'es');
        assert(result.items.length == 1);
        assert(
            result.findItemByKey('hello_world')!.value == '[es] Hello world');
      });
    });

    test('translate item with placeholder', () async {
      final arb = ARBContent([
        ARBItem(
          key: 'greeting',
          value: 'Hello {userName}!',
          number: 0,
          annotation: ARBItemAnnotation(
            description: 'item description',
            placeholders: [
              ARBItemAnnotationPlaceholder(
                key: 'userName',
                type: 'String',
                example: 'John Doe',
              ),
            ],
          ),
        ),
      ], locale: 'en');

      await runOnAllTranslators((svc) async {
        final arbTranslator = ARBTranslator.create(
          translationSvc: svc,
          arb: arb,
          sourceLanguage: 'en',
          logger: Logger<ARBTranslator>(logLevel),
        );

        final translationResult = await arbTranslator.translate(
          languages: ['pt'],
          existFiles: {},
        );

        final result = translationResult['pt']!;
        assert(result.locale == 'pt');
        assert(result.items.length == 1);
        final item = result.findItemByKey('greeting')!;
        assert(item.value == '[pt] Hello {userName}!');
        assert(item.annotation != null);
        assert(item.hasPlaceholders);
        final userNamePlaceholder = item.findPlaceholderByKey('userName')!;
        assert(userNamePlaceholder.example == 'John Doe');
        assert(userNamePlaceholder.type == 'String');
      });
    });

    test('translate item with plurals', () async {
      final arb = ARBContent([
        ARBItem(
          key: 'pageHomeInboxCount',
          value:
              'Hello John Doe. {count, plural, zero{You have no new messages} one{You have 1 new message} other{You have {count} new messages}}',
          number: 0,
          plurals: [
            ARBItemSpecialData(
              key: 'count',
              type: ARBItemSpecialDataType.plural,
              options: [
                ARBItemSpecialDataOption(
                  'zero',
                  'You have no new messages',
                ),
                ARBItemSpecialDataOption(
                  'one',
                  'You have 1 new message',
                ),
                ARBItemSpecialDataOption(
                  'other',
                  'You have {count} new messages',
                ),
              ],
            ),
          ],
          annotation: ARBItemAnnotation(
            description: 'New messages count on the Home screen',
            placeholders: [
              ARBItemAnnotationPlaceholder(
                key: 'count',
                type: 'int',
                example: '1',
              ),
            ],
          ),
        ),
      ], locale: 'en');

      await runOnAllTranslators((svc) async {
        final arbTranslator = ARBTranslator.create(
          translationSvc: svc,
          arb: arb,
          sourceLanguage: 'en',
          logger: Logger<ARBTranslator>(logLevel),
        );

        final translationResult = await arbTranslator.translate(
          languages: ['de', 'it'],
          existFiles: {},
        );

        final resultDeutsch = translationResult['de']!;
        assert(resultDeutsch.locale == 'de');
        assert(resultDeutsch.items.length == 1);
        final itemDeutsch = resultDeutsch.findItemByKey('pageHomeInboxCount')!;
        assert(itemDeutsch.value ==
            '[de] Hello John Doe. {count, plural, zero{[de] You have no new messages} one{[de] You have 1 new message} other{[de] You have {count} new messages}}');
        assert(itemDeutsch.annotation != null);
        assert(itemDeutsch.hasPlaceholders);
        assert(itemDeutsch.hasPlurals);
        final countPlaceholderDeutsch =
            itemDeutsch.findPlaceholderByKey('count')!;
        assert(countPlaceholderDeutsch.example == '1');
        assert(countPlaceholderDeutsch.type == 'int');
        final countPluralDeutsch = itemDeutsch.findPluralByKey('count')!;
        assert(countPluralDeutsch.fullText ==
            '{count, plural, zero{[de] You have no new messages} one{[de] You have 1 new message} other{[de] You have {count} new messages}}');
        assert(countPluralDeutsch.findOptionByKey('zero')!.text ==
            '[de] You have no new messages');
        assert(countPluralDeutsch.findOptionByKey('one')!.text ==
            '[de] You have 1 new message');
        assert(countPluralDeutsch.findOptionByKey('other')!.text ==
            '[de] You have {count} new messages');

        final resultItalian = translationResult['it']!;
        assert(resultItalian.locale == 'it');
        assert(resultItalian.items.length == 1);
        final itemItalian = resultItalian.findItemByKey('pageHomeInboxCount')!;
        assert(itemItalian.value ==
            '[it] Hello John Doe. {count, plural, zero{[it] You have no new messages} one{[it] You have 1 new message} other{[it] You have {count} new messages}}');
        assert(itemItalian.annotation != null);
        assert(itemItalian.hasPlaceholders);
        assert(itemItalian.hasPlurals);
        final countPlaceholderItalian =
            itemItalian.findPlaceholderByKey('count')!;
        assert(countPlaceholderItalian.example == '1');
        assert(countPlaceholderItalian.type == 'int');
        final countPluralItalian = itemItalian.findPluralByKey('count')!;
        assert(countPluralItalian.fullText ==
            '{count, plural, zero{[it] You have no new messages} one{[it] You have 1 new message} other{[it] You have {count} new messages}}');
        assert(countPluralItalian.findOptionByKey('zero')!.text ==
            '[it] You have no new messages');
        assert(countPluralItalian.findOptionByKey('one')!.text ==
            '[it] You have 1 new message');
        assert(countPluralItalian.findOptionByKey('other')!.text ==
            '[it] You have {count} new messages');
      });
    });

    test('translate item with selects', () async {
      final arb = ARBContent([
        ARBItem(
          key: 'pageHomeBirthday',
          value:
              '{sex, select, male{His birthday} female{Her birthday} other{Their birthday}}',
          number: 0,
          selects: [
            ARBItemSpecialData(
              key: 'sex',
              type: ARBItemSpecialDataType.select,
              options: [
                ARBItemSpecialDataOption('male', 'His birthday'),
                ARBItemSpecialDataOption('female', 'Her birthday'),
                ARBItemSpecialDataOption('other', 'Their birthday'),
              ],
            ),
          ],
          annotation: ARBItemAnnotation(
            description: 'Birthday message on the Home screen',
            placeholders: [
              ARBItemAnnotationPlaceholder(
                key: 'sex',
              ),
            ],
          ),
        ),
      ], locale: 'en');

      await runOnAllTranslators((svc) async {
        final arbTranslator = ARBTranslator.create(
          translationSvc: svc,
          arb: arb,
          sourceLanguage: 'en',
          logger: Logger<ARBTranslator>(logLevel),
        );

        final translationResult = await arbTranslator.translate(
          languages: ['fr'],
          existFiles: {},
        );

        final resultFrench = translationResult['fr']!;
        assert(resultFrench.locale == 'fr');
        assert(resultFrench.items.length == 1);
        final itemFrench = resultFrench.findItemByKey('pageHomeBirthday')!;
        assert(itemFrench.value ==
            '{sex, select, male{[fr] His birthday} female{[fr] Her birthday} other{[fr] Their birthday}}');
        assert(itemFrench.annotation != null);
        assert(itemFrench.hasPlaceholders);
        assert(itemFrench.hasSelects);
        final sexPlaceholderFrench = itemFrench.findPlaceholderByKey('sex')!;
        assert(sexPlaceholderFrench.example == null);
        assert(sexPlaceholderFrench.type == null);
        final sexSelectFrench = itemFrench.findSelectByKey('sex')!;
        assert(sexSelectFrench.fullText ==
            '{sex, select, male{[fr] His birthday} female{[fr] Her birthday} other{[fr] Their birthday}}');
        assert(sexSelectFrench.findOptionByKey('male')!.text ==
            '[fr] His birthday');
        assert(sexSelectFrench.findOptionByKey('female')!.text ==
            '[fr] Her birthday');
        assert(sexSelectFrench.findOptionByKey('other')!.text ==
            '[fr] Their birthday');
      });
    });

    test('complex_translations_1', () async {
      final arb = ARBContent([
        ARBItem(
          key: 'complexEntry',
          value:
              'Hello {firstName}, your car is {vehicleType, select, sedan{Sedan} cabriolet{Solid roof cabriolet} truck{16 wheel truck} other{Other}}. You have {count, plural, zero{no new messages} one{1 new message} other{{count} new messages}}',
          number: 0,
          annotation: ARBItemAnnotation(
            description: 'complex entry description',
            placeholders: [
              ARBItemAnnotationPlaceholder(
                key: 'firstName',
                example: 'John Doe',
                type: 'String',
              ),
              ARBItemAnnotationPlaceholder(
                key: 'vehicleType',
              ),
              ARBItemAnnotationPlaceholder(
                key: 'count',
                example: '1',
                type: 'int',
              ),
            ],
          ),
          plurals: [
            ARBItemSpecialData(
              key: 'count',
              type: ARBItemSpecialDataType.plural,
              options: [
                ARBItemSpecialDataOption(
                  'zero',
                  'no new messages',
                ),
                ARBItemSpecialDataOption(
                  'one',
                  '1 new message',
                ),
                ARBItemSpecialDataOption(
                  'other',
                  '{count} new messages',
                ),
              ],
            ),
          ],
          selects: [
            ARBItemSpecialData(
              key: 'vehicleType',
              type: ARBItemSpecialDataType.select,
              options: [
                ARBItemSpecialDataOption(
                  'sedan',
                  'Sedan',
                ),
                ARBItemSpecialDataOption(
                  'cabriolet',
                  'Solid roof cabriolet',
                ),
                ARBItemSpecialDataOption(
                  'truck',
                  '16 wheel truck',
                ),
                ARBItemSpecialDataOption(
                  'other',
                  'Other',
                ),
              ],
            ),
          ],
        ),
      ], locale: 'en');

      await runOnAllTranslators((svc) async {
        final arbTranslator = ARBTranslator.create(
          translationSvc: svc,
          arb: arb,
          sourceLanguage: 'en',
          logger: Logger<ARBTranslator>(logLevel),
        );

        final translationResult = await arbTranslator.translate(
          languages: ['no'],
          existFiles: {},
        );

        final resultNorwegian = translationResult['no']!;
        assert(resultNorwegian.locale == 'no');
        assert(resultNorwegian.items.length == 1);
        final itemNorwegian = resultNorwegian.findItemByKey('complexEntry')!;
        assert(itemNorwegian.value ==
            '[no] Hello {firstName}, your car is {vehicleType, select, sedan{[no] Sedan} cabriolet{[no] Solid roof cabriolet} truck{[no] 16 wheel truck} other{[no] Other}}. You have {count, plural, zero{[no] no new messages} one{[no] 1 new message} other{[no] {count} new messages}}');
        assert(itemNorwegian.annotation != null);
        assert(itemNorwegian.hasPlaceholders);
        assert(itemNorwegian.hasSelects);
        assert(itemNorwegian.hasPlurals);
        assert(itemNorwegian.annotation!.description ==
            'complex entry description');
        final firstNamePlaceholderNorwegian =
            itemNorwegian.findPlaceholderByKey('firstName')!;
        assert(firstNamePlaceholderNorwegian.type == 'String');
        assert(firstNamePlaceholderNorwegian.example == 'John Doe');
        final vehicleTypePlaceholderNorwegian =
            itemNorwegian.findPlaceholderByKey('vehicleType')!;
        assert(vehicleTypePlaceholderNorwegian.type == null);
        assert(vehicleTypePlaceholderNorwegian.example == null);
        final countPlaceholderNorwegian =
            itemNorwegian.findPlaceholderByKey('count')!;
        assert(countPlaceholderNorwegian.type == 'int');
        assert(countPlaceholderNorwegian.example == '1');
        final vehicleTypeSelectNorwegian =
            itemNorwegian.findSelectByKey('vehicleType')!;
        assert(vehicleTypeSelectNorwegian.fullText ==
            '{vehicleType, select, sedan{[no] Sedan} cabriolet{[no] Solid roof cabriolet} truck{[no] 16 wheel truck} other{[no] Other}}');
        assert(vehicleTypeSelectNorwegian.findOptionByKey('sedan')!.text ==
            '[no] Sedan');
        assert(vehicleTypeSelectNorwegian.findOptionByKey('cabriolet')!.text ==
            '[no] Solid roof cabriolet');
        assert(vehicleTypeSelectNorwegian.findOptionByKey('truck')!.text ==
            '[no] 16 wheel truck');
        assert(vehicleTypeSelectNorwegian.findOptionByKey('other')!.text ==
            '[no] Other');
        final countPluralNorwegian = itemNorwegian.findPluralByKey('count')!;
        assert(countPluralNorwegian.fullText ==
            '{count, plural, zero{[no] no new messages} one{[no] 1 new message} other{[no] {count} new messages}}');
        assert(countPluralNorwegian.findOptionByKey('zero')!.text ==
            '[no] no new messages');
        assert(countPluralNorwegian.findOptionByKey('one')!.text ==
            '[no] 1 new message');
        assert(countPluralNorwegian.findOptionByKey('other')!.text ==
            '[no] {count} new messages');
      });
    });

    test('when translate specific key should ignore others', () async {
      final arb = ARBContent([
        ARBItem(
          key: 'hello_world_1',
          value: 'Hello world 1',
          number: 0,
        ),
        ARBItem(
          key: 'hello_world_2',
          value: 'Hello world 2',
          number: 1,
        ),
        ARBItem(
          key: 'hello_world_3',
          value: 'Hello world 3',
          number: 1,
        )
      ], locale: 'en');

      final arbSpanish = ARBContent([
        ARBItem(
          key: 'hello_world_1',
          value: 'es Hello world 1 original',
          number: 0,
        ),
        ARBItem(
          key: 'hello_world_2',
          value: 'es Hello world 2 original',
          number: 1,
        ),
        ARBItem(
          key: 'hello_world_3',
          value: 'es Hello world 3 original',
          number: 2,
        )
      ], locale: 'es');

      final arbItalian = ARBContent([
        ARBItem(
          key: 'hello_world_1',
          value: 'it Hello world 1 original',
          number: 0,
        ),
      ], locale: 'it');

      await runOnAllTranslators((svc) async {
        final arbTranslator = ARBTranslator.create(
          translationSvc: svc,
          arb: arb,
          sourceLanguage: 'en',
          logger: Logger<ARBTranslator>(logLevel),
        );

        final translation = await arbTranslator.translate(
          languages: ['es', 'it'],
          existFiles: {
            'es': arbSpanish,
            'it': arbItalian,
          },
          keys: ['hello_world_2'],
        );

        final translationItalian = translation['it']!;
        final translationSpanish = translation['es']!;

        // only hello_world_2 should be translated
        // other items should not change
        final spanishHelloWorld1 =
            translationSpanish.findItemByKey('hello_world_1');
        assert(spanishHelloWorld1?.value == 'es Hello world 1 original');
        final italianHelloWorld1 =
            translationItalian.findItemByKey('hello_world_1');
        assert(italianHelloWorld1?.value == 'it Hello world 1 original');

        final spanishHelloWorld2 =
            translationSpanish.findItemByKey('hello_world_2');
        assert(spanishHelloWorld2?.value == '[es] Hello world 2');
        final italianHelloWorld2 =
            translationItalian.findItemByKey('hello_world_2');
        assert(italianHelloWorld2?.value == '[it] Hello world 2');

        final spanishHelloWorld3 =
            translationSpanish.findItemByKey('hello_world_3');
        assert(spanishHelloWorld3?.value == 'es Hello world 3 original');
        final italianHelloWorld3 =
            translationItalian.findItemByKey('hello_world_3');
        assert(italianHelloWorld3 == null);
      });
    });

    test('when ignore specific key should translate others', () async {
      final arb = ARBContent([
        ARBItem(
          key: 'hello_world_1',
          value: 'Hello world 1',
          number: 0,
        ),
        ARBItem(
          key: 'hello_world_2',
          value: 'Hello world 2',
          number: 1,
        ),
        ARBItem(
          key: 'hello_world_3',
          value: 'Hello world 3',
          number: 1,
        )
      ], locale: 'en');

      final arbSpanish = ARBContent([
        ARBItem(
          key: 'hello_world_1',
          value: 'es Hello world 1 original',
          number: 0,
        ),
        ARBItem(
          key: 'hello_world_2',
          value: 'es Hello world 2 original',
          number: 1,
        ),
        ARBItem(
          key: 'hello_world_3',
          value: 'es Hello world 3 original',
          number: 2,
        )
      ], locale: 'es');

      final arbItaly = ARBContent([
        ARBItem(
          key: 'hello_world_1',
          value: 'it Hello world 1 original',
          number: 0,
        ),
      ], locale: 'it');

      await runOnAllTranslators((svc) async {
        final arbTranslator = ARBTranslator.create(
          translationSvc: svc,
          arb: arb,
          sourceLanguage: 'en',
          logger: Logger<ARBTranslator>(logLevel),
        );

        final translation = await arbTranslator.translate(
          languages: ['es', 'it'],
          existFiles: {
            'es': arbSpanish,
            'it': arbItaly,
          },
          ignoreKeys: ['hello_world_1'],
        );

        final translationItaly = translation['it']!;
        final translationSpanish = translation['es']!;

        // only hello_world_2 should be translated
        // other items should not change
        final spanishHelloWorld1 =
            translationSpanish.findItemByKey('hello_world_1');
        assert(spanishHelloWorld1?.value == 'es Hello world 1 original');
        final italyHelloWorld1 =
            translationItaly.findItemByKey('hello_world_1');
        assert(italyHelloWorld1?.value == 'it Hello world 1 original');

        final spanishHelloWorld2 =
            translationSpanish.findItemByKey('hello_world_2');
        assert(spanishHelloWorld2?.value == 'es Hello world 2 original');
        final italyHelloWorld2 =
            translationItaly.findItemByKey('hello_world_2');
        assert(italyHelloWorld2?.value == '[it] Hello world 2');

        final spanishHelloWorld3 =
            translationSpanish.findItemByKey('hello_world_3');
        assert(spanishHelloWorld3?.value == 'es Hello world 3 original');
        final italyHelloWorld3 =
            translationItaly.findItemByKey('hello_world_3');
        assert(italyHelloWorld3?.value == '[it] Hello world 3');
      });
    });

    test('when should replace exist entries should work', () async {
      final arb = ARBContent([
        ARBItem(
          key: 'hello_world_1',
          value: 'Hello world 1',
          number: 0,
        ),
        ARBItem(
          key: 'hello_world_2',
          value: 'Hello world 2',
          number: 1,
        ),
        ARBItem(
          key: 'hello_world_3',
          value: 'Hello world 3',
          number: 1,
        )
      ], locale: 'en');

      final arbSpanish = ARBContent([
        ARBItem(
          key: 'hello_world_1',
          value: 'es Hello world 1 original',
          number: 0,
        ),
        ARBItem(
          key: 'hello_world_2',
          value: 'es Hello world 2 original',
          number: 1,
        ),
        ARBItem(
          key: 'hello_world_3',
          value: 'es Hello world 3 original',
          number: 2,
        )
      ], locale: 'es');

      final arbItaly = ARBContent([
        ARBItem(
          key: 'hello_world_1',
          value: 'it Hello world 1 original',
          number: 0,
        ),
      ], locale: 'it');

      await runOnAllTranslators((svc) async {
        final arbTranslator = ARBTranslator.create(
          translationSvc: svc,
          arb: arb,
          sourceLanguage: 'en',
          logger: Logger<ARBTranslator>(logLevel),
        );

        final translation = await arbTranslator.translate(
          languages: ['es', 'it'],
          existFiles: {
            'es': arbSpanish,
            'it': arbItaly,
          },
          overrideExistEntries: true,
        );

        final translationItaly = translation['it']!;
        final translationSpanish = translation['es']!;

        // only hello_world_2 should be translated
        // other items should not change
        final spanishHelloWorld1 =
            translationSpanish.findItemByKey('hello_world_1');
        assert(spanishHelloWorld1?.value == '[es] Hello world 1');
        final italyHelloWorld1 =
            translationItaly.findItemByKey('hello_world_1');
        assert(italyHelloWorld1?.value == '[it] Hello world 1');

        final spanishHelloWorld2 =
            translationSpanish.findItemByKey('hello_world_2');
        assert(spanishHelloWorld2?.value == '[es] Hello world 2');
        final italyHelloWorld2 =
            translationItaly.findItemByKey('hello_world_2');
        assert(italyHelloWorld2?.value == '[it] Hello world 2');

        final spanishHelloWorld3 =
            translationSpanish.findItemByKey('hello_world_3');
        assert(spanishHelloWorld3?.value == '[es] Hello world 3');
        final italyHelloWorld3 =
            translationItaly.findItemByKey('hello_world_3');
        assert(italyHelloWorld3?.value == '[it] Hello world 3');
      });
    });
  });

  group('translation merger', () {
    final targets = ['ko', 'de'];

    final original = ARBContent([
      ARBItem(
        key: 'hello_world',
        value: 'Hello world',
        number: 0,
      ),
      ARBItem(
        key: 'translation',
        value: 'Translation',
        number: 1,
      ),
    ], locale: 'en');

    final originals = {
      'ko': ARBContent(
        [
          ARBItem(
            key: 'hello_world',
            value: '안녕하세요 세계',
            number: 0,
          ),
          ARBItem(
            key: 'translation',
            value: '번역',
            number: 1,
          ),
        ],
        locale: 'ko',
      ),
      'de': null,
    };

    final translations = {
      'ko': ARBContentTranslated(
        original.items
            .map((x) => ARBItemTranslated(
                  key: x.key,
                  number: x.number,
                  value: '[ko] ${x.value}',
                  modificationType: ARBItemModificationType.edited,
                  originalValue: originals['ko']!.findItemByKey(x.key)?.value,
                  annotation: null,
                ))
            .toList(),
        locale: 'ko',
      ),
      'de': ARBContentTranslated(
        original.items
            .map((x) => ARBItemTranslated(
                  key: x.key,
                  number: x.number,
                  value: '[de] ${x.value}',
                  modificationType: ARBItemModificationType.added,
                  originalValue: null,
                  annotation: null,
                ))
            .toList(),
        locale: 'de',
      ),
    };

    test('when apply changes should create correct ARB', () {
      final applier = ARBTranslationApplier(
        original: original,
        originalLocale: 'en',
        translationTargets: targets,
        translations: translations,
        originals: originals,
        logger: Logger<ARBTranslationApplier>(logLevel),
      );

      final applying = TranslationApplying(
        TranslationApplyingType.applyAll,
      );

      while (applier.canMoveNext) {
        applier.processCurrentChange(applying);
        applier.moveNext();
      }

      final result = applier.getResults();
      final resultKorean = result['ko']!;
      final resultDeutsch = result['de']!;

      assert(resultKorean.findItemByKey('hello_world')?.value ==
          '[ko] Hello world');
      assert(resultDeutsch.findItemByKey('hello_world')?.value ==
          '[de] Hello world');
      assert(resultKorean.findItemByKey('translation')?.value ==
          '[ko] Translation');
      assert(resultDeutsch.findItemByKey('translation')?.value ==
          '[de] Translation');
    });

    test('when discard all changes should remain unchanged', () {
      final applier = ARBTranslationApplier(
        original: original,
        originalLocale: 'en',
        translationTargets: targets,
        translations: translations,
        originals: originals,
        logger: Logger<ARBTranslationApplier>(logLevel),
      );

      final applying = TranslationApplying(
        TranslationApplyingType.discardAll,
      );

      while (applier.canMoveNext) {
        applier.processCurrentChange(applying);
        applier.moveNext();
      }

      final result = applier.getResults();
      final resultKorean = result['ko']!;
      final resultDeutsch = result['de']!;

      assert(resultKorean.findItemByKey('hello_world')?.value == '안녕하세요 세계');
      assert(resultDeutsch.findItemByKey('hello_world') == null);
      assert(resultKorean.findItemByKey('translation')?.value == '번역');
      assert(resultDeutsch.findItemByKey('translation') == null);
    });

    test(
        'when apply changes only for specific locale should create correct ARB',
        () {
      final applier = ARBTranslationApplier(
        original: original,
        originalLocale: 'en',
        translationTargets: targets,
        translations: translations,
        originals: originals,
        logger: Logger<ARBTranslationApplier>(logLevel),
      );

      final applying = TranslationApplying(
          TranslationApplyingType.selectTranslations,
          selectedLanguages: ['ko']);

      while (applier.canMoveNext) {
        applier.processCurrentChange(applying);
        applier.moveNext();
      }

      final result = applier.getResults();
      final resultKorean = result['ko']!;
      final resultDeutsch = result['de']!;

      assert(resultKorean.findItemByKey('hello_world')?.value ==
          '[ko] Hello world');
      assert(resultDeutsch.findItemByKey('hello_world') == null);
      assert(resultKorean.findItemByKey('translation')?.value ==
          '[ko] Translation');
      assert(resultDeutsch.findItemByKey('translation') == null);
    });

    test(
        'when apply changes only for specific locale should create correct ARB 2',
        () {
      final applier = ARBTranslationApplier(
        original: original,
        originalLocale: 'en',
        translationTargets: targets,
        translations: translations,
        originals: originals,
        logger: Logger<ARBTranslationApplier>(logLevel),
      );

      final applying = TranslationApplying(
          TranslationApplyingType.selectTranslations,
          selectedLanguages: ['de']);

      while (applier.canMoveNext) {
        applier.processCurrentChange(applying);
        applier.moveNext();
      }

      final result = applier.getResults();
      final resultKorean = result['ko']!;
      final resultDeutsch = result['de']!;

      assert(resultKorean.findItemByKey('hello_world')?.value == '안녕하세요 세계');
      assert(resultDeutsch.findItemByKey('hello_world')?.value ==
          '[de] Hello world');
      assert(resultKorean.findItemByKey('translation')?.value == '번역');
      assert(resultDeutsch.findItemByKey('translation')?.value ==
          '[de] Translation');
    });

    test('when one locale has more items they should keep unchanged', () {
      Map<String, ARBContent?> originalsCopy =
          originals.map((key, value) => MapEntry(key, value));
      originalsCopy['it'] = ARBContent([
        ARBItem(
          key: 'hello_world',
          value: 'Ciao mondo',
          number: 0,
        ),
        ARBItem(
          key: 'translation',
          value: 'Traduzione',
          number: 1,
        ),
        ARBItem(
          key: 'third_item',
          value: 'Terzo elemento',
          number: 2,
        ),
      ], locale: 'it');

      Map<String, ARBContentTranslated> translationsCopy =
          translations.map((key, value) => MapEntry(key, value));
      translationsCopy['it'] = ARBContentTranslated(
        original.items
            .map((x) => ARBItemTranslated(
                  key: x.key,
                  number: x.number,
                  value: '[it] ${x.value}',
                  modificationType: ARBItemModificationType.edited,
                  originalValue:
                      originalsCopy['it']!.findItemByKey(x.key)?.value,
                  annotation: null,
                ))
            .toList(),
        locale: 'it',
      );

      List<String> targetsCopy = targets.toList();
      targetsCopy.add('it');

      final applier = ARBTranslationApplier(
        original: original,
        originalLocale: 'en',
        translationTargets: targetsCopy,
        translations: translationsCopy,
        originals: originalsCopy,
        logger: Logger<ARBTranslationApplier>(logLevel),
      );

      final applying = TranslationApplying(
        TranslationApplyingType.applyAll,
      );

      while (applier.canMoveNext) {
        applier.processCurrentChange(applying);
        applier.moveNext();
      }

      final result = applier.getResults();
      final resultKorean = result['ko']!;
      final resultDeutsch = result['de']!;
      final resultItalian = result['it']!;

      assert(resultKorean.findItemByKey('hello_world')?.value ==
          '[ko] Hello world');
      assert(resultDeutsch.findItemByKey('hello_world')?.value ==
          '[de] Hello world');
      assert(resultItalian.findItemByKey('hello_world')?.value ==
          '[it] Hello world');
      assert(resultKorean.findItemByKey('translation')?.value ==
          '[ko] Translation');
      assert(resultDeutsch.findItemByKey('translation')?.value ==
          '[de] Translation');
      assert(resultItalian.findItemByKey('translation')?.value ==
          '[it] Translation');
      // this item doesn't exist in other ARBs and should be unchanged
      assert(
          resultItalian.findItemByKey('third_item')?.value == 'Terzo elemento');
    });
  });

  group('github issues', () {
    final allTranslators = [
      FakeTranslationService(),
      FakeTranslationServiceSupportsBulkTranslationToMultipleTargets(),
      FakeTranslationServiceSupportsBulkTranslationToSingleTarget(),
      FakeTranslationServiceSupportsTranslationToMultipleTargets(),
    ];

    // https://github.com/sxtfv/flutter_arb_translator/issues/6
    test('issue #6', () async {
      final sampleFilePathWithoutAnnotation =
          path.absolute('test_assets/empty_strings_en.arb');

      final parser = ARBParser(
        logger: Logger<ARBParser>(logLevel),
      );

      final arbContent = parser.parse(sampleFilePathWithoutAnnotation);

      for (final translator in allTranslators) {
        final arbTranslator = ARBTranslator.create(
          translationSvc: translator,
          arb: arbContent,
          sourceLanguage: 'en',
          logger: Logger<ARBTranslator>(logLevel),
        );

        final translation = await arbTranslator.translate(
          languages: ['de'],
          existFiles: {},
        );

        final applier = ARBTranslationApplier(
          original: arbContent,
          originalLocale: 'en',
          translationTargets: ['de'],
          translations: translation,
          originals: {'en': arbContent},
          logger: Logger<ARBTranslationApplier>(logLevel),
        );

        final applying = TranslationApplying(
          TranslationApplyingType.applyAll,
        );

        while (applier.canMoveNext) {
          applier.processCurrentChange(applying);
          applier.moveNext();
        }

        final result = applier.getResults();
        final resultDe = result['de']!;

        assert(resultDe.findItemByKey('findTitle')!.value.isEmpty);
        assert(resultDe.findItemByKey('findTopMsg')!.value.isEmpty);
        assert(resultDe.findItemByKey('findBottomMsg')!.value.isEmpty);
        assert(resultDe.findItemByKey('capacityInfo')!.value ==
            '{capacities} {childBeds, plural, zero{} other{[de] Child beds: {childBeds}}}');
      }
    });
  });
}
