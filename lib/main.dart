
import 'package:flutter/material.dart';

// Importamos la pantalla de inicio de sesión.
import 'screens/login_screen.dart';

/// Punto de entrada principal de MediCertus.
///
/// runApp() inicia Flutter y carga el widget raíz.
void main() {
  runApp(const MediCertusApp());
}

/// Configuración general de MediCertus.
///
/// Esta clase define el nombre, el tema visual
/// y la pantalla inicial de la aplicación.
///
/// StatelessWidget es apropiado porque no administra
/// cambios de estado internos.
class MediCertusApp extends StatelessWidget {
  const MediCertusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Nombre de la aplicación.
      title: 'MediCertus',

      // Oculta la etiqueta de depuración.
      debugShowCheckedModeBanner: false,

      // Configuración visual de Material Design 3.
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
        ),
        useMaterial3: true,
      ),

      // Pantalla inicial: autenticación del usuario.
      home: const LoginPage(),
    );
  }
}
