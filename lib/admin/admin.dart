import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import '../main.dart';
import '../models/ebook_model.dart';
import '../services/ebook_service.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final EbookService _ebookService = EbookService();
  int _selectedIndex = 0;
  List<Ebook> _ebooks = [];
  bool _isLoading = false;

  // Controllers for adding/editing ebooks
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _yearController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _selectedPdf;
  File? _selectedCover;
  String? _pdfName;
  String? _coverName;

  @override
  void initState() {
    super.initState();
    _loadEbooks();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _yearController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyApp()),
      );
    }
  }

  Future<void> _loadEbooks() async {
    setState(() => _isLoading = true);
    try {
      final ebooks = await _ebookService.getAllEbooks();
      setState(() => _ebooks = ebooks);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading ebooks: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _selectedPdf = File(result.files.single.path!);
        _pdfName = result.files.single.name;
      });
    }
  }

  Future<void> _pickCover() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _selectedCover = File(result.files.single.path!);
        _coverName = result.files.single.name;
      });
    }
  }

  void _resetForm() {
    _titleController.clear();
    _authorController.clear();
    _yearController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedPdf = null;
      _selectedCover = null;
      _pdfName = null;
      _coverName = null;
    });
  }

  Future<void> _addEbook() async {
    if (_selectedPdf == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF file')),
      );
      return;
    }

    if (_titleController.text.isEmpty ||
        _authorController.text.isEmpty ||
        _yearController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload PDF
      final pdfUrl = await _ebookService.uploadPdf(_selectedPdf!, _pdfName!);
      
      // Upload cover if selected
      String? coverUrl;
      if (_selectedCover != null) {
        coverUrl = await _ebookService.uploadCover(_selectedCover, _coverName!);
      }

      // Add ebook to database
      await _ebookService.addEbook(
        title: _titleController.text,
        author: _authorController.text,
        year: _yearController.text,
        description: _descriptionController.text,
        pdfUrl: pdfUrl,
        coverUrl: coverUrl,
      );

      // Reset form and reload ebooks
      _resetForm();
      await _loadEbooks();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('eBook added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding ebook: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEbook(String id) async {
    setState(() => _isLoading = true);
    try {
      await _ebookService.deleteEbook(id);
      await _loadEbooks();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('eBook deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting ebook: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildUploadScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload New eBook',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _authorController,
            decoration: const InputDecoration(
              labelText: 'Author',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _yearController,
            decoration: const InputDecoration(
              labelText: 'Year',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickPdf,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Select PDF'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          if (_pdfName != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('Selected PDF: $_pdfName'),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickCover,
                  icon: const Icon(Icons.image),
                  label: const Text('Select Cover Image (Optional)'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          if (_coverName != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('Selected Cover: $_coverName'),
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addEbook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Upload eBook'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManageScreen() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_ebooks.isEmpty) {
      return const Center(child: Text('No eBooks available'));
    }

    return ListView.builder(
      itemCount: _ebooks.length,
      itemBuilder: (context, index) {
        final ebook = _ebooks[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: ebook.coverUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      ebook.coverUrl!,
                      width: 50,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.book, size: 50),
                    ),
                  )
                : const Icon(Icons.book, size: 50),
            title: Text(ebook.title),
            subtitle: Text('${ebook.author} (${ebook.year})'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(ebook),
            ),
            onTap: () => _showEbookDetails(ebook),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(Ebook ebook) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete eBook'),
        content: Text('Are you sure you want to delete "${ebook.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEbook(ebook.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEbookDetails(Ebook ebook) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ebook.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ebook.coverUrl != null)
                Center(
                  child: Image.network(
                    ebook.coverUrl!,
                    height: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 100),
                  ),
                ),
              const SizedBox(height: 16),
              Text('Author: ${ebook.author}'),
              Text('Year: ${ebook.year}'),
              const SizedBox(height: 8),
              const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(ebook.description),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          )
        ],
      ),
      body: _selectedIndex == 0 ? _buildUploadScreen() : _buildManageScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 1) _loadEbooks(); // Refresh ebooks when switching to manage tab
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Manage',
          ),
        ],
      ),
    );
  }
}
