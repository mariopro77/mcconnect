import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mcconnect/views/Screens/Desktop/Divisiones/divisiones.dart';
import 'package:mcconnect/views/Screens/Desktop/Divisiones/divisiones_backend.dart';
import 'package:mcconnect/views/Screens/Homescreen.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart'; // Importa file_picker para Flutter Web
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:io' show File, Platform;
import 'dart:html' as html;

/// Clase que representa el formulario para crear un nuevo usuario.
/// Extiende de [StatefulWidget] ya que mantiene el estado interno.
class CreateUser extends StatefulWidget {
  final Empleado empleado; // Objeto empleado que contiene los datos del usuario
  // For storing selected image on mobile

  const CreateUser({
    Key? key,
    required this.empleado,
  }) : super(key: key);

  @override
  CreateUserState createState() => CreateUserState();
}

/// Estado asociado al widget [CreateUser].
class CreateUserState extends State<CreateUser> {
  final DivisionService divisionService =
      DivisionService(baseUrl: "http://localhost:4000");

  List<Division> divisiones = [];
  int? selectedDivisionId;
  String ubicacion = '';
  String web = '';
  String instagram = '';
  bool isLoadingDivisiones = true;

  final TextEditingController ubicacionController = TextEditingController();
  final TextEditingController webController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();

  final _formKey =
      GlobalKey<FormState>(); // Clave global para el formulario de validación
  String? _value; // Valor seleccionado en el dropdown de grupo
  String? _selectedDepartment; // Departamento seleccionado
  late bool _isChecked; // Estado del checkbox para la ubicación en Santiago

  static const double kFieldWidth =
      250.0; // Ancho constante para los campos de texto
  static const EdgeInsets kFieldPadding =
      EdgeInsets.symmetric(vertical: 15.0); // Padding constante para los campos
  Empleado?
      empleado; // Objeto empleado local que se actualizará con los datos del formulario

  Uint8List? _webImage; // For storing image bytes on web
  File? _selectedImage;
  String? _uploadedImageUrl;

  late TextEditingController
      _direccionController; // Controlador para el campo de dirección

  @override
  void initState() {
    super.initState();
    empleado = widget
        .empleado; // Inicializa el objeto empleado con los datos proporcionados
    _direccionController = TextEditingController(
      text: empleado?.ubicacion ?? '',
      // Asigna el valor inicial si existe
    );
    _fetchDivisiones();
  }

  @override
  void dispose() {
    _direccionController.dispose();
    ubicacionController.dispose();
    webController.dispose();
    instagramController.dispose();
    super.dispose();
  }

  Future<void> _fetchDivisiones() async {
    List<Division> fetchedDivisiones = await divisionService.getAllDivisiones();

    setState(() {
      divisiones = fetchedDivisiones;
      isLoadingDivisiones = false;
    });
  }

  /// Método para seleccionar una imagen del dispositivo
  Future<void> _pickAndUploadImage() async {
    // Utiliza file_picker para seleccionar archivos
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'], // Extensiones permitidas
      withData: kIsWeb, // Para obtener bytes en Web
    );

