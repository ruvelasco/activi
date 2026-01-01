import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/arasaac_service.dart';

class VisualInstructionsResult {
  final String? activityPictogramUrl;
  final List<String> materialPictogramUrls;

  VisualInstructionsResult({
    this.activityPictogramUrl,
    required this.materialPictogramUrls,
  });
}

class VisualInstructionsDialog extends StatefulWidget {
  final String? initialActivityUrl;
  final List<String> initialMaterialUrls;
  final ArasaacService arasaacService;

  const VisualInstructionsDialog({
    super.key,
    this.initialActivityUrl,
    required this.initialMaterialUrls,
    required this.arasaacService,
  });

  @override
  State<VisualInstructionsDialog> createState() =>
      _VisualInstructionsDialogState();
}

class _VisualInstructionsDialogState extends State<VisualInstructionsDialog> {
  late String? tempActivityUrl;
  late List<String> tempMaterialUrls;
  final activitySearchController = TextEditingController();
  final materialSearchController = TextEditingController();
  List<ArasaacImage> activitySearchResults = [];
  List<ArasaacImage> materialSearchResults = [];

  @override
  void initState() {
    super.initState();
    tempActivityUrl = widget.initialActivityUrl;
    tempMaterialUrls = List.from(widget.initialMaterialUrls);
  }

  @override
  void dispose() {
    activitySearchController.dispose();
    materialSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.photo_library, color: Colors.indigo.shade700, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Instrucciones Visuales',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Edita pictogramas de actividad y materiales',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 500,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 0,
                      color: Colors.grey.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.work_outline, size: 20, color: Colors.grey.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Pictograma de actividad',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (tempActivityUrl != null)
                              Stack(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.indigo.shade700, width: 2),
                                      borderRadius: BorderRadius.circular(8),
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
                                        setState(() {
                                          tempActivityUrl = null;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: activitySearchController,
                              decoration: InputDecoration(
                                hintText: 'Buscar actividad (ej: sumar, leer, escribir)',
                                border: const OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.indigo.shade700, width: 2),
                                ),
                              ),
                              onSubmitted: (query) async {
                                if (query.trim().isEmpty) return;
                                final results = await widget.arasaacService.searchPictograms(query);
                                setState(() {
                                  activitySearchResults = results;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
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
                                        setState(() {
                                          tempActivityUrl = url;
                                          activitySearchResults = [];
                                          activitySearchController.clear();
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(8),
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
                    const SizedBox(height: 16),

                    Card(
                      elevation: 0,
                      color: Colors.grey.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.construction, size: 20, color: Colors.grey.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Pictogramas de materiales',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
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
                                          border: Border.all(color: Colors.indigo.shade700, width: 2),
                                          borderRadius: BorderRadius.circular(8),
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
                                            setState(() {
                                              tempMaterialUrls.removeAt(idx);
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: materialSearchController,
                              decoration: InputDecoration(
                                hintText: 'Buscar material (ej: lápiz, tijeras, goma)',
                                border: const OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.indigo.shade700, width: 2),
                                ),
                              ),
                              onSubmitted: (query) async {
                                if (query.trim().isEmpty) return;
                                final results = await widget.arasaacService.searchPictograms(query);
                                setState(() {
                                  materialSearchResults = results;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
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
                                        setState(() {
                                          tempMaterialUrls.add(url);
                                          materialSearchResults = [];
                                          materialSearchController.clear();
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(8),
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      VisualInstructionsResult(
                        activityPictogramUrl: tempActivityUrl,
                        materialPictogramUrls: tempMaterialUrls,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 20),
                      SizedBox(width: 8),
                      Text('Guardar'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
