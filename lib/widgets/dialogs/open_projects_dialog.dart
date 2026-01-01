import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/project_data.dart';
import '../../models/canvas_image.dart';

class OpenProjectsDialog extends StatelessWidget {
  final List<ProjectData> projects;

  const OpenProjectsDialog({super.key, required this.projects});

  @override
  Widget build(BuildContext context) {
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
            // Lista de proyectos
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildProjectCard(context, project),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, ProjectData project) {
    // DEBUG: Imprimir información del coverImage
    if (kDebugMode) {
      print('=== PROJECT CARD DEBUG ===');
      print('Project name: ${project.name}');
      print('CoverImage exists: ${project.coverImage != null}');
      if (project.coverImage != null) {
        print('CoverImage type: ${project.coverImage!.type}');
        print('CoverImage imagePath: ${project.coverImage!.imagePath}');
        print('CoverImage imageUrl: ${project.coverImage!.imageUrl}');
      }
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(project),
        child: SizedBox(
          height: 229,
          width: double.infinity,
          child: Stack(
            children: [
              // Imagen de fondo: usar coverImage si existe
              if (project.coverImage != null)
                _buildCoverImageBackground(project.coverImage!)
              else
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              // Nombre del proyecto superpuesto
              Positioned(
                top: 8,
                left: 240,
                right: 100,
                child: Text(
                  project.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImageBackground(CanvasImage image) {
    if (kDebugMode) {
      print('=== BUILDING COVER IMAGE ===');
      print('ImagePath: ${image.imagePath}');
      print('ImageUrl: ${image.imageUrl}');
      print('Is asset: ${image.imagePath?.startsWith('assets/')}');
    }

    // Devolver un SizedBox con dimensiones explícitas
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: _buildCoverImage(image),
    );
  }

  Widget _buildCoverImage(CanvasImage image) {
    if (image.imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: image.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      );
    } else if (image.webBytes != null) {
      return Image.memory(image.webBytes!, fit: BoxFit.cover);
    } else if (image.imagePath != null) {
      // Si es un asset (etiqueta)
      if (image.imagePath!.startsWith('assets/')) {
        // En iOS, cargar los bytes del asset primero
        if (!kIsWeb) {
          if (kDebugMode) {
            print('>>> Usando FutureBuilder para cargar asset en iOS');
          }
          return FutureBuilder<ByteData>(
            future: rootBundle.load(image.imagePath!),
            builder: (context, snapshot) {
              if (kDebugMode) {
                print('>>> FutureBuilder state: ${snapshot.connectionState}');
              }
              if (snapshot.hasData) {
                final bytes = snapshot.data!.buffer.asUint8List();
                if (kDebugMode) {
                  print('>>> Asset loaded! Bytes length: ${bytes.length}');
                  print('>>> Creando Image.memory con BoxFit.cover');
                }
                if (kDebugMode) {
                  print('>>> Image.memory creado exitosamente');
                }
                return Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    if (kDebugMode) {
                      print('>>> ERROR en Image.memory: $error');
                    }
                    return Container(
                      color: Colors.red,
                      child: const Icon(Icons.error, color: Colors.white, size: 48),
                    );
                  },
                );
              } else if (snapshot.hasError) {
                if (kDebugMode) {
                  print('>>> Error loading asset bytes: ${snapshot.error}');
                }
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, size: 48),
                );
              }
              if (kDebugMode) {
                print('>>> Mostrando loading indicator...');
              }
              return Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              );
            },
          );
        } else {
          // En web, usar Image.asset directamente
          return Image.asset(
            image.imagePath!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              if (kDebugMode) {
                print('Error loading asset: ${image.imagePath}');
                print('Error details: $error');
              }
              return Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, size: 48),
              );
            },
          );
        }
      } else if (!kIsWeb) {
        // Si no es web y no es un asset, es un archivo local
        return Image.file(File(image.imagePath!), fit: BoxFit.cover);
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
}
