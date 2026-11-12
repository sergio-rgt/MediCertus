import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../models/paciente.dart';
import 'auth_service.dart';


/// SERVICIO: PACIENTES
///
/// Centraliza la comunicación entre las pantallas
/// de Pacientes y nuestra API REST de Node.js.
///
/// Responsabilidades:
/// - Consultar el listado de pacientes.
/// - Consultar un paciente por su identificador.
/// - Registrar y actualizar información personal.
/// - Descargar fotografías protegidas.
/// - Enviar fotografías al servidor.
///
/// Todas las operaciones requieren un JWT válido.
///
/// Este servicio no construye interfaces gráficas
/// ni realiza consultas directas a MySQL.
class PacienteService {

  /// Servicio utilizado para recuperar el JWT
  /// almacenado en el dispositivo.
  final AuthService _authService = AuthService();


  // =====================================================
  // 1. CONSULTAR LISTADO DE PACIENTES
  // =====================================================

  /// Consulta todos los pacientes registrados.
  ///
  /// Endpoint: GET /api/pacientes
  ///
  /// Devuelve una lista de objetos Paciente.
  Future<List<Paciente>> obtenerPacientes() async {

    // Recuperar el JWT de la sesión.
    final token = await _authService.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('Sesión no disponible');
    }

    // Enviar solicitud GET autenticada.
    final respuesta = await http.get(
      Uri.parse(
        '${AuthService.baseUrl}/api/pacientes',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 15));

    // Detectar problemas de autenticación o autorización.
    if (respuesta.statusCode == 401 ||
        respuesta.statusCode == 403) {
      throw Exception('Sesión vencida o acceso denegado');
    }

    // Verificar que la consulta haya sido satisfactoria.
    if (respuesta.statusCode != 200) {
      throw Exception(
        'Error HTTP ${respuesta.statusCode}',
      );
    }

    // Interpretar la respuesta JSON.
    final datos = jsonDecode(respuesta.body);

    // Validar la estructura de la respuesta.
    if (datos is! Map<String, dynamic> ||
        datos['ok'] != true ||
        datos['data'] is! List) {
      throw Exception('Respuesta inválida del servidor');
    }

