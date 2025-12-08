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
import 'services/arasaac_service.dart';
import 'services/soy_visual_service.dart';
import 'models/canvas_image.dart';
import 'models/soy_visual.dart';
import 'models/project_data.dart';
import 'models/user_account.dart';
import 'services/user_service.dart';
import 'widgets/template_menu.dart';
import 'widgets/activity_creator_panel.dart';
import 'widgets/activity_app_bar.dart';
import 'widgets/sidebar_panel.dart';
import 'actividades/shadow_matching_activity.dart';
import 'actividades/puzzle_activity.dart';
import 'actividades/writing_practice_activity.dart';
import 'actividades/counting_activity.dart';
import 'actividades/series_activity.dart' as series_activity;
import 'actividades/symmetry_activity.dart' as symmetry_activity;
import 'actividades/syllable_vocabulary_activity.dart' as syllable_activity;
import 'actividades/semantic_field_activity.dart' as semantic_activity;
import 'actividades/instructions_activity.dart' as instructions_activity;
import 'actividades/phrases_activity.dart' as phrases_activity;
import 'actividades/card_activity.dart' as card_activity;

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ActivityCreatorPage(),
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
}

enum ConfigTab { background, pagination, headerFooter, arasaac }

class _ActivityCreatorPageState extends State<ActivityCreatorPage> {
  // A4 en puntos (pts) para PDF: 1 punto = 1/72 pulgadas
  // A4 = 210mm x 297mm = 8.27" x 11.69" = 595.28 x 841.89 pts
  static const double _a4WidthPts = 595.28; // A4 ancho en puntos
  static const double _a4HeightPts = 841.89; // A4 alto en puntos
  late ArasaacService _arasaacService;
  final SoyVisualService _soyVisualService = SoyVisualService();
  final UserService _userService = UserService();
  UserAccount? _currentUser;
  String? _activeProjectId;
  bool _isPersisting = false;
  bool _sidebarCollapsed = false;
  static const String _arasaacCredit =
      'Autor pictogramas: Sergio Palao. Origen: ARASAAC (http://www.arasaac.org). Licencia: CC (BY-NC-SA). Propiedad: Gobierno de Aragón (España)';
  static const String _soyVisualCredit =
      'Las fotografías/ láminas ilustradas utilizados a partir del API #Soyvisual son parte de una obra colectiva propiedad de la Fundación Orange y han sido creados bajo licencia Creative Commons (BY-NC-SA)';

  // Configuración de ARASAAC
  ArasaacConfig _arasaacConfig = const ArasaacConfig();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _soyVisualSearchController =
      TextEditingController();
  final TextEditingController _headerController = TextEditingController();
  final TextEditingController _footerController = TextEditingController();
  List<ArasaacImage> _searchResults = [];
  List<SoyVisualElement> _soyVisualResults = [];
  List<List<CanvasImage>> _pages = [
    [],
  ]; // Lista de páginas, cada página tiene sus imágenes
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
  ConfigTab _configTab = ConfigTab.background;
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
  double _viewScale = 1.0; // factor pantalla->lienzo
  Offset _editBarPosition = const Offset(
    20,
    20,
  ); // Posición de la barra de edición

  // Sistema de historial para undo/redo
  final List<List<List<CanvasImage>>> _history = [[]]; // Historial de estados
  int _historyIndex = 0; // Índice actual en el historial

