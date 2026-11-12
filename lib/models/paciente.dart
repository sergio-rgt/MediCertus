
/// MODELO DE DATOS: PACIENTE
///
/// Representa la información personal de un paciente
/// registrado en MediCertus.
///
/// Responsabilidades:
/// - Definir los atributos del paciente.
/// - Convertir el JSON de Node.js en objetos Dart.
/// - Preparar los datos que enviamos a la API REST.
///
/// Este modelo no realiza consultas HTTP ni accede
/// directamente a la base de datos MySQL.
class Paciente {

  // =====================================================
  // 1. ATRIBUTOS DEL PACIENTE
  // =====================================================

  /// Identificador único del paciente en MySQL.
  ///
  /// Es opcional porque todavía no existe cuando
  /// estamos registrando un paciente nuevo.
  final int? idPaciente;

  /// Apellido paterno.
  final String apePaterno;

  /// Apellido materno.
  final String apeMaterno;

  /// Nombres del paciente.
  final String nombres;

  /// Fecha de nacimiento.
  ///
  /// Se mantiene como String para trabajar con el
  /// formato de fecha que proporciona nuestra API.
  final String fechaNacimiento;

  /// Sexo del paciente: M o F.
  final String sexo;

  /// Nombre del archivo de fotografía en el servidor.
  ///
  /// Es null cuando el paciente no tiene fotografía.
  final String? foto;


  // =====================================================
  // 2. CONSTRUCTOR
  // =====================================================

  /// Crea un objeto Paciente.
  ///
  /// required identifica los parámetros obligatorios.
  ///
  /// idPaciente y foto son opcionales.
  const Paciente({
    this.idPaciente,
    required this.apePaterno,
    required this.apeMaterno,
    required this.nombres,
    required this.fechaNacimiento,
    required this.sexo,
    this.foto,
  });


  // =====================================================
  // 3. CONVERSIÓN JSON A OBJETO DART
  // =====================================================

  /// Construye un objeto Paciente a partir del JSON
  /// recibido desde nuestra API REST Node.js.
  ///
  /// factory permite aplicar una lógica de conversión
  /// antes de devolver la instancia del modelo.
  factory Paciente.fromJson(Map<String, dynamic> json) {

    // Recuperar el identificador del paciente.
    final id = json['id_paciente'];

    // Recuperar el nombre del archivo de fotografía.
    final nombreFoto = json['foto']?.toString();

    return Paciente(

      // El ID puede llegar como número o texto.
      idPaciente: id == null
          ? null
          : int.parse(id.toString()),

      // Convertir los campos recibidos a String.
      // Si son null, utilizamos una cadena vacía.
      apePaterno: json['ape_paterno']?.toString() ?? '',
      apeMaterno: json['ape_materno']?.toString() ?? '',
      nombres: json['nombres']?.toString() ?? '',

      fechaNacimiento:
          json['fecha_nacimiento']?.toString() ?? '',

      sexo: json['sexo']?.toString() ?? '',

      // Si la fotografía no existe o su nombre está vacío,
      // almacenamos null.
      foto: nombreFoto == null || nombreFoto.isEmpty
          ? null
          : nombreFoto,
    );
  }


  // =====================================================
  // 4. CONVERSIÓN OBJETO DART A JSON
  // =====================================================

  /// Prepara los atributos del paciente para enviarlos
  /// al backend mediante PacienteService.
  ///
  /// No incluye idPaciente porque durante la edición
  /// el identificador se transmite en la URL.
  ///
  /// No incluye foto porque las fotografías se envían
  /// mediante una solicitud HTTP multipart independiente.
  Map<String, dynamic> toJson() {
    return {
      'ape_paterno': apePaterno,
      'ape_materno': apeMaterno,
      'nombres': nombres,
      'fecha_nacimiento': fechaNacimiento,
      'sexo': sexo,
    };
  }
}
