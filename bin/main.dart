import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:args/args.dart' as args;

import 'package:flutter_arb_translator/service/translation/base.dart';
import 'package:flutter_arb_translator/service/arb/parser.dart';
import 'package:flutter_arb_translator/service/arb/writer.dart';
import 'package:flutter_arb_translator/service/translation/service_factory.dart';
import 'package:flutter_arb_translator/service/arb/translator.dart';
import 'package:flutter_arb_translator/service/log/logger.dart';
import 'package:flutter_arb_translator/service/arb/translation_applier.dart';
import 'package:flutter_arb_translator/models/translation_applying.dart';
import 'package:flutter_arb_translator/models/arb_content.dart';
import 'package:flutter_arb_translator/models/translation_options.dart';
import 'package:flutter_arb_translator/utils/extensions.dart';

const logLevel = LogLevel.production;

void main(List<String> arguments) async {
  final argsParser = _initArgsParser();
  final args = argsParser.parse(arguments);

  if (args[_ArgsNames.help] == true) {
    print(argsParser.usage);
    return;
  }

  final dir = args[_ArgsNames.dir] as String;
  final serviceName = args[_ArgsNames.service] as String?;
  final from = args[_ArgsNames.from] as String?;
  final to = args[_ArgsNames.to] as List<String>;
  final interactive = args[_ArgsNames.interactive] as bool;
  final translationOptions = _createTranslationOptions(
    args,
  );

  if (to.contains(from)) {
    to.remove(from);
  }

  List<String> requiredArgsErrors = [];

  if (serviceName == null) {
    requiredArgsErrors.add('Please specify [service] option [azure, '
        'yandex, google, deepl]');
  }

  if (from == null) {
    requiredArgsErrors.add('Please specify [from] option');
  }

  if (to.isEmpty) {
    requiredArgsErrors.add('At least 1 [to] option is required');
  }

  if (requiredArgsErrors.isNotEmpty) {
    stdout.writeln('\x1B[33m${requiredArgsErrors.join('\n')}\x1B[0m');
    stdout.writeln(argsParser.usage);
    return;
  }

  final absDir = path.absolute(dir);
  if (!Directory(absDir).existsSync()) {
    stdout.writeln('\x1B[33mDirectory $absDir does not exist.\x1B[0m');
    return;
  }

  final sourceArbPath = path.join(absDir, 'app_$from.arb');
  if (!File(sourceArbPath).existsSync()) {
    stdout.writeln('\x1B[33mFile $sourceArbPath does not exist.\x1B[0m');
    return;
  }

  if (!TranslationServiceFactory.checkConfigurationFileExists()) {
    final configFilePath = TranslationServiceFactory.getConfigurationFilePath();
    stdout.writeln(
        '\x1B[33mConfiguration file $configFilePath does not exist.\x1B[0m');
    return;
  }

  final arbParser = ARBParser(
    logger: Logger<ARBParser>(logLevel),
  );

  ARBContent arb;
  try {
    arb = arbParser.parse(sourceArbPath);
  } on Exception catch (ex) {
    Logger(logLevel).error('Failed to read arb file', ex);
    stdout.writeln('\x1B[33mFailed to read ARB file $sourceArbPath\x1B[0m');
    return;
  }

  TranslationServiceType serviceType;
  switch (serviceName!.toLowerCase()) {
    case 'azure':
      serviceType = TranslationServiceType.azureCognitiveServices;
      break;
    case 'yandex':
      serviceType = TranslationServiceType.yandex;
      break;
    case 'google':
      serviceType = TranslationServiceType.googleCloud;
      break;
    case 'deepl':
      serviceType = TranslationServiceType.deepL;
      break;
    default:
      throw Exception('Unsupported service type: $serviceName');
  }

  AbstractTranslationService translationSvc;
  try {
    translationSvc = await TranslationServiceFactory(
      logger: Logger<TranslationServiceFactory>(logLevel),
    ).create(serviceType);
  } on Exception catch (_) {
    final configFilePath = TranslationServiceFactory.getConfigurationFilePath();
    stdout.writeln('\x1B[33mFailed to initialize $serviceName service. Please '
        'fix $configFilePath file\x1B[0m');
    return;
  }

  final existFiles = to
      .map((x) => MapEntry(x, path.join(absDir, 'app_$x.arb')))
      .map(
        (x) => MapEntry(
          x.key,
          File(x.value).existsSync() ? arbParser.parse(x.value) : null,
        ),
      )
      .toMap();

  final arbTranslator = ARBTranslator.create(
    translationSvc: translationSvc,
    arb: arb,
    sourceLanguage: from!,
    logger: Logger<ARBTranslator>(logLevel),
  );

  final translations = await arbTranslator.translate(
    languages: to,
    existFiles: existFiles,
    options: translationOptions,
  );

  final applier = ARBTranslationApplier(
    original: arb,
    originalLocale: from,
    translations: translations,
    translationTargets: to,
    originals: existFiles,
    logger: Logger<ARBTranslationApplier>(logLevel),
  );

  bool shouldCancel = false;
  while (applier.canMoveNext) {
    applier.stdoutCurrentChange();

    if (interactive) {
      applier.requestApplyCurrentTranslationConfirmation();
      final applying = applier.readTranslationApplyFromConsole();
      if (applying.type == TranslationApplyingType.cancel) {
        shouldCancel = true;
        break;
      } else {
        applier.processCurrentChange(applying);
      }
    } else {
      applier.processCurrentChange(TranslationApplying(
        TranslationApplyingType.applyAll,
      ));
    }

    applier.moveNext();
  }

  if (shouldCancel) {
    stdout.writeln('Translation applying canceled');
    return;
  }

  final results = applier.getResults();
  for (final kv in results.entries) {
    final lang = kv.key;

    final writer = ARBWriter(
      kv.value,
      logger: Logger<ARBWriter>(logLevel),
    );

    writer.writeToFile(path.join(absDir, 'app_$lang.arb'));
  }
}

