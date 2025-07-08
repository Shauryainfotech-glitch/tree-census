import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLocale = localeProvider.locale?.languageCode ?? 'en';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Select Language'),
          ),
          RadioListTile<String>(
            title: const Text('English'),
            value: 'en',
            groupValue: currentLocale,
            onChanged: (value) {
              localeProvider.setLocale(const Locale('en'));
            },
          ),
          RadioListTile<String>(
            title: const Text('Hindi'),
            value: 'hi',
            groupValue: currentLocale,
            onChanged: (value) {
              localeProvider.setLocale(const Locale('hi'));
            },
          ),
          RadioListTile<String>(
            title: const Text('Marathi'),
            value: 'mr',
            groupValue: currentLocale,
            onChanged: (value) {
              localeProvider.setLocale(const Locale('mr'));
            },
          ),
        ],
      ),
    );
  }
}
