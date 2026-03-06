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
      body: Stack(
        children: [
          // Fondo con curvas personalizadas
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundPainter(),
            ),
          ),
          SafeArea(
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
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                // Contenido Central (Logo, Error, Botones)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/icon/saving_money_logo.png',
                          width: 180,
                          height: 180,
                        ),
                      ),
                      if (_authError != null) ...[
                        const SizedBox(height: 40),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.red.shade100),
                            ),
                            child: const Column(
                              children: [
                                Text(
                                  'Autenticación cancelada o fallida.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Intenta nuevamente.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _checkSecurity,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: () => SystemNavigator.pop(),
                              icon: const Icon(Icons.exit_to_app),
                              label: const Text('Salir'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                              ),
                            ),
                          ],
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
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }
                      return const Text(
                        'Cargando...',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Curva Superior Naranja
    final orangePaint = Paint()
      ..color = Colors.orange.shade300.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final orangePath = Path();
    orangePath.moveTo(0, size.height * 0.15);
    orangePath.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.05,
      size.width,
      size.height * 0.1,
    );
    orangePath.lineTo(size.width, 0);
    orangePath.lineTo(0, 0);
    orangePath.close();
    canvas.drawPath(orangePath, orangePaint);

    // Curva Inferior Celeste
    final bluePaint = Paint()
      ..color = Colors.blue.shade200.withOpacity(0.25)
      ..style = PaintingStyle.fill;

    final bluePath = Path();
    bluePath.moveTo(0, size.height * 0.9);
    bluePath.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.85,
      size.width,
      size.height * 0.95,
    );
    bluePath.lineTo(size.width, size.height);
    bluePath.lineTo(0, size.height);
    bluePath.close();
    canvas.drawPath(bluePath, bluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
