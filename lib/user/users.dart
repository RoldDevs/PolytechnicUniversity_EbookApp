import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart'; // This imports our ResponsiveUtil class
import '../models/ebook_model.dart';
import '../services/ebook_service.dart';

class UserPanel extends StatefulWidget {
  const UserPanel({super.key});

  @override
  State<UserPanel> createState() => _UserState();
}

class _UserState extends State<UserPanel> {
  final EbookService _ebookService = EbookService();
  List<Ebook> _ebooks = [];
  List<Ebook> _filteredEbooks = [];
  bool _isLoading = false;
  
  // Search controllers
  final TextEditingController _searchController = TextEditingController();
  String _searchType = 'title'; // Default search type
  
  @override
  void initState() {
    super.initState();
    _loadEbooks();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
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
      setState(() {
        _ebooks = ebooks;
        _filteredEbooks = ebooks;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading ebooks: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _searchEbooks() async {
    setState(() => _isLoading = true);
    try {
      final searchText = _searchController.text.trim();
      
      if (searchText.isEmpty) {
        // If search is empty, show all ebooks
        setState(() => _filteredEbooks = _ebooks);
        return;
      }
      
      // Search based on selected type
      List<Ebook> results;
      switch (_searchType) {
        case 'title':
          results = await _ebookService.searchEbooks(title: searchText);
          break;
        case 'author':
          results = await _ebookService.searchEbooks(author: searchText);
          break;
        case 'year':
          results = await _ebookService.searchEbooks(year: searchText);
          break;
        default:
          results = await _ebookService.searchEbooks(title: searchText);
      }
      
      setState(() => _filteredEbooks = results);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching ebooks: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openPdf(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open PDF')),
        );
      }
    }
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
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openPdf(ebook.pdfUrl);
            },
            icon: const Icon(Icons.download),
            label: const Text('Download'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size information
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('eBook Library'),
        actions: [  
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEbooks,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          )
        ],
      ),
      body: Column(
        children: [
          // Search bar - Adaptive for different screen sizes
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 4.0 : 8.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 4.0 : 8.0,
                  vertical: isSmallScreen ? 2.0 : 4.0,
                ),
                child: isSmallScreen
                    // Stacked layout for small screens
                    ? Column(
                        children: [
                          Row(
                            children: [
                              // Search type dropdown
                              DropdownButton<String>(
                                value: _searchType,
                                underline: const SizedBox(),
                                items: const [
                                  DropdownMenuItem(value: 'title', child: Text('Title')),
                                  DropdownMenuItem(value: 'author', child: Text('Author')),
                                  DropdownMenuItem(value: 'year', child: Text('Year')),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _searchType = value);
                                    if (_searchController.text.isNotEmpty) {
                                      _searchEbooks();
                                    }
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              // Search button
                              IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: _searchEbooks,
                              ),
                            ],
                          ),
                          // Search field
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by ${_searchType}...',
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _filteredEbooks = _ebooks);
                                },
                              ),
                            ),
                            onSubmitted: (_) => _searchEbooks(),
                          ),
                        ],
                      )
                    // Row layout for larger screens
                    : Row(
                        children: [
                          // Search type dropdown
                          DropdownButton<String>(
                            value: _searchType,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 'title', child: Text('Title')),
                              DropdownMenuItem(value: 'author', child: Text('Author')),
                              DropdownMenuItem(value: 'year', child: Text('Year')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _searchType = value);
                                if (_searchController.text.isNotEmpty) {
                                  _searchEbooks();
                                }
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          // Search field
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search by ${_searchType}...',
                                border: InputBorder.none,
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _filteredEbooks = _ebooks);
                                  },
                                ),
                              ),
                              onSubmitted: (_) => _searchEbooks(),
                            ),
                          ),
                          // Search button
                          IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: _searchEbooks,
                          ),
                        ],
                      ),
              ),
            ),
          ),
          // Ebooks grid - Responsive grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEbooks.isEmpty
                    ? const Center(child: Text('No eBooks found'))
                    : RefreshIndicator(
                        onRefresh: _loadEbooks,
                        child: Padding(
                          padding: EdgeInsets.all(isSmallScreen ? 4.0 : 8.0),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Calculate optimal grid layout based on available width
                              final crossAxisCount = constraints.maxWidth < 400 ? 1 :
                                                    constraints.maxWidth < 650 ? 2 :
                                                    constraints.maxWidth < 900 ? 3 : 4;
                              
                              final childAspectRatio = constraints.maxWidth < 400 ? 0.8 : 0.7;
                              
                              return GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: childAspectRatio,
                                  crossAxisSpacing: isSmallScreen ? 5 : 10,
                                  mainAxisSpacing: isSmallScreen ? 5 : 10,
                                ),
                                itemCount: _filteredEbooks.length,
                                itemBuilder: (context, index) {
                                  final ebook = _filteredEbooks[index];
                                  return GestureDetector(
                                    onTap: () => _showEbookDetails(ebook),
                                    child: Card(
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius: const BorderRadius.vertical(
                                                top: Radius.circular(10),
                                              ),
                                              child: ebook.coverUrl != null
                                                  ? Image.network(
                                                      ebook.coverUrl!,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) =>
                                                          Container(
                                                            color: Colors.grey[300],
                                                            child: const Icon(Icons.book, size: 50),
                                                          ),
                                                    )
                                                  : Container(
                                                      color: Colors.grey[300],
                                                      child: const Icon(Icons.book, size: 50),
                                                    ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(isSmallScreen ? 4.0 : 8.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  ebook.title,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: isSmallScreen ? 12 : 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: isSmallScreen ? 2 : 4),
                                                Text(
                                                  ebook.author,
                                                  style: TextStyle(
                                                    fontSize: isSmallScreen ? 10 : 12,
                                                    color: Colors.grey[700],
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
