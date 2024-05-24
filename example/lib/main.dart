import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// lib/l10n already contains translations for Spanish and doesn't contain
/// translations for Italian and Deutsch
/// If you will run the application and try to change the language it will
/// fail until you add them using flutter_arb_translator tool

/// 1. Open dev_assets/flutter_arb_translator_config.json
/// 2. Add AzureCognitiveServices or YandexCloud or GoogleCloud config
/// 3. Run the following command:
/// flutter pub run flutter_arb_translator:main --from en --to de --to it --service azure
/// where --service azure depends on service you want to use. For Yandex it will
/// be --service yandex, for Google Cloud it will be --service google, for
/// DeepL it will be --deepl.
/// Once you completed these steps translations will be created and you will
/// be able to change the language
void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _supportedLocales = const [
    Locale('en', ''), // English, no country code
    Locale('es', ''), // Spanish, no country code
    Locale('it', ''), // Italian, no country code
    Locale('de', ''), // Deutsch, no country code
  ];

  String _selectedLocale = 'en';

  void _changeLocale(String newLocale) {
    if (newLocale.isEmpty) {
      return;
    }

    if (!_supportedLocales.map((x) => x.languageCode).contains(newLocale)) {
      return;
    }

    setState(() {
      _selectedLocale = newLocale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: _supportedLocales,
      locale: Locale(_selectedLocale),
      home: MyHomePage(
        title: 'Demo Home Page',
        supportedLocales: _supportedLocales,
        selectedLocale: _selectedLocale,
        selectLocale: _changeLocale,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
    required this.title,
    required this.supportedLocales,
    required this.selectedLocale,
    required this.selectLocale,
  }) : super(key: key);

  final String title;
  final List<Locale> supportedLocales;
  final String selectedLocale;
  final void Function(String) selectLocale;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale.pick_language,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(
                  height: 4,
                ),
                DropdownButton<String>(
                  isExpanded: true,
                  value: widget.selectedLocale,
                  items: widget.supportedLocales
                      .map(
                        (x) => DropdownMenuItem<String>(
                          value: x.languageCode,
                          child: Text(x.languageCode),
                        ),
                      )
                      .toList(),
                  onChanged: (String? v) {
                    if (v == null) {
                      return;
                    }

                    widget.selectLocale.call(v);
                  },
                ),
                Text(
                  locale.make_sure_you_added_italian_and_deutsch_translations,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontSize:
                            Theme.of(context).textTheme.bodyLarge!.fontSize! *
                                0.85,
                      ),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      '${locale.you_have_pushed_the_button_this_many_times}:',
                    ),
                    Text(
                      '$_counter',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: locale.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
