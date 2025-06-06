class Ebook {
  final String id;
  final String title;
  final String author;
  final String year;
  final String description;
  final String pdfUrl;
  final String? coverUrl;
  final DateTime createdAt;

  Ebook({
    required this.id,
    required this.title,
    required this.author,
    required this.year,
    required this.description,
    required this.pdfUrl,
    this.coverUrl,
    required this.createdAt,
  });
 
  factory Ebook.fromJson(Map<String, dynamic> json) {
    return Ebook(
      id: json['id'].toString(),  // Convert to String instead of casting
      title: json['title'] as String,
      author: json['author'] as String,
      year: json['year'] as String,
      description: json['description'] as String,
      pdfUrl: json['pdf_url'] as String,
      coverUrl: json['cover_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  } 

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'year': year,
      'description': description,
      'pdf_url': pdfUrl,
      'cover_url': coverUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}