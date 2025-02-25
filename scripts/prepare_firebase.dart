import 'dart:io';

void main() {
  final template = File('web/firebase-config.template.js').readAsStringSync();

  final config = template
          .replaceAll('FIREBASE_API_KEY',
              const String.fromEnvironment('FIREBASE_API_KEY'))
          .replaceAll('FIREBASE_AUTH_DOMAIN',
              const String.fromEnvironment('FIREBASE_AUTH_DOMAIN'))
      // ... replace other values
      ;

  File('web/firebase-config.js').writeAsStringSync(config);
}
