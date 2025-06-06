import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ebook_model.dart';

class EbookService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _tableName = 'ebooks';
  final String _storageBucket = 'ebooks';

  // Get all ebooks
  Future<List<Ebook>> getAllEbooks() async {
    final response = await _supabase.from(_tableName).select().order('created_at', ascending: false);
    return response.map((json) => Ebook.fromJson(json)).toList();
  }

  // Get ebook by id
  Future<Ebook?> getEbookById(String id) async {
    final response = await _supabase.from(_tableName).select().eq('id', id).single();
    if (response != null) {
      return Ebook.fromJson(response);
    }
    return null;
  }
  
  // Search ebooks by title, author, or year
  Future<List<Ebook>> searchEbooks({
    String? title,
    String? author,
    String? year,
  }) async {
    var query = _supabase.from(_tableName).select();
    
    if (title != null && title.isNotEmpty) {
      query = query.ilike('title', '%$title%');
    }
    
    if (author != null && author.isNotEmpty) {
      query = query.ilike('author', '%$author%');
    }
    
    if (year != null && year.isNotEmpty) {
      query = query.eq('year', year);
    }
    
    final response = await query.order('created_at', ascending: false);
    return response.map((json) => Ebook.fromJson(json)).toList();
  }

  // Upload PDF file
  Future<String> uploadPdf(File file, String fileName) async {
    final fileExt = fileName.split('.').last;
    final filePath = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    await _supabase.storage.from(_storageBucket).upload(filePath, file);
    return _supabase.storage.from(_storageBucket).getPublicUrl(filePath);
  }

  // Upload cover image
  Future<String?> uploadCover(File? file, String fileName) async {
    if (file == null) return null;
    final fileExt = fileName.split('.').last;
    final filePath = 'covers/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    await _supabase.storage.from(_storageBucket).upload(filePath, file);
    return _supabase.storage.from(_storageBucket).getPublicUrl(filePath);
  }

  // Add new ebook
  Future<Ebook> addEbook({
    required String title,
    required String author,
    required String year,
    required String description,
    required String pdfUrl,
    String? coverUrl,
  }) async {
    final data = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'author': author,
      'year': year,
      'description': description,
      'pdf_url': pdfUrl,
      'cover_url': coverUrl,
      'created_at': DateTime.now().toIso8601String(),
    };

    await _supabase.from(_tableName).insert(data);
    return Ebook.fromJson(data);
  }

  // Update ebook
  Future<void> updateEbook(Ebook ebook) async {
    await _supabase.from(_tableName).update(ebook.toJson()).eq('id', ebook.id);
  }

  // Delete ebook
  Future<void> deleteEbook(String id) async {
    await _supabase.from(_tableName).delete().eq('id', id);
  }
}