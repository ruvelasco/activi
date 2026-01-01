import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:arasaac_activities/widgets/template_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/arasaac_service.dart';
import 'services/soy_visual_service.dart';
import 'services/activity_type_service.dart';
import 'models/canvas_image.dart';
import 'models/soy_visual.dart';
import 'models/project_data.dart';
import 'models/user_account.dart';
import 'models/activity_type.dart';
import 'services/user_service.dart';
import 'widgets/template_menu.dart';
import 'widgets/dynamic_activity_creator_panel.dart';
import 'widgets/activity_app_bar.dart';
import 'widgets/sidebar_panel.dart';
import 'widgets/auth/auth_dialog.dart';
import 'widgets/splash_screen.dart';
import 'actividades/shadow_matching_activity.dart';
import 'actividades/puzzle_activity.dart';
import 'actividades/writing_practice_activity.dart';
import 'actividades/counting_activity.dart';
import 'actividades/phonological_awareness_activity.dart';
import 'actividades/series_activity.dart' as series_activity;
import 'actividades/symmetry_activity.dart' as symmetry_activity;
import 'actividades/syllable_vocabulary_activity.dart' as syllable_activity;
import 'actividades/classification_activity.dart';
import 'actividades/semantic_field_activity.dart' as semantic_activity;
import 'actividades/instructions_activity.dart' as instructions_activity;
import 'actividades/phrases_activity.dart' as phrases_activity;
import 'actividades/card_activity.dart' as card_activity;
import 'actividades/activity_pack_generator.dart';
import 'actividades/phonological_squares_activity.dart'
    as phonological_squares_activity;
import 'actividades/crossword_activity.dart' as crossword_activity;
import 'actividades/sentence_completion_activity.dart'
    as sentence_completion_activity;
import 'actividades/word_search_activity.dart' as word_search_activity;
import 'widgets/activity_pack_config_dialog.dart';
import 'widgets/activity_pack_progress_dialog.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ARASAAC Activities',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6A1B9A)),
        useMaterial3: true,
      ),
      home: const SplashScreen(child: ActivityCreatorPage()),
    );
  }
}

class ActivityCreatorPage extends StatefulWidget {
  const ActivityCreatorPage({super.key});

  @override
  State<ActivityCreatorPage> createState() => _ActivityCreatorPageState();
}

enum SidebarMode {
  arasaac,
  soyVisual,
  text,
  shapes,
  photo,
  templates,
  config,
  creador,
  visualInstructions,
}

enum ConfigTab { page, arasaac }

class _ActivityCreatorPageState extends State<ActivityCreatorPage> {
  // A4 en puntos (pts) para PDF: 1 punto = 1/72 pulgadas
  // A4 = 210mm x 297mm = 8.27" x 11.69" = 595.28 x 841.89 pts
  static const double _a4WidthPts = 595.28; // A4 ancho en puntos
  static const double _a4HeightPts = 841.89; // A4 alto en puntos
  late ArasaacService _arasaacService;
  final SoyVisualService _soyVisualService = SoyVisualService();
  final UserService _userService = UserService();
  final ActivityTypeService _activityTypeService = ActivityTypeService();
  UserAccount? _currentUser;
  Map<String, ActivityType> _activityTypes = {}; // Mapa de nombre -> ActivityType
  String? _activeProjectId;
  String _projectName = ''; // Nombre del proyecto actual
  bool _isPersisting = false;
  bool _sidebarCollapsed = false;
  static const String _arasaacCredit =
      '    Autor pictogramas: Sergio Palao. Origen: ARASAAC (http://www.arasaac.org). Licencia: CC (BY-NC-SA). Propiedad: Gobierno de Aragón (España)';
  static const String _soyVisualCredit =
      '    Las fotografías/ láminas ilustradas utilizados a partir del API #Soyvisual son parte de una obra colectiva propiedad de la Fundación Orange y han sido creados bajo licencia Creative Commons (BY-NC-SA)';

  // Configuración de ARASAAC
  ArasaacConfig _arasaacConfig = const ArasaacConfig();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _soyVisualSearchController =
      TextEditingController();
  final TextEditingController _headerController = TextEditingController(); // Título de la página actual
  final TextEditingController _footerController = TextEditingController(); // Instrucciones de la página actual
  final TextEditingController _documentFooterController = TextEditingController(); // Pie de página del documento (autor, licencia, etc)
  List<ArasaacImage> _searchResults = [];
  List<SoyVisualElement> _soyVisualResults = [];
  List<List<CanvasImage>> _pages = [
    [],
  ]; // Lista de páginas, cada página tiene sus imágenes
  List<String> _pageTitles = ['']; // Título de cada página
  List<String> _pageInstructions = ['']; // Instrucciones de cada página
  List<TemplateType> _pageTemplates = [
    TemplateType.blank,
  ]; // Plantilla de cada página
  List<Color> _pageBackgrounds = [Colors.white];
  List<bool> _pageOrientations = [false]; // false = vertical, true = horizontal
  int _currentPage = 0;
  bool _isSearching = false;
  bool _isSoyVisualSearching = false;
  Set<String> _selectedImageIds = {}; // Selección múltiple
  SidebarMode _sidebarMode = SidebarMode.arasaac;
  String _lastSoyVisualQuery = '';
  SoyVisualCategory _lastSoyVisualCategory = SoyVisualCategory.photos;
  SoyVisualCategory _soyVisualCategory = SoyVisualCategory.photos;
  ConfigTab _configTab = ConfigTab.page;
  HeaderFooterScope _headerScope = HeaderFooterScope.all;
  HeaderFooterScope _footerScope = HeaderFooterScope.all;
  bool _showPageNumbers = false;
  bool _addAsCard = false; // Modo tarjeta activado/desactivado
  String? _logoPath; // Ruta del logo
  Offset _logoPosition = const Offset(20, 20); // Posición del logo
  double _logoSize = 50.0; // Tamaño del logo
  Uint8List? _logoWebBytes; // Logo en web
  bool _showArasaacCredit = true;
  bool _showSoyVisualCredit = false;
  double _canvasZoom = 1.0;
  Size _canvasSize = Size.zero;
  final TransformationController _transformationController = TransformationController();
  Offset _editBarPosition = const Offset(
    20,
    20,
  ); // Posición de la barra de edición

  // Sistema de historial para undo/redo
  final List<List<List<CanvasImage>>> _history = [[]]; // Historial de estados
  int _historyIndex = 0; // Índice actual en el historial

  // Instrucciones visuales temporales para añadir después de generar actividad
  CanvasImage? _pendingVisualInstructions;

