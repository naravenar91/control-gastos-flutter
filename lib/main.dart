import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Para localización de Intl

import 'domain/repositories/categoria_repository.dart';
import 'domain/repositories/gasto_repository.dart';
import 'domain/repositories/presupuesto_repository.dart';
import 'infrastructure/app_database.dart';
import 'infrastructure/repositories/drift_categoria_repository.dart';
import 'infrastructure/repositories/drift_gasto_repository.dart';
import 'infrastructure/repositories/drift_presupuesto_repository.dart';
import 'infrastructure/services/excel_export_service.dart';
import 'infrastructure/services/pdf_export_service.dart';
import 'presentation/bloc/export_bloc.dart';
import 'presentation/bloc/gasto_bloc.dart';
import 'presentation/bloc/gasto_event.dart';
import 'presentation/bloc/theme_cubit.dart';
import 'presentation/pages/main_screen.dart';
import 'presentation/pages/splash_page.dart';
import 'presentation/theme_provider.dart';
import 'infrastructure/notification_service.dart';

/// Punto de entrada principal de la aplicación Flutter.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Asegura que los bindings de Flutter estén inicializados antes de usar plugins.
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = NotificationService(); // Instancia única

  try {
    print("***** Intentando inicializar notificaciones *****");
    await notificationService.init();
    await notificationService.requestPermissions();
    print("***** Notificaciones listas *****");
  } catch (e) {
    // Si falla el icono, la app imprimirá el error pero NO se cerrará
    debugPrint("ADVERTENCIA: Error al inicializar notificaciones (Icono no encontrado): $e");
  }

  // Instancia la base de datos de la aplicación.
  // Esta instancia será inyectada en los repositorios.
  final AppDatabase database = AppDatabase();

  runApp(
    // MultiRepositoryProvider provee las implementaciones concretas de los repositorios
    // a través del árbol de widgets. Esto permite que los BLoCs los consuman.
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppDatabase>(
          create: (context) => database,
        ),
        RepositoryProvider<CategoriaRepository>(
          create: (context) => DriftCategoriaRepository(database),
        ),
        RepositoryProvider<GastoRepository>(
          create: (context) => DriftGastoRepository(database),
        ),
        RepositoryProvider<PresupuestoRepository>(
          create: (context) => DriftPresupuestoRepository(database),
        ),
        RepositoryProvider<ExcelExportService>(
          create: (context) => ExcelExportService(),
        ),
        RepositoryProvider<PdfExportService>(
          create: (context) => PdfExportService(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          // ThemeCubit se encarga de manejar el tema claro/oscuro de la aplicación.
          BlocProvider<ThemeCubit>(
            create: (context) => ThemeCubit(),
          ),
          // GastoBloc se encarga de la lógica de negocio de los gastos.
          // Consume los repositorios de Gasto y Categoría inyectados.
          BlocProvider<GastoBloc>(
            create: (context) => GastoBloc(
              context.read<GastoRepository>(),
              context.read<CategoriaRepository>(),
            )..add(LoadGastos(DateTime.now())), // Carga inicial de gastos para el mes actual.
          ),
          // ExportBloc se encarga de la exportación de reportes.
          BlocProvider<ExportBloc>(
            create: (context) => ExportBloc(
              gastoRepository: context.read<GastoRepository>(),
              categoriaRepository: context.read<CategoriaRepository>(),
              excelExportService: context.read<ExcelExportService>(),
              pdfExportService: context.read<PdfExportService>(),
            ),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );

  // Considerar cerrar la base de datos cuando la aplicación se detenga por completo.
  // Esto puede hacerse con un WidgetsBindingObserver o manejando el ciclo de vida de la app
  // si la base de datos es un singleton o tiene una vida útil gestionada.
  // database.close(); // NO LLAMAR AQUÍ DIRECTAMENTE, ya que la app aún está corriendo.
}

/// Widget raíz de la aplicación.
///
/// Configura el [MaterialApp] con el tema dinámico y la localización.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // BlocBuilder para reaccionar a los cambios de estado de ThemeCubit
    // y aplicar el tema correspondiente (claro u oscuro).
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          scaffoldMessengerKey: scaffoldMessengerKey,
          title: 'Control de Gastos',
          // Temas definidos en theme_provider.dart
          theme: themeMode == ThemeMode.system ? AppTheme.systemTheme : AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          // El tema actual se obtiene del estado de ThemeCubit
          themeMode: themeMode,
          // Configuración de localización para formatear fechas, monedas, etc.
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es', 'CL'), // Español (Chile) como ejemplo
            Locale('en', 'US'), // Inglés (Estados Unidos)
            // Agrega más locales según sea necesario
          ],
          home: const SplashPage(),
          );
          },
          );
          }
          }

