import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/paciente.dart';
import '../models/usuario.dart';
import '../services/paciente_service.dart';
import 'paciente_detalle_screen.dart';
import 'paciente_form_screen.dart';

/// PANTALLA: LISTADO DE PACIENTES
///
/// Presenta los pacientes registrados en MediCertus.
///
/// Responsabilidades:
/// - Consultar pacientes mediante PacienteService.
/// - Mostrar información personal y fotografías.
/// - Calcular la edad a partir de la fecha de nacimiento.
/// - Actualizar el listado.
/// - Permitir consultar el detalle de un paciente.
/// - Abrir el formulario para registrar pacientes.
///
/// Los permisos dependen del rol del usuario autenticado.
class PacientesScreen extends StatefulWidget {

  /// Usuario autenticado recibido desde MenuScreen.
  final Usuario usuario;

  const PacientesScreen({
    super.key,
    required this.usuario,
  });

  @override
  State<PacientesScreen> createState() =>
      _PacientesScreenState();
}


/// Administra la carga y actualización de pacientes.
///
/// Utilizamos StatefulWidget porque el listado puede
/// cambiar después de registrar o editar pacientes.
class _PacientesScreenState extends State<PacientesScreen> {

  // =====================================================
  // 1. SERVICIO Y VARIABLES DE ESTADO
  // =====================================================

  /// Servicio encargado de comunicarse con Node.js.
  final PacienteService _pacienteService =
      PacienteService();

  /// Representa el resultado futuro de la consulta.
  ///
  /// Future permite trabajar con operaciones asíncronas.
  late Future<List<Paciente>> _pacientesFuture;


  // =====================================================
  // 2. INICIALIZACIÓN
  // =====================================================

  /// Se ejecuta una sola vez al crear esta pantalla.
  @override
  void initState() {
    super.initState();

    // Iniciar la consulta del listado de pacientes.
    _cargarPacientes();
  }

  /// Solicita el listado de pacientes a la API REST.
  ///
  /// El servicio devuelve una lista de objetos Paciente.
  void _cargarPacientes() {
    _pacientesFuture =
        _pacienteService.obtenerPacientes();
  }


  // =====================================================
  // 3. ACTUALIZACIÓN DEL LISTADO
  // =====================================================

  /// Vuelve a consultar los pacientes registrados.
  ///
  /// Se utiliza después de registrar o editar pacientes,
  /// al pulsar Actualizar y al deslizar el listado.
  Future<void> _actualizarPacientes() async {

    // setState informa a Flutter que debe reconstruir
    // la interfaz con una nueva consulta.
    setState(() {
      _cargarPacientes();
    });

    try {
      // Esperar que termine la consulta.
      await _pacientesFuture;

    } catch (_) {
      // FutureBuilder se encargará de mostrar
      // el mensaje correspondiente al error.
    }
  }


  // =====================================================
  // 4. REGISTRO DE NUEVOS PACIENTES
  // =====================================================

