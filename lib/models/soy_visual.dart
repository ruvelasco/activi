// MARK: - SoyVisualElement
class SoyVisualElement {
  final int id;
  final String type;
  final String title;
  final Imagen image;
  final Imagen thumbnail;
  final String created;
  final String changed;
  final String definition;
  final String tags;
  final String authors;

  SoyVisualElement({
    required this.id,
    required this.type,
    required this.title,
    required this.image,
    required this.thumbnail,
    required this.created,
    required this.changed,
    required this.definition,
    required this.tags,
    required this.authors,
  });

  factory SoyVisualElement.fromJson(Map<String, dynamic> json) {
    return SoyVisualElement(
      id: json['id'] as int? ?? 0,
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      image: Imagen.fromJson((json['image'] as Map<String, dynamic>?) ?? {}),
      thumbnail: Imagen.fromJson((json['thumbnail'] as Map<String, dynamic>?) ?? {}),
      created: json['created'] as String? ?? '',
      changed: json['changed'] as String? ?? '',
      definition: json['definition'] as String? ?? '',
      tags: json['tags'] as String? ?? '',
      authors: json['authors'] as String? ?? '',
    );
  }
}

// MARK: - Image
class Imagen {
  final String src;
  final String alt;

  Imagen({
    required this.src,
    required this.alt,
  });

  factory Imagen.fromJson(Map<String, dynamic> json) {
    return Imagen(
      src: json['src'] as String? ?? '',
      alt: json['alt'] as String? ?? '',
    );
  }
}
