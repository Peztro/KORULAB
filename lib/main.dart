import 'package:flutter/material.dart';
import 'servicio_bd.dart';
import 'paginas/pagina_inicio.dart';
import 'paginas/pagina_login.dart';
import 'pagina_bienvenida.dart';
import 'servicios/koru_controlador.dart';
import 'tema/preferencia_tema.dart';
import 'widgets/koru_mascota.dart';
import 'tema/tema_korulab.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBService.init();
  await PreferenciaTema.instancia.cargar();
  await KoruControlador.instancia.cargarPreferencias();
  runApp(const KoruApp());
}

// ─────────────────────────────────────────────
// Widget raíz de la aplicación - configura el tema, rutas y pantalla inicial
// ─────────────────────────────────────────────
class KoruApp extends StatelessWidget {
  const KoruApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: PreferenciaTema.instancia,
      builder: (context, themeMode, _) => MaterialApp(
        title: 'Korulab',
        debugShowCheckedModeBanner: false,
        theme: construirTemaKorulab(Brightness.light),
        darkTheme: construirTemaKorulab(Brightness.dark),
        themeMode: themeMode,
        // Permite a Koru saber si su pantalla está a la vista.
        navigatorObservers: [observadorRutas],
        home: const SplashPage(),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginPage());
            case '/home':
              final username = settings.arguments as String?;
              if (username != null) {
                return MaterialPageRoute(
                  builder: (_) => HomePage(username: username),
                );
              }
              return MaterialPageRoute(builder: (_) => const LoginPage());
            default:
              return MaterialPageRoute(builder: (_) => const SplashPage());
          }
        },
      ),
    );
  }
}