  Future<void> _loadUserLogoPreference() async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('user_logo_${_currentUser!.id}_path');
    final web = prefs.getString('user_logo_${_currentUser!.id}_web');
    setState(() {
      _logoPath = (path != null && path.isNotEmpty) ? path : null;
      _logoWebBytes = web != null ? base64Decode(web) : null;
    });
  }

  Future<void> _saveUserLogoPreference() async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    final keyPath = 'user_logo_${_currentUser!.id}_path';
    final keyWeb = 'user_logo_${_currentUser!.id}_web';
    if (_logoPath != null && _logoPath!.isNotEmpty) {
      await prefs.setString(keyPath, _logoPath!);
    } else {
      await prefs.remove(keyPath);
    }
    if (_logoWebBytes != null && _logoWebBytes!.isNotEmpty) {
      await prefs.setString(keyWeb, base64Encode(_logoWebBytes!));
    } else {
      await prefs.remove(keyWeb);
    }
  }

  List<CanvasImage> get _canvasImages {
    // Validar que _currentPage esté dentro del rango
    if (_currentPage >= 0 && _currentPage < _pages.length) {
      return _pages[_currentPage];
    }
    // Si está fuera de rango, retornar lista vacía
    print(
      'ADVERTENCIA: _currentPage ($_currentPage) fuera de rango. Total páginas: ${_pages.length}',
    );
    return [];
  }

  TemplateType get _currentTemplate {
    // Validar que _currentPage esté dentro del rango
    if (_currentPage >= 0 && _currentPage < _pageTemplates.length) {
      return _pageTemplates[_currentPage];
    }
    // Si está fuera de rango, retornar blank
    print(
      'ADVERTENCIA: _currentPage ($_currentPage) fuera de rango para templates. Total: ${_pageTemplates.length}',
    );
    return TemplateType.blank;
  }

  bool _isHttpUrl(String value) =>
      value.startsWith('http://') || value.startsWith('https://');

  Widget _buildLogoWidget() {
    if (_logoPath == null && _logoWebBytes == null) return const SizedBox();

    if (kIsWeb) {
      if (_logoWebBytes != null) {
        return Image.memory(_logoWebBytes!, fit: BoxFit.contain);
      }
      if (_logoPath != null && _isHttpUrl(_logoPath!)) {
        return Image.network(_logoPath!, fit: BoxFit.contain);
      }
      return const SizedBox();
    }

    if (_logoPath != null) {
      return Image.file(File(_logoPath!), fit: BoxFit.contain);
    }
    return const SizedBox();
  }

  @override
  void initState() {
    super.initState();
    _arasaacService = ArasaacService(config: _arasaacConfig);
    _loadActivityTypes();

    // Añadir listeners para guardar automáticamente cuando se editen título/instrucciones
    _headerController.addListener(() {
      if (_pageTitles.length > _currentPage) {
        _pageTitles[_currentPage] = _headerController.text;
      }
    });
    _footerController.addListener(() {
      if (_pageInstructions.length > _currentPage) {
        _pageInstructions[_currentPage] = _footerController.text;
      }
    });
  }

  Future<void> _loadActivityTypes() async {
    try {
      final activities = await _activityTypeService.getAll();
      setState(() {
        _activityTypes = {
          for (var activity in activities) activity.name: activity,
        };
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error al cargar tipos de actividades: $e');
      }
      // Continuar sin activity types del backend (usará valores por defecto)
    }
  }

  /// Aplica título e instrucciones desde ActivityType si existe, sino usa los del result
  void _applyTitleAndInstructions(String activityName, {required String defaultTitle, required String defaultInstructions}) {
    final activityType = _activityTypes[activityName];
    String title, instructions;
    if (activityType != null && activityType.title.isNotEmpty) {
      title = activityType.title;
      instructions = activityType.description;
    } else {
      title = defaultTitle;
      instructions = defaultInstructions;
    }

    // Aplicar a la página actual
    _pageTitles[_currentPage] = title;
    _pageInstructions[_currentPage] = instructions;
    _headerController.text = title;
    _footerController.text = instructions;
  }

  /// Sincroniza los controllers con la página actual
  void _syncControllersWithCurrentPage() {
    _headerController.text = _pageTitles[_currentPage];
    _footerController.text = _pageInstructions[_currentPage];
  }

  /// Guarda los valores de los controllers en la página actual
  void _saveControllersToCurrentPage() {
    _pageTitles[_currentPage] = _headerController.text;
    _pageInstructions[_currentPage] = _footerController.text;
  }

  void _updateArasaacConfig(ArasaacConfig newConfig) {
    setState(() {
      _arasaacConfig = newConfig;
      _arasaacService = ArasaacService(config: newConfig);
    });
  }

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();

  void _requireLogin() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Inicia sesión para usar esta función')),
    );
  }

  Future<void> _showAuthDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AuthDialog(
        onLogin: (email, password) async {
          final user = await _userService.login(email, password);
          if (user != null) {
            setState(() {
              _currentUser = user;
              _activeProjectId = null;
            });
            await _loadUserLogoPreference();
            return true;
          }
          return false;
        },
        onRegister: (email, password) async {
          final user = await _userService.register(email, password);
          if (user != null) {
            setState(() {
              _currentUser = user;
              _activeProjectId = null;
            });
            await _loadUserLogoPreference();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Cuenta creada exitosamente!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
            return true;
          }
          return false;
        },
        errorMessage: _userService.lastError,
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Bienvenido ${_currentUser?.username}!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _newProject() {
    setState(() {
      _pages.clear();
      _pageOrientations.clear();
      _pageTemplates.clear();
      _pageBackgrounds.clear();
      _currentPage = 0;
      _pages.add([]);
      _pageOrientations.add(false);
      _pageTemplates.add(TemplateType.blank);
      _pageBackgrounds.add(Colors.white);
      _activeProjectId = null;
      _history.clear();
      _historyIndex = -1;
    });
    _saveToHistory();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nuevo proyecto creado')));
    }
  }

  Future<void> _promptSaveProject() async {
    if (_currentUser == null) {
      _requireLogin();
      return;
    }

    // Paso 1: Elegir etiqueta
    final selectedLabel = await showDialog<String>(
      context: context,
      builder: (context) => _LabelSelectionDialog(),
    );

    if (selectedLabel == null) return; // Usuario canceló

    // Paso 2: Nombre del proyecto
    final nameController = TextEditingController(
      text: 'Proyecto ${DateTime.now().toLocal().toString().split(' ').first}',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Guardar proyecto'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(nameController.text.trim()),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      // Insertar etiqueta como primera página
      await _insertLabelAsFirstPage(selectedLabel);
      await _saveProject(result);
    }
  }

  Future<void> _insertLabelAsFirstPage(String labelPath) async {
    // Cargar la imagen de assets como bytes para que funcione en web
    final ByteData data = await rootBundle.load(labelPath);
    final Uint8List bytes = data.buffer.asUint8List();

    setState(() {
      // Insertar una nueva página vacía al inicio
      _pages.insert(0, []);
      _pageOrientations.insert(0, false); // Vertical por defecto
      _pageTemplates.insert(0, TemplateType.blank);
      _pageBackgrounds.insert(0, Colors.white);

      // Añadir la etiqueta centrada en la página
      final canvasWidth = _a4WidthPts;
      final canvasHeight = _a4HeightPts;

      // Las etiquetas son 2000x600 (proporción 10:3)
      // Ajustar tamaño respetando la proporción
      final labelWidth = canvasWidth * 0.85; // 85% del ancho de la página
      final labelHeight = labelWidth * (600 / 2000); // Mantener proporción 10:3
      final labelX = (canvasWidth - labelWidth) / 2;
      final labelY = (canvasHeight - labelHeight) / 2;

      _pages[0].add(
        CanvasImage.localImage(
          id: 'label_${DateTime.now().millisecondsSinceEpoch}',
          imagePath: labelPath,
          position: Offset(labelX, labelY),
          scale: 1.0,
        ).copyWith(
          width: labelWidth,
          height: labelHeight,
          webBytes: bytes, // Añadir los bytes para que funcione en web
        ),
      );

      // Ir a la primera página
      _currentPage = 0;
    });
  }

  ProjectData _buildProjectData(String name) {
    // Guardar los valores actuales de los controllers en las listas
    _saveControllersToCurrentPage();

    // Determinar imagen de portada: es la etiqueta de la primera página (si existe)
    CanvasImage? coverImage;
    if (_pages.isNotEmpty && _pages.first.isNotEmpty) {
      // Buscar la etiqueta en la primera página (id empieza con 'label_')
      final labelImage = _pages.first.where((img) =>
        img.id.startsWith('label_') && img.imagePath != null
      ).firstOrNull;

      if (labelImage != null) {
        coverImage = labelImage.copyWith();
        if (kDebugMode) {
          print('=== DEBUG: CoverImage (etiqueta): ${coverImage.imagePath}');
        }
      }
    }

    return ProjectData(
      id: _activeProjectId ?? _generateId(),
      name: name,
      updatedAt: DateTime.now(),
      pages: _pages
          .map((page) => page.map((img) => img.copyWith()).toList())
          .toList(),
      templates: List<TemplateType>.from(_pageTemplates),
      backgrounds: List<Color>.from(_pageBackgrounds),
      orientations: List<bool>.from(_pageOrientations),
      pageTitles: List<String>.from(_pageTitles),
      pageInstructions: List<String>.from(_pageInstructions),
      documentFooter: _documentFooterController.text.trim().isEmpty
          ? null
          : _documentFooterController.text,
      headerText: null, // Ya no se usa
      footerText: null, // Ya no se usa
      headerScope: _headerScope,
      footerScope: _footerScope,
      showPageNumbers: _showPageNumbers,
      logoPath: _logoPath,
      logoPosition: _logoPosition,
      logoSize: _logoSize,
      coverImage: coverImage,
    );
  }

  Future<void> _saveProject(String name) async {
    if (_currentUser == null) {
      _requireLogin();
      return;
    }
    setState(() {
      _isPersisting = true;
    });

    print('DEBUG: Intentando guardar proyecto: $name');
    final project = _buildProjectData(name);
    print('DEBUG: Proyecto construido con ID: ${project.id}');
    final saved = await _userService.saveProject(project);
    print(
      'DEBUG: Resultado de saveProject: ${saved != null ? "SUCCESS" : "FAILED"}',
    );
    setState(() {
      _activeProjectId = saved?.id;
      _projectName = name; // Guardar nombre del proyecto
      _isPersisting = false;
    });
    if (saved == null) {
      print('ERROR: saveProject retornó null');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error al guardar')));
      }
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Proyecto guardado')));
    }
  }

  Future<void> _showLoadProjectDialog() async {
    if (_currentUser == null) {
      _requireLogin();
      return;
    }

    final projects = await _userService.fetchProjects();
    if (projects.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay proyectos guardados')),
        );
      }
      return;
    }

    final selected = await showDialog<ProjectData>(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            width: 800,
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_open),
                      const SizedBox(width: 8),
                      Text(
                        'Mis proyectos',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // Grid de proyectos
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      return _buildProjectCard(context, project);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      await _loadProject(selected);
    }
  }

  Widget _buildProjectCard(BuildContext context, ProjectData project) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(project),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen de portada
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.grey[200],
                child: project.coverImage != null
                    ? _buildCoverImage(project.coverImage!)
                    : Center(
                        child: Icon(
                          Icons.insert_drive_file,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
            ),
            // Información del proyecto
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${project.pages.length} página${project.pages.length != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Text(
                      'Actualizado: ${_formatDate(project.updatedAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage(CanvasImage image) {
    if (image.imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: image.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      );
    } else if (image.webBytes != null) {
      return Image.memory(
        image.webBytes!,
        fit: BoxFit.cover,
      );
    } else if (image.imagePath != null) {
      // Si es un asset (etiqueta), usar Image.asset
      if (image.imagePath!.startsWith('assets/')) {
        return Image.asset(
          image.imagePath!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            if (kDebugMode) {
              print('Error loading asset: ${image.imagePath}');
            }
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, size: 48),
            );
          },
        );
      } else if (!kIsWeb) {
        // Si no es web y no es un asset, es un archivo local
        return Image.file(
          File(image.imagePath!),
          fit: BoxFit.cover,
        );
      }
    }
    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.image, size: 48),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Hoy ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Ayer';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _showEditVisualInstructionsDialog(String barId) async {
    final index = _canvasImages.indexWhere((img) => img.id == barId);
    if (index == -1) return;

    final currentBar = _canvasImages[index];
    String? tempActivityUrl = currentBar.activityPictogramUrl;
    List<String> tempMaterialUrls = List.from(currentBar.materialPictogramUrls ?? []);

    final activitySearchController = TextEditingController();
    final materialSearchController = TextEditingController();
    List<ArasaacImage> activitySearchResults = [];
    List<ArasaacImage> materialSearchResults = [];

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar instrucciones visuales'),
              content: SizedBox(
                width: 500,
                height: 600,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pictograma de actividad',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      if (tempActivityUrl != null)
                        Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.blue, width: 2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: tempActivityUrl!,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setDialogState(() {
                                    tempActivityUrl = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: activitySearchController,
                        decoration: const InputDecoration(
                          hintText: 'Buscar actividad (ej: sumar, leer, escribir)',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (query) async {
                          if (query.trim().isEmpty) return;
                          final results = await _arasaacService.searchPictograms(query);
                          setDialogState(() {
                            activitySearchResults = results;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      if (activitySearchResults.isNotEmpty)
                        SizedBox(
                          height: 150,
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: activitySearchResults.length,
                            itemBuilder: (context, index) {
                              final pictogram = activitySearchResults[index];
                              final url = 'https://api.arasaac.org/api/pictograms/${pictogram.id}?download=false';
                              return GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    tempActivityUrl = url;
                                    activitySearchResults = [];
                                    activitySearchController.clear();
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: url,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Pictogramas de materiales',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      if (tempMaterialUrls.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tempMaterialUrls.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final url = entry.value;
                            return Stack(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: url,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      setDialogState(() {
                                        tempMaterialUrls.removeAt(idx);
                                      });
                                    },
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: materialSearchController,
                        decoration: const InputDecoration(
                          hintText: 'Buscar material (ej: lápiz, tijeras, goma)',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (query) async {
                          if (query.trim().isEmpty) return;
                          final results = await _arasaacService.searchPictograms(query);
                          setDialogState(() {
                            materialSearchResults = results;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      if (materialSearchResults.isNotEmpty)
                        SizedBox(
                          height: 150,
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: materialSearchResults.length,
                            itemBuilder: (context, index) {
                              final pictogram = materialSearchResults[index];
                              final url = 'https://api.arasaac.org/api/pictograms/${pictogram.id}?download=false';
                              return GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    tempMaterialUrls.add(url);
                                    materialSearchResults = [];
                                    materialSearchController.clear();
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: url,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _canvasImages[index] = currentBar.copyWith(
                        activityPictogramUrl: tempActivityUrl,
                        materialPictogramUrls: tempMaterialUrls,
                      );
                      _saveToHistory();
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _loadProject(ProjectData project) async {
    final pageCount = project.pages.length;
    final templates = List<TemplateType>.generate(
      pageCount,
      (index) => index < project.templates.length
          ? project.templates[index]
          : TemplateType.blank,
    );
    final backgrounds = List<Color>.generate(
      pageCount,
      (index) => index < project.backgrounds.length
          ? project.backgrounds[index]
          : Colors.white,
    );
    final orientations = List<bool>.generate(
      pageCount,
      (index) => index < project.orientations.length
          ? project.orientations[index]
          : false,
    );
    final pageTitles = List<String>.generate(
      pageCount,
      (index) => index < project.pageTitles.length
          ? project.pageTitles[index]
          : '',
    );
    final pageInstructions = List<String>.generate(
      pageCount,
      (index) => index < project.pageInstructions.length
          ? project.pageInstructions[index]
          : '',
    );

    setState(() {
      _pages = project.pages
          .map((page) => page.map((img) => img.copyWith()).toList())
          .toList();
      _pageTemplates = templates;
      _pageBackgrounds = backgrounds;
      _pageOrientations = orientations;
      _pageTitles = pageTitles;
      _pageInstructions = pageInstructions;
      _documentFooterController.text = project.documentFooter ?? '';
      _headerScope = project.headerScope;
      _footerScope = project.footerScope;
      _showPageNumbers = project.showPageNumbers;
      _logoPath = project.logoPath;
      _logoPosition = project.logoPosition;
      _logoSize = project.logoSize;
      _currentPage = 0;
      _selectedImageIds.clear();
      _history
        ..clear()
        ..add([]);
      _historyIndex = 0;
      _activeProjectId = project.id;
      _projectName = project.name; // Guardar nombre del proyecto

      // Sincronizar los controllers con la primera página
      _syncControllersWithCurrentPage();
    });
    await _saveUserLogoPreference();
    _saveToHistory();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Proyecto "${project.name}" cargado')),
      );
    }
  }

  void _logout() {
    _userService.logout();
    setState(() {
      _currentUser = null;
      _activeProjectId = null;
    });
  }

  // Guardar el estado actual en el historial
  void _saveToHistory() {
    // Copiar el estado actual de todas las páginas
    final currentState = _pages
        .map((page) => page.map((img) => img.copyWith()).toList())
        .toList();

    // Si no estamos al final del historial, eliminar los estados futuros
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }

    // Añadir el nuevo estado
    _history.add(currentState);
    _historyIndex = _history.length - 1;

    // Limitar el historial a 50 estados
    if (_history.length > 50) {
      _history.removeAt(0);
      _historyIndex--;
    }
  }

  // Deshacer
  void _undo() {
    if (_historyIndex > 0) {
      setState(() {
        _historyIndex--;
        _pages = _history[_historyIndex]
            .map((page) => page.map((img) => img.copyWith()).toList())
            .toList();
      });
    }
  }

  // Rehacer
  void _redo() {
    if (_historyIndex < _history.length - 1) {
      setState(() {
        _historyIndex++;
        _pages = _history[_historyIndex]
            .map((page) => page.map((img) => img.copyWith()).toList())
            .toList();
      });
    }
  }

  // Limpiar el canvas de la página actual
  void _clearCanvas() {
    _saveToHistory();
    setState(() {
      _pages[_currentPage].clear();
    });
  }

  void _searchPictograms(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final results = await _arasaacService.searchPictograms(query);

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  void _searchSoyVisual(String query) async {
    debugPrint('_searchSoyVisual called with query: "$query"');

    if (query.isEmpty) {
      setState(() {
        _soyVisualResults = [];
        _isSoyVisualSearching = false;
        _lastSoyVisualQuery = '';
        _lastSoyVisualCategory = _soyVisualCategory;
      });
      return;
    }

    // Evitar búsquedas duplicadas
    if (query == _lastSoyVisualQuery &&
        _soyVisualCategory == _lastSoyVisualCategory) {
      debugPrint('Query is same as last query, skipping');
      return;
    }

    setState(() {
      _isSoyVisualSearching = true;
      _lastSoyVisualQuery = query;
      _lastSoyVisualCategory = _soyVisualCategory;
    });

    debugPrint('Starting SoyVisual search...');
    final results = await _soyVisualService.search(
      query,
      category: _soyVisualCategory,
    );
    debugPrint('SoyVisual search completed. Results: ${results.length}');

    setState(() {
      _soyVisualResults = results;
      _isSoyVisualSearching = false;
    });
  }

  void _addImageToCanvas(String imageUrl, {bool fullSize = false}) {
    final isLandscape = _pageOrientations[_currentPage];
    final baseWidth = isLandscape ? _a4HeightPts : _a4WidthPts;
    final double targetWidth = fullSize
        ? (baseWidth - 40).clamp(100, baseWidth).toDouble()
        : 150;
    final Offset initialPosition = fullSize
        ? const Offset(20, 20)
        : const Offset(50, 50);

    setState(() {
      final element = CanvasImage.networkImage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imageUrl: imageUrl,
        position: initialPosition,
        scale: 1.0,
        width: targetWidth,
        height: null, // dejar altura para que respete el aspecto real
      );
      _pages[_currentPage].add(element);
    });
  }

  void _addPictogramCard(String imageUrl, String text) {
    setState(() {
      _pages[_currentPage].add(
        CanvasImage.pictogramCard(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          imageUrl: imageUrl,
          text: text,
          position: const Offset(100, 100),
          scale: 1.0,
        ),
      );
    });
  }

  void _generateShadowMatchingActivity() {
    final images = _canvasImages
        .where(
          (element) =>
              element.type == CanvasElementType.networkImage ||
              element.type == CanvasElementType.localImage ||
              element.type == CanvasElementType.pictogramCard,
        )
        .toList();

    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos una imagen primero')),
      );
      return;
    }

    int selected = 6;
    showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Configurar Sombras'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Sombras por página'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [4, 6, 8, 10]
                        .map(
                          (n) => ChoiceChip(
                            label: Text('$n'),
                            selected: selected == n,
                            onSelected: (_) => setState(() => selected = n),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(selected),
                  child: const Text('Generar'),
                ),
              ],
            );
          },
        );
      },
    ).then((pairsPerPage) {
      if (pairsPerPage == null) return;

      final result = generateShadowMatchingActivity(
        images: images,
        isLandscape: _pageOrientations[_currentPage],
        a4WidthPts: _a4WidthPts,
        a4HeightPts: _a4HeightPts,
        pairsPerPage: pairsPerPage,
      );

      if (result.pages.isEmpty || result.pages.first.isEmpty) return;

      while (_pages.length < _currentPage + result.pages.length) {
        _pages.add([]);
        _pageOrientations.add(_pageOrientations[_currentPage]);
        _pageTemplates.add(TemplateType.blank);
        _pageBackgrounds.add(Colors.white);
      }

      setState(() {
        for (int i = 0; i < result.pages.length; i++) {
          final pageIndex = _currentPage + i;
          _pages[pageIndex].clear();
          _pages[pageIndex].addAll(result.pages[i]);
          if (i == 0) {
            _addPendingVisualInstructions(pageIndex);
          }

          // Añadir instrucciones visuales en la primera página si hay pendientes
          if (i == 0) {
            _addPendingVisualInstructions(pageIndex);
          }

          _pageTemplates[pageIndex] = TemplateType.blank;
          _pageOrientations[pageIndex] = _pageOrientations[_currentPage];
        }

        // Aplicar título e instrucciones desde backend o valores por defecto
        _applyTitleAndInstructions(
          'shadow_matching',
          defaultTitle: result.title,
          defaultInstructions: result.instructions,
        );
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    });
  }

  Future<void> _generateActivityPack() async {
    final images = _canvasImages
        .where(
          (element) =>
              element.type == CanvasElementType.networkImage ||
              element.type == CanvasElementType.localImage ||
              element.type == CanvasElementType.pictogramCard,
        )
        .toList();

    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos una imagen primero')),
      );
      return;
    }

    final config = await showDialog<ActivityPackConfig>(
      context: context,
      builder: (context) => const ActivityPackConfigDialog(),
    );

    if (config == null) return;
    if (!mounted) return;

    // Mostrar diálogo de progreso inicial
    ActivityPackProgressDialog.show(
      context: context,
      title: config.title,
      currentActivity: 0,
      totalActivities: config.selectedActivities.length,
      currentActivityName: 'Iniciando...',
    );

    try {
      final result = await ActivityPackGenerator.generatePack(
        canvasImages: images,
        config: config,
        isLandscape: _pageOrientations[_currentPage],
        a4WidthPts: _a4WidthPts,
        a4HeightPts: _a4HeightPts,
        onProgress: (current, total, activityName) {
          if (!mounted) return;
          // Actualizar el diálogo de progreso
          ActivityPackProgressDialog.update(
            context: context,
            title: config.title,
            currentActivity: current,
            totalActivities: total,
            currentActivityName: activityName,
          );
        },
      );

      if (!mounted) return;

      // Cerrar diálogo de progreso
      ActivityPackProgressDialog.dismiss(context);

      if (result.pages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo generar ninguna actividad')),
        );
        return;
      }

      while (_pages.length < _currentPage + result.pages.length) {
        _pages.add([]);
        _pageOrientations.add(_pageOrientations[_currentPage]);
        _pageTemplates.add(TemplateType.blank);
        _pageBackgrounds.add(Colors.white);
      }

      setState(() {
        for (int i = 0; i < result.pages.length; i++) {
          final pageIndex = _currentPage + i;
          _pages[pageIndex].clear();
          _pages[pageIndex].addAll(result.pages[i]);
          if (i == 0) {
            _addPendingVisualInstructions(pageIndex);
          }
          _pageTemplates[pageIndex] = TemplateType.blank;
          _pageOrientations[pageIndex] = _pageOrientations[_currentPage];
        }
        // ActivityPack: cada página tiene su propio título e instrucciones
        // Por ahora, usar el título de la primera página
        if (result.pagesWithMetadata.isNotEmpty) {
          _headerController.text = result.pagesWithMetadata.first.title;
          _footerController.text = result.pagesWithMetadata.first.instructions;
        }
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    } catch (e) {
      if (!mounted) return;

      // Cerrar diálogo de progreso en caso de error
      ActivityPackProgressDialog.dismiss(context);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al generar el pack: $e')));
    }
  }

  Future<void> _generatePuzzleActivity() async {
    // Usar solo las imágenes de la página actual
    final images = _pages[_currentPage]
        .where(
          (element) =>
              element.type == CanvasElementType.networkImage ||
              element.type == CanvasElementType.localImage ||
              element.type == CanvasElementType.pictogramCard,
        )
        .toList();

    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Añade al menos una imagen en esta página primero'),
        ),
      );
      return;
    }

    // Preguntar número de piezas
    final gridSize = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Configurar Puzzle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Selecciona el número de piezas:'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int size in [2, 3, 4, 5, 6])
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(size),
                      child: Text('${size}x$size (${size * size} piezas)'),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );

    if (gridSize == null) return;

    final result = generatePuzzleActivity(
      images: images,
      isLandscape: _pageOrientations[_currentPage],
      a4WidthPts: _a4WidthPts,
      a4HeightPts: _a4HeightPts,
      gridSize: gridSize,
    );

    if (result.referencePage.isEmpty && result.piecesPage.isEmpty) return;

    // Asegurar que hay espacio para la página actual y la siguiente
    final nextPage = _currentPage + 1;
    while (_pages.length <= nextPage) {
      _pages.add([]);
      _pageOrientations.add(_pageOrientations[_currentPage]);
      _pageTemplates.add(TemplateType.blank);
      _pageBackgrounds.add(Colors.white);
    }

    setState(() {
      // Página actual: Imagen de referencia en sombra
      _pages[_currentPage].clear();
      _pages[_currentPage].addAll(result.referencePage);
      _addPendingVisualInstructions(_currentPage);

      // Página siguiente: Piezas recortables
      _pages[nextPage].clear();
      _pages[nextPage].addAll(result.piecesPage);

      // Aplicar título e instrucciones desde backend o valores por defecto
      _applyTitleAndInstructions(
        'puzzle',
        defaultTitle: result.title,
        defaultInstructions: result.instructions,
      );
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Puzle ${gridSize}x$gridSize generado (2 páginas)'),
        ),
      );
    }
  }

  Future<void> _generateWritingPracticeActivity() async {
    final images = _canvasImages
        .where(
          (element) =>
              element.type == CanvasElementType.networkImage ||
              element.type == CanvasElementType.localImage ||
              element.type == CanvasElementType.pictogramCard,
        )
        .toList();

    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos una imagen primero')),
      );
      return;
    }

    int selectedItems = 6;
    bool showModel = false;
    String fontFamily = 'ColeCarreira';
    bool uppercase = true;

    final config = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Configurar Práctica de Escritura'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dibujos/repeticiones por página'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [4, 6, 8, 10]
                          .map(
                            (n) => ChoiceChip(
                              label: Text('$n'),
                              selected: selectedItems == n,
                              onSelected: (_) =>
                                  setState(() => selectedItems = n),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      value: showModel,
                      onChanged: (v) => setState(() => showModel = v ?? false),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Mostrar modelo de palabra (si la hay)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Tipo de letra'),
                    DropdownButton<String>(
                      value: fontFamily,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'ColeCarreira',
                          child: Text(
                            'Cole Carreira',
                            style: TextStyle(fontFamily: 'ColeCarreira'),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'EscolarG',
                          child: Text(
                            'Escolar G',
                            style: TextStyle(fontFamily: 'EscolarG'),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'EscolarP',
                          child: Text(
                            'Escolar P',
                            style: TextStyle(fontFamily: 'EscolarP'),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Trace',
                          child: Text(
                            'Trace',
                            style: TextStyle(fontFamily: 'Trace'),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Massallera',
                          child: Text(
                            'Massallera',
                            style: TextStyle(fontFamily: 'Massallera'),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Roboto',
                          child: Text(
                            'Roboto (Normal)',
                            style: TextStyle(fontFamily: 'Roboto'),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => fontFamily = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Formato de texto'),
                    RadioListTile<bool>(
                      title: const Text('MAYÚSCULAS'),
                      value: true,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      groupValue: uppercase,
                      onChanged: (v) {
                        if (v != null) setState(() => uppercase = v);
                      },
                    ),
                    RadioListTile<bool>(
                      title: const Text('minúsculas'),
                      value: false,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      groupValue: uppercase,
                      onChanged: (v) {
                        if (v != null) setState(() => uppercase = v);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop({
                    'items': selectedItems,
                    'showModel': showModel,
                    'fontFamily': fontFamily,
                    'uppercase': uppercase,
                  }),
                  child: const Text('Generar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (config == null) return;

    final result = await generateWritingPracticeActivity(
      images: images,
      isLandscape: _pageOrientations[_currentPage],
      a4WidthPts: _a4WidthPts,
      a4HeightPts: _a4HeightPts,
      itemsPerPage: config['items'] as int,
      showModel: config['showModel'] as bool,
      fontFamily: config['fontFamily'] as String,
      uppercase: config['uppercase'] as bool,
    );

    if (result.pages.isEmpty || result.pages.first.isEmpty) return;

    while (_pages.length < _currentPage + result.pages.length) {
      _pages.add([]);
      _pageOrientations.add(_pageOrientations[_currentPage]);
      _pageTemplates.add(TemplateType.blank);
      _pageBackgrounds.add(Colors.white);
    }

    setState(() {
      for (int i = 0; i < result.pages.length; i++) {
        final pageIndex = _currentPage + i;
        _pages[pageIndex].clear();
        _pages[pageIndex].addAll(result.pages[i]);
        if (i == 0) {
          _addPendingVisualInstructions(pageIndex);
        }
        _pageTemplates[pageIndex] = TemplateType.writingPractice;
        _pageOrientations[pageIndex] = _pageOrientations[_currentPage];
      }
      // Aplicar título e instrucciones desde backend o valores por defecto
      _applyTitleAndInstructions(
        'writing_practice',
        defaultTitle: result.title,
        defaultInstructions: result.instructions,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? 'Actividad generada')),
    );
  }

  void _generateCountingActivity() {
    final images = _canvasImages
        .where(
          (element) =>
              element.type == CanvasElementType.networkImage ||
              element.type == CanvasElementType.localImage ||
              element.type == CanvasElementType.pictogramCard,
        )
        .toList();

    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos una imagen primero')),
      );
      return;
    }

    int selectedBoxes = 6;
    RangeValues selectedRange = const RangeValues(1, 20);

    showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Configurar Práctica de Conteo'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Cajas por página'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [2, 4, 6, 8]
                        .map(
                          (n) => ChoiceChip(
                            label: Text('$n'),
                            selected: selectedBoxes == n,
                            onSelected: (_) =>
                                setState(() => selectedBoxes = n),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text('Rango de cantidades'),
                  RangeSlider(
                    values: selectedRange,
                    min: 1,
                    max: 20,
                    divisions: 19,
                    labels: RangeLabels(
                      selectedRange.start.round().toString(),
                      selectedRange.end.round().toString(),
                    ),
                    onChanged: (values) {
                      if (values.end - values.start >= 1) {
                        setState(() => selectedRange = values);
                      }
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Mín: ${selectedRange.start.round()}'),
                      Text('Máx: ${selectedRange.end.round()}'),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(selectedBoxes),
                  child: const Text('Generar'),
                ),
              ],
            );
          },
        );
      },
    ).then((boxesPerPage) {
      if (boxesPerPage == null) return;

      final result = generateCountingActivity(
        images: images,
        isLandscape: _pageOrientations[_currentPage],
        a4WidthPts: _a4WidthPts,
        a4HeightPts: _a4HeightPts,
        boxesPerPage: boxesPerPage,
        minCount: selectedRange.start.round(),
        maxCount: selectedRange.end.round(),
      );

      if (result.pages.isEmpty || result.pages.first.isEmpty) return;

      while (_pages.length < _currentPage + result.pages.length) {
        _pages.add([]);
        _pageOrientations.add(_pageOrientations[_currentPage]);
        _pageTemplates.add(TemplateType.blank);
        _pageBackgrounds.add(Colors.white);
      }

      setState(() {
        for (int i = 0; i < result.pages.length; i++) {
          final pageIndex = _currentPage + i;
          _pages[pageIndex].clear();
          _pages[pageIndex].addAll(result.pages[i]);
          if (i == 0) {
            _addPendingVisualInstructions(pageIndex);
          }
          _pageTemplates[pageIndex] = TemplateType.countingPractice;
          _pageOrientations[pageIndex] = _pageOrientations[_currentPage];
        }
      // Aplicar título e instrucciones desde backend o valores por defecto
      _applyTitleAndInstructions(
        'counting_practice',
        defaultTitle: result.title,
        defaultInstructions: result.instructions,
      );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Actividad generada')),
      );
    });
  }

  Future<void> _generatePhonologicalAwarenessActivity() async {
    final images = _pages[_currentPage]
        .where(
          (element) =>
              element.type == CanvasElementType.networkImage ||
              element.type == CanvasElementType.localImage ||
              element.type == CanvasElementType.pictogramCard,
        )
        .toList();

    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Añade al menos una imagen de ARASAAC primero'),
        ),
      );
      return;
    }

    // Mostrar diálogo de configuración
    final config = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _PhonologicalAwarenessConfigDialog(),
    );

    if (config == null) return; // Usuario canceló

    // Mostrar indicador de carga
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generando actividad de conciencia fonológica...'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    debugPrint('DEBUG main.dart: _projectName = "$_projectName"');

    final result = await generatePhonologicalAwarenessActivity(
      images: images,
      isLandscape: _pageOrientations[_currentPage],
      a4WidthPts: _a4WidthPts,
      a4HeightPts: _a4HeightPts,
      fontFamily: config['fontFamily'] as String,
      uppercase: config['uppercase'] as bool,
      imagesPerPage: 8,
      showWord: true,
      showSyllables: true,
      showLetters: false,
      projectName: _projectName, // Pasar nombre del proyecto
    );

    if (result.pages.isEmpty || result.pages.first.isEmpty) return;

    // Asegurar que hay suficientes páginas
    while (_pages.length < _currentPage + result.pages.length) {
      _pages.add([]);
      _pageOrientations.add(_pageOrientations[_currentPage]);
      _pageTemplates.add(TemplateType.blank);
      _pageBackgrounds.add(Colors.white);
    }

    setState(() {
      // Reemplazar páginas con el resultado
      for (int i = 0; i < result.pages.length; i++) {
        final pageIndex = _currentPage + i;
        _pages[pageIndex].clear();
        _pages[pageIndex].addAll(result.pages[i]);
          if (i == 0) {
            _addPendingVisualInstructions(pageIndex);
          }
      }
      // Aplicar título e instrucciones desde backend o valores por defecto
      _applyTitleAndInstructions(
        'phonological_awareness',
        defaultTitle: result.title,
        defaultInstructions: result.instructions,
      );
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  Future<void> _generatePhonologicalBoardActivity() async {
    final images = _pages[_currentPage]
        .where(
          (element) =>
              element.type == CanvasElementType.networkImage ||
              element.type == CanvasElementType.localImage ||
              element.type == CanvasElementType.pictogramCard,
        )
        .toList();

    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Añade al menos una imagen de ARASAAC primero'),
        ),
      );
      return;
    }

    final config = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _PhonologicalAwarenessConfigDialog(),
    );

    if (config == null) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generando tablero fonológico...'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    final result = await generatePhonologicalBoardActivity(
      images: images,
      isLandscape: _pageOrientations[_currentPage],
      a4WidthPts: _a4WidthPts,
      a4HeightPts: _a4HeightPts,
      fontFamily: config['fontFamily'] as String,
      uppercase: config['uppercase'] as bool,
    );

    if (result.pages.isEmpty || result.pages.first.isEmpty) return;

    while (_pages.length < _currentPage + result.pages.length) {
      _pages.add([]);
      _pageOrientations.add(_pageOrientations[_currentPage]);
      _pageTemplates.add(TemplateType.blank);
      _pageBackgrounds.add(Colors.white);
    }

    setState(() {
      for (int i = 0; i < result.pages.length; i++) {
        final pageIndex = _currentPage + i;
        _pages[pageIndex].clear();
        _pages[pageIndex].addAll(result.pages[i]);
          if (i == 0) {
            _addPendingVisualInstructions(pageIndex);
          }
      }
      // Aplicar título e instrucciones desde backend o valores por defecto
      _applyTitleAndInstructions(
        'phonological_board',
        defaultTitle: result.title,
        defaultInstructions: result.instructions,
      );
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  void _generateSeriesActivity() {
    final images = _canvasImages
        .where(
          (element) =>
              element.type == CanvasElementType.networkImage ||
              element.type == CanvasElementType.localImage ||
              element.type == CanvasElementType.pictogramCard,
        )
        .toList();

    if (images.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos dos imágenes primero')),
      );
      return;
    }

    final result = series_activity.generateSeriesActivity(
      images: images,
      isLandscape: _pageOrientations[_currentPage],
      a4WidthPts: _a4WidthPts,
      a4HeightPts: _a4HeightPts,
    );

    if (result.pages.isEmpty || result.pages.first.isEmpty) return;

    while (_pages.length < _currentPage + result.pages.length) {
      _pages.add([]);
      _pageOrientations.add(_pageOrientations[_currentPage]);
      _pageTemplates.add(TemplateType.blank);
      _pageBackgrounds.add(Colors.white);
    }

    setState(() {
      for (int i = 0; i < result.pages.length; i++) {
        final pageIndex = _currentPage + i;
        _pages[pageIndex].clear();
        _pages[pageIndex].addAll(result.pages[i]);
          if (i == 0) {
            _addPendingVisualInstructions(pageIndex);
          }
        _pageTemplates[pageIndex] = TemplateType.blank;
        _pageOrientations[pageIndex] = _pageOrientations[_currentPage];
      }
      // Aplicar título e instrucciones desde backend o valores por defecto
      _applyTitleAndInstructions(
        'series',
        defaultTitle: result.title,
        defaultInstructions: result.instructions,
      );
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _generatePhrasesActivity() async {
    final images = _canvasImages
        .where(
          (element) =>
              element.type == CanvasElementType.networkImage ||
              element.type == CanvasElementType.localImage ||
              element.type == CanvasElementType.pictogramCard,
        )
        .toList();

    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos una imagen primero')),
      );
      return;
    }

    final controller = TextEditingController();
    final phrase = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Frase'),
        scrollable: true,
        content: SingleChildScrollView(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Escribe la frase',
              hintText: 'Ej: El niño juega en el parque',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            maxLines: null,
            minLines: 2,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Generar'),
          ),
        ],
      ),
    );

    if (phrase == null || phrase.isEmpty) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Buscando pictogramas...')));

    try {
      final result = await phrases_activity.generatePhrasesActivity(
        images: images,
        phrase: phrase,
        arasaacService: _arasaacService,
        isLandscape: _pageOrientations[_currentPage],
        a4WidthPts: _a4WidthPts,
        a4HeightPts: _a4HeightPts,
      );

      if (result.elements.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo generar la actividad')),
        );
        return;
      }

      setState(() {
        _pages[_currentPage].clear();
        _pages[_currentPage].addAll(result.elements);
        _addPendingVisualInstructions(_currentPage);
      // Aplicar título e instrucciones desde backend o valores por defecto
      _applyTitleAndInstructions(
        'phrases',
        defaultTitle: result.title,
        defaultInstructions: result.instructions,
      );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Actividad generada')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al generar la actividad')),
      );
    }
  }

  Future<void> _generateCardActivity() async {
    final images = _canvasImages
        .where(
          (element) =>
              element.type == CanvasElementType.networkImage ||
              element.type == CanvasElementType.localImage ||
              element.type == CanvasElementType.pictogramCard,
        )
        .toList();

    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos una imagen primero')),
      );
      return;
    }

    final config = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        card_activity.CardLayout layout = card_activity.CardLayout.imageLeft;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Generar tarjeta'),
              scrollable: true,
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Diseño de tarjeta',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    RadioListTile<card_activity.CardLayout>(
                      title: const Text('Imagen arriba, título y texto debajo'),
                      value: card_activity.CardLayout.imageTop,
                      groupValue: layout,
                      onChanged: (v) {
                        if (v != null) setState(() => layout = v);
                      },
                      dense: true,
                    ),
                    RadioListTile<card_activity.CardLayout>(
                      title: const Text(
                        'Imagen a la izquierda, texto a la derecha',
                      ),
                      value: card_activity.CardLayout.imageLeft,
                      groupValue: layout,
                      onChanged: (v) {
                        if (v != null) setState(() => layout = v);
                      },
                      dense: true,
                    ),
                    RadioListTile<card_activity.CardLayout>(
                      title: const Text(
                        'Imagen a la derecha, texto a la izquierda',
                      ),
                      value: card_activity.CardLayout.imageRight,
                      groupValue: layout,
                      onChanged: (v) {
                        if (v != null) setState(() => layout = v);
                      },
                      dense: true,
                    ),
                    RadioListTile<card_activity.CardLayout>(
                      title: const Text('Título y texto arriba, imagen abajo'),
                      value: card_activity.CardLayout.textThenImage,
                      groupValue: layout,
                      onChanged: (v) {
                        if (v != null) setState(() => layout = v);
                      },
                      dense: true,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pop({'layout': layout}),
                  child: const Text('Generar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (config == null) return;

    final result = await card_activity.generateCardActivity(
      images: images,
      isLandscape: _pageOrientations[_currentPage],
      a4WidthPts: _a4WidthPts,
      a4HeightPts: _a4HeightPts,
      layout: config['layout'] as card_activity.CardLayout,
    );

    if (result.pages.isEmpty || result.pages.first.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo generar la tarjeta')),
      );
      return;
    }

    while (_pages.length < _currentPage + result.pages.length) {
      _pages.add([]);
      _pageOrientations.add(_pageOrientations[_currentPage]);
      _pageTemplates.add(TemplateType.blank);
      _pageBackgrounds.add(Colors.white);
    }

    setState(() {
      for (int i = 0; i < result.pages.length; i++) {
        final pageIndex = _currentPage + i;
        _pages[pageIndex].clear();
        _pages[pageIndex].addAll(result.pages[i]);
          if (i == 0) {
            _addPendingVisualInstructions(pageIndex);
          }
        _pageTemplates[pageIndex] = TemplateType.blank;
        _pageOrientations[pageIndex] = _pageOrientations[_currentPage];
      }
      // Aplicar título e instrucciones desde backend o valores por defecto
      _applyTitleAndInstructions(
        'card',
        defaultTitle: result.title,
        defaultInstructions: result.instructions,
      );
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  void _generateSymmetryActivity() {
    final images = _canvasImages
        .where(
          (element) =>
              element.type == CanvasElementType.networkImage ||
              element.type == CanvasElementType.localImage ||
              element.type == CanvasElementType.pictogramCard,
        )
        .toList();

    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos una imagen primero')),
      );
      return;
    }

    final result = symmetry_activity.generateSymmetryActivity(
      images: images,
      isLandscape: _pageOrientations[_currentPage],
      a4WidthPts: _a4WidthPts,
      a4HeightPts: _a4HeightPts,
    );

    if (result.pages.isEmpty || result.pages.first.isEmpty) return;

    while (_pages.length < _currentPage + result.pages.length) {
      _pages.add([]);
      _pageOrientations.add(_pageOrientations[_currentPage]);
      _pageTemplates.add(TemplateType.blank);
      _pageBackgrounds.add(Colors.white);
    }

    setState(() {
      for (int i = 0; i < result.pages.length; i++) {
        final pageIndex = _currentPage + i;
        _pages[pageIndex].clear();
        _pages[pageIndex].addAll(result.pages[i]);
          if (i == 0) {
            _addPendingVisualInstructions(pageIndex);
          }
        _pageTemplates[pageIndex] = TemplateType.blank;
        _pageOrientations[pageIndex] = _pageOrientations[_currentPage];
      }
      // Aplicar título e instrucciones desde backend o valores por defecto
      _applyTitleAndInstructions(
        'symmetry',
        defaultTitle: result.title,
        defaultInstructions: result.instructions,
      );
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _generateClassificationActivity() async {
    final images = _canvasImages
        .where(
          (element) =>
              element.type == CanvasElementType.networkImage ||
              element.type == CanvasElementType.pictogramCard,
        )
        .toList();

    if (images.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Añade al menos 2 imágenes ARASAAC primero'),
        ),
      );
      return;
    }

    // Tomar las dos primeras imágenes como categorías
    final categoryImages = images.take(2).toList();

    // Mostrar indicador de carga
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Buscando imágenes relacionadas...')),
    );

    try {
      // Buscar 10 imágenes relacionadas por campo semántico
      final List<String> relatedUrls = [];

      for (final catImg in categoryImages) {
        // Extraer el ID del pictograma de la URL
        final url = catImg.imageUrl!;
        print('DEBUG: URL completa: $url');

        // Buscar /pictograms/NÚMERO con o sin extensión
        final match = RegExp(r'/pictograms/(\d+)').firstMatch(url);
        if (match != null) {
          final pictogramId = match.group(1)!;
          print('DEBUG: ID extraído: $pictogramId');

          // Buscar imágenes relacionadas (10 por cada categoría)
          final results = await _arasaacService.searchRelatedPictograms(
            int.parse(pictogramId),
          );

          print('DEBUG: Imágenes relacionadas encontradas: ${results.length}');

          // Tomar las primeras 10 URLs de cada categoría
          relatedUrls.addAll(results.take(10).map((p) => p.imageUrl));
        } else {
          print('DEBUG: No se pudo extraer ID de la URL');
        }
      }

      if (relatedUrls.length < 20) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se encontraron suficientes imágenes relacionadas (${relatedUrls.length}/20)',
            ),
          ),
        );
        return;
      }

      final result = generateClassificationActivity(
        categoryImages: categoryImages,
        relatedImageUrls: relatedUrls.take(20).toList(),
        isLandscape: _pageOrientations[_currentPage],
        a4WidthPts: _a4WidthPts,
        a4HeightPts: _a4HeightPts,
      );

      print(
        'DEBUG: Elementos en categoriesPage: ${result.categoriesPage.length}',
      );
      print('DEBUG: Elementos en objectsPage: ${result.objectsPage.length}');

      print('DEBUG ANTES DE SETSTATE: _pages.length = ${_pages.length}');

      setState(() {
        print('DEBUG DENTRO DE SETSTATE: Preparando páginas...');

        // Asegurar que existan al menos 2 páginas con todas las listas sincronizadas
        while (_pages.length < 2) {
          _pages.add([]);
          _pageOrientations.add(false);
          _pageTemplates.add(TemplateType.blank);
          _pageBackgrounds.add(Colors.white);
          print('DEBUG: Añadiendo página vacía. Total: ${_pages.length}');
        }

        // Limpiar el contenido de las páginas existentes
        _pages[0].clear();
        _pages[1].clear();

        // Llenar página 1: Categorías
        _pages[0].addAll(result.categoriesPage);
        _pageOrientations[0] = false;
        _pageTemplates[0] = TemplateType.blank;
        print('DEBUG: Página 0 llenada con ${_pages[0].length} elementos');

        // Llenar página 2: Objetos recortables
        _pages[1].addAll(result.objectsPage);
        _pageOrientations[1] = false;
        _pageTemplates[1] = TemplateType.blank;
        print('DEBUG: Página 1 llenada con ${_pages[1].length} elementos');

        print('DEBUG: Total páginas: ${_pages.length}');
        print('DEBUG: Elementos en página 0: ${_pages[0].length}');
        print('DEBUG: Elementos en página 1: ${_pages[1].length}');

        _currentPage = 0;
      });

      print('DEBUG DESPUÉS DE SETSTATE: _pages.length = ${_pages.length}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Actividad de clasificación generada (2 páginas)'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al generar actividad: $e')));
    }
  }

  Future<void> _generatePhonologicalSquaresActivity() async {
    final images = _canvasImages
        .where(
          (element) =>
              element.type == CanvasElementType.networkImage ||
              element.type == CanvasElementType.pictogramCard,
        )
        .toList();

    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos una imagen al canvas')),
      );
      return;
    }

    try {
      final result = await phonological_squares_activity
          .generatePhonologicalSquaresActivity(
            images: images,
            isLandscape: _pageOrientations[_currentPage],
            a4WidthPts: _a4WidthPts,
            a4HeightPts: _a4HeightPts,
          );

      setState(() {
        _pages[_currentPage].clear();
        _pages[_currentPage].addAll(result.pages[0]);
        _addPendingVisualInstructions(_currentPage);
        _addPendingVisualInstructions(_currentPage);
      // Aplicar título e instrucciones desde backend o valores por defecto
      _applyTitleAndInstructions(
        'phonological_squares',
        defaultTitle: result.title,
        defaultInstructions: result.instructions,
      );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Actividad de Cuadrados Fonológicos generada'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _generateCrosswordActivity() async {
    final images = _canvasImages
        .where(
          (element) =>
              element.type == CanvasElementType.networkImage ||
              element.type == CanvasElementType.pictogramCard,
        )
        .toList();

    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos una imagen al canvas')),
      );
      return;
    }

    try {
      final result = await crossword_activity.generateCrosswordActivity(
        images: images,
        isLandscape: _pageOrientations[_currentPage],
        a4WidthPts: _a4WidthPts,
        a4HeightPts: _a4HeightPts,
      );

      setState(() {
        _pages[_currentPage].clear();
        _pages[_currentPage].addAll(result.pages[0]);
        _addPendingVisualInstructions(_currentPage);
      // Aplicar título e instrucciones desde backend o valores por defecto
      _applyTitleAndInstructions(
        'crossword',
        defaultTitle: result.title,
        defaultInstructions: result.instructions,
      );
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Crucigrama generado')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _generateWordSearchActivity() async {
    final images = _canvasImages
        .where(
          (element) =>
              element.type == CanvasElementType.networkImage ||
              element.type == CanvasElementType.pictogramCard,
        )
        .toList();

    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos una imagen al canvas')),
      );
      return;
    }

    try {
      final result = await word_search_activity.generateWordSearchActivity(
        images: images,
        isLandscape: _pageOrientations[_currentPage],
        a4WidthPts: _a4WidthPts,
        a4HeightPts: _a4HeightPts,
      );

      setState(() {
        _pages[_currentPage].clear();
        _pages[_currentPage].addAll(result.pages[0]);
        _addPendingVisualInstructions(_currentPage);
      // Aplicar título e instrucciones desde backend o valores por defecto
      _applyTitleAndInstructions(
        'word_search',
        defaultTitle: result.title,
        defaultInstructions: result.instructions,
      );
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sopa de letras generada')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _generateSentenceCompletionActivity() async {
    final images = _canvasImages
        .where(
          (element) =>
              element.type == CanvasElementType.networkImage ||
              element.type == CanvasElementType.pictogramCard,
        )
        .toList();

    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos una imagen al canvas')),
      );
      return;
    }

    // Mostrar configuración
    final config =
        await showDialog<sentence_completion_activity.SentenceCompletionConfig>(
          context: context,
          builder: (context) =>
              const sentence_completion_activity.SentenceCompletionConfigDialog(),
        );

    if (config == null) return;

    try {
      final result = await sentence_completion_activity
          .generateSentenceCompletionActivity(
            config: config,
            isLandscape: _pageOrientations[_currentPage],
            a4WidthPts: _a4WidthPts,
            a4HeightPts: _a4HeightPts,
          );

      if (result.pages.length > _pages.length) {
        setState(() {
          while (_pages.length < result.pages.length) {
            _pages.add([]);
            _pageOrientations.add(_pageOrientations[_currentPage]);
            _pageBackgrounds.add(_pageBackgrounds[_currentPage]);
            _pageTemplates.add(TemplateType.blank);
          }
        });
      }

      setState(() {
        for (var i = 0; i < result.pages.length; i++) {
          if (i < _pages.length) {
            _pages[i].clear();
            _pages[i].addAll(result.pages[i]);
          }
        }
        _currentPage = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Actividad generada con ${result.pages.length} páginas',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _generateSyllableVocabularyActivity() async {
    // Mostrar diálogo para ingresar la sílaba
    final config = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _SyllableVocabularyConfigDialog(),
    );

    if (config == null) return;

    final syllable = config['syllable'] as String;
    final position = config['position'] as String;
    final numWords = config['numWords'] as int;
    final usePictograms = config['usePictograms'] as bool;

    // Mostrar indicador de carga
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Buscando palabras en ARASAAC...')),
    );

    try {
      final result = await syllable_activity.generateSyllableVocabularyActivity(
        syllable: syllable,
        arasaacService: _arasaacService,
        isLandscape: _pageOrientations[_currentPage],
        a4WidthPts: _a4WidthPts,
        a4HeightPts: _a4HeightPts,
        syllablePosition: position,
        maxWords: numWords,
        usePictograms: usePictograms,
      );

      if (result.pages.isEmpty ||
          (result.pages.isNotEmpty && result.pages[0].isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se encontraron palabras para la sílaba "$syllable"',
            ),
          ),
        );
        return;
      }

      setState(() {
        _pages[_currentPage].clear();
        _pages[_currentPage].addAll(result.pages[0]);
        _addPendingVisualInstructions(_currentPage);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ??
                'Actividad de vocabulario generada con ${result.pages[0].length} palabras',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al generar la actividad')),
      );
    }
  }

  Future<void> _generateSemanticFieldActivity() async {
    final images = _canvasImages
        .where(
          (element) =>
              element.type == CanvasElementType.networkImage ||
              element.type == CanvasElementType.pictogramCard,
        )
        .toList();

    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Añade al menos una imagen con texto primero'),
        ),
      );
      return;
    }

    // Mostrar diálogo de configuración
    final config = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _SemanticFieldConfigDialog(),
    );

    if (config == null) return; // Usuario canceló

    final numImages = config['numImages'] as int;
    final usePictograms = config['usePictograms'] as bool;

    // Mostrar indicador de carga
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Buscando palabras del campo semántico...')),
    );

    try {
      final result = await semantic_activity.generateSemanticFieldActivity(
        images: images,
        arasaacService: _arasaacService,
        isLandscape: _pageOrientations[_currentPage],
        a4WidthPts: _a4WidthPts,
        a4HeightPts: _a4HeightPts,
        maxWords: numImages,
        usePictograms: usePictograms,
      );

      if (result.pages.isEmpty ||
          (result.pages.isNotEmpty && result.pages[0].isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontraron palabras relacionadas'),
          ),
        );
        return;
      }

      setState(() {
        _pages[_currentPage].clear();
        _pages[_currentPage].addAll(result.pages[0]);
        _addPendingVisualInstructions(_currentPage);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Campo semántico generado')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al generar la actividad')),
      );
    }
  }

  Future<void> _generateInstructionsActivity() async {
    final images = _canvasImages
        .where(
          (element) =>
              element.type == CanvasElementType.networkImage ||
              element.type == CanvasElementType.localImage ||
              element.type == CanvasElementType.pictogramCard,
        )
        .toList();

    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos una imagen primero')),
      );
      return;
    }

    final config = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => _InstructionsConfigDialog(),
    );

    if (config == null) return;

    // Mostrar indicador de carga
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generando actividad de instrucciones...')),
    );

    final result = instructions_activity.generateInstructionsActivity(
      images: images,
      isLandscape: _pageOrientations[_currentPage],
      a4WidthPts: _a4WidthPts,
      a4HeightPts: _a4HeightPts,
      minTargets: config['min'] ?? 1,
      maxTargets: config['max'] ?? 3,
    );

    if (result.elements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron generar las instrucciones'),
        ),
      );
      return;
    }

    setState(() {
      _pages[_currentPage].clear();
      _pages[_currentPage].addAll(result.elements);
      _addPendingVisualInstructions(_currentPage);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message ?? 'Actividad de instrucciones generada'),
      ),
    );
  }

  /// Añade las instrucciones visuales pendientes a una página si existen
  void _addPendingVisualInstructions(int pageIndex) {
    if (_pendingVisualInstructions != null) {
      _pages[pageIndex].add(_pendingVisualInstructions!);
      if (kDebugMode) {
        print('=== DEBUG: Instrucciones visuales añadidas a la página $pageIndex');
      }
      _pendingVisualInstructions = null;
    }
  }

  /// Mapeo de nombres de actividad a sus métodos de generación
  Future<void> _handleActivitySelection(String activityName) async {
    // Buscar el tipo de actividad en el servicio para obtener las instrucciones visuales
    try {
      if (kDebugMode) {
        print('=== DEBUG: Buscando actividad: $activityName');
      }

      final activities = await _activityTypeService.getEnabled();

      if (kDebugMode) {
        print('=== DEBUG: Actividades encontradas: ${activities.length}');
        for (final act in activities) {
          print('  - ${act.name}: activityPictogramUrl=${act.activityPictogramUrl}, materials=${act.materialPictogramUrls?.length ?? 0}');
        }
      }

      final activityType = activities.firstWhere(
        (a) => a.name == activityName,
        orElse: () => activities.first,
      );

      if (kDebugMode) {
        print('=== DEBUG: Tipo de actividad encontrado: ${activityType.name}');
        print('=== DEBUG: activityPictogramUrl: ${activityType.activityPictogramUrl}');
        print('=== DEBUG: materialPictogramUrls: ${activityType.materialPictogramUrls}');
      }

      // Si tiene instrucciones visuales configuradas, guardarlas para añadir después
      if (activityType.activityPictogramUrl != null ||
          (activityType.materialPictogramUrls != null &&
              activityType.materialPictogramUrls!.isNotEmpty)) {
        if (kDebugMode) {
          print('=== DEBUG: Guardando instrucciones visuales para añadir después');
        }

        _pendingVisualInstructions = CanvasImage.visualInstructionsBar(
          id: _generateId(),
          position: const Offset(100, 100),
          activityPictogramUrl: activityType.activityPictogramUrl,
          materialPictogramUrls: activityType.materialPictogramUrls,
        );

        if (kDebugMode) {
          print('=== DEBUG: Instrucciones guardadas temporalmente');
        }
      } else {
        _pendingVisualInstructions = null;
        if (kDebugMode) {
          print('=== DEBUG: No hay instrucciones visuales configuradas para esta actividad');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('=== DEBUG ERROR: Error al obtener tipo de actividad: $e');
      }
    }

    final activityMap = {
      'activity_pack': _generateActivityPack,
      'shadow_matching': _generateShadowMatchingActivity,
      'puzzle': _generatePuzzleActivity,
      'writing_practice': _generateWritingPracticeActivity,
      'counting_practice': _generateCountingActivity,
      'phonological_awareness': _generatePhonologicalAwarenessActivity,
      'phonological_board': _generatePhonologicalBoardActivity,
      'series': _generateSeriesActivity,
      'symmetry': _generateSymmetryActivity,
      'syllable_vocabulary': _generateSyllableVocabularyActivity,
      'semantic_field': _generateSemanticFieldActivity,
      'instructions': _generateInstructionsActivity,
      'phrases': _generatePhrasesActivity,
      'card': _generateCardActivity,
      'classification': _generateClassificationActivity,
      'phonological_squares': _generatePhonologicalSquaresActivity,
      'crossword': _generateCrosswordActivity,
      'word_search': _generateWordSearchActivity,
      'sentence_completion': _generateSentenceCompletionActivity,
    };

    final handler = activityMap[activityName];
    if (handler != null) {
      handler();
    } else {
      if (kDebugMode) {
        print('Actividad no encontrada: $activityName');
      }
    }
  }

  Future<void> _addLocalImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      Uint8List? bytes;
      if (kIsWeb) {
        bytes = await image.readAsBytes();
      }
      setState(() {
        _pages[_currentPage].add(
          CanvasImage.localImage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            imagePath: image.path,
            webBytes: bytes,
            position: const Offset(100, 100),
            scale: 1.0,
          ),
        );
      });
    }
  }

  Future<void> _selectLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      Uint8List? bytes;
      if (kIsWeb) {
        bytes = await image.readAsBytes();
      }
      setState(() {
        _logoPath = image.path;
        _logoWebBytes = bytes;
      });
      await _saveUserLogoPreference();
    }
  }

  void _addText(String text) {
    setState(() {
      final newText = CanvasImage.text(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        position: const Offset(100, 100),
        fontSize: 24.0,
        textColor: Colors.black,
        fontFamily: 'Roboto',
        scale: 1.0,
      );
      _pages[_currentPage].add(newText);
      _selectedImageIds = {newText.id};
    });
  }

  void _addShape(ShapeType shapeType) {
    setState(() {
      final newShape = CanvasImage.shape(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        shapeType: shapeType,
        position: const Offset(100, 100),
        shapeColor: Colors.black,
        strokeWidth: 2.0,
        scale: 1.0,
      );
      _pages[_currentPage].add(newShape);
      _selectedImageIds = {newShape.id};
    });
  }

  void _updateText(String id, String newText) {
    setState(() {
      final index = _pages[_currentPage].indexWhere((img) => img.id == id);
      if (index != -1) {
        _pages[_currentPage][index] = _pages[_currentPage][index].copyWith(
          text: newText,
        );
      }
    });
  }

  void _updateTextAlign(String id, TextAlign alignment) {
    setState(() {
      final index = _pages[_currentPage].indexWhere((img) => img.id == id);
      if (index != -1) {
        _pages[_currentPage][index].textAlign = alignment;
      }
    });
  }

  void _updateTextFontSize(String id, double newSize) {
    setState(() {
      final index = _pages[_currentPage].indexWhere((img) => img.id == id);
      if (index != -1) {
        _pages[_currentPage][index].fontSize = newSize;
      }
    });
  }

  void _updateTextColor(String id, Color newColor) {
    setState(() {
      final index = _pages[_currentPage].indexWhere((img) => img.id == id);
      if (index != -1) {
        _pages[_currentPage][index].textColor = newColor;
      }
    });
  }

  void _toggleTextBold(String id) {
    setState(() {
      final index = _pages[_currentPage].indexWhere((img) => img.id == id);
      if (index != -1) {
        _pages[_currentPage][index].isBold =
            !_pages[_currentPage][index].isBold;
      }
    });
  }

  void _toggleTextItalic(String id) {
    setState(() {
      final index = _pages[_currentPage].indexWhere((img) => img.id == id);
      if (index != -1) {
        _pages[_currentPage][index].isItalic =
            !_pages[_currentPage][index].isItalic;
      }
    });
  }

  void _toggleTextUnderline(String id) {
    setState(() {
      final index = _pages[_currentPage].indexWhere((img) => img.id == id);
      if (index != -1) {
        _pages[_currentPage][index].isUnderline =
            !_pages[_currentPage][index].isUnderline;
      }
    });
  }

  /// Parsea texto con markdown y retorna TextSpan formateado (para Flutter)
  TextSpan _parseMarkdownToTextSpan(String text, TextStyle baseStyle) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'(\*\*|_|~)([^\*_~]+)\1');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Añadir texto antes del match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }

      // Extraer el marcador y el texto
      final marker = match.group(1);
      final content = match.group(2) ?? '';

      // Aplicar estilo según el marcador
      TextStyle style = baseStyle;
      if (marker == '**') {
        style = baseStyle.copyWith(fontWeight: FontWeight.bold);
      } else if (marker == '_') {
        style = baseStyle.copyWith(fontStyle: FontStyle.italic);
      } else if (marker == '~') {
        style = baseStyle.copyWith(decoration: TextDecoration.underline);
      }

      spans.add(TextSpan(text: content, style: style));
      lastEnd = match.end;
    }

    // Añadir texto restante
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: baseStyle,
      ));
    }

    return TextSpan(children: spans.isNotEmpty ? spans : [TextSpan(text: text, style: baseStyle)]);
  }

  /// Parsea texto con markdown y retorna pw.TextSpan formateado (para PDF)
  pw.TextSpan _parseMarkdownToPdfTextSpan(String text, pw.TextStyle baseStyle) {
    final spans = <pw.TextSpan>[];
    final regex = RegExp(r'(\*\*|_|~)([^\*_~]+)\1');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Añadir texto antes del match
      if (match.start > lastEnd) {
        spans.add(pw.TextSpan(
          text: text.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }

      // Extraer el marcador y el texto
      final marker = match.group(1);
      final content = match.group(2) ?? '';

      // Aplicar estilo según el marcador
      pw.TextStyle style = baseStyle;
      if (marker == '**') {
        style = baseStyle.copyWith(fontWeight: pw.FontWeight.bold);
      } else if (marker == '_') {
        style = baseStyle.copyWith(fontStyle: pw.FontStyle.italic);
      } else if (marker == '~') {
        style = baseStyle.copyWith(decoration: pw.TextDecoration.underline);
      }

      spans.add(pw.TextSpan(text: content, style: style));
      lastEnd = match.end;
    }

    // Añadir texto restante
    if (lastEnd < text.length) {
      spans.add(pw.TextSpan(
        text: text.substring(lastEnd),
        style: baseStyle,
      ));
    }

    return pw.TextSpan(children: spans.isNotEmpty ? spans : [pw.TextSpan(text: text, style: baseStyle)]);
  }

  /// Aplica formato markdown al texto seleccionado en el TextEditingController
  void _applySelectionFormat(TextEditingController controller, String id, String formatType) {
    final selection = controller.selection;

    // Si no hay selección, no hacer nada
    if (!selection.isValid || selection.start == selection.end) {
      return;
    }

    final text = controller.text;
    final selectedText = selection.textInside(text);

    // Aplicar el markup markdown según el tipo de formato
    String formattedText;
    switch (formatType) {
      case 'bold':
        formattedText = '**$selectedText**';
        break;
      case 'italic':
        formattedText = '_${selectedText}_';
        break;
      case 'underline':
        formattedText = '~$selectedText~';
        break;
      default:
        formattedText = selectedText;
    }

    // Reconstruir el texto completo con la parte seleccionada formateada
    final newText = text.replaceRange(selection.start, selection.end, formattedText);

    // Actualizar el controller
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + formattedText.length),
    );

    // Actualizar el elemento en el canvas
    _updateText(id, newText);
  }

  void _updateShapeColor(String id, Color newColor) {
    setState(() {
      final index = _pages[_currentPage].indexWhere((img) => img.id == id);
      if (index != -1) {
        _pages[_currentPage][index].shapeColor = newColor;
      }
    });
  }

  void _updateShapeStroke(String id, double newStroke) {
    setState(() {
      final index = _pages[_currentPage].indexWhere((img) => img.id == id);
      if (index != -1) {
        _pages[_currentPage][index].strokeWidth = newStroke.clamp(0.5, 12.0);
      }
    });
  }

  void _duplicateElement(String id) {
    final index = _pages[_currentPage].indexWhere((img) => img.id == id);
    if (index == -1) return;

    final original = _pages[_currentPage][index];
    final copy = original.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      position: original.position + const Offset(20, 20),
    );

    setState(() {
      _pages[_currentPage].insert(index + 1, copy);
      _selectedImageIds = {copy.id};
    });
  }

  void _resizeElement(String id, Offset delta, Alignment handle) {
    final index = _pages[_currentPage].indexWhere((img) => img.id == id);
    if (index == -1) return;

    final element = _pages[_currentPage][index];
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final adjustedDelta = delta / (currentScale == 0 ? 1 : currentScale);

    if (element.type == CanvasElementType.shape ||
        element.type == CanvasElementType.text) {
      final minSize = 20.0;
      double newWidth =
          (element.width ??
          (element.type == CanvasElementType.text ? 300.0 : 100.0));
      double newHeight = (element.height ?? 100.0);
      double newLeft = element.position.dx;
      double newTop = element.position.dy;

      // Detectar si es esquina (resize proporcional) o lado (resize unidireccional)
      final isCorner = handle.x != 0 && handle.y != 0;

      if (isCorner && element.type == CanvasElementType.shape) {
        // ESQUINA: Resize proporcional manteniendo aspect ratio
        final aspectRatio = newWidth / newHeight;

        // Usar el delta promedio para mantener proporción
        final avgDelta = (adjustedDelta.dx + adjustedDelta.dy) / 2;

        if (handle.x < 0) {
          // Esquina izquierda: reducir tamaño y mover posición
          final widthChange = -avgDelta;
          newWidth = (newWidth + widthChange).clamp(minSize, 1000.0);
          newHeight = (newWidth / aspectRatio).clamp(minSize, 1000.0);
          newLeft += (element.width! - newWidth);
          if (handle.y < 0) {
            newTop += (element.height! - newHeight);
          }
        } else {
          // Esquina derecha: aumentar tamaño
          newWidth = (newWidth + avgDelta).clamp(minSize, 1000.0);
          newHeight = (newWidth / aspectRatio).clamp(minSize, 1000.0);
          if (handle.y < 0) {
            newTop += (element.height! - newHeight);
          }
        }
      } else {
        // LADO: Resize unidireccional (solo ancho O solo alto)

        // Redimensionar ancho (si handle tiene componente x)
        if (handle.x < 0) {
          // Lado izquierdo: reducir ancho y mover posición
          newWidth = (newWidth - adjustedDelta.dx).clamp(minSize, 1000.0);
          newLeft += adjustedDelta.dx;
        } else if (handle.x > 0) {
          // Lado derecho: aumentar ancho
          newWidth = (newWidth + adjustedDelta.dx).clamp(minSize, 1000.0);
        }

        // Redimensionar alto (si handle tiene componente y y no es texto)
        if (element.type == CanvasElementType.shape) {
          if (handle.y < 0) {
            // Lado superior: reducir alto y mover posición
            newHeight = (newHeight - adjustedDelta.dy).clamp(minSize, 1000.0);
            newTop += adjustedDelta.dy;
          } else if (handle.y > 0) {
            // Lado inferior: aumentar alto
            newHeight = (newHeight + adjustedDelta.dy).clamp(minSize, 1000.0);
          }
        }
      }

      setState(() {
        _pages[_currentPage][index].width = newWidth;
        if (element.type == CanvasElementType.shape) {
          _pages[_currentPage][index].height = newHeight;
        }
        _pages[_currentPage][index].position = Offset(newLeft, newTop);
      });
    } else {
      // Para otros elementos (imágenes)
      final isCorner = handle.x != 0 && handle.y != 0;

      if (element.height == null) {
        // Imagen con aspect ratio natural (height = null) - usar scale
        final base = element.width ?? 150.0;

        if (isCorner) {
          // ESQUINA: Resize proporcional usando scale
          final deltaScale = (adjustedDelta.dx + adjustedDelta.dy) / (2 * base);
          setState(() {
            final newScale = (element.scale + deltaScale).clamp(0.1, 5.0);
            _pages[_currentPage][index].scale = newScale;
          });
        } else {
          // LADO: Resize unidireccional - convertir a width/height explícitos
          final minSize = 20.0;
          final currentWidth = base * element.scale;

          double newWidth = currentWidth;
          double newLeft = element.position.dx;

          if (handle.x != 0) {
            if (handle.x < 0) {
              newWidth = (currentWidth - adjustedDelta.dx).clamp(minSize, 2000.0);
              newLeft += (currentWidth - newWidth);
            } else {
              newWidth = (currentWidth + adjustedDelta.dx).clamp(minSize, 2000.0);
            }

            setState(() {
              _pages[_currentPage][index].width = newWidth;
              _pages[_currentPage][index].scale = 1.0;
              _pages[_currentPage][index].position = Offset(newLeft, element.position.dy);
            });
          }
          // Si es handle vertical (y != 0), no hacer nada para mantener aspect ratio
        }
      } else {
        // Imagen con width Y height definidos - resize directo
        final minSize = 20.0;
        final currentWidth = element.width! * element.scale;
        final currentHeight = element.height! * element.scale;

        double newWidth = currentWidth;
        double newHeight = currentHeight;
        double newLeft = element.position.dx;
        double newTop = element.position.dy;

        if (isCorner) {
          // ESQUINA: Resize proporcional
          final aspectRatio = currentWidth / currentHeight;
          final avgDelta = (adjustedDelta.dx + adjustedDelta.dy) / 2;

          if (handle.x < 0) {
            newWidth = (currentWidth - avgDelta).clamp(minSize, 2000.0);
            newHeight = (newWidth / aspectRatio).clamp(minSize, 2000.0);
            newLeft += (currentWidth - newWidth);
            if (handle.y < 0) {
              newTop += (currentHeight - newHeight);
            }
          } else {
            newWidth = (currentWidth + avgDelta).clamp(minSize, 2000.0);
            newHeight = (newWidth / aspectRatio).clamp(minSize, 2000.0);
            if (handle.y < 0) {
              newTop += (currentHeight - newHeight);
            }
          }
        } else {
          // LADO: Resize unidireccional
          if (handle.x != 0) {
            if (handle.x < 0) {
              newWidth = (currentWidth - adjustedDelta.dx).clamp(minSize, 2000.0);
              newLeft += (currentWidth - newWidth);
            } else {
              newWidth = (currentWidth + adjustedDelta.dx).clamp(minSize, 2000.0);
            }
          }

          if (handle.y != 0) {
            if (handle.y < 0) {
              newHeight = (currentHeight - adjustedDelta.dy).clamp(minSize, 2000.0);
              newTop += (currentHeight - newHeight);
            } else {
              newHeight = (currentHeight + adjustedDelta.dy).clamp(minSize, 2000.0);
            }
          }
        }

        setState(() {
          _pages[_currentPage][index].width = newWidth;
          _pages[_currentPage][index].height = newHeight;
          _pages[_currentPage][index].scale = 1.0;
          _pages[_currentPage][index].position = Offset(newLeft, newTop);
        });
      }
    }
  }

  void _updateTextFontFamily(String id, String newFont) {
    setState(() {
      final index = _pages[_currentPage].indexWhere((img) => img.id == id);
      if (index != -1) {
        _pages[_currentPage][index].fontFamily = newFont;
      }
    });
  }

  void _updateImagePosition(String id, Offset delta) {
    setState(() {
      final currentScale = _transformationController.value.getMaxScaleOnAxis();
      final adjustedDelta = delta / (currentScale == 0 ? 1 : currentScale);
      final ids = _idsForElement(id);
      for (final targetId in ids) {
        final index = _pages[_currentPage].indexWhere(
          (img) => img.id == targetId,
        );
        if (index != -1) {
          _pages[_currentPage][index].position += adjustedDelta;
        }
      }
    });
  }

  void _updateImageScale(String id, double scaleDelta) {
    setState(() {
      final ids = _idsForElement(id);
      for (final targetId in ids) {
        final index = _pages[_currentPage].indexWhere(
          (img) => img.id == targetId,
        );
        if (index != -1) {
          final newScale = (_pages[_currentPage][index].scale + scaleDelta)
              .clamp(0.1, double.infinity);
          _pages[_currentPage][index].scale = newScale;
        }
      }
    });
  }

  void _updateImageRotation(String id, double rotationDelta) {
    setState(() {
      final ids = _idsForElement(id);
      for (final targetId in ids) {
        final index = _pages[_currentPage].indexWhere(
          (img) => img.id == targetId,
        );
        if (index != -1) {
          _pages[_currentPage][index].rotation += rotationDelta;
        }
      }
    });
  }

  void _toggleFlipHorizontal(String id) {
    setState(() {
      final ids = _idsForElement(id);
      for (final targetId in ids) {
        final index = _pages[_currentPage].indexWhere(
          (img) => img.id == targetId,
        );
        if (index != -1) {
          _pages[_currentPage][index].flipHorizontal =
              !_pages[_currentPage][index].flipHorizontal;
        }
      }
    });
  }

  void _toggleFlipVertical(String id) {
    setState(() {
      final ids = _idsForElement(id);
      for (final targetId in ids) {
        final index = _pages[_currentPage].indexWhere(
          (img) => img.id == targetId,
        );
        if (index != -1) {
          _pages[_currentPage][index].flipVertical =
              !_pages[_currentPage][index].flipVertical;
        }
      }
    });
  }

  // Métodos helper para selección múltiple
  bool _isSelected(String id) => _selectedImageIds.contains(id);

  void _selectSingle(String id) {
    setState(() {
      _selectedImageIds = {id};
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      final ids = _idsForElement(id);
      if (_selectedImageIds.containsAll(ids)) {
        _selectedImageIds.removeAll(ids);
      } else {
        _selectedImageIds.addAll(ids);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedImageIds.clear();
    });
  }

  void _selectImage(String? id) {
    setState(() {
      if (id == null) {
        _selectedImageIds.clear();
      } else {
        _selectedImageIds = _idsForElement(id);
      }
    });
  }

  Set<String> _idsForElement(String id) {
    final element = _canvasImages.firstWhere(
      (e) => e.id == id,
      orElse: () => CanvasImage(
        id: id,
        type: CanvasElementType.text,
        position: Offset.zero,
      ),
    );
    if (element.groupId == null) return {id};
    final groupIds = _canvasImages
        .where((e) => e.groupId == element.groupId)
        .map((e) => e.id)
        .toSet();
    return groupIds.isNotEmpty ? groupIds : {id};
  }

  void _bringToFront(String id) {
    setState(() {
      final index = _pages[_currentPage].indexWhere((img) => img.id == id);
      if (index != -1 && index < _pages[_currentPage].length - 1) {
        final image = _pages[_currentPage].removeAt(index);
        _pages[_currentPage].add(image);
      }
    });
  }

  void _sendToBack(String id) {
    setState(() {
      final index = _pages[_currentPage].indexWhere((img) => img.id == id);
      if (index > 0) {
        final image = _pages[_currentPage].removeAt(index);
        _pages[_currentPage].insert(0, image);
      }
    });
  }

  void _bringForward(String id) {
    setState(() {
      final index = _pages[_currentPage].indexWhere((img) => img.id == id);
      if (index != -1 && index < _pages[_currentPage].length - 1) {
        final image = _pages[_currentPage].removeAt(index);
        _pages[_currentPage].insert(index + 1, image);
      }
    });
  }

  void _sendBackward(String id) {
    setState(() {
      final index = _pages[_currentPage].indexWhere((img) => img.id == id);
      if (index > 0) {
        final image = _pages[_currentPage].removeAt(index);
        _pages[_currentPage].insert(index - 1, image);
      }
    });
  }

  void _deleteImage(String id) {
    setState(() {
      _pages[_currentPage].removeWhere((img) => img.id == id);
      _selectedImageIds.clear();
    });
  }

  void _groupSelection() {
    if (_selectedImageIds.length < 2) return;
    final newGroup = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      for (final img in _pages[_currentPage]) {
        if (_selectedImageIds.contains(img.id)) {
          img.groupId = newGroup;
        }
      }
      _selectedImageIds = _pages[_currentPage]
          .where((e) => e.groupId == newGroup)
          .map((e) => e.id)
          .toSet();
      _saveToHistory();
    });
  }

  void _ungroupSelection() {
    if (_selectedImageIds.isEmpty) return;
    final groupIds = _pages[_currentPage]
        .where((e) => _selectedImageIds.contains(e.id) && e.groupId != null)
        .map((e) => e.groupId)
        .toSet();
    if (groupIds.isEmpty) return;

    setState(() {
      for (final img in _pages[_currentPage]) {
        if (groupIds.contains(img.groupId)) {
          img.groupId = null;
        }
      }
      _selectedImageIds = _selectedImageIds.where((id) {
        final el = _pages[_currentPage].firstWhere(
          (e) => e.id == id,
          orElse: () => CanvasImage(
            id: id,
            type: CanvasElementType.text,
            position: Offset.zero,
          ),
        );
        return el.groupId == null;
      }).toSet();
      _saveToHistory();
    });
  }

  // Funciones de alineación
  void _alignLeft() {
    if (_selectedImageIds.length < 2) return;

    setState(() {
      final selectedImages = _pages[_currentPage]
          .where((img) => _selectedImageIds.contains(img.id))
          .toList();

      if (selectedImages.isEmpty) return;

      // Encontrar el extremo izquierdo
      final minLeft = selectedImages
          .map((img) => img.position.dx)
          .reduce((a, b) => a < b ? a : b);

      // Alinear todos los elementos a la izquierda
      for (final img in selectedImages) {
        final index = _pages[_currentPage].indexWhere((i) => i.id == img.id);
        if (index != -1) {
          _pages[_currentPage][index] = img.copyWith(
            position: Offset(minLeft, img.position.dy),
          );
        }
      }
      _saveToHistory();
    });
  }

  void _alignCenterHorizontal() {
    if (_selectedImageIds.length < 2) return;

    setState(() {
      final selectedImages = _pages[_currentPage]
          .where((img) => _selectedImageIds.contains(img.id))
          .toList();

      if (selectedImages.isEmpty) return;

      // Calcular el centro horizontal promedio
      final centers = selectedImages.map((img) {
        final width = (img.width ?? 150) * img.scale;
        return img.position.dx + width / 2;
      }).toList();

      final avgCenter = centers.reduce((a, b) => a + b) / centers.length;

      // Alinear todos al centro
      for (final img in selectedImages) {
        final index = _pages[_currentPage].indexWhere((i) => i.id == img.id);
        if (index != -1) {
          final width = (img.width ?? 150) * img.scale;
          _pages[_currentPage][index] = img.copyWith(
            position: Offset(avgCenter - width / 2, img.position.dy),
          );
        }
      }
      _saveToHistory();
    });
  }

  void _alignRight() {
    if (_selectedImageIds.length < 2) return;

    setState(() {
      final selectedImages = _pages[_currentPage]
          .where((img) => _selectedImageIds.contains(img.id))
          .toList();

      if (selectedImages.isEmpty) return;

      // Encontrar el extremo derecho
      final maxRight = selectedImages
          .map((img) {
            final width = (img.width ?? 150) * img.scale;
            return img.position.dx + width;
          })
          .reduce((a, b) => a > b ? a : b);

      // Alinear todos a la derecha
      for (final img in selectedImages) {
        final index = _pages[_currentPage].indexWhere((i) => i.id == img.id);
        if (index != -1) {
          final width = (img.width ?? 150) * img.scale;
          _pages[_currentPage][index] = img.copyWith(
            position: Offset(maxRight - width, img.position.dy),
          );
        }
      }
      _saveToHistory();
    });
  }

  void _alignTop() {
    if (_selectedImageIds.length < 2) return;

    setState(() {
      final selectedImages = _pages[_currentPage]
          .where((img) => _selectedImageIds.contains(img.id))
          .toList();

      if (selectedImages.isEmpty) return;

      // Encontrar el extremo superior
      final minTop = selectedImages
          .map((img) => img.position.dy)
          .reduce((a, b) => a < b ? a : b);

      // Alinear todos arriba
      for (final img in selectedImages) {
        final index = _pages[_currentPage].indexWhere((i) => i.id == img.id);
        if (index != -1) {
          _pages[_currentPage][index] = img.copyWith(
            position: Offset(img.position.dx, minTop),
          );
        }
      }
      _saveToHistory();
    });
  }

  void _alignCenterVertical() {
    if (_selectedImageIds.length < 2) return;

    setState(() {
      final selectedImages = _pages[_currentPage]
          .where((img) => _selectedImageIds.contains(img.id))
          .toList();

      if (selectedImages.isEmpty) return;

      // Calcular el centro vertical promedio
      final centers = selectedImages.map((img) {
        final height = (img.height ?? 150) * img.scale;
        return img.position.dy + height / 2;
      }).toList();

      final avgCenter = centers.reduce((a, b) => a + b) / centers.length;

      // Alinear todos al centro vertical
      for (final img in selectedImages) {
        final index = _pages[_currentPage].indexWhere((i) => i.id == img.id);
        if (index != -1) {
          final height = (img.height ?? 150) * img.scale;
          _pages[_currentPage][index] = img.copyWith(
            position: Offset(img.position.dx, avgCenter - height / 2),
          );
        }
      }
      _saveToHistory();
    });
  }

  void _alignBottom() {
    if (_selectedImageIds.length < 2) return;

    setState(() {
      final selectedImages = _pages[_currentPage]
          .where((img) => _selectedImageIds.contains(img.id))
          .toList();

      if (selectedImages.isEmpty) return;

      // Encontrar el extremo inferior
      final maxBottom = selectedImages
          .map((img) {
            final height = (img.height ?? 150) * img.scale;
            return img.position.dy + height;
          })
          .reduce((a, b) => a > b ? a : b);

      // Alinear todos abajo
      for (final img in selectedImages) {
        final index = _pages[_currentPage].indexWhere((i) => i.id == img.id);
        if (index != -1) {
          final height = (img.height ?? 150) * img.scale;
          _pages[_currentPage][index] = img.copyWith(
            position: Offset(img.position.dx, maxBottom - height),
          );
        }
      }
      _saveToHistory();
    });
  }

  // Funciones de distribución
  void _distributeHorizontally() {
    if (_selectedImageIds.length < 3) return;

    setState(() {
      final selectedImages = _pages[_currentPage]
          .where((img) => _selectedImageIds.contains(img.id))
          .toList();

      if (selectedImages.length < 3) return;

      // Ordenar por posición X
      selectedImages.sort((a, b) => a.position.dx.compareTo(b.position.dx));

      // Calcular el espacio total y el espacio entre elementos
      final first = selectedImages.first;
      final last = selectedImages.last;
      final firstWidth = (first.width ?? 150) * first.scale;
      final lastWidth = (last.width ?? 150) * last.scale;

      // Espacio disponible entre el borde derecho del primero y el borde izquierdo del último
      final availableSpace =
          (last.position.dx) - (first.position.dx + firstWidth);

      // Ancho total de los elementos intermedios
      double middleElementsWidth = 0;
      for (int i = 1; i < selectedImages.length - 1; i++) {
        middleElementsWidth +=
            (selectedImages[i].width ?? 150) * selectedImages[i].scale;
      }

      // Espacio entre elementos
      final spacing =
          (availableSpace - middleElementsWidth) / (selectedImages.length - 1);

      // Distribuir elementos (solo los intermedios)
      double currentX = first.position.dx + firstWidth + spacing;
      for (int i = 1; i < selectedImages.length - 1; i++) {
        final img = selectedImages[i];
        final index = _pages[_currentPage].indexWhere(
          (item) => item.id == img.id,
        );
        if (index != -1) {
          _pages[_currentPage][index] = img.copyWith(
            position: Offset(currentX, img.position.dy),
          );
        }
        currentX += (img.width ?? 150) * img.scale + spacing;
      }
      _saveToHistory();
    });
  }

  void _distributeVertically() {
    if (_selectedImageIds.length < 3) return;

    setState(() {
      final selectedImages = _pages[_currentPage]
          .where((img) => _selectedImageIds.contains(img.id))
          .toList();

      if (selectedImages.length < 3) return;

      // Ordenar por posición Y
      selectedImages.sort((a, b) => a.position.dy.compareTo(b.position.dy));

      // Calcular el espacio total y el espacio entre elementos
      final first = selectedImages.first;
      final last = selectedImages.last;
      final firstHeight = (first.height ?? 150) * first.scale;
      final lastHeight = (last.height ?? 150) * last.scale;

      // Espacio disponible entre el borde inferior del primero y el borde superior del último
      final availableSpace =
          (last.position.dy) - (first.position.dy + firstHeight);

      // Altura total de los elementos intermedios
      double middleElementsHeight = 0;
      for (int i = 1; i < selectedImages.length - 1; i++) {
        middleElementsHeight +=
            (selectedImages[i].height ?? 150) * selectedImages[i].scale;
      }

      // Espacio entre elementos
      final spacing =
          (availableSpace - middleElementsHeight) / (selectedImages.length - 1);

      // Distribuir elementos (solo los intermedios)
      double currentY = first.position.dy + firstHeight + spacing;
      for (int i = 1; i < selectedImages.length - 1; i++) {
        final img = selectedImages[i];
        final index = _pages[_currentPage].indexWhere(
          (item) => item.id == img.id,
        );
        if (index != -1) {
          _pages[_currentPage][index] = img.copyWith(
            position: Offset(img.position.dx, currentY),
          );
        }
        currentY += (img.height ?? 150) * img.scale + spacing;
      }
      _saveToHistory();
    });
  }

  void _addPage() {
    setState(() {
      // Guardar el contenido actual antes de cambiar de página
      _saveControllersToCurrentPage();

      _pages.add([]);
      _pageTemplates.add(TemplateType.blank);
      _pageBackgrounds.add(Colors.white);
      _pageOrientations.add(false); // Nueva página en vertical por defecto
      _pageTitles.add(''); // Título vacío para la nueva página
      _pageInstructions.add(''); // Instrucciones vacías para la nueva página
      _currentPage = _pages.length - 1;
      _selectedImageIds.clear();

      // Sincronizar los controllers con la nueva página
      _syncControllersWithCurrentPage();
    });
  }

  void _deletePage(int index) {
    if (_pages.length <= 1) return;
    setState(() {
      _pages.removeAt(index);
      _pageTemplates.removeAt(index);
      _pageBackgrounds.removeAt(index);
      _pageOrientations.removeAt(index);
      _pageTitles.removeAt(index);
      _pageInstructions.removeAt(index);
      if (_currentPage >= _pages.length) {
        _currentPage = _pages.length - 1;
      }
      _selectedImageIds.clear();

      // Sincronizar con la página actual después de eliminar
      _syncControllersWithCurrentPage();
    });
  }

  void _setPageTemplate(TemplateType template) {
    setState(() {
      _pageTemplates[_currentPage] = template;
    });
  }

  void _goToPage(int index) {
    setState(() {
      // Validar que el índice esté dentro del rango
      if (index < 0 || index >= _pages.length) {
        print(
          'ERROR: Índice de página fuera de rango: $index, total páginas: ${_pages.length}',
        );
        return;
      }

      // Guardar el contenido de los controllers en la página actual antes de cambiar
      _saveControllersToCurrentPage();

      // Asegurar que _pageOrientations tenga suficientes elementos
      while (_pageOrientations.length <= index) {
        _pageOrientations.add(false);
        print(
          'DEBUG: Añadiendo orientación para página ${_pageOrientations.length - 1}',
        );
      }

      // Asegurar que _pageTitles y _pageInstructions tengan suficientes elementos
      while (_pageTitles.length <= index) {
        _pageTitles.add('');
      }
      while (_pageInstructions.length <= index) {
        _pageInstructions.add('');
      }

      _currentPage = index;
      _selectedImageIds.clear();

      // Sincronizar los controllers con la nueva página
      _syncControllersWithCurrentPage();
    });
  }

  void _changeZoom(double delta) {
    setState(() {
      _canvasZoom = (_canvasZoom + delta).clamp(0.5, 2.5).toDouble();

      // Actualizar el TransformationController para aplicar el zoom
      final currentTranslation = _transformationController.value.getTranslation();
      _transformationController.value = Matrix4.identity()
        ..setTranslation(currentTranslation)
        ..scale(_canvasZoom, _canvasZoom, 1.0);
    });
  }

  bool _shouldRenderHeaderFooter(HeaderFooterScope scope, int pageIndex) {
    final isFirst = pageIndex == 0;
    final isLast = pageIndex == _pages.length - 1;

    switch (scope) {
      case HeaderFooterScope.all:
        return true;
      case HeaderFooterScope.first:
        return isFirst;
      case HeaderFooterScope.last:
        return isLast;
    }
  }

  Future<pw.MemoryImage?> _fetchNetworkImageForPdf(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: const {
          // Algunos servidores (p. ej. SoyVisual) bloquean el user-agent por defecto de Dart
          'User-Agent': 'Mozilla/5.0 (compatible; ArasaacActivities/1.0)',
          'Accept': 'image/*,*/*',
        },
      );

      if (response.statusCode == 200) {
        return pw.MemoryImage(response.bodyBytes);
      }

      debugPrint(
        'No se pudo descargar imagen ($url), status: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('Error descargando imagen $url: $e');
    }
    return null;
  }

  Future<void> _generatePDF() async {
    // Verificar si hay al menos una página con contenido
    final hasContent = _pages.any((page) => page.isNotEmpty);
    if (!hasContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay contenido para exportar')),
      );
      return;
    }

    // Cargar fuentes escolares para PDF
    final coleCarreiraData = await rootBundle.load(
      'assets/fonts/ColeCarreira.ttf',
    );
    final coleCarreiraFont = pw.Font.ttf(coleCarreiraData);

    final escolarGData = await rootBundle.load('assets/fonts/Escolar_G.TTF');
    final escolarGFont = pw.Font.ttf(escolarGData);

    final escolarPData = await rootBundle.load('assets/fonts/Escolar_P.TTF');
    final escolarPFont = pw.Font.ttf(escolarPData);

    final traceData = await rootBundle.load('assets/fonts/TRACE___.TTF');
    final traceFont = pw.Font.ttf(traceData);

    final massalleraData = await rootBundle.load('assets/fonts/massallera.TTF');
    final massalleraFont = pw.Font.ttf(massalleraData);

    final pdf = pw.Document();

    // Generar cada página del PDF
    for (var pageIndex = 0; pageIndex < _pages.length; pageIndex++) {
      final pageElements = _pages[pageIndex];
      final widgets = <pw.Widget>[];

      final PdfPageFormat pageFormat = _pageOrientations[pageIndex]
          ? PdfPageFormat(_a4HeightPts, _a4WidthPts, marginAll: 0)
          : PdfPageFormat(_a4WidthPts, _a4HeightPts, marginAll: 0);
      final double pageWidth = pageFormat.width;
      final double pageHeight = pageFormat.height;
      double _bottomFromCanvas(double top, double height) =>
          pageHeight - top - height;

      // Fondo de página
      widgets.add(
        pw.Container(
          width: pageWidth,
          height: pageHeight,
          color: PdfColor.fromInt(_pageBackgrounds[pageIndex].value),
        ),
      );

      // Plantilla de fondo (solo grid/lineas simples)
      widgets.add(
        pw.Container(
          width: pageWidth,
          height: pageHeight,
          child: _buildPdfTemplate(
            _pageTemplates[pageIndex],
            pageWidth,
            pageHeight,
          ),
        ),
      );

      // Obtener título e instrucciones de esta página específica
      final headerText = pageIndex < _pageTitles.length ? _pageTitles[pageIndex].trim() : '';
      final footerText = pageIndex < _pageInstructions.length ? _pageInstructions[pageIndex].trim() : '';
      final documentFooter = _documentFooterController.text.trim();
      final isFirst = pageIndex == 0;
      final isLast = pageIndex == _pages.length - 1;

      bool shouldRender(HeaderFooterScope scope) {
        switch (scope) {
          case HeaderFooterScope.all:
            return true;
          case HeaderFooterScope.first:
            return isFirst;
          case HeaderFooterScope.last:
            return isLast;
        }
      }

      // Logo
      if (_logoPath != null || _logoWebBytes != null) {
        try {
          pw.MemoryImage? logoImage;

          if (kIsWeb) {
            // En web, usar _logoWebBytes si está disponible
            if (_logoWebBytes != null) {
              logoImage = pw.MemoryImage(_logoWebBytes!);
            } else if (_logoPath != null && _isHttpUrl(_logoPath!)) {
              // Si es una URL, intentar descargarla
              final response = await http.get(Uri.parse(_logoPath!));
              if (response.statusCode == 200) {
                logoImage = pw.MemoryImage(response.bodyBytes);
              }
            }
          } else {
            // En móvil/escritorio, leer desde el archivo
            if (_logoPath != null) {
              final logoFile = File(_logoPath!);
              final logoBytes = await logoFile.readAsBytes();
              logoImage = pw.MemoryImage(logoBytes);
            }
          }

          if (logoImage != null) {
            final logoBottom = _bottomFromCanvas(_logoPosition.dy, _logoSize);
            widgets.add(
              pw.Positioned(
                left: _logoPosition.dx,
                bottom: logoBottom,
                child: pw.Container(
                  width: _logoSize,
                  height: _logoSize,
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
              ),
            );
          }
        } catch (e) {
          print('Error al cargar logo para PDF: $e');
          // Continuar sin el logo si hay error
        }
      }

      // Renderizar título e instrucciones juntos en la parte superior
      if ((headerText.isNotEmpty && shouldRender(_headerScope)) ||
          (footerText.isNotEmpty && shouldRender(_footerScope))) {
        const headerFontSize = 16.0;
        const instructionsFontSize = 12.0;

        // Calcular altura total del bloque
        double totalHeight = 0;
        if (headerText.isNotEmpty && shouldRender(_headerScope)) {
          totalHeight += headerFontSize * 1.2;
        }
        if (headerText.isNotEmpty && footerText.isNotEmpty &&
            shouldRender(_headerScope) && shouldRender(_footerScope)) {
          totalHeight += 4; // Espaciado entre título e instrucciones
        }
        if (footerText.isNotEmpty && shouldRender(_footerScope)) {
          totalHeight += instructionsFontSize * 1.2;
        }

        final blockBottom = _bottomFromCanvas(10, totalHeight);

        final children = <pw.Widget>[];
        if (headerText.isNotEmpty && shouldRender(_headerScope)) {
          children.add(
            pw.Text(
              headerText,
              style: pw.TextStyle(
                fontSize: headerFontSize,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
          );
        }
        if (headerText.isNotEmpty && footerText.isNotEmpty &&
            shouldRender(_headerScope) && shouldRender(_footerScope)) {
          children.add(pw.SizedBox(height: 4));
        }
        if (footerText.isNotEmpty && shouldRender(_footerScope)) {
          children.add(
            pw.Text(
              footerText,
              style: const pw.TextStyle(fontSize: instructionsFontSize),
              textAlign: pw.TextAlign.center,
            ),
          );
        }

        widgets.add(
          pw.Positioned(
            left: 20,
            right: 20,
            bottom: blockBottom,
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: children,
            ),
          ),
        );
      }

      for (final element in pageElements) {
        try {
          if (element.type == CanvasElementType.text) {
            // Elemento de texto
            final textWidth = (element.width ?? 300.0) * element.scale;

            // Estilo base para el PDF
            final pdfBaseStyle = pw.TextStyle(
              fontSize: element.fontSize,
              color: PdfColor.fromInt(element.textColor.value),
              fontWeight: element.isBold
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
              fontStyle: element.isItalic
                  ? pw.FontStyle.italic
                  : pw.FontStyle.normal,
              decoration: element.isUnderline
                  ? pw.TextDecoration.underline
                  : pw.TextDecoration.none,
              font: element.fontFamily == 'ColeCarreira'
                  ? coleCarreiraFont
                  : element.fontFamily == 'EscolarG'
                  ? escolarGFont
                  : element.fontFamily == 'EscolarP'
                  ? escolarPFont
                  : element.fontFamily == 'Trace'
                  ? traceFont
                  : element.fontFamily == 'Massallera'
                  ? massalleraFont
                  : null,
            );

            widgets.add(
              pw.Positioned(
                left: element.position.dx,
                top: element.position.dy,
                child: pw.Transform.rotate(
                  angle: element.rotation,
                  alignment: pw.Alignment.center,
                  child: pw.Transform(
                    transform: Matrix4.diagonal3Values(
                      element.flipHorizontal ? -1.0 : 1.0,
                      element.flipVertical ? -1.0 : 1.0,
                      1.0,
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Container(
                      width: textWidth,
                      padding: pw.EdgeInsets.zero,
                      child: pw.RichText(
                        text: _parseMarkdownToPdfTextSpan(element.text ?? '', pdfBaseStyle),
                        textAlign: element.textAlign == TextAlign.left
                            ? pw.TextAlign.left
                            : element.textAlign == TextAlign.right
                            ? pw.TextAlign.right
                            : element.textAlign == TextAlign.justify
                            ? pw.TextAlign.justify
                            : pw.TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            );
          } else if (element.type == CanvasElementType.localImage) {
            // Imagen local del dispositivo
            pw.MemoryImage? image;
            if (kIsWeb) {
              if (element.webBytes != null) {
                image = pw.MemoryImage(element.webBytes!);
              }
            } else {
              final file = File(element.imagePath!);
              final imageBytes = await file.readAsBytes();
              image = pw.MemoryImage(imageBytes);
            }

            if (image == null) continue;

            final imgWidth = (element.width ?? 150) * element.scale;
            final imgHeight = (element.height ?? 150) * element.scale;
            final bottom = _bottomFromCanvas(element.position.dy, imgHeight);

            widgets.add(
              pw.Positioned(
                left: element.position.dx,
                bottom: bottom,
                child: pw.Transform.rotate(
                  angle: element.rotation,
                  alignment: pw.Alignment.center,
                  child: pw.Transform(
                    transform: Matrix4.diagonal3Values(
                      element.flipHorizontal ? -1.0 : 1.0,
                      element.flipVertical ? -1.0 : 1.0,
                      1.0,
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Container(
                      width: imgWidth,
                      height: imgHeight,
                      child: pw.Image(image, fit: pw.BoxFit.contain),
                    ),
                  ),
                ),
              ),
            );
          } else if (element.type == CanvasElementType.shape) {
            // Forma geométrica
            final width = (element.width ?? 100.0) * element.scale;
            final height = (element.height ?? 100.0) * element.scale;
            final bottom = _bottomFromCanvas(element.position.dy, height);
            widgets.add(
              pw.Positioned(
                left: element.position.dx,
                bottom: bottom,
                child: pw.Transform.rotate(
                  angle: element.rotation,
                  child: pw.CustomPaint(
                    size: PdfPoint(width, height),
                    painter: (canvas, pdfSize) {
                      _drawShapeOnPdfCanvas(
                        canvas,
                        pdfSize,
                        element.shapeType!,
                        PdfColor.fromInt(element.shapeColor.value),
                        element.strokeWidth,
                      );
                    },
                  ),
                ),
              ),
            );
          } else if (element.type == CanvasElementType.pictogramCard) {
            // Tarjeta de pictograma (imagen + texto)
            final image = await _fetchNetworkImageForPdf(element.imageUrl!);
            if (image != null) {
              final cardWidth = (element.width ?? 150) * element.scale;
              final cardHeight = (element.height ?? 190) * element.scale;
              final imageHeight = cardWidth;
              final textHeight = cardHeight - imageHeight;
              final bottom = _bottomFromCanvas(element.position.dy, cardHeight);

              widgets.add(
                pw.Positioned(
                  left: element.position.dx,
                  bottom: bottom,
                  child: pw.SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: pw.Transform.rotate(
                      angle: element.rotation,
                      alignment: pw.Alignment.center,
                      child: pw.Transform(
                        transform: Matrix4.diagonal3Values(
                          element.flipHorizontal ? -1.0 : 1.0,
                          element.flipVertical ? -1.0 : 1.0,
                          1.0,
                        ),
                        alignment: pw.Alignment.center,
                        child: pw.Container(
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            border: pw.Border.all(
                              color: PdfColors.black,
                              width: 1,
                            ),
                            borderRadius: pw.BorderRadius.circular(8),
                          ),
                          child: pw.Column(
                            children: [
                              // Imagen
                              pw.Container(
                                height: imageHeight,
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Image(image, fit: pw.BoxFit.contain),
                              ),
                              // Texto
                              pw.Container(
                                height: textHeight,
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                alignment: pw.Alignment.center,
                                child: pw.Text(
                                  element.text ?? '',
                                  style: pw.TextStyle(
                                    fontSize: element.fontSize * element.scale,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColor.fromInt(
                                      element.textColor.value,
                                    ),
                                  ),
                                  textAlign: pw.TextAlign.center,
                                  maxLines: 2,
                                  overflow: pw.TextOverflow.clip,
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
          } else if (element.type == CanvasElementType.shadow) {
            // Sombra (imagen en negro) - en PDF se renderiza con filtro de color
            final image = await _fetchNetworkImageForPdf(element.imageUrl!);
            if (image != null) {
              final imgWidth = (element.width ?? 150) * element.scale;
              final double imgHeight;
              if (element.height != null) {
                imgHeight = element.height! * element.scale;
              } else {
                final double imgWidthPx = (image.width ?? 1).toDouble();
                final double imgHeightPx = (image.height ?? 1).toDouble();
                final double ratio = imgHeightPx / imgWidthPx;
                imgHeight = imgWidth * ratio;
              }
              final bottom = _bottomFromCanvas(element.position.dy, imgHeight);

              widgets.add(
                pw.Positioned(
                  left: element.position.dx,
                  bottom: bottom,
                  child: pw.Transform.rotate(
                    angle: element.rotation,
                    alignment: pw.Alignment.center,
                    child: pw.Opacity(
                      opacity: 0.3,
                      child: pw.Container(
                        width: imgWidth,
                        height: imgHeight,
                        child: pw.Image(image, fit: pw.BoxFit.contain),
                      ),
                    ),
                  ),
                ),
              );
            }
          } else if (element.type == CanvasElementType.networkImage) {
            // Imagen de red (ARASAAC y SoyVisual)
            final image = await _fetchNetworkImageForPdf(element.imageUrl!);
            if (image != null) {
              final double imgWidth = (element.width ?? 150) * element.scale;
              final double imgHeight;

              if (element.height != null) {
                imgHeight = element.height! * element.scale;
              } else {
                // Calcular altura manteniendo aspecto real de la imagen
                final double imgWidthPx = (image.width ?? 1).toDouble();
                final double imgHeightPx = (image.height ?? 1).toDouble();
                final double ratio = imgHeightPx / imgWidthPx;
                imgHeight = imgWidth * ratio;
              }

              // Si height es null, usar SizedBox solo con width para mantener aspecto
              // Si height está definido, usar Container con ambas dimensiones
              final pw.Widget imageWidget;
              if (element.height == null) {
                imageWidget = pw.Image(image, fit: pw.BoxFit.fitWidth);
              } else {
                imageWidget = pw.Container(
                  width: imgWidth,
                  height: imgHeight,
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                );
              }

              // Aplicar transformaciones con alignment center para que roten desde el centro
              widgets.add(
                pw.Positioned(
                  left: element.position.dx,
                  bottom: _bottomFromCanvas(element.position.dy, imgHeight),
                  child: pw.SizedBox(
                    width: imgWidth,
                    height: imgHeight,
                    child: pw.Transform.rotate(
                      angle: element.rotation,
                      alignment: pw.Alignment.center,
                      child: pw.Transform(
                        transform: Matrix4.diagonal3Values(
                          element.flipHorizontal ? -1.0 : 1.0,
                          element.flipVertical ? -1.0 : 1.0,
                          1.0,
                        ),
                        alignment: pw.Alignment.center,
                        child: imageWidget,
                      ),
                    ),
                  ),
                ),
              );
            }
          } else if (element.type == CanvasElementType.visualInstructionsBar) {
            // Barra de instrucciones visuales
            final barWidth = (element.width ?? 400) * element.scale;
            final barHeight = (element.height ?? 80) * element.scale;
            final bottom = _bottomFromCanvas(element.position.dy, barHeight);

            final barWidgets = <pw.Widget>[];

            // Pictograma de actividad (con borde azul)
            if (element.activityPictogramUrl != null) {
              final activityImage = await _fetchNetworkImageForPdf(element.activityPictogramUrl!);
              if (activityImage != null) {
                barWidgets.add(
                  pw.Container(
                    width: 60,
                    height: 60,
                    margin: const pw.EdgeInsets.only(right: 8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.blue300, width: 2),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.ClipRRect(
                      horizontalRadius: 4,
                      verticalRadius: 4,
                      child: pw.Image(activityImage, fit: pw.BoxFit.contain),
                    ),
                  ),
                );
              }
            }

            // Pictogramas de materiales
            if (element.materialPictogramUrls != null) {
              for (final materialUrl in element.materialPictogramUrls!) {
                final materialImage = await _fetchNetworkImageForPdf(materialUrl);
                if (materialImage != null) {
                  barWidgets.add(
                    pw.Container(
                      width: 60,
                      height: 60,
                      margin: const pw.EdgeInsets.only(right: 8),
                      child: pw.Image(materialImage, fit: pw.BoxFit.contain),
                    ),
                  );
                }
              }
            }

            widgets.add(
              pw.Positioned(
                left: element.position.dx,
                bottom: bottom,
                child: pw.Transform.rotate(
                  angle: element.rotation,
                  alignment: pw.Alignment.center,
                  child: pw.Container(
                    width: barWidth,
                    height: barHeight,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      border: pw.Border.all(color: PdfColors.grey400, width: 2),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.start,
                        children: barWidgets,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
        } catch (e) {
          debugPrint('Error al procesar elemento: $e');
        }
      }

      // Pie de página del documento (autor, licencia, etc.)
      if (documentFooter.isNotEmpty) {
        widgets.add(
          pw.Positioned(
            bottom: 10,
            left: 20,
            right: _showPageNumbers ? 120 : 20, // Dejar espacio para número de página si existe
            child: pw.Text(
              documentFooter,
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              textAlign: pw.TextAlign.center,
            ),
          ),
        );
      }

      if (_showPageNumbers) {
        widgets.add(
          pw.Positioned(
            bottom: 10,
            right: 20,
            child: pw.Text('Página ${pageIndex + 1} de ${_pages.length}'),
          ),
        );
      }

      // Créditos verticales igual que en el canvas
      if (_showArasaacCredit) {
        widgets.add(
          pw.Positioned(
            left: 10,
            top: 0,
            child: pw.SizedBox(
              height: pageHeight,
              child: pw.Transform.rotate(
                angle: -math.pi / 2, // quarterTurns: 3 equivale a -90 grados
                alignment: pw.Alignment.topLeft,
                child: pw.SizedBox(
                  width: pageHeight - 20,
                  child: pw.Text(
                    _arasaacCredit,
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        );
      }
      if (_showSoyVisualCredit) {
        widgets.add(
          pw.Positioned(
            right: 10,
            top: 0,
            child: pw.SizedBox(
              height: pageHeight,
              child: pw.Transform.rotate(
                angle: -math.pi / 2, // quarterTurns: 3 equivale a -90 grados
                alignment: pw.Alignment.topLeft,
                child: pw.SizedBox(
                  width: pageHeight - 20,
                  child: pw.Text(
                    _soyVisualCredit,
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        );
      }

      final zeroMarginFormat =
          (_pageOrientations[pageIndex]
                  ? PdfPageFormat.a4.landscape
                  : PdfPageFormat.a4)
              .copyWith(
                marginLeft: 0,
                marginTop: 0,
                marginRight: 0,
                marginBottom: 0,
              );

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (pw.Context context) {
            return pw.SizedBox(
              width: pageWidth,
              height: pageHeight,
              child: pw.Stack(children: widgets),
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildPdfTemplate(
    TemplateType template,
    double width,
    double height,
  ) {
    switch (template) {
      case TemplateType.blank:
        return pw.SizedBox(width: width, height: height);
      case TemplateType.lined:
        return pw.CustomPaint(
          size: PdfPoint(width, height),
          painter: (canvas, size) {
            final lineSpacing = 30.0;
            canvas
              ..setStrokeColor(PdfColors.grey300)
              ..setLineWidth(1);
            for (double y = lineSpacing; y < size.y; y += lineSpacing) {
              canvas
                ..moveTo(0, y)
                ..lineTo(size.x, y);
            }
            canvas.strokePath();
          },
        );
      case TemplateType.grid:
        return pw.CustomPaint(
          size: PdfPoint(width, height),
          painter: (canvas, size) {
            final gridSpacing = 30.0;
            canvas
              ..setStrokeColor(PdfColors.grey300)
              ..setLineWidth(1);
            for (double y = gridSpacing; y < size.y; y += gridSpacing) {
              canvas
                ..moveTo(0, y)
                ..lineTo(size.x, y);
            }
            for (double x = gridSpacing; x < size.x; x += gridSpacing) {
              canvas
                ..moveTo(x, 0)
                ..lineTo(x, size.y);
            }
            canvas.strokePath();
          },
        );
      case TemplateType.comic4:
        return pw.CustomPaint(
          size: PdfPoint(width, height),
          painter: (canvas, size) {
            final midX = size.x / 2;
            final midY = size.y / 2;
            final margin = 20.0;
            canvas
              ..setStrokeColor(PdfColors.black)
              ..setLineWidth(3);
            canvas
              ..moveTo(midX, margin)
              ..lineTo(midX, size.y - margin)
              ..moveTo(margin, midY)
              ..lineTo(size.x - margin, midY)
              ..drawRect(
                margin,
                margin,
                size.x - 2 * margin,
                size.y - 2 * margin,
              )
              ..strokePath();
          },
        );
      case TemplateType.comic6:
        return pw.CustomPaint(
          size: PdfPoint(width, height),
          painter: (canvas, size) {
            final thirdY = size.y / 3;
            final halfX = size.x / 2;
            final margin = 20.0;
            canvas
              ..setStrokeColor(PdfColors.black)
              ..setLineWidth(3);
            canvas
              ..moveTo(margin, thirdY)
              ..lineTo(size.x - margin, thirdY)
              ..moveTo(margin, thirdY * 2)
              ..lineTo(size.x - margin, thirdY * 2)
              ..moveTo(halfX, margin)
              ..lineTo(halfX, size.y - margin)
              ..drawRect(
                margin,
                margin,
                size.x - 2 * margin,
                size.y - 2 * margin,
              )
              ..strokePath();
          },
        );
      case TemplateType.twoColumns:
        return pw.CustomPaint(
          size: PdfPoint(width, height),
          painter: (canvas, size) {
            final midX = size.x / 2;
            canvas
              ..setStrokeColor(PdfColors.grey400)
              ..setLineWidth(2)
              ..moveTo(midX, 0)
              ..lineTo(midX, size.y)
              ..strokePath();
          },
        );
      case TemplateType.threeColumns:
        return pw.CustomPaint(
          size: PdfPoint(width, height),
          painter: (canvas, size) {
            final thirdX = size.x / 3;
            canvas
              ..setStrokeColor(PdfColors.grey400)
              ..setLineWidth(2)
              ..moveTo(thirdX, 0)
              ..lineTo(thirdX, size.y)
              ..moveTo(thirdX * 2, 0)
              ..lineTo(thirdX * 2, size.y)
              ..strokePath();
          },
        );
      case TemplateType.shadowMatching:
        return pw.CustomPaint(
          size: PdfPoint(width, height),
          painter: (canvas, size) {
            final margin = 40.0;
            final columnWidth = (size.x - 3 * margin) / 2;
            final rowHeight = (size.y - 2 * margin) / 5;
            canvas
              ..setStrokeColor(PdfColors.grey600)
              ..setLineWidth(2)
              ..moveTo(size.x / 2, margin)
              ..lineTo(size.x / 2, size.y - margin);
            canvas
              ..setStrokeColor(PdfColors.grey300)
              ..setLineWidth(1);
            for (int i = 1; i < 5; i++) {
              final y = margin + rowHeight * i;
              canvas
                ..moveTo(margin, y)
                ..lineTo(size.x - margin, y);
            }
            canvas.strokePath();
            final text = pw.TextStyle(
              color: PdfColors.grey700,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            );
            return pw.Stack(
              children: [
                pw.Positioned(
                  left: margin + columnWidth / 2 - 30,
                  top: 10,
                  child: pw.Text('IMÁGENES', style: text),
                ),
                pw.Positioned(
                  left: size.x / 2 + margin + columnWidth / 2 - 30,
                  top: 10,
                  child: pw.Text('SOMBRAS', style: text),
                ),
              ],
            );
          },
        );
      case TemplateType.puzzle:
        return pw.CustomPaint(
          size: PdfPoint(width, height),
          painter: (canvas, size) {
            const rows = 4;
            const cols = 4;
            final pieceWidth = size.x / cols;
            final pieceHeight = size.y / rows;
            canvas
              ..setStrokeColor(PdfColors.black)
              ..setLineWidth(2.5);
            for (int i = 1; i < rows; i++) {
              canvas
                ..moveTo(0, i * pieceHeight)
                ..lineTo(size.x, i * pieceHeight);
            }
            for (int i = 1; i < cols; i++) {
              canvas
                ..moveTo(i * pieceWidth, 0)
                ..lineTo(i * pieceWidth, size.y);
            }
            canvas
              ..setLineWidth(4.0)
              ..drawRect(0, 0, size.x, size.y)
              ..strokePath();
          },
        );
      case TemplateType.writingPractice:
        // Sin pauta de fondo; las líneas se añaden en los elementos
        return pw.Container();
      case TemplateType.countingPractice:
        return pw.CustomPaint(
          size: PdfPoint(width, height),
          painter: (canvas, size) {
            final margin = 30.0;
            final rowHeight = (size.y - 2 * margin) / 4;
            final colWidth = (size.x - 2 * margin) / 5;
            canvas
              ..setStrokeColor(PdfColors.grey400)
              ..setLineWidth(1.5);
            for (int i = 0; i <= 4; i++) {
              final y = margin + rowHeight * i;
              canvas
                ..moveTo(margin, y)
                ..lineTo(size.x - margin, y);
            }
            for (int i = 0; i <= 5; i++) {
              final x = margin + colWidth * i;
              canvas
                ..moveTo(x, margin)
                ..lineTo(x, size.y - margin);
            }
            canvas.strokePath();
          },
        );
    }
  }

  void _drawShapeOnPdfCanvas(
    PdfGraphics canvas,
    PdfPoint size,
    ShapeType shapeType,
    PdfColor color,
    double strokeWidth,
  ) {
    canvas
      ..setStrokeColor(color)
      ..setLineWidth(strokeWidth);

    switch (shapeType) {
      case ShapeType.line:
        // Si width es 0, es una línea vertical; si height es 0, es horizontal
        if (size.x == 0) {
          // Línea vertical
          canvas
            ..moveTo(0, 0)
            ..lineTo(0, size.y)
            ..strokePath();
        } else {
          // Línea horizontal (comportamiento por defecto)
          canvas
            ..moveTo(0, size.y / 2)
            ..lineTo(size.x, size.y / 2)
            ..strokePath();
        }
        break;
      case ShapeType.circle:
        canvas
          ..drawEllipse(size.x / 2, size.y / 2, size.x / 2, size.y / 2)
          ..strokePath();
        break;
      case ShapeType.rectangle:
        canvas
          ..drawRect(0, 0, size.x, size.y)
          ..strokePath();
        break;
      case ShapeType.arrow:
        canvas
          ..moveTo(0, size.y / 2)
          ..lineTo(size.x * 0.7, size.y / 2)
          ..moveTo(size.x * 0.7, size.y / 2)
          ..lineTo(size.x * 0.5, size.y * 0.3)
          ..moveTo(size.x * 0.7, size.y / 2)
          ..lineTo(size.x * 0.5, size.y * 0.7)
          ..strokePath();
        break;
      case ShapeType.triangle:
        canvas
          ..moveTo(size.x / 2, 0)
          ..lineTo(size.x, size.y)
          ..lineTo(0, size.y)
          ..closePath()
          ..strokePath();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ActivityAppBar(
        canUndo: _historyIndex > 0,
        canRedo: _historyIndex < _history.length - 1,
        isPersisting: _isPersisting,
        sidebarCollapsed: _sidebarCollapsed,
        isLoggedIn: _currentUser != null,
        userLabel: _currentUser?.username ?? 'Invitado',
        userEmail: _currentUser?.username,
        onUndo: _undo,
        onRedo: _redo,
        onClear: _clearCanvas,
        onToggleSidebar: () =>
            setState(() => _sidebarCollapsed = !_sidebarCollapsed),
        onNewProject: _newProject,
        onSaveProject: _promptSaveProject,
        onLoadProject: _showLoadProjectDialog,
        onGeneratePdf: _generatePDF,
        onAuthAction: _currentUser == null ? _showAuthDialog : _logout,
      ),
      body: Row(
        children: [
          SidebarPanel(
            collapsed: _sidebarCollapsed,
            onToggleCollapsed: () =>
                setState(() => _sidebarCollapsed = !_sidebarCollapsed),
            onSelectText: () {
              setState(() {
                _sidebarMode = SidebarMode.text;
              });
            },
            onAddPhoto: _addLocalImage,
            onSelectShapes: () {
              setState(() {
                _sidebarMode = SidebarMode.shapes;
              });
            },
            onSelectArasaac: () {
              setState(() {
                _sidebarMode = SidebarMode.arasaac;
                _searchController.clear();
                _searchResults = [];
              });
            },
            onSelectSoyVisual: () {
              setState(() {
                _sidebarMode = SidebarMode.soyVisual;
                _soyVisualSearchController.clear();
                _soyVisualResults = [];
              });
            },
            onSelectTemplates: () {
              setState(() {
                _sidebarMode = SidebarMode.templates;
              });
            },
            onSelectCreator: () {
              setState(() {
                _sidebarMode = SidebarMode.creador;
              });
            },
            onSelectConfig: () {
              setState(() {
                _sidebarMode = SidebarMode.config;
              });
            },
            onSelectVisualInstructions: () {
              setState(() {
                _sidebarMode = SidebarMode.visualInstructions;
              });
            },
            isTextSelected: _sidebarMode == SidebarMode.text,
            isShapesSelected: _sidebarMode == SidebarMode.shapes,
            isArasaacSelected: _sidebarMode == SidebarMode.arasaac,
            isSoyVisualSelected: _sidebarMode == SidebarMode.soyVisual,
            isTemplatesSelected: _sidebarMode == SidebarMode.templates,
            isCreatorSelected: _sidebarMode == SidebarMode.creador,
            isConfigSelected: _sidebarMode == SidebarMode.config,
            isVisualInstructionsSelected: _sidebarMode == SidebarMode.visualInstructions,
            panel: _buildSidebarPanel(),
          ),
          Expanded(
            child: Container(
              color: Colors.grey[300],
              child: Stack(
                children: [
                  Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Calcular dimensiones según orientación de la página actual
                        final isLandscape = _pageOrientations[_currentPage];
                        final double baseWidth = isLandscape
                            ? _a4HeightPts
                            : _a4WidthPts;
                        final double baseHeight = isLandscape
                            ? _a4WidthPts
                            : _a4HeightPts;

                        final availableWidth = constraints.maxWidth * 0.9;
                        final availableHeight = constraints.maxHeight * 0.9;
                        final scaleToFit =
                            (availableWidth / baseWidth) <
                                (availableHeight / baseHeight)
                            ? availableWidth / baseWidth
                            : availableHeight / baseHeight;

                        if (_canvasSize != Size(baseWidth, baseHeight)) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            setState(() {
                              _canvasSize = Size(baseWidth, baseHeight);
                            });
                          });
                        }

                        // Inicializar el controller con el zoom actual si no está establecido
                        if (_transformationController.value == Matrix4.identity()) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _transformationController.value = Matrix4.identity()
                              ..scale(_canvasZoom, _canvasZoom, 1.0);
                          });
                        }

                        return InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 0.5,
                          maxScale: 2.5,
                          boundaryMargin: const EdgeInsets.all(double.infinity),
                          constrained: false,
                          onInteractionUpdate: (details) {
                            setState(() {
                              _canvasZoom = _transformationController.value.getMaxScaleOnAxis();
                            });
                          },
                          child: Transform.scale(
                            scale: scaleToFit,
                            alignment: Alignment.topLeft,
                            child: Container(
                                  width: baseWidth,
                                  height: baseHeight,
                                  decoration: BoxDecoration(
                                    color: _pageBackgrounds[_currentPage],
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      CustomPaint(
                                        size: Size(baseWidth, baseHeight),
                                        painter: TemplatePainter(_currentTemplate),
                                      ),
                                      GestureDetector(
                                        onTap: () => _selectImage(null),
                                        child: Container(color: Colors.transparent),
                                      ),
                                      ..._canvasImages.map((canvasElement) {
                                        final isSelected =
                                            _selectedImageIds.contains(canvasElement.id);
                                        // Compensación de zoom para bordes de selección
                                        final currentZoom = _transformationController.value.getMaxScaleOnAxis();
                                        final borderWidth = 2 / currentZoom;

                                        Widget content;
                                        if (canvasElement.type == CanvasElementType.text) {
                                          final textWidth =
                                              (canvasElement.width ?? 300.0) * canvasElement.scale;

                                          // Estilo base del texto
                                          final baseStyle = TextStyle(
                                            fontSize: canvasElement.fontSize,
                                            color: canvasElement.textColor,
                                            fontFamily: canvasElement.fontFamily,
                                            fontWeight: canvasElement.isBold
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontStyle: canvasElement.isItalic
                                                ? FontStyle.italic
                                                : FontStyle.normal,
                                            decoration: canvasElement.isUnderline
                                                ? TextDecoration.underline
                                                : TextDecoration.none,
                                          );

                                          content = Container(
                                            width: textWidth,
                                            padding: EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              border: isSelected
                                                  ? Border.all(color: Colors.blue, width: borderWidth)
                                                  : null,
                                            ),
                                            child: Text.rich(
                                              _parseMarkdownToTextSpan(canvasElement.text ?? '', baseStyle),
                                              textAlign: canvasElement.textAlign,
                                            ),
                                          );
                                        } else if (canvasElement.type ==
                                            CanvasElementType.shape) {
                                          final size = Size(
                                            (canvasElement.width ?? 100.0) * canvasElement.scale,
                                            (canvasElement.height ?? 100.0) * canvasElement.scale,
                                          );
                                          content = CustomPaint(
                                            size: size,
                                            painter: ShapePainter(
                                              shapeType: canvasElement.shapeType!,
                                              color: canvasElement.shapeColor,
                                              strokeWidth: canvasElement.strokeWidth,
                                              isSelected: isSelected,
                                              isDashed: canvasElement.isDashed,
                                            ),
                                          );
                                        } else if (canvasElement.type ==
                                            CanvasElementType.pictogramCard) {
                                          final cardWidth =
                                              (canvasElement.width ?? 150) * canvasElement.scale;
                                          final cardHeight =
                                              (canvasElement.height ?? 190) * canvasElement.scale;
                                          content = Container(
                                            width: cardWidth,
                                            height: cardHeight,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                color: isSelected ? Colors.blue : Colors.black,
                                                width: isSelected ? (3 / currentZoom) : (1 / currentZoom),
                                              ),
                                              borderRadius: BorderRadius.circular(8 / currentZoom),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.1),
                                                  blurRadius: 4 / currentZoom,
                                                  offset: Offset(0, 2 / currentZoom),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8 / currentZoom),
                                              child: Column(
                                                children: [
                                                  Expanded(
                                                    flex: 150,
                                                    child: Padding(
                                                      padding: EdgeInsets.all(6 / currentZoom),
                                                      child: CachedNetworkImage(
                                                        imageUrl: canvasElement.imageUrl!,
                                                        fit: BoxFit.contain,
                                                        placeholder: (context, url) =>
                                                            const Center(child: CircularProgressIndicator()),
                                                        errorWidget: (context, url, error) =>
                                                            const Icon(Icons.error),
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    height: 40,
                                                    width: double.infinity,
                                                    color: Colors.grey[200],
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      canvasElement.text ?? '',
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        fontSize: canvasElement.fontSize,
                                                        fontWeight: canvasElement.isBold
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        } else if (canvasElement.type ==
                                            CanvasElementType.visualInstructionsBar) {
                                          final barWidth =
                                              (canvasElement.width ?? 400) * canvasElement.scale;
                                          final barHeight =
                                              (canvasElement.height ?? 80) * canvasElement.scale;

                                          // Construir lista de pictogramas
                                          final List<Widget> pictograms = [];

                                          // Pictograma de actividad (con borde azul)
                                          if (canvasElement.activityPictogramUrl != null) {
                                            pictograms.add(
                                              Container(
                                                width: 60,
                                                height: 60,
                                                margin: const EdgeInsets.only(right: 8),
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.blue, width: 2),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(4),
                                                  child: CachedNetworkImage(
                                                    imageUrl: canvasElement.activityPictogramUrl!,
                                                    fit: BoxFit.contain,
                                                    placeholder: (context, url) =>
                                                        const Center(child: CircularProgressIndicator()),
                                                    errorWidget: (context, url, error) =>
                                                        const Icon(Icons.error),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }

                                          // Pictogramas de materiales (sin borde especial)
                                          if (canvasElement.materialPictogramUrls != null) {
                                            for (final materialUrl in canvasElement.materialPictogramUrls!) {
                                              pictograms.add(
                                                Container(
                                                  width: 60,
                                                  height: 60,
                                                  margin: const EdgeInsets.only(right: 8),
                                                  child: CachedNetworkImage(
                                                    imageUrl: materialUrl,
                                                    fit: BoxFit.contain,
                                                    placeholder: (context, url) =>
                                                        const Center(child: CircularProgressIndicator()),
                                                    errorWidget: (context, url, error) =>
                                                        const Icon(Icons.error),
                                                  ),
                                                ),
                                              );
                                            }
                                          }

                                          content = Container(
                                            width: barWidth,
                                            height: barHeight,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                color: isSelected ? Colors.blue : Colors.grey[400]!,
                                                width: isSelected ? (3 / currentZoom) : (2 / currentZoom),
                                              ),
                                              borderRadius: BorderRadius.circular(8 / currentZoom),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.1),
                                                  blurRadius: 4 / currentZoom,
                                                  offset: Offset(0, 2 / currentZoom),
                                                ),
                                              ],
                                            ),
                                            child: pictograms.isEmpty
                                                ? Center(
                                                    child: Text(
                                                      'Doble clic para añadir pictogramas',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  )
                                                : Padding(
                                                    padding: const EdgeInsets.all(10),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                      children: pictograms,
                                                    ),
                                                  ),
                                          );
                                        } else {
                                          final double scaledWidth =
                                              (canvasElement.width ?? 150.0) * canvasElement.scale;
                                          final double? scaledHeight = canvasElement.height != null
                                              ? canvasElement.height! * canvasElement.scale
                                              : null;
                                          Widget imageWidget = const SizedBox();
                                          if (canvasElement.type ==
                                              CanvasElementType.networkImage) {
                                            imageWidget = CachedNetworkImage(
                                              imageUrl: canvasElement.imageUrl!,
                                              fit: BoxFit.contain,
                                              placeholder: (context, url) =>
                                                  const Center(child: CircularProgressIndicator()),
                                              errorWidget: (context, url, error) => const Icon(Icons.error),
                                            );
                                          } else if (canvasElement.type ==
                                              CanvasElementType.localImage) {
                                            if (kIsWeb) {
                                              if (canvasElement.webBytes != null) {
                                                imageWidget = Image.memory(
                                                  canvasElement.webBytes!,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (context, error, stackTrace) =>
                                                      const Icon(Icons.error),
                                                );
                                              } else {
                                                imageWidget = const Center(
                                                  child: Text(
                                                    'Imagen local no soportada en web',
                                                    style: TextStyle(fontSize: 10),
                                                  ),
                                                );
                                              }
                                            } else {
                                              imageWidget = Image.file(
                                                File(canvasElement.imagePath!),
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) =>
                                                    const Icon(Icons.error),
                                              );
                                            }
                                          }
                                          if (scaledHeight == null) {
                                            content = Container(
                                              width: scaledWidth,
                                              decoration: BoxDecoration(
                                                border: isSelected
                                                    ? Border.all(color: Colors.blue, width: borderWidth)
                                                    : null,
                                              ),
                                              child: Transform(
                                                alignment: Alignment.center,
                                                transform: Matrix4.diagonal3Values(
                                                  canvasElement.flipHorizontal ? -1.0 : 1.0,
                                                  canvasElement.flipVertical ? -1.0 : 1.0,
                                                  1.0,
                                                ),
                                                child: imageWidget,
                                              ),
                                            );
                                          } else {
                                            content = SizedBox(
                                              width: scaledWidth,
                                              height: scaledHeight,
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  Transform(
                                                    alignment: Alignment.center,
                                                    transform: Matrix4.diagonal3Values(
                                                      canvasElement.flipHorizontal ? -1.0 : 1.0,
                                                      canvasElement.flipVertical ? -1.0 : 1.0,
                                                      1.0,
                                                    ),
                                                    child: imageWidget,
                                                  ),
                                                  if (isSelected)
                                                    IgnorePointer(
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          border: Border.all(
                                                            color: Colors.blue,
                                                            width: borderWidth,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            );
                                          }
                                        }
                                        if (isSelected && _selectedImageIds.length == 1) {
                                          content = Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              content,
                                              Positioned.fill(
                                                child: IgnorePointer(
                                                  ignoring: false,
                                                  child: LayoutBuilder(
                                                    builder: (context, constraints) {
                                                      final elementWidth = constraints.maxWidth;
                                                      final elementHeight = constraints.maxHeight;
                                                      return Stack(
                                                        clipBehavior: Clip.none,
                                                        children: [
                                                          _buildResizeHandle(
                                                            Alignment.topLeft,
                                                            canvasElement.id,
                                                            elementWidth,
                                                            elementHeight,
                                                          ),
                                                          _buildResizeHandle(
                                                            Alignment.topRight,
                                                            canvasElement.id,
                                                            elementWidth,
                                                            elementHeight,
                                                          ),
                                                          _buildResizeHandle(
                                                            Alignment.bottomLeft,
                                                            canvasElement.id,
                                                            elementWidth,
                                                            elementHeight,
                                                          ),
                                                          _buildResizeHandle(
                                                            Alignment.bottomRight,
                                                            canvasElement.id,
                                                            elementWidth,
                                                            elementHeight,
                                                          ),
                                                          _buildResizeHandle(
                                                            Alignment.centerLeft,
                                                            canvasElement.id,
                                                            elementWidth,
                                                            elementHeight,
                                                          ),
                                                          _buildResizeHandle(
                                                            Alignment.centerRight,
                                                            canvasElement.id,
                                                            elementWidth,
                                                            elementHeight,
                                                          ),
                                                          if (canvasElement.type ==
                                                                  CanvasElementType.networkImage ||
                                                              canvasElement.type ==
                                                                  CanvasElementType.localImage ||
                                                              canvasElement.type ==
                                                                  CanvasElementType.pictogramCard ||
                                                              canvasElement.type ==
                                                                  CanvasElementType.shape ||
                                                              canvasElement.type ==
                                                                  CanvasElementType.visualInstructionsBar)
                                                            ...[
                                                              _buildResizeHandle(
                                                                Alignment.topCenter,
                                                                canvasElement.id,
                                                                elementWidth,
                                                                elementHeight,
                                                              ),
                                                              _buildResizeHandle(
                                                                Alignment.bottomCenter,
                                                                canvasElement.id,
                                                                elementWidth,
                                                                elementHeight,
                                                              ),
                                                            ],
                                                        ],
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }
                                        return Positioned(
                                          left: canvasElement.position.dx,
                                          top: canvasElement.position.dy,
                                          child: GestureDetector(
                                            onPanUpdate: (details) {
                                              _updateImagePosition(
                                                canvasElement.id,
                                                details.delta,
                                              );
                                            },
                                            onTap: () {
                                              final isMultiSelectKey =
                                                  HardwareKeyboard.instance.isMetaPressed ||
                                                      HardwareKeyboard.instance.isControlPressed;
                                              if (isMultiSelectKey) {
                                                _toggleSelection(canvasElement.id);
                                              } else {
                                                _selectImage(canvasElement.id);
                                              }
                                            },
                                            onDoubleTap: () {
                                              if (canvasElement.type == CanvasElementType.visualInstructionsBar) {
                                                _showEditVisualInstructionsDialog(canvasElement.id);
                                              }
                                            },
                                            onLongPress: () {
                                              _selectImage(canvasElement.id);
                                            },
                                            child: Transform.rotate(
                                              angle: canvasElement.rotation,
                                              child: content,
                                            ),
                                          ),
                                        );
                                      }),
                                      if ((_headerController.text.trim().isNotEmpty ||
                                              _footerController.text.trim().isNotEmpty) &&
                                          (_shouldRenderHeaderFooter(_headerScope, _currentPage) ||
                                              _shouldRenderHeaderFooter(_footerScope, _currentPage)))
                                        Positioned(
                                          left: 20,
                                          right: 20,
                                          top: 10,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (_headerController.text.trim().isNotEmpty &&
                                                  _shouldRenderHeaderFooter(_headerScope, _currentPage))
                                                Text(
                                                  _headerController.text,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              if (_headerController.text.trim().isNotEmpty &&
                                                  _footerController.text.trim().isNotEmpty &&
                                                  _shouldRenderHeaderFooter(_headerScope, _currentPage) &&
                                                  _shouldRenderHeaderFooter(_footerScope, _currentPage))
                                                const SizedBox(height: 4),
                                              if (_footerController.text.trim().isNotEmpty &&
                                                  _shouldRenderHeaderFooter(_footerScope, _currentPage))
                                                Text(
                                                  _footerController.text,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black87,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                            ],
                                          ),
                                        ),
                                      // Pie de página del documento (autor, licencia, etc.)
                                      if (_documentFooterController.text.trim().isNotEmpty)
                                        Positioned(
                                          bottom: 10,
                                          left: 20,
                                          right: _showPageNumbers ? 120 : 20,
                                          child: Text(
                                            _documentFooterController.text,
                                            style: const TextStyle(
                                              fontSize: 8,
                                              color: Colors.black54,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      if (_showPageNumbers)
                                        Positioned(
                                          bottom: 10,
                                          right: 20,
                                          child: Text(
                                            'Página ${_currentPage + 1} de ${_pages.length}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                      if (_showArasaacCredit)
                                        Positioned(
                                          left: 10,
                                          top: 0,
                                          child: SizedBox(
                                            height: baseHeight,
                                            child: RotatedBox(
                                              quarterTurns: 3,
                                              child: SizedBox(
                                                width: baseHeight - 20,
                                                child: Text(
                                                  _arasaacCredit,
                                                  style: const TextStyle(
                                                    fontSize: 8,
                                                    color: Colors.black54,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (_showSoyVisualCredit)
                                        Positioned(
                                          right: 10,
                                          top: 0,
                                          child: SizedBox(
                                            height: baseHeight,
                                            child: RotatedBox(
                                              quarterTurns: 3,
                                              child: SizedBox(
                                                width: baseHeight - 20,
                                                child: Text(
                                                  _soyVisualCredit,
                                                  style: const TextStyle(
                                                    fontSize: 8,
                                                    color: Colors.black54,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: _currentPage > 0
                                    ? () => _goToPage(_currentPage - 1)
                                    : null,
                                tooltip: 'Página anterior',
                              ),
                              Text(
                                'Página ${_currentPage + 1} de ${_pages.length}',
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: _currentPage < _pages.length - 1
                                    ? () => _goToPage(_currentPage + 1)
                                    : null,
                                tooltip: 'Página siguiente',
                              ),
                              const VerticalDivider(),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: _addPage,
                                tooltip: 'Nueva página',
                              ),
                              if (_pages.length > 1)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deletePage(_currentPage),
                                  tooltip: 'Eliminar página actual',
                                ),
                              const VerticalDivider(),
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => _changeZoom(-0.1),
                                tooltip: 'Alejar zoom',
                              ),
                              Text('${(_canvasZoom * 100).round()}%'),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => _changeZoom(0.1),
                                tooltip: 'Acercar zoom',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_selectedImageIds.length == 1)
                    Positioned(
                      bottom: 100,
                      right: 20,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _editBarPosition += details.delta;
                          });
                        },
                        child: Card(
                          elevation: 4,
                          child: Container(
                            width: 60,
                            padding: const EdgeInsets.all(4.0),
                            child: Builder(
                              builder: (context) {
                                final selectedId = _selectedImageIds.first;
                                final selectedElement = _canvasImages.firstWhere(
                                  (e) => e.id == selectedId,
                                  orElse: () => CanvasImage(
                                    id: selectedId,
                                    type: CanvasElementType.text,
                                    position: Offset.zero,
                                  ),
                                );
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Icono de arrastre
                                    const Icon(
                                      Icons.drag_handle,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const Divider(height: 4),
                                    // Tamaño
                                    IconButton(
                                      icon: const Icon(
                                        Icons.zoom_out,
                                        size: 20,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () =>
                                          _updateImageScale(selectedId, -0.1),
                                      tooltip: 'Reducir',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.zoom_in, size: 20),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () =>
                                          _updateImageScale(selectedId, 0.1),
                                      tooltip: 'Aumentar',
                                    ),
                                    const Divider(height: 4),
                                    // Rotación
                                    IconButton(
                                      icon: const Icon(
                                        Icons.rotate_left,
                                        size: 20,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _updateImageRotation(
                                        selectedId,
                                        -0.1745,
                                      ),
                                      tooltip: 'Rotar izquierda',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.rotate_right,
                                        size: 20,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _updateImageRotation(
                                        selectedId,
                                        0.1745,
                                      ),
                                      tooltip: 'Rotar derecha',
                                    ),
                                    const Divider(height: 4),
                                    // Voltear
                                    IconButton(
                                      icon: const Icon(Icons.flip, size: 20),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () =>
                                          _toggleFlipHorizontal(selectedId),
                                      tooltip: 'Voltear H',
                                    ),
                                    IconButton(
                                      icon: Transform.rotate(
                                        angle: 1.5708,
                                        child: const Icon(Icons.flip, size: 20),
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () =>
                                          _toggleFlipVertical(selectedId),
                                      tooltip: 'Voltear V',
                                    ),
                                    const Divider(height: 4),
                                    // Capas
                                    IconButton(
                                      icon: const Icon(
                                        Icons.flip_to_front,
                                        size: 20,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () =>
                                          _bringToFront(selectedId),
                                      tooltip: 'Al frente',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.flip_to_back,
                                        size: 20,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _sendToBack(selectedId),
                                      tooltip: 'Al fondo',
                                    ),
                                    const Divider(height: 4),
                                    // Duplicar
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 20),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () =>
                                          _duplicateElement(selectedId),
                                      tooltip: 'Duplicar',
                                    ),
                                    const Divider(height: 4),
                                    // Eliminar
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _deleteImage(selectedId),
                                      tooltip: 'Eliminar',
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Barra de herramientas para selección múltiple
                  if (_selectedImageIds.length > 1)
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _editBarPosition += details.delta;
                          });
                        },
                        child: Card(
                          elevation: 4,
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Icono de arrastre
                                const Icon(
                                  Icons.drag_handle,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const Divider(height: 8),
                                Text(
                                  '${_selectedImageIds.length} elementos',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Divider(height: 8),
                                const Text(
                                  'Alinear',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Alineación horizontal
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.align_horizontal_left,
                                        size: 18,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: _alignLeft,
                                      tooltip: 'Alinear izquierda',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.align_horizontal_center,
                                        size: 18,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: _alignCenterHorizontal,
                                      tooltip: 'Alinear centro H',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.align_horizontal_right,
                                        size: 18,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: _alignRight,
                                      tooltip: 'Alinear derecha',
                                    ),
                                  ],
                                ),
                                // Alineación vertical
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.align_vertical_top,
                                        size: 18,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: _alignTop,
                                      tooltip: 'Alinear arriba',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.align_vertical_center,
                                        size: 18,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: _alignCenterVertical,
                                      tooltip: 'Alinear centro V',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.align_vertical_bottom,
                                        size: 18,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: _alignBottom,
                                      tooltip: 'Alinear abajo',
                                    ),
                                  ],
                                ),
                                if (_selectedImageIds.length >= 3) ...[
                                  const Divider(height: 8),
                                  const Text(
                                    'Distribuir',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.space_bar,
                                          size: 18,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: _distributeHorizontally,
                                        tooltip: 'Distribuir H',
                                      ),
                                      IconButton(
                                        icon: Transform.rotate(
                                          angle: 1.5708,
                                          child: const Icon(
                                            Icons.space_bar,
                                            size: 18,
                                          ),
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: _distributeVertically,
                                        tooltip: 'Distribuir V',
                                      ),
                                    ],
                                  ),
                                ],
                                const Divider(height: 8),
                                const Text(
                                  'Agrupar',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.group, size: 18),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: _groupSelection,
                                      tooltip: 'Agrupar',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.group_off,
                                        size: 18,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: _ungroupSelection,
                                      tooltip: 'Desagrupar',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarPanel() {
    // Si estamos en modo texto y hay un texto seleccionado, mostrar editor
    if (_sidebarMode == SidebarMode.text &&
        _selectedImageIds.length == 1 &&
        _canvasImages.any(
          (e) =>
              e.id == _selectedImageIds.first &&
              e.type == CanvasElementType.text,
        )) {
      return _buildTextEditorPanel();
    }

    // Según el modo seleccionado
    switch (_sidebarMode) {
      case SidebarMode.text:
        return _buildTextInputPanel();
      case SidebarMode.shapes:
        return _buildShapesPanel();
      case SidebarMode.arasaac:
        return _buildArasaacSearchPanel();
      case SidebarMode.soyVisual:
        return _buildSoyVisualSearchPanel();
      case SidebarMode.templates:
        return TemplateMenuPanel(
          currentTemplate: _currentTemplate,
          onSelected: _setPageTemplate,
        );
      case SidebarMode.config:
        return _buildConfigPanel();
      case SidebarMode.creador:
        return DynamicActivityCreatorPanel(
          onActivitySelected: _handleActivitySelection,
        );
      case SidebarMode.photo:
        return const Center(child: Text('Foto'));
      case SidebarMode.visualInstructions:
        return _buildVisualInstructionsPanel();
    }
  }

  Widget _buildVisualInstructionsPanel() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Instrucciones Visuales',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Añade una barra con pictogramas de actividad y materiales necesarios.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addVisualInstructionsBar,
            icon: const Icon(Icons.add),
            label: const Text('Añadir barra de instrucciones'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            '💡 Consejo:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '• Arrastra la barra para posicionarla donde quieras\n'
            '• Haz doble clic para editar pictogramas\n'
            '• Selecciónala y pulsa Supr para eliminarla',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  void _addVisualInstructionsBar() {
    final newBar = CanvasImage.visualInstructionsBar(
      id: _generateId(),
      position: const Offset(100, 100), // Posición inicial
      activityPictogramUrl: null,
      materialPictogramUrls: [],
    );

    setState(() {
      _canvasImages.add(newBar);
      _saveToHistory();
    });
  }

  Widget _buildConfigPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configuración',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                children: [
                  ChoiceChip(
                    label: const Text('Página'),
                    selected: _configTab == ConfigTab.page,
                    onSelected: (_) =>
                        setState(() => _configTab = ConfigTab.page),
                  ),
                  ChoiceChip(
                    label: const Text('ARASAAC'),
                    selected: _configTab == ConfigTab.arasaac,
                    onSelected: (_) =>
                        setState(() => _configTab = ConfigTab.arasaac),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildConfigContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildConfigContent() {
    switch (_configTab) {
      case ConfigTab.page:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Página',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              'Orientación',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _pageOrientations[_currentPage] = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_pageOrientations[_currentPage]
                          ? const Color(0xFF6A1B9A)
                          : null,
                      foregroundColor: !_pageOrientations[_currentPage]
                          ? Colors.white
                          : null,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.crop_portrait,
                          size: 32,
                          color: !_pageOrientations[_currentPage]
                              ? Colors.white
                              : null,
                        ),
                        const SizedBox(height: 4),
                        const Text('Vertical', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _pageOrientations[_currentPage] = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pageOrientations[_currentPage]
                          ? const Color(0xFF6A1B9A)
                          : null,
                      foregroundColor: _pageOrientations[_currentPage]
                          ? Colors.white
                          : null,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.crop_landscape,
                          size: 32,
                          color: _pageOrientations[_currentPage]
                              ? Colors.white
                              : null,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Horizontal',
                          style: TextStyle(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Logo', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectLogo,
                    icon: const Icon(Icons.image),
                    label: Text(
                      _logoPath == null ? 'Seleccionar logo' : 'Cambiar logo',
                    ),
                  ),
                ),
                if (_logoPath != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _logoPath = null;
                      });
                    },
                    tooltip: 'Eliminar logo',
                  ),
                ],
              ],
            ),
            if (_logoPath != null) ...[
              const SizedBox(height: 8),
              Text('Tamaño: ${_logoSize.round()}px'),
              Slider(
                value: _logoSize,
                min: 30,
                max: 150,
                divisions: 24,
                label: '${_logoSize.round()}px',
                onChanged: (value) {
                  setState(() {
                    _logoSize = value;
                  });
                },
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Crédito ARASAAC'),
              value: _showArasaacCredit,
              onChanged: (v) => setState(() => _showArasaacCredit = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Crédito SoyVisual'),
              value: _showSoyVisualCredit,
              onChanged: (v) => setState(() => _showSoyVisualCredit = v),
            ),
            const SizedBox(height: 16),
            const Text(
              'Color de fondo',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildBgColorButton(Colors.white),
                _buildBgColorButton(Colors.grey[200]!),
                _buildBgColorButton(Colors.yellow[100]!),
                _buildBgColorButton(Colors.blue[50]!),
                _buildBgColorButton(Colors.green[50]!),
                _buildBgColorButton(Colors.pink[50]!),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mostrar número de página en PDF'),
              value: _showPageNumbers,
              onChanged: (value) {
                setState(() {
                  _showPageNumbers = value;
                });
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Título e Instrucciones de la Página Actual',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _headerController,
              decoration: const InputDecoration(
                labelText: 'Título de la página',
                hintText: 'Ej: RELACIONAR SOMBRAS',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _footerController,
              decoration: const InputDecoration(
                labelText: 'Instrucciones de la página',
                hintText: 'Ej: Relaciona cada imagen con su sombra',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Pie de Página del Documento',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              'Aparece en todas las páginas (autor, licencia, etc.)',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _documentFooterController,
              decoration: const InputDecoration(
                labelText: 'Pie de página del documento',
                hintText: 'Ej: Material creado por... bajo licencia CC BY-NC-SA',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (_) => setState(() {}),
            ),
          ],
        );
      case ConfigTab.arasaac:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Opciones de importación de pictogramas ARASAAC',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),

            // Idioma
            const Text('Idioma', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _arasaacConfig.language,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'es', child: Text('Español')),
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'fr', child: Text('Français')),
                DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                DropdownMenuItem(value: 'it', child: Text('Italiano')),
                DropdownMenuItem(value: 'pt', child: Text('Português')),
                DropdownMenuItem(value: 'ca', child: Text('Català')),
                DropdownMenuItem(value: 'eu', child: Text('Euskara')),
                DropdownMenuItem(value: 'gl', child: Text('Galego')),
              ],
              onChanged: (value) {
                if (value != null) {
                  _updateArasaacConfig(
                    _arasaacConfig.copyWith(language: value),
                  );
                }
              },
            ),
            const SizedBox(height: 16),

            // Opciones visuales
            const Text(
              'Apariencia',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Color'),
              subtitle: const Text('Desactivar para blanco y negro'),
              value: _arasaacConfig.color,
              onChanged: (value) {
                _updateArasaacConfig(_arasaacConfig.copyWith(color: value));
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mostrar piel'),
              value: _arasaacConfig.skin,
              onChanged: (value) {
                _updateArasaacConfig(_arasaacConfig.copyWith(skin: value));
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mostrar pelo'),
              value: _arasaacConfig.hair,
              onChanged: (value) {
                _updateArasaacConfig(_arasaacConfig.copyWith(hair: value));
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mostrar identificador'),
              subtitle: const Text('Número del pictograma'),
              value: _arasaacConfig.identifier,
              onChanged: (value) {
                _updateArasaacConfig(
                  _arasaacConfig.copyWith(identifier: value),
                );
              },
            ),
            const SizedBox(height: 16),

            // Color de fondo
            const Text(
              'Color de fondo',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildArasaacBgColorButton(null, 'Sin color'),
                const SizedBox(width: 8),
                _buildArasaacBgColorButton('FFFFFF', 'Blanco'),
                const SizedBox(width: 8),
                _buildArasaacBgColorButton('000000', 'Negro'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildArasaacBgColorButton('FF0000', 'Rojo'),
                const SizedBox(width: 8),
                _buildArasaacBgColorButton('00FF00', 'Verde'),
                const SizedBox(width: 8),
                _buildArasaacBgColorButton('0000FF', 'Azul'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildArasaacBgColorButton('FFFF00', 'Amarillo'),
                const SizedBox(width: 8),
                _buildArasaacBgColorButton('FFA500', 'Naranja'),
                const SizedBox(width: 8),
                _buildArasaacBgColorButton('800080', 'Morado'),
              ],
            ),
            const SizedBox(height: 16),

            // Opciones gramaticales
            const Text(
              'Opciones gramaticales',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Plural'),
              value: _arasaacConfig.plural,
              onChanged: (value) {
                _updateArasaacConfig(_arasaacConfig.copyWith(plural: value));
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tiempo pasado'),
              value: _arasaacConfig.past,
              onChanged: (value) {
                _updateArasaacConfig(_arasaacConfig.copyWith(past: value));
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mostrar acción'),
              value: _arasaacConfig.action,
              onChanged: (value) {
                _updateArasaacConfig(_arasaacConfig.copyWith(action: value));
              },
            ),
          ],
        );
    }
  }

  Widget _buildBgColorButton(Color color) {
    final isSelected = _pageBackgrounds[_currentPage].value == color.value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _pageBackgrounds[_currentPage] = color;
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildArasaacBgColorButton(String? colorHex, String label) {
    final isSelected = _arasaacConfig.backgroundColor == colorHex;
    Color displayColor;

    if (colorHex == null) {
      displayColor = Colors.transparent;
    } else {
      displayColor = Color(int.parse('FF$colorHex', radix: 16));
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _updateArasaacConfig(
            _arasaacConfig.copyWith(backgroundColor: colorHex),
          );
        },
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: colorHex == null ? Colors.white : displayColor,
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey,
              width: isSelected ? 3 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: colorHex == null || colorHex == 'FFFFFF'
                    ? Colors.black
                    : Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextInputPanel() {
    final TextEditingController textController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Agregar Texto',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: 'Escribe tu texto',
              border: OutlineInputBorder(),
              hintText: 'Introduce el texto aquí...',
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  _addText(textController.text);
                  textController.clear();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Añadir al lienzo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShapesPanel() {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildShapeButton('Línea', Icons.remove, ShapeType.line),
        _buildShapeButton('Círculo', Icons.circle_outlined, ShapeType.circle),
        _buildShapeButton(
          'Rectángulo',
          Icons.square_outlined,
          ShapeType.rectangle,
        ),
        _buildShapeButton('Flecha', Icons.arrow_forward, ShapeType.arrow),
        _buildShapeButton(
          'Triángulo',
          Icons.change_history,
          ShapeType.triangle,
        ),
      ],
    );
  }

  Widget _buildShapeButton(String label, IconData icon, ShapeType shapeType) {
    return ElevatedButton(
      onPressed: () => _addShape(shapeType),
      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildTextEditorPanel() {
    final selectedId = _selectedImageIds.first;
    final selectedElement = _canvasImages.firstWhere(
      (e) => e.id == selectedId,
      orElse: () => CanvasImage(
        id: selectedId,
        type: CanvasElementType.text,
        position: Offset.zero,
      ),
    );

    // Controller local para manejar la selección de texto
    final textController = TextEditingController(text: selectedElement.text);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Editar Texto',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Barra de herramientas de formato (como Word)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Primera fila: Formato de texto
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.format_bold, size: 20),
                      tooltip: 'Negrita (Ctrl+B)',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      onPressed: () => _applySelectionFormat(textController, selectedId, 'bold'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_italic, size: 20),
                      tooltip: 'Cursiva (Ctrl+I)',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      onPressed: () => _applySelectionFormat(textController, selectedId, 'italic'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_underline, size: 20),
                      tooltip: 'Subrayado (Ctrl+U)',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      onPressed: () => _applySelectionFormat(textController, selectedId, 'underline'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Segunda fila: Alineación
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.format_align_left, size: 20),
                      tooltip: 'Alinear a la izquierda',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      style: IconButton.styleFrom(
                        backgroundColor: selectedElement.textAlign == TextAlign.left
                            ? Colors.blue.withOpacity(0.2)
                            : null,
                      ),
                      onPressed: () => _updateTextAlign(selectedId, TextAlign.left),
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_align_center, size: 20),
                      tooltip: 'Centrar',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      style: IconButton.styleFrom(
                        backgroundColor: selectedElement.textAlign == TextAlign.center
                            ? Colors.blue.withOpacity(0.2)
                            : null,
                      ),
                      onPressed: () => _updateTextAlign(selectedId, TextAlign.center),
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_align_right, size: 20),
                      tooltip: 'Alinear a la derecha',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      style: IconButton.styleFrom(
                        backgroundColor: selectedElement.textAlign == TextAlign.right
                            ? Colors.blue.withOpacity(0.2)
                            : null,
                      ),
                      onPressed: () => _updateTextAlign(selectedId, TextAlign.right),
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_align_justify, size: 20),
                      tooltip: 'Justificar',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      style: IconButton.styleFrom(
                        backgroundColor: selectedElement.textAlign == TextAlign.justify
                            ? Colors.blue.withOpacity(0.2)
                            : null,
                      ),
                      onPressed: () => _updateTextAlign(selectedId, TextAlign.justify),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Campo de texto con selección
          TextField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: 'Contenido',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
              ),
              hintText: 'Selecciona texto y usa los botones para dar formato',
            ),
            maxLines: 5,
            onChanged: (value) => _updateText(selectedId, value),
          ),
          const SizedBox(height: 16),
          const Text('Fuente', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: selectedElement.fontFamily,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(
                value: 'ColeCarreira',
                child: Text(
                  'Cole Carreira',
                  style: TextStyle(fontFamily: 'ColeCarreira'),
                ),
              ),
              DropdownMenuItem(
                value: 'EscolarG',
                child: Text(
                  'Escolar G',
                  style: TextStyle(fontFamily: 'EscolarG'),
                ),
              ),
              DropdownMenuItem(
                value: 'EscolarP',
                child: Text(
                  'Escolar P',
                  style: TextStyle(fontFamily: 'EscolarP'),
                ),
              ),
              DropdownMenuItem(
                value: 'Trace',
                child: Text('Trace', style: TextStyle(fontFamily: 'Trace')),
              ),
              DropdownMenuItem(
                value: 'Massallera',
                child: Text(
                  'Massallera',
                  style: TextStyle(fontFamily: 'Massallera'),
                ),
              ),
              DropdownMenuItem(value: 'Roboto', child: Text('Roboto')),
              DropdownMenuItem(value: 'Arial', child: Text('Arial')),
              DropdownMenuItem(value: 'Courier', child: Text('Courier')),
              DropdownMenuItem(
                value: 'Times New Roman',
                child: Text('Times New Roman'),
              ),
              DropdownMenuItem(value: 'Georgia', child: Text('Georgia')),
              DropdownMenuItem(value: 'Verdana', child: Text('Verdana')),
            ],
            onChanged: (value) {
              if (value != null) _updateTextFontFamily(selectedId, value);
            },
          ),
          const SizedBox(height: 16),
          const Text('Tamaño', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () => _updateTextFontSize(
                  selectedId,
                  selectedElement.fontSize - 2,
                ),
              ),
              Expanded(
                child: Slider(
                  value: selectedElement.fontSize,
                  min: 8,
                  max: 72,
                  divisions: 32,
                  label: selectedElement.fontSize.round().toString(),
                  onChanged: (value) => _updateTextFontSize(selectedId, value),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _updateTextFontSize(
                  selectedId,
                  selectedElement.fontSize + 2,
                ),
              ),
            ],
          ),
          Text(
            'Tamaño: ${selectedElement.fontSize.round()}',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),
          const Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildColorButton(
                Colors.black,
                selectedElement.textColor,
                selectedId,
              ),
              _buildColorButton(
                Colors.red,
                selectedElement.textColor,
                selectedId,
              ),
              _buildColorButton(
                Colors.blue,
                selectedElement.textColor,
                selectedId,
              ),
              _buildColorButton(
                Colors.green,
                selectedElement.textColor,
                selectedId,
              ),
              _buildColorButton(
                Colors.yellow,
                selectedElement.textColor,
                selectedId,
              ),
              _buildColorButton(
                Colors.orange,
                selectedElement.textColor,
                selectedId,
              ),
              _buildColorButton(
                Colors.purple,
                selectedElement.textColor,
                selectedId,
              ),
              _buildColorButton(
                Colors.pink,
                selectedElement.textColor,
                selectedId,
              ),
              _buildColorButton(
                Colors.brown,
                selectedElement.textColor,
                selectedId,
              ),
              _buildColorButton(
                Colors.grey,
                selectedElement.textColor,
                selectedId,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color, Color currentColor, String elementId) {
    final isSelected = color.value == currentColor.value;
    return GestureDetector(
      onTap: () => _updateTextColor(elementId, color),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildShapeColorButton(
    Color color,
    Color currentColor,
    String elementId,
  ) {
    final isSelected = color.value == currentColor.value;
    return GestureDetector(
      onTap: () => _updateShapeColor(elementId, color),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildResizeHandle(
    Alignment alignment,
    String id,
    double elementWidth,
    double elementHeight,
  ) {
    // Obtener el zoom actual para compensar el tamaño de los handles
    final currentZoom = _transformationController.value.getMaxScaleOnAxis();
    final zoomCompensation = 1.0 / currentZoom;

    // Determinar el tipo de manejador según el alignment
    final bool isCorner = alignment.x != 0 && alignment.y != 0;
    final bool isHorizontal = alignment.y == 0 && alignment.x != 0;
    final bool isVertical = alignment.x == 0 && alignment.y != 0;

    Widget handleWidget;
    double handleWidth;
    double handleHeight;

    if (isCorner) {
      // Esquinas: círculo para redimensionamiento proporcional
      // Compensar por el zoom para que siempre se vean del mismo tamaño
      handleWidth = 14 * zoomCompensation;
      handleHeight = 14 * zoomCompensation;
      handleWidget = Container(
        width: handleWidth,
        height: handleHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.blue, width: 2 * zoomCompensation),
          shape: BoxShape.circle,
        ),
      );
    } else if (isHorizontal) {
      // Laterales horizontales: rectángulo vertical para ajuste de ancho
      handleWidth = 8 * zoomCompensation;
      handleHeight = 20 * zoomCompensation;
      handleWidget = Container(
        width: handleWidth,
        height: handleHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.blue, width: 2 * zoomCompensation),
          borderRadius: BorderRadius.circular(2 * zoomCompensation),
        ),
      );
    } else if (isVertical) {
      // Laterales verticales: rectángulo horizontal para ajuste de alto
      handleWidth = 20 * zoomCompensation;
      handleHeight = 8 * zoomCompensation;
      handleWidget = Container(
        width: handleWidth,
        height: handleHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.blue, width: 2 * zoomCompensation),
          borderRadius: BorderRadius.circular(2 * zoomCompensation),
        ),
      );
    } else {
      // Fallback
      handleWidth = 14 * zoomCompensation;
      handleHeight = 14 * zoomCompensation;
      handleWidget = Container(
        width: handleWidth,
        height: handleHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.blue, width: 2 * zoomCompensation),
          shape: BoxShape.circle,
        ),
      );
    }

    // Calcular posición basada en el alignment y el tamaño del elemento
    // Los handles se posicionan DENTRO del borde del objeto
    double left = 0;
    double top = 0;

    // Posición horizontal (dentro del borde)
    if (alignment.x == -1) {
      left = 0; // Completamente dentro, pegado al borde izquierdo
    } else if (alignment.x == 0) {
      left = (elementWidth - handleWidth) / 2;
    } else if (alignment.x == 1) {
      left = elementWidth - handleWidth; // Completamente dentro, pegado al borde derecho
    }

    // Posición vertical (dentro del borde)
    if (alignment.y == -1) {
      top = 0; // Completamente dentro, pegado al borde superior
    } else if (alignment.y == 0) {
      top = (elementHeight - handleHeight) / 2;
    } else if (alignment.y == 1) {
      top = elementHeight - handleHeight; // Completamente dentro, pegado al borde inferior
    }

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanUpdate: (details) => _resizeElement(id, details.delta, alignment),
        child: handleWidget,
      ),
    );
  }

  Widget _buildArasaacSearchPanel() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar pictogramas... (pulsa Enter)',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onSubmitted: _searchPictograms,
                textInputAction: TextInputAction.search,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pictograma'),
                subtitle: const Text(''),
                secondary: Icon(
                  _addAsCard ? Icons.credit_card : Icons.image,
                  color: _addAsCard ? Colors.green : Colors.blue,
                ),
                value: _addAsCard,
                onChanged: (value) {
                  setState(() {
                    _addAsCard = value;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator())
              : _searchResults.isEmpty
              ? const Center(child: Text('Busca pictogramas de ARASAAC'))
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final image = _searchResults[index];
                    final keyword = image.keywords.isNotEmpty
                        ? image.keywords.first
                        : 'ID: ${image.id}';

                    return GestureDetector(
                      onTap: () {
                        if (_addAsCard) {
                          _addPictogramCard(image.imageUrl, keyword);
                        } else {
                          _addImageToCanvas(image.imageUrl);
                        }
                      },
                      onLongPress: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (context) => Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 40,
                                  height: 4,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const Text(
                                  'Opciones de pictograma',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  leading: const Icon(
                                    Icons.image,
                                    color: Colors.blue,
                                  ),
                                  title: const Text('Solo imagen'),
                                  subtitle: const Text(
                                    'Añade el pictograma sin texto',
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _addImageToCanvas(image.imageUrl);
                                  },
                                ),
                                const Divider(),
                                ListTile(
                                  leading: const Icon(
                                    Icons.credit_card,
                                    color: Colors.green,
                                  ),
                                  title: const Text('Tarjeta con palabra'),
                                  subtitle: Text('Añade tarjeta: "$keyword"'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _addPictogramCard(image.imageUrl, keyword);
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 2,
                        color: _addAsCard ? Colors.green[50] : null,
                        child: Stack(
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: CachedNetworkImage(
                                      imageUrl: image.imageUrl,
                                      placeholder: (context, url) =>
                                          const CircularProgressIndicator(),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                Container(
                                  color: _addAsCard
                                      ? Colors.green[100]
                                      : Colors.grey[100],
                                  padding: const EdgeInsets.all(4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_addAsCard)
                                        const Icon(
                                          Icons.credit_card,
                                          size: 12,
                                          color: Colors.green,
                                        ),
                                      if (_addAsCard) const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          keyword,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: _addAsCard
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.more_vert,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (_addAsCard)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.credit_card,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSoyVisualSearchPanel() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _soyVisualSearchController,
                decoration: InputDecoration(
                  hintText: 'Buscar imágenes SoyVisual...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () =>
                        _searchSoyVisual(_soyVisualSearchController.text),
                    tooltip: 'Buscar',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onSubmitted: _searchSoyVisual,
                textInputAction: TextInputAction.search,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pictograma'),
                subtitle: const Text(''),
                secondary: Icon(
                  _addAsCard ? Icons.credit_card : Icons.image,
                  color: _addAsCard ? Colors.green : Colors.blue,
                ),
                value: _addAsCard,
                onChanged: (value) {
                  setState(() {
                    _addAsCard = value;
                  });
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ToggleButtons(
            isSelected: [
              _soyVisualCategory == SoyVisualCategory.photos,
              _soyVisualCategory == SoyVisualCategory.sheets,
            ],
            onPressed: (index) {
              final selected = index == 0
                  ? SoyVisualCategory.photos
                  : SoyVisualCategory.sheets;
              if (selected == _soyVisualCategory) return;
              setState(() {
                _soyVisualCategory = selected;
              });
              if (_lastSoyVisualQuery.isNotEmpty) {
                _searchSoyVisual(_lastSoyVisualQuery);
              }
            },
            borderRadius: BorderRadius.circular(8),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Fotos'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Láminas'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isSoyVisualSearching
              ? const Center(child: CircularProgressIndicator())
              : _soyVisualResults.isEmpty
              ? Center(
                  child: Text(
                    _lastSoyVisualQuery.isEmpty
                        ? 'Busca imágenes de SoyVisual'
                        : 'No se encontraron resultados para "$_lastSoyVisualQuery"',
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _soyVisualResults.length,
                  itemBuilder: (context, index) {
                    final image = _soyVisualResults[index];
                    final isSheet =
                        _soyVisualCategory == SoyVisualCategory.sheets;
                    return GestureDetector(
                      onTap: () {
                        if (_addAsCard) {
                          _addPictogramCard(image.image.src, image.title);
                        } else {
                          _addImageToCanvas(image.image.src, fullSize: isSheet);
                        }
                      },
                      child: Card(
                        elevation: 2,
                        color: _addAsCard ? Colors.green[50] : null,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CachedNetworkImage(
                                  imageUrl: image.thumbnail.src,
                                  placeholder: (context, url) =>
                                      const CircularProgressIndicator(),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_addAsCard)
                                    const Icon(
                                      Icons.credit_card,
                                      size: 12,
                                      color: Colors.green,
                                    ),
                                  if (_addAsCard) const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      image.title,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: _addAsCard
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _soyVisualSearchController.dispose();
    _headerController.dispose();
    _footerController.dispose();
    super.dispose();
  }
}

// Diálogo de configuración para actividad de instrucciones
class _InstructionsConfigDialog extends StatefulWidget {
  @override
  State<_InstructionsConfigDialog> createState() =>
      _InstructionsConfigDialogState();
}

class _InstructionsConfigDialogState extends State<_InstructionsConfigDialog> {
  RangeValues _targetRange = const RangeValues(1, 3);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Actividad de Instrucciones (Rodea)'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Usa los objetos del canvas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecciona el rango de cantidad que deben encontrarse.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            const Text('Cantidad de cada objetivo (mín-máx)'),
            RangeSlider(
              values: _targetRange,
              min: 1,
              max: 10,
              divisions: 9,
              labels: RangeLabels(
                _targetRange.start.round().toString(),
                _targetRange.end.round().toString(),
              ),
              onChanged: (values) {
                if (values.end - values.start >= 0) {
                  setState(() => _targetRange = values);
                }
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Mín: ${_targetRange.start.round()}'),
                Text('Máx: ${_targetRange.end.round()}'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'min': _targetRange.start.round(),
              'max': _targetRange.end.round(),
            });
          },
          child: const Text('Generar'),
        ),
      ],
    );
  }
}

// Diálogo de configuración para vocabulario por sílaba
class _SyllableVocabularyConfigDialog extends StatefulWidget {
  @override
  State<_SyllableVocabularyConfigDialog> createState() =>
      _SyllableVocabularyConfigDialogState();
}

class _SyllableVocabularyConfigDialogState
    extends State<_SyllableVocabularyConfigDialog> {
  final TextEditingController _syllableController = TextEditingController();
  String _syllablePosition = 'start';
  int _numWords = 9;
  bool _usePictograms = true;

  @override
  void dispose() {
    _syllableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Vocabulario por Sílaba'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Introduce la sílaba (ej: pa, ma, sa, la):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _syllableController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Sílaba',
                hintText: 'pa',
              ),
              textCapitalization: TextCapitalization.none,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'Posición de la sílaba:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            RadioListTile<String>(
              title: const Text('Empieza por'),
              value: 'start',
              groupValue: _syllablePosition,
              onChanged: (value) {
                setState(() {
                  _syllablePosition = value!;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<String>(
              title: const Text('Termina en'),
              value: 'end',
              groupValue: _syllablePosition,
              onChanged: (value) {
                setState(() {
                  _syllablePosition = value!;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            const Text(
              'Número de palabras:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _numWords.toDouble(),
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: _numWords.toString(),
                    onChanged: (value) {
                      setState(() {
                        _numWords = value.toInt();
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    _numWords.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Tipo de imagen:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            RadioListTile<bool>(
              title: const Text('Pictogramas'),
              value: true,
              groupValue: _usePictograms,
              onChanged: (value) {
                setState(() {
                  _usePictograms = value!;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<bool>(
              title: const Text('Dibujos'),
              value: false,
              groupValue: _usePictograms,
              onChanged: (value) {
                setState(() {
                  _usePictograms = value!;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final text = _syllableController.text.trim().toLowerCase();
            if (text.isNotEmpty && text.length <= 3) {
              Navigator.of(context).pop({
                'syllable': text,
                'position': _syllablePosition,
                'numWords': _numWords,
                'usePictograms': _usePictograms,
              });
            }
          },
          child: const Text('Generar'),
        ),
      ],
    );
  }
}

// Diálogo de configuración para campo semántico
class _SemanticFieldConfigDialog extends StatefulWidget {
  @override
  State<_SemanticFieldConfigDialog> createState() =>
      _SemanticFieldConfigDialogState();
}

class _SemanticFieldConfigDialogState
    extends State<_SemanticFieldConfigDialog> {
  int _numImages = 15;
  bool _usePictograms = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configuración de Campo Semántico'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Número de imágenes:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _numImages.toDouble(),
                  min: 1,
                  max: 25,
                  divisions: 24,
                  label: _numImages.toString(),
                  onChanged: (value) {
                    setState(() {
                      _numImages = value.toInt();
                    });
                  },
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  _numImages.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Tipo de imagen:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('Pictogramas'),
                  value: true,
                  groupValue: _usePictograms,
                  onChanged: (value) {
                    setState(() {
                      _usePictograms = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('Dibujos'),
                  value: false,
                  groupValue: _usePictograms,
                  onChanged: (value) {
                    setState(() {
                      _usePictograms = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(
              context,
            ).pop({'numImages': _numImages, 'usePictograms': _usePictograms});
          },
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}

// CustomPainter para dibujar formas
class ShapePainter extends CustomPainter {
  final ShapeType shapeType;
  final Color color;
  final double strokeWidth;
  final bool isSelected;
  final bool isDashed;

  ShapePainter({
    required this.shapeType,
    required this.color,
    required this.strokeWidth,
    this.isSelected = false,
    this.isDashed = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Aplicar estilo discontinuo si es necesario
    if (isDashed) {
      final dashWidth = 5.0;
      final dashSpace = 5.0;

      switch (shapeType) {
        case ShapeType.rectangle:
          // Dibujar rectángulo con líneas discontinuas
          _drawDashedRect(canvas, size, paint, dashWidth, dashSpace);
          return;
        default:
          // Para otras formas, usar el estilo normal por ahora
          break;
      }
    }

    if (isSelected) {
      final selectionPaint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawRect(
        Rect.fromLTWH(-2, -2, size.width + 4, size.height + 4),
        selectionPaint,
      );
    }

    switch (shapeType) {
      case ShapeType.line:
        // Si width es 0, es una línea vertical; si height es 0, es horizontal
        if (isDashed) {
          // Líneas discontinuas
          final dashWidth = 5.0;
          final dashSpace = 5.0;

          if (size.width == 0) {
            // Línea vertical discontinua
            _drawDashedVerticalLine(
              canvas,
              size.height,
              paint,
              dashWidth,
              dashSpace,
            );
          } else {
            // Línea horizontal discontinua
            _drawDashedHorizontalLine(
              canvas,
              size.width,
              size.height,
              paint,
              dashWidth,
              dashSpace,
            );
          }
        } else {
          // Líneas continuas
          if (size.width == 0) {
            // Línea vertical
            canvas.drawLine(Offset(0, 0), Offset(0, size.height), paint);
          } else {
            // Línea horizontal (comportamiento por defecto)
            canvas.drawLine(
              Offset(0, size.height / 2),
              Offset(size.width, size.height / 2),
              paint,
            );
          }
        }
        break;
      case ShapeType.circle:
        canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          size.width / 2,
          paint,
        );
        break;
      case ShapeType.rectangle:
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
        break;
      case ShapeType.arrow:
        final arrowPath = Path();
        arrowPath.moveTo(0, size.height / 2);
        arrowPath.lineTo(size.width * 0.7, size.height / 2);
        arrowPath.moveTo(size.width * 0.7, size.height / 2);
        arrowPath.lineTo(size.width * 0.5, size.height * 0.3);
        arrowPath.moveTo(size.width * 0.7, size.height / 2);
        arrowPath.lineTo(size.width * 0.5, size.height * 0.7);
        canvas.drawPath(arrowPath, paint);
        break;
      case ShapeType.triangle:
        final trianglePath = Path();
        trianglePath.moveTo(size.width / 2, 0);
        trianglePath.lineTo(size.width, size.height);
        trianglePath.lineTo(0, size.height);
        trianglePath.close();
        canvas.drawPath(trianglePath, paint);
        break;
    }
  }

  void _drawDashedRect(
    Canvas canvas,
    Size size,
    Paint paint,
    double dashWidth,
    double dashSpace,
  ) {
    // Dibujar los 4 lados del rectángulo con líneas discontinuas
    _drawDashedLine(
      canvas,
      Offset(0, 0),
      Offset(size.width, 0),
      paint,
      dashWidth,
      dashSpace,
    ); // Top
    _drawDashedLine(
      canvas,
      Offset(size.width, 0),
      Offset(size.width, size.height),
      paint,
      dashWidth,
      dashSpace,
    ); // Right
    _drawDashedLine(
      canvas,
      Offset(size.width, size.height),
      Offset(0, size.height),
      paint,
      dashWidth,
      dashSpace,
    ); // Bottom
    _drawDashedLine(
      canvas,
      Offset(0, size.height),
      Offset(0, 0),
      paint,
      dashWidth,
      dashSpace,
    ); // Left
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double dashWidth,
    double dashSpace,
  ) {
    final totalDistance = (end - start).distance;
    final dashCount = (totalDistance / (dashWidth + dashSpace)).floor();

    for (int i = 0; i < dashCount; i++) {
      final t1 = (i * (dashWidth + dashSpace)) / totalDistance;
      final t2 = ((i * (dashWidth + dashSpace)) + dashWidth) / totalDistance;

      final p1 = Offset.lerp(start, end, t1)!;
      final p2 = Offset.lerp(start, end, t2.clamp(0.0, 1.0))!;

      canvas.drawLine(p1, p2, paint);
    }
  }

  void _drawDashedHorizontalLine(
    Canvas canvas,
    double width,
    double height,
    Paint paint,
    double dashWidth,
    double dashSpace,
  ) {
    final y = height / 2;
    _drawDashedLine(
      canvas,
      Offset(0, y),
      Offset(width, y),
      paint,
      dashWidth,
      dashSpace,
    );
  }

  void _drawDashedVerticalLine(
    Canvas canvas,
    double height,
    Paint paint,
    double dashWidth,
    double dashSpace,
  ) {
    _drawDashedLine(
      canvas,
      Offset(0, 0),
      Offset(0, height),
      paint,
      dashWidth,
      dashSpace,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Diálogo de configuración para actividad de Conciencia Fonológica
class _PhonologicalAwarenessConfigDialog extends StatefulWidget {
  @override
  _PhonologicalAwarenessConfigDialogState createState() =>
      _PhonologicalAwarenessConfigDialogState();
}

class _PhonologicalAwarenessConfigDialogState
    extends State<_PhonologicalAwarenessConfigDialog> {
  String _selectedFont = 'ColeCarreira';
  bool _uppercase = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configuración de Conciencia Fonológica'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tipo de letra:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _selectedFont,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: 'ColeCarreira',
                  child: Text(
                    'Cole Carreira',
                    style: TextStyle(fontFamily: 'ColeCarreira'),
                  ),
                ),
                DropdownMenuItem(
                  value: 'EscolarG',
                  child: Text(
                    'Escolar G',
                    style: TextStyle(fontFamily: 'EscolarG'),
                  ),
                ),
                DropdownMenuItem(
                  value: 'EscolarP',
                  child: Text(
                    'Escolar P',
                    style: TextStyle(fontFamily: 'EscolarP'),
                  ),
                ),
                DropdownMenuItem(
                  value: 'Trace',
                  child: Text('Trace', style: TextStyle(fontFamily: 'Trace')),
                ),
                DropdownMenuItem(
                  value: 'Massallera',
                  child: Text(
                    'Massallera',
                    style: TextStyle(fontFamily: 'Massallera'),
                  ),
                ),
                DropdownMenuItem(
                  value: 'Roboto',
                  child: Text(
                    'Roboto (Normal)',
                    style: TextStyle(fontFamily: 'Roboto'),
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedFont = value);
                }
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Formato de texto:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            RadioListTile<bool>(
              title: const Text('MAYÚSCULAS'),
              value: true,
              dense: true,
              contentPadding: EdgeInsets.zero,
              groupValue: _uppercase,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _uppercase = value);
                }
              },
            ),
            RadioListTile<bool>(
              title: const Text('minúsculas'),
              value: false,
              dense: true,
              contentPadding: EdgeInsets.zero,
              groupValue: _uppercase,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _uppercase = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(
              context,
            ).pop({'fontFamily': _selectedFont, 'uppercase': _uppercase});
          },
          child: const Text('Generar'),
        ),
      ],
    );
  }
}

// Diálogo de selección de etiquetas
class _LabelSelectionDialog extends StatefulWidget {
  @override
  _LabelSelectionDialogState createState() => _LabelSelectionDialogState();
}

class _LabelSelectionDialogState extends State<_LabelSelectionDialog> {
  final List<String> _labels = List.generate(
    34,
    (index) => 'assets/etiquetasCajas/etiqueta_${index + 1}.png',
  );

  String? _selectedLabel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Selecciona una etiqueta para la caja'),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 3.33, // Proporción 2000x600 = 10:3
          ),
          itemCount: _labels.length,
          itemBuilder: (context, index) {
            final label = _labels[index];
            final isSelected = _selectedLabel == label;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedLabel = label;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey,
                    width: isSelected ? 3 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(label, fit: BoxFit.cover),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _selectedLabel != null
              ? () => Navigator.of(context).pop(_selectedLabel)
              : null,
          child: const Text('Seleccionar'),
        ),
      ],
    );
  }
}
