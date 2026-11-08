import 'package:flutter/material.dart';

//? [HomeScreen] Pantalla independiente ubicada en su propio archivo
class HomeScreen extends StatelessWidget {
  final String userEmail; // Recibe el correo electrónico enviado desde el login

  const HomeScreen({super.key, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medi Certus - Panel Principal'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 100,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              const Text(
                '¡Hola, esta es una nueva pantalla!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Conectado como: $userEmail',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 32),
              
              //! Botón para regresar al Login (Cerrar sesión)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Saca esta pantalla de la pila y regresa al Login
                },
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar Sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}