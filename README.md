# control_de_gastos

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

Configurar aplicacíon:
Luego de clonar del repositorio ""
ejecutar en una consola lo soguiente:
- flutter clean
- flutter pub get
- flutter pub run build_runner build --delete-conflicting-outputs

- flutter build apk --release; mv build/app/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/control-de-gastos-v1.1.0.apk

Modo depulacion USB:
- ir deade el terminal a cd "C:\Users\narav\AppData\Local\Android\Sdk\platform-tools"
- .\adb pair 192.168.100.93:37635
- .\adb connect 192.168.100.93:PUERTO_NUEVO