    if (result != null) {
      PlatformFile file = result.files.first;

      setState(() {
        if (kIsWeb) {
          _webImage = file.bytes;
          _selectedImage = null; // Asegura que solo uno esté seleccionado
        } else {
          _selectedImage = File(file.path!);
          _webImage = null;
        }
      });

      // Muestra un indicador de carga mientras se sube la imagen
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      try {
        MultipartFile multipartFile;

        if (kIsWeb) {
          // Obtiene el tipo MIME del archivo
          String? mimeType = lookupMimeType(file.name);
          if (mimeType == null) {
            mimeType = 'application/octet-stream'; // Tipo MIME por defecto
          }
          MediaType mediaType = MediaType.parse(mimeType);

          // Para Flutter Web, usa fromBytes
          multipartFile = MultipartFile.fromBytes(
            file.bytes!,
            filename: file.name,
            contentType: mediaType,
          );
        } else {
          // Para plataformas móviles, usa fromFile
          multipartFile = await MultipartFile.fromFile(
            file.path!,
            filename: file.name,
          );
        }

        // Crea los datos del formulario para la subida
        FormData formData = FormData.fromMap({
          'file': multipartFile,
        });

        // Realiza la petición POST para subir la imagen
        Response response = await Dio().post(
          'http://localhost:4000/api/upload-image', // Asegúrate de que esta URL sea correcta
          data: formData,
          options: Options(
            contentType: 'multipart/form-data',
          ),
        );

        // Cierra el indicador de carga
        Navigator.of(context).pop();

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Obtiene 'name_saved' desde la respuesta
          String nameSaved = response.data['name_saved'];

          // Construye la URL completa de la imagen
          String imageUrl = 'http://localhost:4000/public/$nameSaved';

          setState(() {
            _uploadedImageUrl = imageUrl; // Almacena la URL de la imagen subida
            empleado!.imagen_empleado =
                imageUrl; // Actualiza la imagen del empleado
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imagen subida correctamente')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Error al subir la imagen: ${response.statusCode}')),
          );
        }
      } catch (e) {
        // Cierra el indicador de carga en caso de error
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir la imagen: $e')),
        );
      }
    }
  }

  Future<void> postUserData() async {
    try {
      // Determina la URL correcta según la plataforma
      const uri =
          'http://localhost:4000/api/agregarempleado'; // Asegúrate de que esta URL sea correcta

      final response = await http.post(
        Uri.parse(uri),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(empleado!
            .toJson()), // Asegúrate de que 'imagen_empleado' esté incluido en toJson()
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Datos enviados correctamente');
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Manejar 'empleadoId'
        if (responseData.containsKey('empleadoId')) {
          setState(() {
            empleado!.id_empleado = responseData['empleadoId'];
          });
          print('ID del Empleado: ${empleado!.id_empleado}');
        } else {
          print("La respuesta no contiene 'empleadoId'");
        }

        // Opcional: Navegar o actualizar la UI después de guardar
      } else {
        print(
            "Error al enviar los datos. Código de estado: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Error al enviar los datos: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print("Error al enviar los datos: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar los datos: $e')),
      );
    }
  }

  /// Método personalizado para crear una decoración de input con estilos específicos.
  InputDecoration customInputDecoration({required String labelText}) {
    return InputDecoration(
      labelText: labelText, // Texto de la etiqueta
      labelStyle: const TextStyle(
          color: Colors.grey), // Estilo del texto de la etiqueta
      floatingLabelStyle:
          const TextStyle(color: Colors.black), // Estilo del texto flotante
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10), // Bordes redondeados
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10), // Bordes redondeados
        borderSide: const BorderSide(
            color: Colors.grey,
            width: 1.0), // Color del borde cuando está habilitado
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10), // Bordes redondeados
        borderSide: const BorderSide(
            color: Color(0xFF17A2B8),
            width: 2.0), // Color del borde cuando está enfocado
      ),
    );
  }

  /// Método que construye los campos del formulario.
  Widget buildFormFields() {
    return Form(
        key: _formKey, // Asigna la clave al formulario para validación
        child: Wrap(
          spacing: 20, // Espaciado horizontal entre widgets
          runSpacing: 20, // Espaciado vertical entre líneas
          alignment: WrapAlignment.start, // Alineación inicial
          children: [
            // Primera columna de campos
            Column(
              children: [
                // Widget para seleccionar y mostrar la imagen del usuario
                GestureDetector(
                  onTap:
                      _pickAndUploadImage, // Maneja el evento de toque para seleccionar una imagen
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                        100), // Hace que la imagen tenga bordes circulares
                    child: empleado?.imagen_empleado != null
                        ? Image.network(
                            empleado!.imagen_empleado!,
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            loadingBuilder: (BuildContext context, Widget child,
                                ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          (loadingProgress.expectedTotalBytes ??
                                              1)
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (BuildContext context,
                                Object exception, StackTrace? stackTrace) {
                              return Image.asset(
                                "../assets/Icons/UserIcon.png",
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : Image.asset(
                            "../assets/Icons/UserIcon.png",
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(height: 25), // Espaciado vertical
                // Campo de texto para el nombre del usuario
                CustomTextFormField(
                  labelText: "Nombre",
                  onChange: (v) {
                    setState(() {
                      empleado!.nombre_empleado =
                          v; // Actualiza el nombre del empleado
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa el nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 25), // Espaciado vertical
                // Campo de texto para el correo electrónico del usuario
                CustomTextFormField(
                  labelText: "Correo electrónico",
                  onChange: (v) {
                    setState(() {
                      empleado!.correo_empleado =
                          v; // Actualiza el correo electrónico del empleado
                    });
                  },
                ),
                const SizedBox(height: 25), // Espaciado vertical
                // Row que contiene los campos de teléfono y extensión
                SizedBox(
                    width: 250,
                    height: 45,
                    child: Row(
                      children: [
                        // Campo de texto para el teléfono
                        Expanded(
                          child: TextFormField(
                            onChanged: (v) {
                              setState(() {
                                empleado!.telefono_empleado =
                                    v; // Actualiza el teléfono del empleado
                              });
                            },
                            decoration: InputDecoration(
                              label: Text("Teléfono"),
                              labelStyle: const TextStyle(
                                  color: Colors.grey), // Estilo de la etiqueta
                              floatingLabelStyle: const TextStyle(
                                  color: Colors
                                      .black), // Estilo de la etiqueta flotante
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    10), // Bordes redondeados
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    10), // Bordes redondeados
                                borderSide: const BorderSide(
                                    color: Colors.grey,
                                    width:
                                        1.0), // Color y grosor del borde cuando está habilitado
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    10), // Bordes redondeados
                                borderSide: const BorderSide(
                                    color: Color(0xFF17A2B8),
                                    width:
                                        2.0), // Color y grosor del borde cuando está enfocado
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10), // Espaciado entre campos
                        // Campo de texto para la extensión
                        SizedBox(
                          width: 70,
                          height: 45,
                          child: TextFormField(
                            onChanged: (v) {
                              setState(() {
                                empleado!.extension_empleado =
                                    v; // Actualiza la extensión del empleado
                              });
                            },
                            decoration: InputDecoration(
                              label: Text("Ext"),
                              labelStyle: const TextStyle(
                                  color: Colors.grey), // Estilo de la etiqueta
                              floatingLabelStyle: const TextStyle(
                                  color: Colors
                                      .black), // Estilo de la etiqueta flotante
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    10), // Bordes redondeados
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    10), // Bordes redondeados
                                borderSide: const BorderSide(
                                    color: Colors.grey,
                                    width:
                                        1.0), // Color y grosor del borde cuando está habilitado
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    10), // Bordes redondeados
                                borderSide: const BorderSide(
                                    color: Color(0xFF17A2B8),
                                    width:
                                        2.0), // Color y grosor del borde cuando está enfocado
                              ),
                            ),
                          ),
                        ),
                      ],
                    )),
                const SizedBox(height: 25), // Espaciado vertical
                // Campo de texto para el número de celular o WhatsApp
                CustomTextFormField(
                  labelText: "Flota/Whatsapp",
                  onChange: (v) {
                    setState(() {
                      empleado!.telefono_empleado =
                          v; // Actualiza el celular del empleado
                    });
                  },
                ),
              ],
            ),
            // Segunda columna de campos
            Column(
              children: [
                // Campo de texto para Instagram
                instagram.isNotEmpty
                    ? CustomTextFormField(
                        labelText: "Instagram",
                        readOnly: true,
                        controller: instagramController,
                      )
                    : SizedBox.shrink(),
                const SizedBox(height: 25), // Espaciado vertical
                // Dropdown para seleccionar el grupo
                SizedBox(
                  width: kFieldWidth,
                  child: isLoadingDivisiones
                      ? Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<int>(
                          decoration:
                              customInputDecoration(labelText: "División"),
                          value: selectedDivisionId,
                          hint: const Text("Seleccione una División"),
                          items: divisiones.map((Division division) {
                            return DropdownMenuItem<int>(
                              value: division.idDivision,
                              child: Text(division.division),
                            );
                          }).toList(),
                          onChanged: (newValue) async {
                            if (newValue == null) return;

                            setState(() {
                              selectedDivisionId = newValue;
                              empleado!.id_division =
                                  newValue; // Actualiza el campo división del empleado
                              ubicacion = '';
                              web = '';
                              instagram = '';
                              _direccionController.text = '';
                              ubicacionController.text = '';
                              webController.text = '';
                              instagramController.text = '';
                            });

                            // Obtener los detalles de la división seleccionada
                            Map<String, dynamic>? divisionDetails =
                                await divisionService
                                    .getDivisionDetails(newValue.toString());

                            if (divisionDetails != null) {
                              setState(() {
                                ubicacion = divisionDetails['ubicacion'] ?? '';
                                web = divisionDetails['web'] ?? '';
                                instagram = divisionDetails['instagram'] ?? '';
                                _direccionController.text = ubicacion;
                                ubicacionController.text = ubicacion;
                                webController.text = web;
                                instagramController.text = instagram;
                              });
                            } else {
                              // Manejar el error, por ejemplo, mostrar un SnackBar
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'No se pudieron cargar los detalles de la división')),
                              );
                            }
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Por favor, selecciona una división';
                            }
                            return null;
                          },
                        ),
                ),
                const SizedBox(height: 25), // Espaciado vertical
                // Dropdown para seleccionar el departamento
                SizedBox(
                  width: kFieldWidth,
                  child: DropdownButtonFormField<String>(
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedDepartment =
                            newValue; // Actualiza el departamento seleccionado
                        empleado!.departamento =
                            newValue!; // Actualiza el departamento del empleado
                      });
                    },
                    value: _selectedDepartment, // Valor actual del dropdown
                    decoration: customInputDecoration(
                        labelText: "Departamento"), // Decoración del dropdown
                    hint: const Text(
                        "Seleccione Departamento"), // Texto de sugerencia
                    items: const [
                      DropdownMenuItem(value: "Ventas", child: Text("Ventas")),
                      DropdownMenuItem(
                          value: "Operaciones", child: Text("Operaciones")),
                      DropdownMenuItem(
                          value: "Coordinación", child: Text("Coordinación")),
                      DropdownMenuItem(
                          value: "Aduanas", child: Text("Aduanas")),
                      DropdownMenuItem(
                          value: "Créditos y Cobros",
                          child: Text("Créditos y Cobros")),
                      DropdownMenuItem(
                          value: "Finanzas", child: Text("Finanzas")),
                      DropdownMenuItem(
                          value: "Administración",
                          child: Text("Administración")),
                      DropdownMenuItem(
                          value: "Recursos Humano",
                          child: Text("Recursos Humano")),
                      DropdownMenuItem(
                          value: "Servicio al cliente",
                          child: Text("Servicio al cliente")),
                      DropdownMenuItem(
                          value: "Tecnología", child: Text("Tecnología")),
                      DropdownMenuItem(
                          value: "Product Development",
                          child: Text("Product Development")),
                      DropdownMenuItem(
                          value: "Product Manager",
                          child: Text("Product Manager")),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, selecciona un departamento'; // Mensaje de error si no se selecciona ningún departamento
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 25), // Espaciado vertical
                // Campo de texto para la posición del usuario
                CustomTextFormField(
                  labelText: "Posición",
                  onChange: (v) {
                    setState(() {
                      empleado!.posicion_empleado =
                          v; // Actualiza la posición del empleado
                    });
                  },
                ),
                const SizedBox(height: 25), // Espaciado vertical
                // Campo de texto para la dirección del usuario (solo lectura)
                SizedBox(
                  width: kFieldWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment
                        .start, // Alineación del contenido a la izquierda
                    children: [
                      CustomTextFormField(
                        controller:
                            _direccionController, // Controlador del campo de dirección
                        labelText: "Dirección",
                        readOnly: true, // Campo de solo lectura
                      ),
                      // Checkbox para indicar si la ubicación es en Santiago, solo visible para ciertos grupos
                    ],
                  ),
                ),
              ],
            ),
          ],
        ));
  }

  /// Método que construye los botones del formulario.
  Widget buildButtons() {
    return Padding(
      padding: const EdgeInsets.all(8.0), // Espaciado alrededor de los botones
      child: Wrap(
        runSpacing: 10, // Espaciado vertical entre botones
        spacing: 10, // Espaciado horizontal entre botones
        alignment:
            WrapAlignment.spaceEvenly, // Distribución equitativa de los botones
        children: [
          // Botón para guardar los datos del usuario
          CustomButton(
            text: "Agregar",
            color: Colors.green,
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Valida el formulario antes de enviar los datos
                postUserData(); // Envía los datos al servidor
                setState(() {
                  empleado =
                      empleado; // Actualiza el estado del empleado (no es necesario aquí)
                });
                if (mounted) {
                  Navigator.of(context)
                      .pop(true); // Cierra el diálogo y retorna true
                }
                // Puedes cerrar el diálogo después de enviar los datos si lo deseas
                // Navigator.of(context).pop();
              }
            },
          ),
          // Botón para cancelar la creación del usuario y cerrar el diálogo
          CustomButton(
            text: "Cancelar",
            color: Colors.grey,
            onPressed: () {
              Navigator.of(context).pop(); // Cierra el diálogo
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String divisionName = '';

    if (selectedDivisionId != null) {
      final selectedDivision = divisiones.firstWhere(
        (d) => d.idDivision == selectedDivisionId,
        orElse: () => Division(idDivision: 0, division: ''),
      );
      divisionName = selectedDivision.division;
    }

    return Dialog(
      child: Container(
        height: 700, // Altura del diálogo
        width: 600, // Ancho del diálogo
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(10), // Bordes redondeados del diálogo
        ),
        child: Column(
          children: [
            // Encabezado del diálogo
            Padding(
              padding: const EdgeInsets.all(
                  34.0), // Espaciado alrededor del encabezado
              child: Row(
                mainAxisAlignment: MainAxisAlignment
                    .spaceBetween, // Espacio entre los elementos del encabezado
                children: [
                  const Text(
                    "Agregar Empleado",
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    divisionName.isNotEmpty
                        ? divisionName
                        : "", // Muestra el tipo de empleado o "Figibox" si es "ASW"
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // Formulario dentro de un scroll para manejar contenido excedente
            Expanded(
              child: SingleChildScrollView(
                child: buildFormFields(), // Construye los campos del formulario
              ),
            ),

            // Botones al final del diálogo
            Padding(
              padding: const EdgeInsets.all(
                  8.0), // Espaciado alrededor de los botones
              child: buildButtons(), // Construye los botones
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget personalizado para campos de texto con estilos específicos.
/// Extiende de [StatelessWidget].
class CustomTextFormField extends StatelessWidget {
  final String labelText; // Texto de la etiqueta del campo
  final bool readOnly; // Determina si el campo es de solo lectura
  final ValueChanged<String>? onChange; // Callback para cambios en el texto
  final FormFieldValidator<String>?
      validator; // Función de validación del campo
  final TextEditingController? controller; // Controlador del campo de texto

  const CustomTextFormField({
    super.key,
    required this.labelText,
    this.readOnly = false,
    this.onChange,
    this.validator,
    this.controller,
  });

  static const double kFieldWidth = 250.0; // Ancho constante para los campos

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kFieldWidth, // Define el ancho del campo
      child: TextFormField(
        controller: controller, // Asigna el controlador si existe
        readOnly: readOnly, // Asigna la propiedad de solo lectura
        textAlign: TextAlign.start, // Alineación del texto
        decoration: InputDecoration(
          labelText: labelText, // Texto de la etiqueta
          labelStyle:
              const TextStyle(color: Colors.grey), // Estilo de la etiqueta
          floatingLabelStyle: const TextStyle(
              color: Colors.black), // Estilo de la etiqueta flotante
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), // Bordes redondeados
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), // Bordes redondeados
            borderSide: const BorderSide(
                color: Colors.grey,
                width: 1.0), // Color y grosor del borde cuando está habilitado
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), // Bordes redondeados
            borderSide: const BorderSide(
                color: Color(0xFF17A2B8),
                width: 2.0), // Color y grosor del borde cuando está enfocado
          ),
        ),
        onChanged: onChange, // Asigna el callback de cambios si existe
        cursorColor: Colors.black, // Color del cursor
        maxLines: null, // Permite múltiples líneas si es necesario
        style:
            const TextStyle(color: Colors.black), // Estilo del texto ingresado
        validator: validator, // Asigna la función de validación si existe
      ),
    );
  }
}

/// Widget personalizado para botones con estilos específicos.
/// Extiende de [StatelessWidget].
class CustomButton extends StatelessWidget {
  final String text; // Texto que se muestra en el botón
  final Color color; // Color de fondo del botón
  final VoidCallback onPressed; // Callback que se ejecuta al presionar el botón

  const CustomButton({
    Key? key,
    required this.text,
    required this.color,
    required this.onPressed,
  }) : super(key: key);

  static const EdgeInsets kButtonPadding = EdgeInsets.symmetric(
      horizontal: 40, vertical: 20); // Padding constante para los botones

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed, // Asigna la función al presionar el botón
      style: FilledButton.styleFrom(
        backgroundColor: color, // Color de fondo del botón
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)), // Bordes redondeados
        padding: kButtonPadding, // Padding interno del botón
      ),
      child: Text(text), // Texto que se muestra en el botón
    );
  }
}