  List<CanvasImage> get _canvasImages => _pages[_currentPage];
  TemplateType get _currentTemplate => _pageTemplates[_currentPage];

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
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    bool isRegister = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: Text(isRegister ? 'Crear cuenta' : 'Iniciar sesión'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(labelText: 'Usuario'),
                  ),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        setLocalState(() => isRegister = !isRegister),
                    child: Text(
                      isRegister
                          ? 'Tengo cuenta, entrar'
                          : 'No tengo cuenta, registrarme',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final username = usernameController.text.trim();
                    final password = passwordController.text.trim();
                    if (username.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Introduce usuario y contraseña válidos',
                          ),
                        ),
                      );
                      return;
                    }

                    if (isRegister) {
                      final newUser = await _userService.register(
                        username,
                        password,
                      );
                      if (newUser == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Usuario ya existe')),
                        );
                        return;
                      }
                      setState(() {
                        _currentUser = newUser;
                        _activeProjectId = null;
                      });
                    } else {
                      final user = await _userService.login(username, password);
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Credenciales incorrectas'),
                          ),
                        );
                        return;
                      }
                      setState(() {
                        _currentUser = user;
                        _activeProjectId = null;
                      });
                    }

                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: Text(isRegister ? 'Crear' : 'Entrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _promptSaveProject() async {
    if (_currentUser == null) {
      _requireLogin();
      return;
    }
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
      await _saveProject(result);
    }
  }

  ProjectData _buildProjectData(String name) {
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
      headerText: _headerController.text,
      footerText: _footerController.text,
      headerScope: _headerScope,
      footerScope: _footerScope,
      showPageNumbers: _showPageNumbers,
      logoPath: _logoPath,
      logoPosition: _logoPosition,
      logoSize: _logoSize,
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

    final project = _buildProjectData(name);
    final users = await _userService.loadUsers();
    final index = users.indexWhere((u) => u.id == _currentUser!.id);
    if (index == -1) {
      setState(() {
        _isPersisting = false;
      });
      return;
    }

    final user = users[index];
    final existingIndex = user.projects.indexWhere((p) => p.id == project.id);
    final updatedProjects = List<ProjectData>.from(user.projects);
    if (existingIndex >= 0) {
      updatedProjects[existingIndex] = project;
    } else {
      updatedProjects.add(project);
    }

    final updatedUser = user.copyWith(projects: updatedProjects);
    users[index] = updatedUser;
    await _userService.saveUsers(users);
    setState(() {
      _currentUser = updatedUser;
      _activeProjectId = project.id;
      _isPersisting = false;
    });
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

    final projects = await _userService.fetchProjects(_currentUser!.id);
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
        return AlertDialog(
          title: const Text('Mis proyectos'),
          content: SizedBox(
            width: 400,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return ListTile(
                  title: Text(project.name),
                  subtitle: Text(
                    'Actualizado: ${project.updatedAt.toLocal().toString().split(".").first}',
                  ),
                  onTap: () => Navigator.of(context).pop(project),
                );
              },
            ),
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

    if (selected != null) {
      await _loadProject(selected);
    }
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

    setState(() {
      _pages = project.pages
          .map((page) => page.map((img) => img.copyWith()).toList())
          .toList();
      _pageTemplates = templates;
      _pageBackgrounds = backgrounds;
      _pageOrientations = orientations;
      _headerController.text = project.headerText ?? '';
      _footerController.text = project.footerText ?? '';
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
    });
    _saveToHistory();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Proyecto "${project.name}" cargado')),
      );
    }
  }

  void _logout() {
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

    final result = generateShadowMatchingActivity(
      images: images,
      isLandscape: _pageOrientations[_currentPage],
      a4WidthPts: _a4WidthPts,
      a4HeightPts: _a4HeightPts,
    );

    if (result.elements.isEmpty) return;

    setState(() {
      _pages[_currentPage].clear();
      if (result.template != null) {
        _pageTemplates[_currentPage] = result.template!;
      }
      _pages[_currentPage].addAll(result.elements);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? 'Actividad generada')),
    );
  }

  void _generatePuzzleActivity() {
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

    final result = generatePuzzleActivity(
      images: images,
      isLandscape: _pageOrientations[_currentPage],
      a4WidthPts: _a4WidthPts,
      a4HeightPts: _a4HeightPts,
    );

    if (result.elements.isEmpty) return;

    setState(() {
      _pages[_currentPage].clear();
      if (result.template != null) {
        _pageTemplates[_currentPage] = result.template!;
      }
      _pages[_currentPage].addAll(result.elements);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message ?? 'Puzle generado')));
  }

  void _generateWritingPracticeActivity() {
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

    final result = generateWritingPracticeActivity(
      images: images,
      isLandscape: _pageOrientations[_currentPage],
      a4WidthPts: _a4WidthPts,
      a4HeightPts: _a4HeightPts,
    );

    if (result.elements.isEmpty) return;

    setState(() {
      _pages[_currentPage].clear();
      if (result.template != null) {
        _pageTemplates[_currentPage] = result.template!;
      }
      _pages[_currentPage].addAll(result.elements);
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

    final result = generateCountingActivity(
      images: images,
      isLandscape: _pageOrientations[_currentPage],
      a4WidthPts: _a4WidthPts,
      a4HeightPts: _a4HeightPts,
    );

    if (result.elements.isEmpty) return;

    setState(() {
      _pages[_currentPage].clear();
      if (result.template != null) {
        _pageTemplates[_currentPage] = result.template!;
      }
      _pages[_currentPage].addAll(result.elements);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? 'Actividad generada')),
    );
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

    if (result.elements.isEmpty) return;

    setState(() {
      _pages[_currentPage].clear();
      _pages[_currentPage].addAll(result.elements);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? 'Actividad de series generada')),
    );
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

    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generar tarjeta'),
        scrollable: true,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(
                  labelText: 'Párrafo',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                minLines: 3,
                keyboardType: TextInputType.multiline,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Generar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final title = titleController.text.trim();
    final body = bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) return;

    final result = card_activity.generateCardActivity(
      images: images,
      title: title,
      body: body,
      isLandscape: _pageOrientations[_currentPage],
      a4WidthPts: _a4WidthPts,
      a4HeightPts: _a4HeightPts,
    );

    if (result.elements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo generar la tarjeta')),
      );
      return;
    }

    setState(() {
      _pages[_currentPage].clear();
      _pages[_currentPage].addAll(result.elements);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? 'Tarjeta generada')),
    );
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

    if (result.elements.isEmpty) return;

    setState(() {
      _pages[_currentPage].clear();
      _pages[_currentPage].addAll(result.elements);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message ?? 'Actividad de simetrías generada'),
      ),
    );
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

      if (result.elements.isEmpty || result.elements.length == 1) {
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
        _pages[_currentPage].addAll(result.elements);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ??
                'Actividad de vocabulario generada con ${result.elements.length - 1} palabras',
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

      if (result.elements.isEmpty || result.elements.length == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontraron palabras relacionadas'),
          ),
        );
        return;
      }

      setState(() {
        _pages[_currentPage].clear();
        _pages[_currentPage].addAll(result.elements);
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
    // Mostrar diálogo de configuración
    final config = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _InstructionsConfigDialog(),
    );

    if (config == null) return;

    final instructions =
        config['instructions'] as List<instructions_activity.InstructionItem>;

    // Mostrar indicador de carga
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generando actividad de instrucciones...')),
    );

    try {
      final result = await instructions_activity.generateInstructionsActivity(
        instructions: instructions,
        arasaacService: _arasaacService,
        isLandscape: _pageOrientations[_currentPage],
        a4WidthPts: _a4WidthPts,
        a4HeightPts: _a4HeightPts,
      );

      if (result.elements.isEmpty || result.elements.length == 1) {
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
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ?? 'Actividad de instrucciones generada',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al generar la actividad')),
      );
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

  double _baseSizeFor(CanvasImage element) {
    switch (element.type) {
      case CanvasElementType.shape:
        return element.width ?? 100.0;
      case CanvasElementType.text:
        return 150.0;
      case CanvasElementType.networkImage:
      case CanvasElementType.localImage:
        return element.width ?? 150.0;
      case CanvasElementType.pictogramCard:
        return element.width ?? 150.0;
      case CanvasElementType.shadow:
        return element.width ?? 150.0;
    }
  }

  void _resizeElement(String id, Offset delta, Alignment handle) {
    final index = _pages[_currentPage].indexWhere((img) => img.id == id);
    if (index == -1) return;

    final element = _pages[_currentPage][index];
    final adjustedDelta = delta / (_viewScale == 0 ? 1 : _viewScale);

    if (element.type == CanvasElementType.shape) {
      final minSize = 20.0;
      double newWidth = (element.width ?? 100.0);
      double newHeight = (element.height ?? 100.0);
      double newLeft = element.position.dx;
      double newTop = element.position.dy;

      if (handle.x < 0) {
        newWidth = (newWidth - adjustedDelta.dx).clamp(minSize, 1000.0);
        newLeft += adjustedDelta.dx;
      } else if (handle.x > 0) {
        newWidth = (newWidth + adjustedDelta.dx).clamp(minSize, 1000.0);
      }

      if (handle.y < 0) {
        newHeight = (newHeight - adjustedDelta.dy).clamp(minSize, 1000.0);
        newTop += adjustedDelta.dy;
      } else if (handle.y > 0) {
        newHeight = (newHeight + adjustedDelta.dy).clamp(minSize, 1000.0);
      }

      setState(() {
        _pages[_currentPage][index].width = newWidth;
        _pages[_currentPage][index].height = newHeight;
        _pages[_currentPage][index].position = Offset(newLeft, newTop);
      });
    } else {
      final base = _baseSizeFor(element);
      final deltaScale = (adjustedDelta.dx + adjustedDelta.dy) / (2 * base);

      setState(() {
        final newScale = (element.scale + deltaScale).clamp(0.1, 5.0);
        _pages[_currentPage][index].scale = newScale;
      });
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
      final adjustedDelta = delta / (_viewScale == 0 ? 1 : _viewScale);
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
    final element = _canvasImages.firstWhere((e) => e.id == id);
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
        final el = _pages[_currentPage].firstWhere((e) => e.id == id);
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
      _pages.add([]);
      _pageTemplates.add(TemplateType.blank);
      _pageBackgrounds.add(Colors.white);
      _pageOrientations.add(false); // Nueva página en vertical por defecto
      _currentPage = _pages.length - 1;
      _selectedImageIds.clear();
    });
  }

  void _deletePage(int index) {
    if (_pages.length <= 1) return;
    setState(() {
      _pages.removeAt(index);
      _pageTemplates.removeAt(index);
      _pageBackgrounds.removeAt(index);
      _pageOrientations.removeAt(index);
      if (_currentPage >= _pages.length) {
        _currentPage = _pages.length - 1;
      }
      _selectedImageIds.clear();
    });
  }

  void _setPageTemplate(TemplateType template) {
    setState(() {
      _pageTemplates[_currentPage] = template;
    });
  }

  void _goToPage(int index) {
    setState(() {
      _currentPage = index;
      _selectedImageIds.clear();
    });
  }

  void _setZoom(double value) {
    setState(() {
      _canvasZoom = value.clamp(0.5, 2.5).toDouble();
    });
  }

  void _changeZoom(double delta) {
    setState(() {
      _canvasZoom = (_canvasZoom + delta).clamp(0.5, 2.5).toDouble();
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

      final headerText = _headerController.text.trim();
      final footerText = _footerController.text.trim();
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
      if (_logoPath != null) {
        final logoFile = File(_logoPath!);
        final logoBytes = await logoFile.readAsBytes();
        final logoImage = pw.MemoryImage(logoBytes);
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

      if (headerText.isNotEmpty && shouldRender(_headerScope)) {
        const headerFontSize = 14.0;
        final headerHeight = headerFontSize * 1.2;
        final headerBottom = _bottomFromCanvas(10, headerHeight);
        widgets.add(
          pw.Positioned(
            left: 20,
            right: 20,
            bottom: headerBottom,
            child: pw.Text(
              headerText,
              style: const pw.TextStyle(fontSize: headerFontSize),
            ),
          ),
        );
      }

      if (footerText.isNotEmpty && shouldRender(_footerScope)) {
        const footerFontSize = 12.0;
        final footerHeight = footerFontSize * 1.2;
        final footerBottom = _bottomFromCanvas(10, footerHeight);
        widgets.add(
          pw.Positioned(
            left: 20,
            right: 20,
            bottom: footerBottom,
            child: pw.Text(
              footerText,
              style: const pw.TextStyle(fontSize: footerFontSize),
            ),
          ),
        );
      }

      for (final element in pageElements) {
        try {
          if (element.type == CanvasElementType.text) {
            // Elemento de texto
            final fontSize = element.fontSize * element.scale;
            final textHeight = fontSize * 1.2;
            final bottom = _bottomFromCanvas(element.position.dy, textHeight);
            widgets.add(
              pw.Positioned(
                left: element.position.dx,
                bottom: bottom,
                child: pw.SizedBox(
                  height: textHeight,
                  child: pw.Transform.rotate(
                    angle: element.rotation,
                    child: pw.Transform(
                      transform: Matrix4.diagonal3Values(
                        element.flipHorizontal ? -1.0 : 1.0,
                        element.flipVertical ? -1.0 : 1.0,
                        1.0,
                      ),
                      child: pw.Text(
                        element.text ?? '',
                        style: pw.TextStyle(
                          fontSize: element.fontSize * element.scale,
                          color: PdfColor.fromInt(element.textColor.value),
                        ),
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
                  child: pw.Transform(
                    transform: Matrix4.diagonal3Values(
                      element.flipHorizontal ? -1.0 : 1.0,
                      element.flipVertical ? -1.0 : 1.0,
                      1.0,
                    ),
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
                      child: pw.Transform(
                        transform: Matrix4.diagonal3Values(
                          element.flipHorizontal ? -1.0 : 1.0,
                          element.flipVertical ? -1.0 : 1.0,
                          1.0,
                        ),
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

              widgets.add(
                pw.Positioned(
                  left: element.position.dx,
                  bottom: _bottomFromCanvas(element.position.dy, imgHeight),
                  child: pw.SizedBox(
                    width: imgWidth,
                    height: imgHeight,
                    child: pw.Transform.rotate(
                      angle: element.rotation,
                      child: pw.Transform(
                        transform: Matrix4.diagonal3Values(
                          element.flipHorizontal ? -1.0 : 1.0,
                          element.flipVertical ? -1.0 : 1.0,
                          1.0,
                        ),
                        child: imageWidget,
                      ),
                    ),
                  ),
                ),
              );
            }
          }
        } catch (e) {
          debugPrint('Error al procesar elemento: $e');
        }
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

      // Créditos verticales
      if (_showArasaacCredit) {
        widgets.add(
          pw.Positioned(
            left: 6,
            top: 0,
            child: pw.SizedBox(
              height: pageHeight,
              child: pw.Transform.rotate(
                angle: -math.pi / 2,
                child: pw.Text(
                  _arasaacCredit,
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ),
            ),
          ),
        );
      }
      if (_showSoyVisualCredit) {
        widgets.add(
          pw.Positioned(
            right: 6,
            top: 0,
            child: pw.SizedBox(
              height: pageHeight,
              child: pw.Transform.rotate(
                angle: -math.pi / 2,
                child: pw.Text(
                  _soyVisualCredit,
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
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
        return pw.CustomPaint(
          size: PdfPoint(width, height),
          painter: (canvas, size) {
            final spacing = 40.0;
            final mainLineWidth = 2.0;
            final dashLength = 6.0;
            final dashGap = 6.0;
            canvas.setStrokeColor(PdfColors.grey500);
            for (double y = spacing; y < size.y; y += spacing) {
              // Línea superior (punteada)
              double x = 0;
              while (x < size.x) {
                canvas
                  ..moveTo(x, y - 10)
                  ..lineTo(x + dashLength, y - 10);
                x += dashLength + dashGap;
              }
              // Línea media
              canvas
                ..setLineWidth(1)
                ..moveTo(0, y)
                ..lineTo(size.x, y);
            }
            // Última línea base gruesa
            canvas
              ..setLineWidth(mainLineWidth)
              ..moveTo(0, size.y - spacing)
              ..lineTo(size.x, size.y - spacing)
              ..strokePath();
          },
        );
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
        canvas
          ..moveTo(0, size.y / 2)
          ..lineTo(size.x, size.y / 2)
          ..strokePath();
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
        onUndo: _undo,
        onRedo: _redo,
        onClear: _clearCanvas,
        onToggleSidebar: () =>
            setState(() => _sidebarCollapsed = !_sidebarCollapsed),
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
            isTextSelected: _sidebarMode == SidebarMode.text,
            isShapesSelected: _sidebarMode == SidebarMode.shapes,
            isArasaacSelected: _sidebarMode == SidebarMode.arasaac,
            isSoyVisualSelected: _sidebarMode == SidebarMode.soyVisual,
            isTemplatesSelected: _sidebarMode == SidebarMode.templates,
            isCreatorSelected: _sidebarMode == SidebarMode.creador,
            isConfigSelected: _sidebarMode == SidebarMode.config,
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

                        final displayScale = scaleToFit * _canvasZoom;
                        _viewScale = displayScale;

                        if (_canvasSize != Size(baseWidth, baseHeight)) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            setState(() {
                              _canvasSize = Size(baseWidth, baseHeight);
                            });
                          });
                        }

                        return ClipRect(
                          child: Transform.scale(
                            scale: displayScale,
                            alignment: Alignment.center,
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
                                  // Fondo con plantilla
                                  CustomPaint(
                                    size: Size(baseWidth, baseHeight),
                                    painter: TemplatePainter(_currentTemplate),
                                  ),
                                  GestureDetector(
                                    onTap: () => _selectImage(null),
                                    child: Container(color: Colors.transparent),
                                  ),
                                  ..._canvasImages.map((canvasElement) {
                                    final isSelected = _selectedImageIds
                                        .contains(canvasElement.id);
                                    Widget content;

                                    if (canvasElement.type ==
                                        CanvasElementType.text) {
                                      content = Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          border: isSelected
                                              ? Border.all(
                                                  color: Colors.blue,
                                                  width: 2,
                                                )
                                              : null,
                                        ),
                                        child: Text(
                                          canvasElement.text ?? '',
                                          style: TextStyle(
                                            fontSize:
                                                canvasElement.fontSize *
                                                canvasElement.scale,
                                            color: canvasElement.textColor,
                                            fontFamily:
                                                canvasElement.fontFamily,
                                          ),
                                        ),
                                      );
                                    } else if (canvasElement.type ==
                                        CanvasElementType.shape) {
                                      final size = Size(
                                        (canvasElement.width ?? 100.0) *
                                            canvasElement.scale,
                                        (canvasElement.height ?? 100.0) *
                                            canvasElement.scale,
                                      );
                                      content = CustomPaint(
                                        size: size,
                                        painter: ShapePainter(
                                          shapeType: canvasElement.shapeType!,
                                          color: canvasElement.shapeColor,
                                          strokeWidth:
                                              canvasElement.strokeWidth,
                                          isSelected: isSelected,
                                        ),
                                      );
                                    } else if (canvasElement.type ==
                                        CanvasElementType.pictogramCard) {
                                      // Tarjeta de pictograma (imagen + texto)
                                      final cardWidth =
                                          (canvasElement.width ?? 150) *
                                          canvasElement.scale;
                                      final cardHeight =
                                          (canvasElement.height ?? 190) *
                                          canvasElement.scale;

                                      content = Container(
                                        width: cardWidth,
                                        height: cardHeight,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.blue
                                                : Colors.black,
                                            width: isSelected ? 3 : 1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Column(
                                            children: [
                                              // Imagen - ocupa el espacio proporcional
                                              Expanded(
                                                flex: 150,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    6,
                                                  ),
                                                  child: CachedNetworkImage(
                                                    imageUrl:
                                                        canvasElement.imageUrl!,
                                                    fit: BoxFit.contain,
                                                    placeholder:
                                                        (
                                                          context,
                                                          url,
                                                        ) => const Center(
                                                          child:
                                                              CircularProgressIndicator(),
                                                        ),
                                                    errorWidget:
                                                        (context, url, error) =>
                                                            const Icon(
                                                              Icons.error,
                                                            ),
                                                  ),
                                                ),
                                              ),
                                              // Texto - ocupa el espacio restante
                                              Container(
                                                height:
                                                    40 * canvasElement.scale,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 4,
                                                    ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  canvasElement.text ?? '',
                                                  style: TextStyle(
                                                    fontSize:
                                                        canvasElement.fontSize *
                                                        canvasElement.scale,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        canvasElement.textColor,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    } else if (canvasElement.type ==
                                        CanvasElementType.shadow) {
                                      // Sombra (imagen en negro/silueta)
                                      final scaledWidth =
                                          (canvasElement.width ?? 150) *
                                          canvasElement.scale;
                                      final scaledHeight =
                                          (canvasElement.height ?? 150) *
                                          canvasElement.scale;

                                      content = Container(
                                        width: scaledWidth,
                                        height: scaledHeight,
                                        decoration: BoxDecoration(
                                          border: isSelected
                                              ? Border.all(
                                                  color: Colors.blue,
                                                  width: 2,
                                                )
                                              : null,
                                        ),
                                        child: ColorFiltered(
                                          colorFilter: const ColorFilter.mode(
                                            Colors.black,
                                            BlendMode.srcIn,
                                          ),
                                          child: Opacity(
                                            opacity: 0.8,
                                            child: CachedNetworkImage(
                                              imageUrl: canvasElement.imageUrl!,
                                              fit: BoxFit.contain,
                                              placeholder: (context, url) =>
                                                  const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(Icons.error),
                                            ),
                                          ),
                                        ),
                                      );
                                    } else {
                                      final scaledWidth =
                                          (canvasElement.width ?? 150) *
                                          canvasElement.scale;
                                      final scaledHeight =
                                          canvasElement.height != null
                                          ? canvasElement.height! *
                                                canvasElement.scale
                                          : null;
                                      Widget imageWidget;

                                      if (canvasElement.type ==
                                          CanvasElementType.networkImage) {
                                        imageWidget = CachedNetworkImage(
                                          imageUrl: canvasElement.imageUrl!,
                                          placeholder: (context, url) =>
                                              const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.error),
                                          fit: BoxFit.contain,
                                        );
                                      } else {
                                        if (kIsWeb) {
                                          if (canvasElement.webBytes != null) {
                                            imageWidget = Image.memory(
                                              canvasElement.webBytes!,
                                              fit: BoxFit.contain,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(Icons.error),
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
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(Icons.error),
                                          );
                                        }
                                      }

                                      // Si solo tenemos width (láminas), usar Container sin height fijo
                                      if (scaledHeight == null) {
                                        content = Container(
                                          width: scaledWidth,
                                          decoration: BoxDecoration(
                                            border: isSelected
                                                ? Border.all(
                                                    color: Colors.blue,
                                                    width: 2,
                                                  )
                                                : null,
                                          ),
                                          child: Transform(
                                            alignment: Alignment.center,
                                            transform: Matrix4.diagonal3Values(
                                              canvasElement.flipHorizontal
                                                  ? -1.0
                                                  : 1.0,
                                              canvasElement.flipVertical
                                                  ? -1.0
                                                  : 1.0,
                                              1.0,
                                            ),
                                            child: imageWidget,
                                          ),
                                        );
                                      } else {
                                        // Si tenemos width y height, usar SizedBox con dimensiones fijas
                                        content = SizedBox(
                                          width: scaledWidth,
                                          height: scaledHeight,
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Transform(
                                                alignment: Alignment.center,
                                                transform:
                                                    Matrix4.diagonal3Values(
                                                      canvasElement
                                                              .flipHorizontal
                                                          ? -1.0
                                                          : 1.0,
                                                      canvasElement.flipVertical
                                                          ? -1.0
                                                          : 1.0,
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
                                                        width: 2,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      }
                                    }

                                    // Solo mostrar resize handles si hay exactamente 1 elemento seleccionado
                                    if (isSelected &&
                                        _selectedImageIds.length == 1) {
                                      content = Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          content,
                                          _buildResizeHandle(
                                            Alignment.topLeft,
                                            canvasElement.id,
                                          ),
                                          _buildResizeHandle(
                                            Alignment.topRight,
                                            canvasElement.id,
                                          ),
                                          _buildResizeHandle(
                                            Alignment.bottomLeft,
                                            canvasElement.id,
                                          ),
                                          _buildResizeHandle(
                                            Alignment.bottomRight,
                                            canvasElement.id,
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
                                          // Detectar si se está presionando Cmd (macOS) o Ctrl (Windows/Linux)
                                          final isMultiSelectKey =
                                              HardwareKeyboard
                                                  .instance
                                                  .isMetaPressed ||
                                              HardwareKeyboard
                                                  .instance
                                                  .isControlPressed;

                                          if (isMultiSelectKey) {
                                            _toggleSelection(canvasElement.id);
                                          } else {
                                            _selectImage(canvasElement.id);
                                          }
                                        },
                                        child: Transform.rotate(
                                          angle: canvasElement.rotation,
                                          child: content,
                                        ),
                                      ),
                                    );
                                  }),
                                  // Logo (en web solo si es URL accesible)
                                  if (_logoPath != null)
                                    Positioned(
                                      left: _logoPosition.dx,
                                      top: _logoPosition.dy,
                                      child: GestureDetector(
                                        onPanUpdate: (details) {
                                          setState(() {
                                            _logoPosition +=
                                                details.delta /
                                                (_viewScale == 0
                                                    ? 1
                                                    : _viewScale);
                                          });
                                        },
                                        child: Container(
                                          width: _logoSize,
                                          height: _logoSize,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.blue.withOpacity(
                                                0.3,
                                              ),
                                              width: 1,
                                            ),
                                          ),
                                          child: _buildLogoWidget(),
                                        ),
                                      ),
                                    ),
                                  // Encabezado
                                  if (_headerController.text
                                          .trim()
                                          .isNotEmpty &&
                                      _shouldRenderHeaderFooter(
                                        _headerScope,
                                        _currentPage,
                                      ))
                                    Positioned(
                                      left: 20,
                                      right: 20,
                                      top: 10,
                                      child: Text(
                                        _headerController.text,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  // Pie de página
                                  if (_footerController.text
                                          .trim()
                                          .isNotEmpty &&
                                      _shouldRenderHeaderFooter(
                                        _footerScope,
                                        _currentPage,
                                      ))
                                    Positioned(
                                      left: 20,
                                      right: 20,
                                      bottom: 10,
                                      child: Text(
                                        _footerController.text,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black87,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  // Número de página
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
                                  // Crédito ARASAAC vertical en el lateral izquierdo
                                  if (_showArasaacCredit)
                                    Positioned(
                                      left: 6,
                                      top: 0,
                                      child: SizedBox(
                                        height: baseHeight,
                                        child: RotatedBox(
                                          quarterTurns: 3,
                                          child: Text(
                                            _arasaacCredit,
                                            style: const TextStyle(
                                              fontSize: 8,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (_showSoyVisualCredit)
                                    Positioned(
                                      right: 6,
                                      top: 0,
                                      child: SizedBox(
                                        height: baseHeight,
                                        child: RotatedBox(
                                          quarterTurns: 3,
                                          child: Text(
                                            _soyVisualCredit,
                                            style: const TextStyle(
                                              fontSize: 8,
                                              color: Colors.black54,
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
                    top: 20,
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Zoom',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => _changeZoom(-0.1),
                                  tooltip: 'Alejar',
                                ),
                                SizedBox(
                                  width: 140,
                                  child: Slider(
                                    value: _canvasZoom,
                                    min: 0.5,
                                    max: 2.5,
                                    divisions: 20,
                                    label: '${(_canvasZoom * 100).round()}%',
                                    onChanged: _setZoom,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => _changeZoom(0.1),
                                  tooltip: 'Acercar',
                                ),
                              ],
                            ),
                            Text('${(_canvasZoom * 100).round()}%'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_selectedImageIds.length == 1)
                    Positioned(
                      left: _editBarPosition.dx,
                      top: _editBarPosition.dy,
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
                                final selectedElement = _canvasImages
                                    .firstWhere((e) => e.id == selectedId);
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
                      left: _editBarPosition.dx,
                      top: _editBarPosition.dy,
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
        return ActivityCreatorPanel(
          onShadowMatching: _generateShadowMatchingActivity,
          onPuzzle: _generatePuzzleActivity,
          onWritingPractice: _generateWritingPracticeActivity,
          onCountingPractice: _generateCountingActivity,
          onSeries: _generateSeriesActivity,
          onSymmetry: _generateSymmetryActivity,
          onSyllableVocabulary: _generateSyllableVocabularyActivity,
          onSemanticField: _generateSemanticFieldActivity,
          onInstructions: _generateInstructionsActivity,
          onPhrases: _generatePhrasesActivity,
          onCard: _generateCardActivity,
        );
      case SidebarMode.photo:
        return const Center(child: Text('Foto'));
    }
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
                spacing: 12,
                children: [
                  ChoiceChip(
                    label: const Text('Fondo'),
                    selected: _configTab == ConfigTab.background,
                    onSelected: (_) =>
                        setState(() => _configTab = ConfigTab.background),
                  ),
                  ChoiceChip(
                    label: const Text('Numerar'),
                    selected: _configTab == ConfigTab.pagination,
                    onSelected: (_) =>
                        setState(() => _configTab = ConfigTab.pagination),
                  ),
                  ChoiceChip(
                    label: const Text('Encabezado/Pie'),
                    selected: _configTab == ConfigTab.headerFooter,
                    onSelected: (_) =>
                        setState(() => _configTab = ConfigTab.headerFooter),
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
      case ConfigTab.background:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Orientación de página',
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
                          ? Colors.blue[700]
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
                          ? Colors.blue[700]
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
              title: const Text('Mostrar crédito ARASAAC'),
              subtitle: const Text('Texto lateral con autoría/licencia'),
              value: _showArasaacCredit,
              onChanged: (v) => setState(() => _showArasaacCredit = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mostrar crédito SoyVisual'),
              subtitle: const Text('Para fotografías/láminas SoyVisual'),
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
          ],
        );
      case ConfigTab.pagination:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Mostrar número de página en PDF'),
          value: _showPageNumbers,
          onChanged: (value) {
            setState(() {
              _showPageNumbers = value;
            });
          },
        );
      case ConfigTab.headerFooter:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _headerController,
              decoration: const InputDecoration(
                labelText: 'Texto de encabezado',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            _buildScopeSelector(
              label: 'Aplicar encabezado en',
              value: _headerScope,
              onChanged: (scope) => setState(() => _headerScope = scope),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _footerController,
              decoration: const InputDecoration(
                labelText: 'Texto de pie de página',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            _buildScopeSelector(
              label: 'Aplicar pie en',
              value: _footerScope,
              onChanged: (scope) => setState(() => _footerScope = scope),
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

  Widget _buildScopeSelector({
    required String label,
    required HeaderFooterScope value,
    required ValueChanged<HeaderFooterScope> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: HeaderFooterScope.values.map((scope) {
            String text;
            switch (scope) {
              case HeaderFooterScope.all:
                text = 'Todas';
                break;
              case HeaderFooterScope.first:
                text = 'Primera';
                break;
              case HeaderFooterScope.last:
                text = 'Última';
                break;
            }
            return ChoiceChip(
              label: Text(text),
              selected: value == scope,
              onSelected: (_) => onChanged(scope),
            );
          }).toList(),
        ),
      ],
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
    final selectedElement = _canvasImages.firstWhere((e) => e.id == selectedId);
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
          TextField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: 'Contenido',
              border: OutlineInputBorder(),
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

  Widget _buildResizeHandle(Alignment alignment, String id) {
    return Align(
      alignment: alignment,
      child: GestureDetector(
        onPanUpdate: (details) => _resizeElement(id, details.delta, alignment),
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.blue, width: 2),
            shape: BoxShape.circle,
          ),
        ),
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
                  hintText: 'Buscar imágenes SoyVisual... (pulsa Enter)',
                  prefixIcon: const Icon(Icons.search),
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
              ? const Center(child: Text('Busca imágenes de SoyVisual'))
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
  final List<_InstructionItemConfig> _items = [
    _InstructionItemConfig(word: 'casa', quantity: 1),
  ];

  void _addItem() {
    setState(() {
      _items.add(_InstructionItemConfig(word: '', quantity: 1));
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
      });
    }
  }

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
              'Configura los objetos a rodear:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'La hoja se llenará automáticamente con dibujos mezclados',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Objeto',
                          hintText: 'ej: casa, árbol',
                        ),
                        onChanged: (value) {
                          item.word = value;
                        },
                        controller: TextEditingController(text: item.word)
                          ..selection = TextSelection.collapsed(
                            offset: item.word.length,
                          ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Cantidad',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          item.quantity = int.tryParse(value) ?? 1;
                        },
                        controller:
                            TextEditingController(
                                text: item.quantity.toString(),
                              )
                              ..selection = TextSelection.collapsed(
                                offset: item.quantity.toString().length,
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: _items.length > 1
                          ? () => _removeItem(index)
                          : null,
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
              label: const Text('Añadir objeto'),
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
            final validItems = _items
                .where(
                  (item) => item.word.trim().isNotEmpty && item.quantity > 0,
                )
                .toList();
            if (validItems.isEmpty) return;

            final instructions = validItems
                .map(
                  (item) => instructions_activity.InstructionItem(
                    word: item.word.trim(),
                    quantity: item.quantity,
                  ),
                )
                .toList();

            Navigator.of(context).pop({'instructions': instructions});
          },
          child: const Text('Generar'),
        ),
      ],
    );
  }
}

// Clase auxiliar para configuración de items de instrucciones
class _InstructionItemConfig {
  String word;
  int quantity;

  _InstructionItemConfig({required this.word, required this.quantity});
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

  ShapePainter({
    required this.shapeType,
    required this.color,
    required this.strokeWidth,
    this.isSelected = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

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
        canvas.drawLine(
          Offset(0, size.height / 2),
          Offset(size.width, size.height / 2),
          paint,
        );
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
