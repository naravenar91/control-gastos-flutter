import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'main_screen.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Navegar a MainScreen después de un retraso de 2 segundos
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
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
                  color: Colors.red.shade700, // Usando el color temático de la app
                ),
              ),
            ),

            // Logo Central
            Center(
              child: Image.asset(
                'assets/icon/saving_money_logo.png',
                width: 180,
                height: 180,
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
