import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


/// SERVICIO: AUTENTICACIÓN
///
/// Centraliza la autenticación de usuarios de MediCertus
/// y la administración del token JWT.
///
/// Responsabilidades:
/// - Enviar credenciales a la API REST de Node.js.
/// - Recibir la respuesta del servidor.
/// - Guardar el token JWT de forma segura.
/// - Recuperar el token para solicitudes autenticadas.
/// - Eliminar el token al cerrar sesión.
///
/// Este servicio no construye interfaces gráficas.
class AuthService {

  // =====================================================
  // 1. CONFIGURACIÓN DE LA API REST
  // =====================================================

  /// Dirección del servidor Node.js.
  ///
  /// Entorno de desarrollo: emulador Android.
  /// Ubuntu Server se ejecuta en VirtualBox.
  static const String baseUrl = 'http://192.168.56.200:3000';

  /// Dirección alternativa para el celular físico
  /// conectado a la misma red local de Windows.
  ///
  /// Windows redirige el puerto 3000 hacia Ubuntu.
  // static const String baseUrl = 'http://192.168.18.8:3000';


  // =====================================================
  // 2. ALMACENAMIENTO SEGURO DEL JWT
  // =====================================================

  /// FlutterSecureStorage permite almacenar información
  /// sensible mediante mecanismos seguros del sistema
  /// operativo, como Android Keystore.
  static const _storage = FlutterSecureStorage();

  /// Guarda el JWT recibido después de iniciar sesión.
  ///
  /// El token se identifica con la clave 'jwt_token'.
  Future<void> guardarToken(String token) async {
    await _storage.write(
      key: 'jwt_token',
      value: token,
    );
  }

  /// Recupera el JWT almacenado en el dispositivo.
  ///
  /// Devuelve null cuando no existe un token guardado.
  Future<String?> obtenerToken() async {
    return await _storage.read(
      key: 'jwt_token',
    );
  }

  /// Elimina el JWT del almacenamiento seguro.
  ///
  /// Se utiliza cuando el usuario cierra sesión.
  Future<void> eliminarToken() async {
    await _storage.delete(
      key: 'jwt_token',
    );
  }


  // =====================================================
  // 3. AUTENTICACIÓN CONTRA NODE.JS
  // =====================================================

  /// Envía usuario y contraseña a la API REST.
  ///
  /// Parámetros:
  /// - coduser: código del usuario.
  /// - password: contraseña ingresada.
  ///
  /// Realiza una solicitud HTTP POST a /api/login.
  ///
  /// Devuelve un mapa con la respuesta JSON del servidor.
  /// La pantalla LoginPage interpreta el resultado
  /// y decide si permite acceder al menú principal.
  Future<Map<String, dynamic>> login(
    String coduser,
    String password,
  ) async {

    // Enviar las credenciales mediante una solicitud POST.
    final respuesta = await http.post(
      Uri.parse('$baseUrl/api/login'),

      // Indicamos que enviamos datos JSON.
      headers: {
        'Content-Type': 'application/json',
      },

      // Convertimos los parámetros a formato JSON.
      //
      // trim() elimina espacios al inicio y al final
      // del código de usuario.
      //
      // La contraseña no se modifica porque los espacios
      // podrían formar parte de ella.
      body: jsonEncode({
        'coduser': coduser.trim(),
        'password': password,
      }),

    ).timeout(const Duration(seconds: 15));

    // Convertir la respuesta JSON en datos Dart.
    // Verificar si ocurrió un error técnico del servidor.
    if (respuesta.statusCode >= 500) {
      throw Exception(
        'Error interno del servidor: HTTP ${respuesta.statusCode}',
      );
    }

    // Convertir la respuesta JSON en datos Dart.
    final datos = jsonDecode(respuesta.body);

    // Verificar que la respuesta tenga la estructura esperada.
    if (datos is! Map<String, dynamic>) {
      throw const FormatException(
        'Respuesta inválida del servidor',
      );
    }

    // Diferenciar errores HTTP de respuestas satisfactorias.
    // Los errores 400 y 401 pueden contener mensajes válidos
    // de autenticación que LoginPage debe mostrar al usuario.
    if (respuesta.statusCode < 200 ||
        respuesta.statusCode >= 400) {
      if (respuesta.statusCode != 400 &&
          respuesta.statusCode != 401 &&
          respuesta.statusCode != 403 &&
          respuesta.statusCode != 429) {
        throw Exception(
          'Error HTTP ${respuesta.statusCode}',
        );
      }
    }

    // Entregar la respuesta a LoginPage.
    return datos;
  }
}
