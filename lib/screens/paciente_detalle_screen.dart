import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/paciente.dart';
import '../services/paciente_service.dart';
import 'paciente_form_screen.dart';

/// PANTALLA: DETALLE DEL PACIENTE
///
/// Presenta la información de un paciente registrado
/// en MediCertus.
///
/// Responsabilidades:
/// - Mostrar los datos personales del paciente.
/// - Mostrar su fotografía almacenada en Node.js.
/// - Presentar la información en formato legible.
/// - Permitir la edición cuando el rol esté autorizado.
///
/// Recibe directamente un objeto del modelo Paciente.
///
/// No realiza solicitudes HTTP directamente;
/// utiliza PacienteService para obtener fotografías.
class PacienteDetalleScreen extends StatelessWidget {

  // =====================================================
  // 1. ATRIBUTOS Y CONSTRUCTOR
  // =====================================================

  /// Paciente seleccionado desde el listado.
  final Paciente paciente;

  /// Determina si se muestra el botón de edición.
  ///
  /// Este permiso se calcula en PacientesScreen
  /// según el rol del usuario autenticado.
  final bool puedeModificar;

  const PacienteDetalleScreen({
    super.key,
    required this.paciente,
    required this.puedeModificar,
  });


  // =====================================================
  // 2. FORMATO DE DATOS
  // =====================================================

  /// Devuelve el contenido de un campo.
  ///
  /// Cuando está vacío, muestra un texto predeterminado.
  String _texto(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'No registrado';
    }

    return valor;
  }

  /// Convierte una fecha recibida desde la API
  /// al formato DD/MM/AAAA.
  ///
  /// Si la fecha está vacía o es inválida,
  /// devuelve un mensaje descriptivo.
  String _formatearFecha(String valor) {
    if (valor.isEmpty) {
      return 'No registrada';
    }

    // Intentar convertir el texto a una fecha Dart.
    final fecha = DateTime.tryParse(valor);

    if (fecha == null) {
      return 'Fecha inválida';
    }

    // Completar día y mes con dos dígitos.
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');

    return '$dia/$mes/${fecha.year}';
  }


  // =====================================================
  // 3. COMPONENTE REUTILIZABLE PARA MOSTRAR DATOS
  // =====================================================

  /// Construye un campo informativo.
  ///
  /// Recibe una etiqueta y el valor que se mostrará.
  ///
  /// Este método evita repetir la estructura visual
  /// para cada atributo del paciente.
  Widget _dato(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          // Nombre del atributo.
          Text(
            etiqueta,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 4),

          // Contenido del atributo.
          Text(
            valor,
            style: const TextStyle(fontSize: 17),
          ),

          const Divider(),
        ],
      ),
    );
  }


  // =====================================================
  // 4. FOTOGRAFÍA DEL PACIENTE
  // =====================================================

  /// Obtiene y muestra la fotografía del paciente.
  ///
  /// La imagen se descarga desde Node.js mediante
  /// PacienteService y utilizando autenticación JWT.
  ///
  /// Si el paciente no tiene fotografía o falla
  /// la descarga, muestra un ícono predeterminado.
  Widget _mostrarFoto() {

    // Obtener el nombre del archivo almacenado.
    final nombreFoto = paciente.foto?.trim();

    // Imagen predeterminada.
    const sinFoto = CircleAvatar(
      radius: 45,
      child: Icon(
        Icons.person,
        size: 48,
      ),
    );

    // No existe una fotografía registrada.
    if (nombreFoto == null || nombreFoto.isEmpty) {
      return sinFoto;
    }

    // Descargar la fotografía mediante una operación
    // asíncrona y controlar sus diferentes estados.
    return FutureBuilder<Uint8List>(
      future: PacienteService().obtenerFoto(nombreFoto),

      builder: (context, snapshot) {

        // ======================================
        // FOTOGRAFÍA DESCARGADA
        // ======================================

        if (snapshot.hasData) {
          return Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),

              child: Image.memory(
                snapshot.data!,
                width: 160,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
          );
        }

        // ======================================
        // ERROR DURANTE LA DESCARGA
        // ======================================

        if (snapshot.hasError) {
          return sinFoto;
        }

        // ======================================
        // DESCARGA EN PROCESO
        // ======================================

        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }


  // =====================================================
  // 5. CONSTRUCCIÓN DE LA INTERFAZ
  // =====================================================

  /// Construye la pantalla con los datos recibidos
  /// desde PacientesScreen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // ======================================
      // BARRA SUPERIOR
      // ======================================

      appBar: AppBar(
        title: const Text('Detalle del paciente'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),


      // ======================================
      // INFORMACIÓN DEL PACIENTE
      // ======================================

      body: ListView(
        padding: const EdgeInsets.all(20),

        children: [

          // Fotografía registrada del paciente.
          _mostrarFoto(),

          const SizedBox(height: 24),

          // Identificador único en MySQL.
          _dato(
            'ID',
            paciente.idPaciente?.toString() ??
                'No registrado',
          ),

          // Apellido paterno.
          _dato(
            'Apellido paterno',
            _texto(paciente.apePaterno),
          ),

          // Apellido materno.
          _dato(
            'Apellido materno',
            _texto(paciente.apeMaterno),
          ),

          // Nombres.
          _dato(
            'Nombres',
            _texto(paciente.nombres),
          ),

          // Sexo del paciente.
          _dato(
            'Sexo',
            _texto(paciente.sexo),
          ),

          // Fecha de nacimiento formateada.
          _dato(
            'Fecha de nacimiento',
            _formatearFecha(paciente.fechaNacimiento),
          ),

          const SizedBox(height: 20),


          // ======================================
          // BOTÓN EDITAR PACIENTE
          // ======================================

          // Administradores y operadores pueden editar.
          // Los médicos solo pueden consultar.
          if (puedeModificar)
            ElevatedButton.icon(

              onPressed: () async {

                // Abrir el formulario de edición.
                //
                // Transmitimos directamente el objeto
                // Paciente, sin convertirlo a un mapa.
                final guardado = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PacienteFormScreen(
                      paciente: paciente,
                    ),
                  ),
                );

                // Verificar que la pantalla siga activa.
                if (!context.mounted) return;

                // Si se guardaron cambios correctamente,
                // mostrar un mensaje y regresar al listado.
                if (guardado == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Paciente actualizado correctamente',
                      ),
                    ),
                  );

                  // Devolver true al listado.
                  //
                  // PacientesScreen volverá a consultar
                  // los registros para mostrar los cambios.
                  Navigator.pop(context, true);
                }
              },

              icon: const Icon(Icons.edit),
              label: const Text('Editar paciente'),
            ),
        ],
      ),
    );
  }
}
