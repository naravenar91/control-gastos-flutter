import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_screen.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final LocalAuthentication _auth = LocalAuthentication();
  String? _authError;

  @override
  void initState() {
    super.initState();
    // Navegar a MainScreen después de un retraso de 2 segundos, con chequeo de seguridad
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _checkSecurity();
      }
    });
  }

  Future<void> _checkSecurity() async {
    setState(() {
      _authError = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final bool isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;

    if (isBiometricEnabled) {
      try {
        final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
        final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

        if (!canAuthenticate) {
          _navigateToHome();
          return;
        }

        final bool didAuthenticate = await _auth.authenticate(
          localizedReason: 'Autentícate para acceder',
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
          ),
        );

        if (didAuthenticate) {
          _navigateToHome();
        } else {
          // Si falla o cancela, mostramos error en lugar de cerrar la app
          setState(() {
            _authError = 'Autenticación cancelada o fallida. Intenta nuevamente.';
          });
        }
      } on PlatformException catch (e) {
        debugPrint('Error en autenticación: $e');
        setState(() {
          _authError = 'Error de seguridad: ${e.message}. Reintenta por favor.';
        });
      }
    } else {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Título Superior
            Padding(
              padding: const EdgeInsets.only(top: 60.0),
              child: Text(
                'Control de Gastos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ),

            // Logo Central y Botón de Reintento
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/icon/saving_money_logo.png',
                    width: 180,
                    height: 180,
                  ),
                  if (_authError != null) ...[
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _authError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _checkSecurity,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Versión Inferior
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(
                      'V${snapshot.data!.version}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    );
                  }
                  return const Text(
                    'Cargando...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