args.ArgParser _initArgsParser() {
  final argsParser = args.ArgParser();

  argsParser.addOption(
    _ArgsNames.dir,
    help: _ArgsHelp.directory,
    defaultsTo: 'lib/l10n',
  );

  argsParser.addOption(
    _ArgsNames.service,
    help: _ArgsHelp.service,
    allowed: [
      'azure',
      'yandex',
      'google',
      'deepl',
    ],
  );

  argsParser.addOption(
    _ArgsNames.from,
    help: _ArgsHelp.from,
    valueHelp: 'en',
  );

  argsParser.addMultiOption(
    _ArgsNames.to,
    help: _ArgsHelp.to,
    valueHelp: 'es,pt',
  );

  argsParser.addMultiOption(
    _ArgsNames.key,
    abbr: 'k',
    help: _ArgsHelp.keys,
    valueHelp: 'key1,key2',
  );

  argsParser.addMultiOption(
    _ArgsNames.ignoreKeys,
    help: _ArgsHelp.ignoreKeys,
    valueHelp: 'key1,key2',
  );

  argsParser.addFlag(
    _ArgsNames.override,
    abbr: 'o',
    help: _ArgsHelp.override,
    defaultsTo: false,
  );

  argsParser.addFlag(
    _ArgsNames.interactive,
    abbr: 'i',
    help: _ArgsHelp.interactive,
    defaultsTo: false,
  );

  argsParser.addFlag(
    _ArgsNames.help,
    abbr: 'h',
    help: _ArgsHelp.help,
    defaultsTo: false,
  );

  argsParser.addFlag(
    _ArgsNames.translateEqual,
    abbr: 'e',
    help: _ArgsHelp.translateEqual,
    defaultsTo: false,
  );

  return argsParser;
}

TranslationOptions _createTranslationOptions(args.ArgResults args) {
  final keys = args[_ArgsNames.key] as List<String>;
  final ignoreKeys = args[_ArgsNames.ignoreKeys] as List<String>;
  final override = args[_ArgsNames.override] as bool;
  final translateEqual = args[_ArgsNames.translateEqual] as bool;

  var result = TranslationOptions.createDefault();

  if (override) {
    result = result.withFlags(
      overrideExist: override,
    );
  }

  if (translateEqual) {
    result = result.withFlags(
      translateEqual: translateEqual,
    );
  }

  if (keys.isNotEmpty) {
    result = result.withKeys(keys);
  }

  if (ignoreKeys.isNotEmpty) {
    result = result.withIgnoreKeys(ignoreKeys);
  }

  return result;
}

class _ArgsNames {
  static const dir = 'dir';
  static const service = 'service';
  static const to = 'to';
  static const from = 'from';
  static const key = 'key';
  static const ignoreKeys = 'ignore';
  static const override = 'override';
  static const help = 'help';
  static const interactive = 'interactive';
  static const translateEqual = 'translate-equal';
}

class _ArgsHelp {
  static const directory = 'Directory containing .arb files';
  static const service = '[REQUIRED] Translation service which will be used';
  static const to =
      '[REQUIRED] List of languages to which ARB should be translated. '
      'At least 1 language required';
  static const from = '[REQUIRED] Main language, ARB will be translated from '
      'this language to targets';
  static const keys =
      'If defined, only items with given keys will be translated';
  static const ignoreKeys = 'If defined, items with given keys will be skipped '
      'from translation';
  static const override = 'If true and if ARB file with defined target '
      'language already exist all items will be replaced with new translation.'
      ' Otherwise, they will be not modified';
  static const help = 'Print usage instructions';
  static const interactive = 'You will be prompted before applying translation';
  static const translateEqual = 'If true and if ARB file with defined target '
      'language contains item with the same value as source ARB file it will '
      'be translated';
}
