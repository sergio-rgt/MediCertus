import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/paciente.dart';
import '../services/paciente_service.dart';


/// PANTALLA: FORMULARIO DE PACIENTES
///
/// Permite registrar y editar pacientes de MediCertus.
///
/// Responsabilidades:
/// - Presentar los campos del formulario.
/// - Validar la información ingresada.
/// - Seleccionar fotografías desde cámara o galería.
/// - Mostrar la fotografía actual o seleccionada.
/// - Enviar los datos mediante PacienteService.
///
/// Utiliza el modelo Paciente para representar los datos.
class PacienteFormScreen extends StatefulWidget {

  /// Paciente recibido cuando estamos editando.
  ///
  /// Si es null, el formulario registra uno nuevo.
  final Paciente? paciente;

  const PacienteFormScreen({
    super.key,
    this.paciente,
  });

  @override
  State<PacienteFormScreen> createState() =>
      _PacienteFormScreenState();
}


/// Administra los datos y estados del formulario.
class _PacienteFormScreenState extends State<PacienteFormScreen> {

  // =====================================================
  // 1. CONTROLADORES Y SERVICIOS
  // =====================================================

  /// Identificador que permite validar el formulario.
  final _formKey = GlobalKey<FormState>();

  /// Servicio de comunicación con la API Node.js.
  final _service = PacienteService();

  /// Controladores de los campos de texto.
  final _paterno = TextEditingController();
  final _materno = TextEditingController();
  final _nombres = TextEditingController();

  /// Herramienta para acceder a cámara y galería.
  final ImagePicker _imagePicker = ImagePicker();


  // =====================================================
  // 2. VARIABLES DE ESTADO
  // =====================================================

  /// Solicitud de la fotografía existente del paciente.
  Future<Uint8List>? _fotoFuture;

  /// Archivo seleccionado desde cámara o galería.
  XFile? _fotoSeleccionada;

  /// Bytes utilizados para mostrar la vista previa.
  Uint8List? _fotoVistaPrevia;

  /// Fecha de nacimiento seleccionada.
  DateTime? _fechaNacimiento;

  /// Sexo del paciente: M o F.
  String? _sexo;

  /// Indica si hay una operación de guardado en curso.
  bool _guardando = false;

  /// Conserva el ID de un paciente recién creado.
  ///
  /// Evita insertar nuevamente al paciente si falla
  /// la carga de su fotografía y se vuelve a guardar.
  int? _idPacienteCreado;

  /// Determina si el formulario está en modo edición.
  bool get _esEdicion => widget.paciente != null;


  // =====================================================
  // 3. INICIALIZACIÓN DEL FORMULARIO
  // =====================================================

  /// Carga los datos del paciente cuando editamos.
  ///
  /// En modo registro, los campos permanecen vacíos.
  @override
  void initState() {
    super.initState();

    if (_esEdicion) {
      final paciente = widget.paciente!;

      // Obtener fotografía actual desde Node.js.
      final nombreFoto = paciente.foto?.trim();

      if (nombreFoto != null && nombreFoto.isNotEmpty) {
        _fotoFuture = _service.obtenerFoto(nombreFoto);
      }

      // Cargar datos en los campos de texto.
      _paterno.text = paciente.apePaterno;
      _materno.text = paciente.apeMaterno;
      _nombres.text = paciente.nombres;

      // Convertir la fecha recibida desde la API.
      _fechaNacimiento = DateTime.tryParse(
        paciente.fechaNacimiento,
      );

      // Validar el sexo antes de asignarlo al selector.
      final sexo = paciente.sexo;

      _sexo = (sexo == 'M' || sexo == 'F')
          ? sexo
          : null;
    }
  }


  // =====================================================
  // 4. LIBERACIÓN DE RECURSOS
  // =====================================================

  /// Libera los controladores cuando se cierra la pantalla.
  @override
  void dispose() {
    _paterno.dispose();
    _materno.dispose();
    _nombres.dispose();

    super.dispose();
  }


  // =====================================================
  // 5. SELECCIÓN DE FOTOGRAFÍAS
  // =====================================================