    // Convertir cada registro JSON a un objeto Paciente.
    return (datos['data'] as List).map((registro) {
      return Paciente.fromJson(
        Map<String, dynamic>.from(registro as Map),
      );
    }).toList();
  }


  // =====================================================
  // 2. DESCARGAR FOTOGRAFÍA DEL PACIENTE
  // =====================================================

  /// Descarga una fotografía almacenada en Node.js.
  ///
  /// Endpoint: GET /api/pacientes/fotos/:archivo
  ///
  /// Devuelve los bytes de la imagen como Uint8List.
  ///
  /// La fotografía está protegida por autenticación JWT.
  Future<Uint8List> obtenerFoto(
    String nombreArchivo,
  ) async {

    // Recuperar el token de autenticación.
    final token = await _authService.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('Sesión no disponible');
    }

    // Construir la URL de la fotografía.
    //
    // encodeComponent protege los caracteres especiales
    // del nombre de archivo dentro de la URL.
    final url = Uri.parse(
      '${AuthService.baseUrl}/api/pacientes/fotos/'
      '${Uri.encodeComponent(nombreArchivo)}',
    );

    // Solicitar la imagen al backend.
    final respuesta = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'image/*',
      },
    ).timeout(const Duration(seconds: 15));

    // Verificar el resultado de la solicitud.
    if (respuesta.statusCode != 200) {
      throw Exception(
        'No se pudo obtener la fotografía: '
        'HTTP ${respuesta.statusCode}',
      );
    }

    // Retornar el contenido binario de la fotografía.
    return respuesta.bodyBytes;
  }


  // =====================================================
  // 3. REGISTRAR O ACTUALIZAR PACIENTE
  // =====================================================

  /// Registra o actualiza los datos de un paciente.
  ///
  /// Recibe un objeto del modelo Paciente.
  ///
  /// Si idPaciente es null:
  /// POST /api/pacientes
  ///
  /// Si idPaciente tiene un valor:
  /// PUT /api/pacientes/:id
  ///
  /// Utiliza paciente.toJson() para preparar los datos
  /// que espera nuestra API REST.
  ///
  /// Devuelve la respuesta JSON del servidor.
  Future<Map<String, dynamic>> guardarPaciente(
    Paciente paciente, {
    int? idPaciente,
  }) async {

    // Recuperar el JWT de la sesión.
    final token = await _authService.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('Sesión no disponible');
    }

    // Determinar si registraremos o actualizaremos.
    final esEdicion = idPaciente != null;

    // Seleccionar el endpoint según la operación.
    final url = Uri.parse(
      esEdicion
          ? '${AuthService.baseUrl}/api/pacientes/$idPaciente'
          : '${AuthService.baseUrl}/api/pacientes',
    );

    // Encabezados de autenticación y formato JSON.
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    // PUT actualiza y POST registra un nuevo paciente.
    final respuesta = esEdicion
        ? await http.put(
            url,
            headers: headers,
            body: jsonEncode(paciente.toJson()),
          ).timeout(const Duration(seconds: 15))
        : await http.post(
            url,
            headers: headers,
            body: jsonEncode(paciente.toJson()),
          ).timeout(const Duration(seconds: 15));

    // Interpretar la respuesta recibida.
    final datos = jsonDecode(respuesta.body);

    if (datos is! Map<String, dynamic>) {
      throw const FormatException(
        'Respuesta inválida del servidor',
      );
    }

    // Comprobar el resultado HTTP y la respuesta
    // de nuestra API Node.js.
    if (respuesta.statusCode < 200 ||
        respuesta.statusCode >= 300 ||
        datos['ok'] != true) {
      throw Exception(
        datos['mensaje'] ??
            'No se pudo guardar el paciente',
      );
    }

    // Retornar la respuesta.
    //
    // Durante el registro, el formulario utiliza
    // estos datos para recuperar el nuevo ID.
    return datos;
  }


  // =====================================================
  // 4. CONSULTAR UN PACIENTE POR SU ID
  // =====================================================

  /// Consulta un paciente utilizando su identificador.
  ///
  /// Endpoint: GET /api/pacientes/:id
  ///
  /// Devuelve directamente un objeto Paciente.
  Future<Paciente> obtenerPaciente(
    int idPaciente,
  ) async {

    // Recuperar el JWT de la sesión.
    final token = await _authService.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('Sesión no disponible');
    }

    // Consultar el registro solicitado.
    final respuesta = await http.get(
      Uri.parse(
        '${AuthService.baseUrl}/api/pacientes/$idPaciente',
      ),
      headers: {
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    // Interpretar la respuesta JSON.
    final datos = jsonDecode(respuesta.body);

    // Validar el resultado y la estructura.
    if (datos is! Map<String, dynamic> ||
        respuesta.statusCode != 200 ||
        datos['ok'] != true ||
        datos['data'] is! Map) {
      throw Exception('No se pudo consultar el paciente');
    }

    // Convertir el registro JSON en un objeto Paciente.
    return Paciente.fromJson(
      Map<String, dynamic>.from(datos['data'] as Map),
    );
  }


  // =====================================================
  // 5. SUBIR FOTOGRAFÍA DEL PACIENTE
  // =====================================================

  /// Envía una fotografía al servidor Node.js.
  ///
  /// Endpoint: POST /api/pacientes/:id/foto
  ///
  /// Utiliza multipart/form-data porque enviamos
  /// un archivo binario en lugar de un objeto JSON.
  ///
  /// Formatos permitidos: JPG, JPEG, PNG y WEBP.
  /// Tamaño máximo configurado en Flutter: 2 MB.
  Future<void> subirFotoPaciente(
    int idPaciente,
    XFile foto,
  ) async {

    // Recuperar el token de autenticación.
    final token = await _authService.obtenerToken();

    if (token == null || token.isEmpty) {
      throw Exception('Sesión no disponible');
    }

    // Obtener la extensión del archivo seleccionado.
    final extension = foto.name
        .split('.')
        .last
        .toLowerCase();

    // Verificar las extensiones admitidas.
    if (!['jpg', 'jpeg', 'png', 'webp']
        .contains(extension)) {
      throw Exception('Formato de fotografía no permitido');
    }

    // Verificar el tamaño máximo permitido.
    final tamano = await foto.length();

    if (tamano > 2 * 1024 * 1024) {
      throw Exception('La fotografía supera los 2 MB');
    }

    // Construir la dirección del endpoint.
    final url = Uri.parse(
      '${AuthService.baseUrl}/api/pacientes/$idPaciente/foto',
    );

    // Crear la solicitud multipart.
    final solicitud = http.MultipartRequest('POST', url);

    // Incorporar el JWT en los encabezados.
    solicitud.headers['Authorization'] = 'Bearer $token';
    solicitud.headers['Accept'] = 'application/json';

    // Determinar el subtipo MIME correspondiente.
    final tipoMime = switch (extension) {
      'jpg' || 'jpeg' => 'jpeg',
      'png' => 'png',
      'webp' => 'webp',
      _ => throw Exception('Formato no permitido'),
    };

    // Adjuntar la fotografía al campo 'foto'.
    //
    // El nombre de este campo debe coincidir
    // con el configurado en nuestro backend.
    solicitud.files.add(
      http.MultipartFile.fromBytes(
        'foto',
        await foto.readAsBytes(),
        filename: foto.name,
        contentType: MediaType('image', tipoMime),
      ),
    );

    // Enviar la solicitud al servidor.
    final respuestaStream = await solicitud.send().timeout(
      const Duration(seconds: 30),
    );

    // Convertir la respuesta transmitida en streaming
    // a una respuesta HTTP convencional.
    final respuesta = await http.Response.fromStream(
      respuestaStream,
    ).timeout(const Duration(seconds: 30));

    // Verificar posibles problemas de autorización.
    if (respuesta.statusCode == 401 ||
        respuesta.statusCode == 403) {
      throw Exception('Sesión vencida o acceso denegado');
    }

    // Intentar interpretar el cuerpo de la respuesta.
    Map<String, dynamic>? datos;

    try {
      final contenido = jsonDecode(respuesta.body);

      if (contenido is Map<String, dynamic>) {
        datos = contenido;
      }

    } catch (_) {
      // Algunas respuestas de error HTTP pueden
      // contener texto en lugar de JSON.
    }

    // Verificar si el servidor aceptó la fotografía.
    if (respuesta.statusCode < 200 ||
        respuesta.statusCode >= 300 ||
        datos?['ok'] != true) {
      throw Exception(
        datos?['mensaje']?.toString() ??
            'No se pudo guardar la fotografía. '
                'HTTP ${respuesta.statusCode}',
      );
    }
  }
}
