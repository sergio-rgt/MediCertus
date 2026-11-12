
/// MODELO DE DATOS: USUARIO
///
/// Representa a un usuario autenticado de MediCertus.
///
/// Su información proviene de la API REST desarrollada
/// en Node.js, que consulta nuestra base de datos MySQL.
///
/// Este modelo permite trabajar con objetos Dart
/// en lugar de manipular directamente los datos JSON.
class Usuario {

  // =====================================================
  // 1. ATRIBUTOS DEL USUARIO
  // =====================================================

  /// Identificador único del usuario en la base de datos.
  final int iduser;

  /// Código utilizado para iniciar sesión.
  final String coduser;

  /// Nombre del usuario.
  final String nombre;

  /// Indicador de estado del usuario.
  /// Generalmente: 1 = activo, 0 = inactivo.
  final int flgactivo;

  /// Rol asignado al usuario.
  ///
  /// 1 = Administrador
  /// 2 = Operador
  /// 3 = Médico
  ///
  /// Se almacena como String porque así lo utiliza
  /// actualmente nuestra aplicación Flutter.
  final String rol;


  // =====================================================
  // 2. CONSTRUCTOR
  // =====================================================

  /// Permite crear un objeto Usuario.
  ///
  /// La palabra required indica que todos estos
  /// parámetros deben proporcionarse obligatoriamente.
  Usuario({
    required this.iduser,
    required this.coduser,
    required this.nombre,
    required this.flgactivo,
    required this.rol,
  });


  // =====================================================
  // 3. CONVERSIÓN DE JSON A OBJETO DART
  // =====================================================

  /// Construye un usuario a partir del JSON de Node.js.
  ///
  /// `Map<String, dynamic>` representa un conjunto
  /// de campos con nombres String y valores variables.
  ///
  /// factory permite crear un objeto utilizando
  /// una lógica de conversión personalizada.
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(

      // Convierte el identificador a número entero.
      iduser: int.parse(json['iduser'].toString()),

      // Convierte el código a una cadena de texto.
      coduser: json['coduser'].toString(),

      // Obtiene el nombre del usuario.
      nombre: json['nombre'].toString(),

      // Convierte el indicador de activo a entero.
      flgactivo: int.parse(json['flgactivo'].toString()),

      // Obtiene el rol como texto.
      rol: json['rol'].toString(),
    );
  }
}
