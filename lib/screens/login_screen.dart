import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import 'menu_screen.dart';

/// PANTALLA: INICIO DE SESIÓN
///
/// Permite autenticar a los usuarios de MediCertus.
///
/// Responsabilidades:
/// - Presentar los campos de usuario y contraseña.
/// - Validar que los campos no estén vacíos.
/// - Solicitar la autenticación mediante AuthService.
/// - Guardar el JWT recibido desde Node.js.
/// - Abrir el menú principal del sistema.
///
/// No realiza consultas directas a MySQL.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}


/// Administra el estado del formulario de autenticación.
///
/// StatefulWidget permite actualizar elementos visuales
/// cuando cambia el estado de la pantalla.
class _LoginPageState extends State<LoginPage> {

  // =====================================================
  // 1. CONTROLADORES Y VARIABLES DE ESTADO
  // =====================================================

  /// Identifica el formulario para ejecutar validaciones.
  final _formKey = GlobalKey<FormState>();

  /// Controladores de los campos de usuario y contraseña.
  final _usuarioController = TextEditingController();
  final _claveController = TextEditingController();

  /// Controla la visibilidad de la contraseña.
  bool _mostrarClave = false;

  /// Indica si hay una autenticación en proceso.
  ///
  /// Evita enviar varias solicitudes simultáneamente.
  bool _ingresando = false;


  // =====================================================
  // 2. LIBERACIÓN DE RECURSOS
  // =====================================================

  /// Libera los controladores al destruir la pantalla.
  @override
  void dispose() {
    _usuarioController.dispose();
    _claveController.dispose();

    super.dispose();
  }


  // =====================================================
  // 3. AUTENTICACIÓN DEL USUARIO
  // =====================================================

  /// Ejecuta el proceso de inicio de sesión.
  ///
  /// 1. Valida los campos.
  /// 2. Envía las credenciales mediante AuthService.
  /// 3. Verifica la respuesta de Node.js.
  /// 4. Convierte los datos recibidos en un objeto Usuario.
  /// 5. Guarda el token JWT.
  /// 6. Abre el menú principal.
  Future<void> _ingresar() async {

    // Evita solicitudes simultáneas.
    if (_ingresando) return;

    // Validar los campos antes de enviar información.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Actualizar el estado y deshabilitar el botón.
    setState(() {
      _ingresando = true;
    });

    try {
      // Servicio encargado de comunicarse con Node.js.
      final authService = AuthService();

      // Enviar las credenciales y esperar la respuesta.
      //
      // await permite esperar sin bloquear la interfaz.
      final datos = await authService.login(
        _usuarioController.text,
        _claveController.text,
      );

      // Verificar que la pantalla continúe activa.
      if (!mounted) return;

      if (datos['ok'] == true) {

        // Convertir los datos JSON en un objeto Usuario.
        final usuario = Usuario.fromJson(
          Map<String, dynamic>.from(datos['data']),
        );

        // Recuperar el JWT proporcionado por Node.js.
        final token = datos['token'];

        // Verificar que el token exista y sea una cadena.
        if (token is! String || token.isEmpty) {
          throw const FormatException(
            'Token JWT no recibido',
          );
        }

        // Almacenar el token de manera segura.
        await authService.guardarToken(token);

        if (!mounted) return;

        // Reemplazar la pantalla de Login por el menú.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MenuScreen(
              usuario: usuario,
            ),
          ),
        );

      } else {

        // Mostrar el mensaje enviado por el backend.
        // Por ejemplo: credenciales incorrectas.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              datos['mensaje']?.toString() ??
                  'No se pudo iniciar sesión',
            ),
          ),
        );
      }

    } catch (error) {

      // No modificar una pantalla que ya fue destruida.
      if (!mounted) return;

      // Informar que ocurrió un problema durante el login.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo completar el inicio de sesión',
          ),
        ),
      );

    } finally {

      // Restaurar el botón si la pantalla sigue activa.
      if (mounted) {
        setState(() {
          _ingresando = false;
        });
      }
    }
  }


  // =====================================================
  // 4. CONSTRUCCIÓN DE LA INTERFAZ
  // =====================================================

  /// Construye la interfaz gráfica de inicio de sesión.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),

              child: Form(
                key: _formKey,

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    // ======================================
                    // IDENTIDAD VISUAL
                    // ======================================

                    const Icon(
                      Icons.local_hospital_rounded,
                      size: 80,
                      color: Color(0xFF1565C0),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'MediCertus',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Sistema de Gestión Médica',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 40),


                    // ======================================
                    // CAMPO USUARIO
                    // ======================================

                    TextFormField(
                      controller: _usuarioController,

                      decoration: const InputDecoration(
                        labelText: 'Usuario',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),

                      // El campo es obligatorio.
                      validator: (valor) {
                        if (valor == null ||
                            valor.trim().isEmpty) {
                          return 'Ingrese su usuario';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 20),


                    // ======================================
                    // CAMPO CONTRASEÑA
                    // ======================================

                    TextFormField(
                      controller: _claveController,

                      // Ocultar o mostrar los caracteres.
                      obscureText: !_mostrarClave,

                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon:
                            const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),

                        // Botón de visibilidad.
                        suffixIcon: IconButton(
                          icon: Icon(
                            _mostrarClave
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),

                          onPressed: () {
                            setState(() {
                              _mostrarClave = !_mostrarClave;
                            });
                          },
                        ),
                      ),

                      validator: (valor) {
                        if (valor == null || valor.isEmpty) {
                          return 'Ingrese su contraseña';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 28),


                    // ======================================
                    // BOTÓN INICIAR SESIÓN
                    // ======================================

                    SizedBox(
                      width: double.infinity,
                      height: 52,

                      child: ElevatedButton(

                        // Mientras _ingresando sea true,
                        // el botón permanece deshabilitado.
                        onPressed:
                            _ingresando ? null : _ingresar,

                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                        ),

                        // Mostrar progreso o texto normal.
                        child: _ingresando
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'INICIAR SESIÓN',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),

                    const SizedBox(height: 32),


                    // ======================================
                    // PIE DE PÁGINA
                    // ======================================

                    const Text(
                      'MediCertus © 2026',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