  /// Abre el formulario de registro.
  ///
  /// Si el paciente fue guardado correctamente,
  /// actualiza el listado.
  Future<void> _nuevoPaciente() async {

    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const PacienteFormScreen(),
      ),
    );

    // Comprobar que la pantalla continúa activa.
    if (!mounted) return;

    // Actualizar únicamente si el registro fue exitoso.
    if (guardado == true) {
      await _actualizarPacientes();
    }
  }


  // =====================================================
  // 5. FORMATO DE FECHAS
  // =====================================================

  /// Convierte una fecha recibida desde Node.js
  /// al formato DD/MM/AAAA.
  ///
  /// Devuelve un mensaje cuando la fecha está vacía
  /// o no puede interpretarse.
  String _formatearFecha(String valor) {

    if (valor.isEmpty) {
      return 'No registrada';
    }

    // Interpretar la fecha almacenada como String.
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
  // 6. CÁLCULO DE EDAD
  // =====================================================

  /// Calcula la edad del paciente en años cumplidos.
  ///
  /// Considera si el paciente ya cumplió años
  /// durante el año actual.
  ///
  /// No acepta fechas futuras o inválidas.
  String _calcularEdad(String valor) {

    if (valor.isEmpty) {
      return 'No disponible';
    }

    // Convertir la fecha de nacimiento.
    final nacimiento = DateTime.tryParse(valor);

    if (nacimiento == null) {
      return 'No disponible';
    }

    // Obtener la fecha actual del dispositivo.
    final hoy = DateTime.now();

    // Una fecha de nacimiento futura es inválida.
    if (nacimiento.isAfter(hoy)) {
      return 'No disponible';
    }

    // Diferencia inicial entre los años.
    int edad = hoy.year - nacimiento.year;

    // Restar un año si todavía no cumplió años.
    if (hoy.month < nacimiento.month ||
        (hoy.month == nacimiento.month &&
            hoy.day < nacimiento.day)) {
      edad--;
    }

    return '$edad años';
  }


  // =====================================================
  // 7. CONSTRUCCIÓN DE LA INTERFAZ
  // =====================================================

  /// Construye el listado de pacientes.
  @override
  Widget build(BuildContext context) {

    // Interpretar el rol del usuario autenticado.
    final rol = int.tryParse(widget.usuario.rol);

    // Administradores y operadores pueden modificar.
    // Los médicos únicamente pueden consultar.
    final puedeModificar =
        rol == 1 || rol == 2;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),

      // ======================================
      // BARRA SUPERIOR
      // ======================================

      appBar: AppBar(
        title: const Text('Pacientes'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,

        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar pacientes',
            onPressed: _actualizarPacientes,
          ),
        ],
      ),


      // ======================================
      // LISTADO DE PACIENTES
      // ======================================

      body: FutureBuilder<List<Paciente>>(

        // Consulta asíncrona ejecutada por el servicio.
        future: _pacientesFuture,

        builder: (context, snapshot) {

          // ==================================
          // ESTADO DE CARGA
          // ==================================

          if (snapshot.connectionState !=
              ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }


          // ==================================
          // ERROR DE CONSULTA
          // ==================================

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),

                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 56,
                      color: Colors.red,
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'No se pudieron cargar los pacientes',
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: _actualizarPacientes,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }


          // ==================================
          // RESULTADO DE LA CONSULTA
          // ==================================

          // Recuperar los objetos Paciente.
          final pacientes = snapshot.data ?? [];

          // Mostrar mensaje cuando no hay registros.
          if (pacientes.isEmpty) {
            return const Center(
              child: Text(
                'No hay pacientes registrados',
              ),
            );
          }


          // ==================================
          // LISTA DE TARJETAS
          // ==================================

          return RefreshIndicator(

            // Permite actualizar deslizando hacia abajo.
            onRefresh: _actualizarPacientes,

            child: ListView.builder(
              physics:
                  const AlwaysScrollableScrollPhysics(),

              padding: const EdgeInsets.all(12),

              // Número de pacientes encontrados.
              itemCount: pacientes.length,

              // Crear una tarjeta para cada paciente.
              itemBuilder: (context, index) {

                // Obtener un objeto Paciente del listado.
                final paciente = pacientes[index];

                // Acceder a sus atributos directamente.
                final id =
                    paciente.idPaciente?.toString() ?? '';

                final paterno = paciente.apePaterno;
                final materno = paciente.apeMaterno;
                final nombres = paciente.nombres;
                final sexo = paciente.sexo;

                final fechaNacimiento =
                    paciente.fechaNacimiento;

                // Preparar fecha y edad para visualizar.
                final fechaTexto =
                    _formatearFecha(fechaNacimiento);

                final edadTexto =
                    _calcularEdad(fechaNacimiento);

                // Construir el nombre completo.
                final nombreCompleto =
                    '$paterno $materno, $nombres'.trim();

                return Card(
                  margin:
                      const EdgeInsets.only(bottom: 10),

                  child: ListTile(


                    // ==============================
                    // FOTOGRAFÍA DEL PACIENTE
                    // ==============================

                    leading: Builder(
                      builder: (context) {

                        // Recuperar el nombre de la imagen.
                        final nombreFoto =
                            paciente.foto?.trim();

                        // Imagen predeterminada.
                        const sinFoto = CircleAvatar(
                          radius: 26,
                          backgroundColor:
                              Color(0xFFE9F2FF),

                          child: Icon(
                            Icons.person,
                            color: Color(0xFF1565C0),
                          ),
                        );

                        // Si no existe fotografía,
                        // mostrar el ícono predeterminado.
                        if (nombreFoto == null ||
                            nombreFoto.isEmpty) {
                          return sinFoto;
                        }

                        // Descargar la fotografía mediante
                        // una solicitud HTTP autenticada.
                        return FutureBuilder<Uint8List>(
                          future: _pacienteService
                              .obtenerFoto(nombreFoto),

                          builder: (context, fotoSnapshot) {

                            // Mostrar el ícono mientras carga
                            // o cuando ocurre algún error.
                            if (!fotoSnapshot.hasData ||
                                fotoSnapshot.hasError) {
                              return sinFoto;
                            }

                            // Mostrar la imagen descargada.
                            return CircleAvatar(
                              radius: 26,
                              backgroundImage: MemoryImage(
                                fotoSnapshot.data!,
                              ),
                            );
                          },
                        );
                      },
                    ),


                    // ==============================
                    // INFORMACIÓN DEL PACIENTE
                    // ==============================

                    title: Text(
                      nombreCompleto,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    subtitle: Text(
                      'ID: $id\n'
                      'Sexo: $sexo\n'
                      'Nacimiento: $fechaTexto\n'
                      'Edad: $edadTexto',
                    ),

                    trailing:
                        const Icon(Icons.chevron_right),


                    // ==============================
                    // CONSULTAR DETALLE
                    // ==============================

                    onTap: () async {

                      // Abrir el detalle y transmitir
                      // el objeto Paciente seleccionado.
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PacienteDetalleScreen(
                            paciente: paciente,
                            puedeModificar: puedeModificar,
                          ),
                        ),
                      );

                      // Al regresar, consultar nuevamente
                      // para reflejar cualquier modificación.
                      if (mounted) {
                        await _actualizarPacientes();
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),


      // ======================================
      // BOTÓN NUEVO PACIENTE
      // ======================================

      // Solo se muestra para administradores
      // y operadores autorizados.
      floatingActionButton: puedeModificar
          ? FloatingActionButton(
              tooltip: 'Nuevo paciente',
              onPressed: _nuevoPaciente,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
