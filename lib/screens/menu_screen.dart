import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import 'pacientes_screen.dart';

/// PANTALLA: MENÚ PRINCIPAL
///
/// Muestra la información del usuario autenticado
/// y los módulos disponibles según su rol.
///
/// Responsabilidades:
/// - Identificar al usuario que inició sesión.
/// - Mostrar los módulos correspondientes a su rol.
/// - Permitir la navegación hacia Pacientes.
/// - Administrar el cierre de sesión.
///
/// Los permisos visuales no sustituyen la validación
/// de autorización que realiza la API Node.js.
class MenuScreen extends StatelessWidget {

  /// Usuario autenticado recibido desde LoginPage.
  final Usuario usuario;

  const MenuScreen({
    super.key,
    required this.usuario,
  });


  // =====================================================
  // 1. CIERRE DE SESIÓN
  // =====================================================

  /// Elimina el JWT almacenado en el dispositivo
  /// y regresa a la pantalla inicial.
  ///
  /// pushNamedAndRemoveUntil elimina las rutas anteriores
  /// para impedir que el botón Atrás vuelva al menú.
  Future<void> _cerrarSesion(BuildContext context) async {
    try {
      // Eliminar el token de autenticación.
      await AuthService().eliminarToken();

      // Comprobar que el contexto continúa disponible.
      if (!context.mounted) return;

      // Regresar al Login y limpiar la navegación.
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
      );

    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cerrar la sesión'),
        ),
      );
    }
  }


  // =====================================================
  // 2. COMPONENTE REUTILIZABLE DE MÓDULOS
  // =====================================================

  /// Construye una tarjeta para representar un módulo.
  ///
  /// Parámetros:
  /// - titulo: nombre del módulo.
  /// - descripcion: explicación breve.
  /// - icono: símbolo gráfico del módulo.
  ///
  /// Actualmente solo Pacientes tiene una pantalla
  /// implementada en esta aplicación Flutter.
  Widget _crearModulo(
    BuildContext context, {
    required String titulo,
    required String descripcion,
    required IconData icono,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),

      child: InkWell(
        borderRadius: BorderRadius.circular(16),

        // Determinar qué ocurre al seleccionar el módulo.
        onTap: () {

          if (titulo == 'Pacientes') {

            // Abrir el listado de pacientes.
            // Se transmite el usuario para evaluar
            // los permisos de registro y edición.
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PacientesScreen(
                  usuario: usuario,
                ),
              ),
            );

          } else {

            // Los demás módulos aún no tienen
            // pantallas implementadas en Flutter.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Módulo $titulo: pantalla pendiente',
                ),
              ),
            );
          }
        },

        // Representación visual de la tarjeta.
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Row(
            children: [

              // Ícono del módulo.
              Container(
                padding: const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color: const Color(0xFFE9F2FF),
                  borderRadius: BorderRadius.circular(14),
                ),

                child: Icon(
                  icono,
                  color: const Color(0xFF1565C0),
                  size: 30,
                ),
              ),

              const SizedBox(width: 16),

              // Nombre y descripción del módulo.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      descripcion,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }


  // =====================================================
  // 3. CONSTRUCCIÓN DEL MENÚ PRINCIPAL
  // =====================================================

  /// Construye el menú según los permisos del usuario.
  @override
  Widget build(BuildContext context) {

    // El rol llega como String en el modelo Usuario.
    // Lo convertimos a entero para evaluar permisos.
    final rol = int.tryParse(usuario.rol);

    // Permisos visuales equivalentes a MediCertus Web.
    //
    // Rol 1: Administrador.
    // Rol 2: Operador.
    // Rol 3: Médico.
    final puedeUsuarios = rol == 1;

    final puedePacientes =
        rol == 1 || rol == 2 || rol == 3;

    final puedeServicios = rol == 1 || rol == 3;

    // Obtener el nombre descriptivo del rol.
    final nombreRol = switch (rol) {
      1 => 'Administrador',
      2 => 'Operador',
      3 => 'Médico',
      _ => 'Sin rol reconocido',
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),

      // ======================================
      // BARRA SUPERIOR
      // ======================================

      appBar: AppBar(
        title: const Text('MediCertus'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,

        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _cerrarSesion(context),
          ),
        ],
      ),

      // ======================================
      // INFORMACIÓN DEL USUARIO Y MÓDULOS
      // ======================================

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),

          children: [

            // Identificación del usuario autenticado.
            Text(
              'Bienvenido, ${usuario.nombre}',
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text('Usuario: ${usuario.coduser}'),
            Text('Rol: $nombreRol'),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 20),

            const Text(
              'MENÚ PRINCIPAL',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),

            const SizedBox(height: 20),

            // ======================================
            // MÓDULO USUARIOS
            // ======================================

            // Disponible para administradores.
            if (puedeUsuarios)
              _crearModulo(
                context,
                titulo: 'Usuarios',
                descripcion:
                    'Administración de usuarios y accesos',
                icono: Icons.people_alt_outlined,
              ),

            // ======================================
            // MÓDULO PACIENTES
            // ======================================

            // Administradores, operadores y médicos.
            if (puedePacientes)
              _crearModulo(
                context,
                titulo: 'Pacientes',
                descripcion:
                    'Registro y consulta de pacientes',
                icono: Icons.person_outline,
              ),

            // ======================================
            // MÓDULO SERVICIOS
            // ======================================

            // Administradores y médicos.
            if (puedeServicios)
              _crearModulo(
                context,
                titulo: 'Servicios',
                descripcion:
                    'Atenciones médicas y triaje',
                icono: Icons.medical_services_outlined,
              ),

            // Mensaje cuando el rol no tiene módulos.
            if (!puedeUsuarios &&
                !puedePacientes &&
                !puedeServicios)
              const Text(
                'No hay módulos autorizados para este rol.',
              ),
          ],
        ),
      ),
    );
  }
}
