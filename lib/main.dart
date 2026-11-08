//? Importamos la librería principal de Google para usar los bloques de diseño (Material Design).
import 'package:flutter/material.dart';

//? Importamos el archivo externo donde está la otra pantalla (HomeScreen).
import 'HomeScreen.dart'; 

//? [main] Es la puerta de entrada de la aplicación. Aquí arranca todo.
void main() {
  runApp(const MyApp());
}

//? [MyApp] Es el plano general de tu casa. Configura el tema, los colores y la pantalla principal.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,  //? Quita la banderita roja fea de "DEBUG" de la esquina.
      title: 'Login App',
      theme: ThemeData(   
        //? Define el color principal de toda la aplicación (un azul bonito).
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 5, 82, 50)),
        useMaterial3: true,  //? Activa el estilo moderno de diseño de Google.
      ),
      home: const LoginPage(), //? Ordena: "Muestra la pantalla de Login primero".
    );
  }
}

//! [LoginPage] Pantalla con estado ("Stateful"). 
//! Se usa Stateful porque esta pantalla "recuerda cosas" que cambian (como ver/ocultar la contraseña).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  
  //? [_formKey] Es como un supervisor general. Revisa que todos los campos cumplan las reglas antes de avanzar.
  final _formKey = GlobalKey<FormState>();

  //? [_emailController] y [_passwordController] Son los asistentes que leen lo que el usuario escribe en los inputs.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  //? [_isPasswordObscured] Interruptor para saber si la contraseña está oculta (true) o visible (false).
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    //! Muy importante: Borramos a los asistentes de la memoria cuando cerramos la pantalla para no saturar el celular.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  //? Función que se ejecuta cuando el usuario hace clic en "Iniciar Sesión".
  void _handleLogin() {
    //? Si el supervisor (_formKey) revisa y dice que todo está bien escrito...
    if (_formKey.currentState!.validate()) {
      
      //! [Navigator.push] Es como abrir una puerta y viajar a otra pantalla (HomeScreen).
      //! Le pasamos como "regalo" el correo que escribió el usuario (_emailController.text).
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
    //? [Scaffold] Es el lienzo en blanco o estructura base de la pantalla.
    return Scaffold(
      body: SafeArea( //? Evita que el contenido choque con la cámara o bordes del celular.
        child: Center( //? Centra todo en la pantalla.
          child: SingleChildScrollView( //? Permite deslizar hacia abajo si sale el teclado virtual para que no dé error.
            padding: const EdgeInsets.all(24.0), //? Margen o espacio alrededor de todo.
            child: Form( //? Contenedor especial para manejar formularios y validaciones.
              key: _formKey, //? Conectamos el formulario con nuestro supervisor.
              child: Column( //? Columna: Organiza los elementos de arriba hacia abajo (en fila vertical).
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  
                  //? 1. Ícono o Logo de la clínica en la parte superior.
                  const Icon(
                    Icons.local_hospital,
                    size: 200,
                    color: Color.fromARGB(255, 6, 133, 251),
                  ),
                  const SizedBox(height: 16), //? Espacio vacío vertical de separación.
                  
                  //? 2. Título de bienvenida.
                  Text(
                    '¡Bienvenido!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  
                  //? Subtítulo aclaratorio.
                  Text(
                    'Ingresa tus credenciales para continuar',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 32),

                  //? 3. CAMPO DE CORREO ELECTRÓNICO (TextFormField).
                  TextFormField(
                    controller: _emailController, //? Conectamos al asistente para leer el texto.
                    keyboardType: TextInputType.emailAddress, //? Cambia el teclado del celular para poner el símbolo '@' fácil.
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: const Icon(Icons.email_outlined), //? Icono al inicio de la cajita.
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), //? Bordes redondeados modernos.
                      ),
                    ),
                    validator: (value) {
                      //? Reglas de validación del correo:
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu correo'; //? Error si está vacío.
                      }
                      if (!value.contains('@')) {
                        return 'Ingresa un correo válido'; //? Error si le falta la arroba.
                      }
                      return null; //? Si todo está bien, retorna null (sin errores).
                    },
                  ),
                  const SizedBox(height: 16),

                  //? 4. CAMPO DE CONTRASEÑA.
                  TextFormField(
                    controller: _passwordController, //? Conectamos al asistente de la contraseña.
                    obscureText: _isPasswordObscured, //? Oculta los caracteres con puntitos (•) si está en true.
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      //? Botón interactivo al final de la caja para ver u ocultar la contraseña.
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordObscured
                              ? Icons.visibility_off //? Icono de ojo tachado.
                              : Icons.visibility,    //? Icono de ojo abierto.
                        ),
                        onPressed: () {
                          //? setState avisa a Flutter que cambió una variable y debe redibujar la pantalla.
                          setState(() {
                            _isPasswordObscured = !_isPasswordObscured; //? Cambia de verdadero a falso y viceversa.
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      //? Reglas de validación de la contraseña:
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu contraseña';
                      }
                      if (value.length < 6) {
                        return 'Debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  //? 5. BOTÓN DE ENTRAR (ElevatedButton).
                  ElevatedButton(
                    onPressed: _handleLogin, //? Llama a la función de validación y navegación al hacer clic.
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16), //? Altura del botón.
                      backgroundColor: const Color.fromARGB(255, 6, 133, 251), //? Color de fondo azul.
                      foregroundColor: Colors.white, //? Color del texto (blanco).
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), //? Bordes redondeados iguales a los inputs.
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