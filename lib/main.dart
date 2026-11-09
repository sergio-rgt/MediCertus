
import 'package:flutter/material.dart'; // Importa los componentes visuales de Flutter.
import 'HomeScreen.dart'; // Importa la pantalla principal después del login.

// Punto de entrada de la aplicación.
void main() {
  runApp(const MyApp());
}

// Configuración general de la aplicación.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Oculta la etiqueta de depuración.
      title: 'Login App',
      theme: ThemeData(
        // Define el color principal y el estilo visual.
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 2, 28, 54)),
        useMaterial3: true, // Activa el diseño Material 3.
      ),
      home: const LoginPage(), // Establece la pantalla inicial.
    );
  }
}

// Pantalla de inicio de sesión con estado modificable.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  // Clave utilizada para controlar las validaciones del formulario.
  final _formKey = GlobalKey<FormState>();

  // Controladores para obtener el correo y la contraseña ingresados.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Controla si la contraseña se muestra oculta o visible.
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    // Libera los recursos de los controladores al cerrar la pantalla.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Valida los campos y permite acceder a la siguiente pantalla.
  void _handleLogin() {
    if (_formKey.currentState!.validate()) {

      // Navega a HomeScreen y envía el correo ingresado.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(userEmail: _emailController.text),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Estructura principal de la pantalla.
    return Scaffold(
      body: SafeArea( // Evita que el contenido se superponga con los bordes del dispositivo.
        child: Center( // Centra el contenido.
          child: SingleChildScrollView( // Permite desplazar el formulario cuando aparece el teclado.
            padding: const EdgeInsets.all(24.0), // Establece el margen interno.
            child: Form( // Agrupa los campos y sus validaciones.
              key: _formKey,
              child: Column( // Organiza los elementos verticalmente.
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // Ícono representativo de la aplicación.
                  const Icon(
                    Icons.local_hospital,
                    size: 200,
                    color: Color.fromARGB(255, 6, 133, 251),
                  ),
                  const SizedBox(height: 16), // Espacio entre elementos.

                  // Título de bienvenida.
                  Text(
                    '¡Bienvenido!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),

                  // Texto descriptivo del inicio de sesión.
                  Text(
                    'Ingresa tus credenciales para continuar',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 32),

                  // Campo para ingresar el correo electrónico.
                  TextFormField(
                    controller: _emailController, // Vincula el campo con su controlador.
                    keyboardType: TextInputType.emailAddress, // Muestra un teclado para correos.
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: const Icon(Icons.email_outlined), // Ícono al inicio del campo.
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), // Redondea los bordes.
                      ),
                    ),
                    validator: (value) {
                      // Comprueba que el correo no esté vacío.
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu correo';
                      }

                      // Comprueba que el correo contenga una arroba.
                      if (!value.contains('@')) {
                        return 'Ingresa un correo válido';
                      }

                      return null; // No se encontraron errores.
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo para ingresar la contraseña.
                  TextFormField(
                    controller: _passwordController, // Vincula el campo con su controlador.
                    obscureText: _isPasswordObscured, // Oculta o muestra la contraseña.
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),

                      // Botón para cambiar la visibilidad de la contraseña.
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordObscured
                              ? Icons.visibility_off // Ícono cuando está oculta.
                              : Icons.visibility, // Ícono cuando está visible.
                        ),
                        onPressed: () {
                          // Actualiza la visibilidad de la contraseña.
                          setState(() {
                            _isPasswordObscured = !_isPasswordObscured;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      // Comprueba que la contraseña no esté vacía.
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu contraseña';
                      }

                      // Comprueba que tenga al menos 6 caracteres.
                      if (value.length < 6) {
                        return 'Debe tener al menos 6 caracteres';
                      }

                      return null; // No se encontraron errores.
                    },
                  ),
                  const SizedBox(height: 24),

                  // Botón para iniciar sesión.
                  ElevatedButton(
                    onPressed: _handleLogin, // Ejecuta la validación y navegación.
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16), // Define la altura del botón.
                      backgroundColor: const Color.fromARGB(255, 6, 133, 251), // Color de fondo.
                      foregroundColor: Colors.white, // Color del texto.
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // Redondea los bordes.
                      ),
                    ),
                    child: const Text(
                      'Iniciar Sesión',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
