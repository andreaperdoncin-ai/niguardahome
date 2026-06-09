import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Import dei nostri provider
import 'providers/app_state_provider.dart';
import 'providers/spesa_provider.dart';
import 'providers/lettura_provider.dart';
import 'providers/categoria_provider.dart';

// Import della schermata principale
import 'features/home/home_screen.dart';

void main() async {
  // Assicuriamo che i binding di Flutter siano pronti prima di chiamare il codice nativo
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializzazione di Firebase con le opzioni generate dalla CLI
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    // Il MultiProvider fa da "cappello" a tutta l'app e distribuisce i dati
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => SpesaProvider()),
        ChangeNotifierProvider(create: (_) => LetturaProvider()),
        ChangeNotifierProvider(create: (_) => CategoriaProvider()), // <-- AGGIUNTO QUESTO
      ],
      child: const NiguardaHomeApp(),
    ),
  );
}

class NiguardaHomeApp extends StatelessWidget {
  const NiguardaHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NiguardaHome',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('it', 'IT')],
      locale: const Locale('it', 'IT'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      themeMode: ThemeMode.system, // Segue automaticamente il tema del dispositivo
      home: const HomeScreen(),
    );
  }
}