  /// Permite seleccionar una fotografía desde cámara
  /// o galería, según el origen solicitado.
  ///
  /// Valida los formatos JPG, PNG y WEBP.
  /// El tamaño máximo permitido es de 2 MB.
  Future<void> _seleccionarFoto(ImageSource origen) async {
    try {
      // Abre la cámara o galería del dispositivo.
      final foto = await _imagePicker.pickImage(
        source: origen,
        imageQuality: 85,
      );

      // El usuario canceló la selección.
      if (foto == null) return;

      // Comprobar extensión del archivo.
      final extension = foto.name
          .split('.')
          .last
          .toLowerCase();

      if (!['jpg', 'jpeg', 'png', 'webp']
          .contains(extension)) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Seleccione una imagen JPG, PNG o WEBP',
            ),
          ),
        );
        return;
      }

      // Verificar que no supere los 2 MB.
      final tamano = await foto.length();

      if (tamano > 2 * 1024 * 1024) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La fotografía no debe superar los 2 MB',
            ),
          ),
        );
        return;
      }

      // Leer la imagen para mostrar su vista previa.
      final bytes = await foto.readAsBytes();

      if (!mounted) return;

      // Actualizar la interfaz con la nueva fotografía.
      setState(() {
        _fotoSeleccionada = foto;
        _fotoVistaPrevia = bytes;
      });

    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo seleccionar la fotografía: $error',
          ),
        ),
      );
    }
  }


  // =====================================================
  // 6. VISUALIZACIÓN DE FOTOGRAFÍAS
  // =====================================================

  /// Muestra la fotografía del paciente.
  ///
  /// Prioridad:
  /// 1. Nueva fotografía seleccionada.
  /// 2. Fotografía almacenada en Ubuntu.
  /// 3. Ícono predeterminado.
  Widget _mostrarFoto() {

    // Mostrar una fotografía recién seleccionada.
    if (_fotoVistaPrevia != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          _fotoVistaPrevia!,
          width: 130,
          height: 130,
          fit: BoxFit.cover,
        ),
      );
    }

    // Mostrar la fotografía que ya tiene el paciente.
    if (_fotoFuture != null) {
      return FutureBuilder<Uint8List>(
        future: _fotoFuture,
        builder: (context, snapshot) {

          if (snapshot.hasData) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                snapshot.data!,
                width: 130,
                height: 130,
                fit: BoxFit.cover,
              ),
            );
          }

          if (snapshot.hasError) {
            return const Icon(
              Icons.person,
              size: 90,
              color: Colors.grey,
            );
          }

          return const CircularProgressIndicator();
        },
      );
    }

    // Paciente sin fotografía.
    return const CircleAvatar(
      radius: 55,
      child: Icon(
        Icons.person,
        size: 60,
      ),
    );
  }


  // =====================================================
  // 7. FORMATO DE FECHAS
  // =====================================================

  /// Convierte una fecha al formato AAAA-MM-DD.
  ///
  /// Es el formato que enviamos a Node.js.
  String _fechaApi(DateTime fecha) {
    final anio = fecha.year.toString().padLeft(4, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');

    return '$anio-$mes-$dia';
  }

  /// Convierte una fecha al formato DD/MM/AAAA
  /// para mostrarla en pantalla.
  String _fechaVista(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');

    return '$dia/$mes/${fecha.year}';
  }

  /// Abre el calendario para seleccionar
  /// la fecha de nacimiento.
  Future<void> _seleccionarFecha() async {
    final hoy = DateTime.now();

    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento != null &&
              !_fechaNacimiento!.isAfter(hoy)
          ? _fechaNacimiento!
          : hoy,
      firstDate: DateTime(1900),
      lastDate: hoy,
      helpText: 'Fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (fecha != null && mounted) {
      setState(() {
        _fechaNacimiento = fecha;
      });
    }
  }


  // =====================================================
  // 8. CAMPOS DE TEXTO
  // =====================================================

  /// Construye un campo de texto reutilizable.
  ///
  /// Recibe:
  /// - Etiqueta del campo.
  /// - Controlador.
  /// - Longitud máxima.
  ///
  /// Todos los campos creados aquí son obligatorios.
  Widget _campo({
    required String etiqueta,
    required TextEditingController controller,
    required int maximo,
  }) {
    return TextFormField(
      controller: controller,
      maxLength: maximo,

      // Impedir exceder la longitud configurada.
      inputFormatters: [
        LengthLimitingTextInputFormatter(maximo),
      ],

      decoration: InputDecoration(
        labelText: etiqueta,
        border: const OutlineInputBorder(),
        counterText: '',
      ),

      validator: (valor) {
        if (valor == null || valor.trim().isEmpty) {
          return 'Este campo es obligatorio';
        }

        return null;
      },
    );
  }


  // =====================================================
  // 9. GUARDADO DEL PACIENTE
  // =====================================================

  /// Registra o actualiza un paciente mediante la API.
  ///
  /// Utiliza el modelo Paciente para preparar sus datos.
  ///
  /// Si se seleccionó una fotografía, la envía después
  /// de obtener o recuperar el ID del paciente.
  Future<void> _guardar() async {

    // Validar campos de texto.
    if (!_formKey.currentState!.validate()) return;

    // Validar fecha de nacimiento.
    if (_fechaNacimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Seleccione la fecha de nacimiento',
          ),
        ),
      );
      return;
    }

    // Validar sexo.
    if (_sexo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione el sexo'),
        ),
      );
      return;
    }

    // Deshabilitar el botón mientras se guarda.
    setState(() => _guardando = true);

    // Construir el objeto Paciente con los valores
    // ingresados en el formulario.
    final paciente = Paciente(
      idPaciente: _esEdicion
          ? widget.paciente!.idPaciente
          : _idPacienteCreado,
      apePaterno: _paterno.text.trim(),
      apeMaterno: _materno.text.trim(),
      nombres: _nombres.text.trim(),
      fechaNacimiento: _fechaApi(_fechaNacimiento!),
      sexo: _sexo!,
      foto: widget.paciente?.foto,
    );

    try {
      // Identificador existente o previamente creado.
      int? idPaciente = paciente.idPaciente;

      // toJson() convierte el objeto Paciente en un mapa
      // con los campos que espera nuestra API REST.
      final respuesta = await _service.guardarPaciente(
        paciente,
        idPaciente: idPaciente,
      );

      // Si se creó un paciente, recuperar su nuevo ID.
      if (idPaciente == null) {
        final contenido = respuesta['data'];

        final registro = contenido is Map
            ? contenido
            : respuesta;

        final idDevuelto = registro['id_paciente'] ??
            registro['idPaciente'] ??
            registro['insertId'] ??
            registro['id'] ??
            respuesta['id_paciente'] ??
            respuesta['insertId'];

        idPaciente = int.tryParse(
          idDevuelto?.toString() ?? '',
        );

        // Conservar el ID para evitar otro INSERT
        // si falla posteriormente la fotografía.
        _idPacienteCreado = idPaciente;
      }

      // Subir la fotografía, si fue seleccionada.
      if (_fotoSeleccionada != null) {
        if (idPaciente == null) {
          throw Exception(
            'El paciente fue registrado, pero la API '
            'no devolvió su ID. No repitas el registro; '
            'debemos revisar la respuesta de Node.js.',
          );
        }

        await _service.subirFotoPaciente(
          idPaciente,
          _fotoSeleccionada!,
        );
      }

      if (!mounted) return;

      // Volver a la pantalla anterior.
      // true indica que se guardó correctamente.
      Navigator.pop(context, true);

    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $error'),
          duration: const Duration(seconds: 6),
        ),
      );

    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }


  // =====================================================
  // 10. CONSTRUCCIÓN DE LA INTERFAZ
  // =====================================================

  /// Construye la pantalla de registro o edición.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _esEdicion
              ? 'Editar paciente'
              : 'Nuevo paciente',
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),

      body: Form(
        key: _formKey,

        child: ListView(
          padding: const EdgeInsets.all(20),

          children: [

            // Fotografía actual o nueva vista previa.
            Center(
              child: _mostrarFoto(),
            ),

            const SizedBox(height: 16),

            // Botones para seleccionar fotografías.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _guardando
                      ? null
                      : () => _seleccionarFoto(
                            ImageSource.camera,
                          ),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Cámara'),
                ),

                const SizedBox(width: 12),

                OutlinedButton.icon(
                  onPressed: _guardando
                      ? null
                      : () => _seleccionarFoto(
                            ImageSource.gallery,
                          ),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galería'),
                ),
              ],
            ),

            // Aviso de fotografía pendiente de guardar.
            if (_fotoSeleccionada != null) ...[
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Fotografía seleccionada (sin guardar)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Apellido paterno.
            _campo(
              etiqueta: 'Apellido paterno',
              controller: _paterno,
              maximo: 60,
            ),

            const SizedBox(height: 18),

            // Apellido materno.
            _campo(
              etiqueta: 'Apellido materno',
              controller: _materno,
              maximo: 60,
            ),

            const SizedBox(height: 18),

            // Nombres.
            _campo(
              etiqueta: 'Nombres',
              controller: _nombres,
              maximo: 100,
            ),

            const SizedBox(height: 18),

            // Selector de fecha de nacimiento.
            OutlinedButton.icon(
              onPressed: _seleccionarFecha,
              icon: const Icon(Icons.calendar_month),
              label: Text(
                _fechaNacimiento == null
                    ? 'Seleccionar fecha de nacimiento'
                    : _fechaVista(_fechaNacimiento!),
              ),
            ),

            const SizedBox(height: 18),

            // Selector de sexo.
            DropdownButtonFormField<String>(
              initialValue: _sexo,
              decoration: const InputDecoration(
                labelText: 'Sexo',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'M',
                  child: Text('Masculino'),
                ),
                DropdownMenuItem(
                  value: 'F',
                  child: Text('Femenino'),
                ),
              ],
              onChanged: (valor) {
                setState(() => _sexo = valor);
              },
              validator: (valor) =>
                  valor == null
                      ? 'Seleccione el sexo'
                      : null,
            ),

            const SizedBox(height: 32),

            // Botón para registrar o actualizar.
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: const Icon(Icons.save),
                label: Text(
                  _guardando
                      ? 'Guardando...'
                      : 'Guardar paciente',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
