import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter/services.dart';

class PdfViewerUserScreen extends StatefulWidget {
  final String pdfUrl;
  final String pdfName;

  const PdfViewerUserScreen({
    super.key,
    required this.pdfUrl,
    required this.pdfName,
  });

  @override
  State<PdfViewerUserScreen> createState() => _PdfViewerUserScreenState();
}

class _PdfViewerUserScreenState extends State<PdfViewerUserScreen> with SingleTickerProviderStateMixin {
  bool isLoading = true;
  String? errorMessage;
  final PdfViewerController _pdfViewerController = PdfViewerController();
  late PdfTextSearchResult _searchResult;
  late AnimationController _loadingAnimationController;
  // ignore: unused_field
  double _currentZoom = 1.0;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchResult = PdfTextSearchResult();
    _loadingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Optimize loading with precache
    Future.microtask(() async {
      try {
        await precachePDF();
      } catch (e) {
        if (mounted) {
          setState(() {
            errorMessage = 'Failed to load PDF: $e';
          });
        }
      }
    });
  }

  Future<void> precachePDF() async {
    try {
      // Add a small delay to show loading animation
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      throw Exception('Failed to precache PDF');
    }
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RotationTransition(
            turns: _loadingAnimationController,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const SweepGradient(
                  colors: [Colors.blue, Colors.transparent],
                  stops: [0.8, 1.0],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Loading PDF...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? 'An error occurred',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  errorMessage = null;
                  isLoading = true;
                });
                precachePDF();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Hero(
        tag: 'back_button',
        child: Material(
          color: Colors.transparent,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: Colors.black87,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      title: Hero(
        tag: 'pdf_title',
        child: Material(
          color: Colors.transparent,
          child: Text(
            widget.pdfName,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      actions: _buildAppBarActions(),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.blue.withOpacity(0.1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      if (_isSearching)
        IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchResult.clear();
            });
          },
        ),
      IconButton(
        icon: const Icon(Icons.search, color: Colors.black87),
        onPressed: () => _showSearchDialog(context),
      ),
      PopupMenuButton<double>(
        icon: const Icon(Icons.zoom_in, color: Colors.black87),
        onSelected: (double zoom) {
          setState(() {
            _currentZoom = zoom;
            _pdfViewerController.zoomLevel = zoom;
          });
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 1.0, child: Text('100%')),
          const PopupMenuItem(value: 1.5, child: Text('150%')),
          const PopupMenuItem(value: 2.0, child: Text('200%')),
          const PopupMenuItem(value: 2.5, child: Text('250%')),
        ],
      ),
    ];
  }

  void _showSearchDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Search PDF'),
      content: TextField(
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Enter search term',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          prefixIcon: const Icon(Icons.search),
        ),
        onSubmitted: (value) {
          Navigator.pop(context);
          if (value.isNotEmpty) {
            setState(() {
              _isSearching = true;
              _searchResult = _pdfViewerController.searchText(value);
            });
          }
        },
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Search'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          if (isLoading)
            _buildLoadingIndicator()
          else if (errorMessage != null)
            _buildErrorWidget()
          else
            SfPdfViewer.network(
              widget.pdfUrl,
              controller: _pdfViewerController,
              canShowScrollStatus: true,
              canShowScrollHead: true,
              enableDoubleTapZooming: true,
              pageLayoutMode: PdfPageLayoutMode.continuous,
              scrollDirection: PdfScrollDirection.vertical,
              onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
                if (details.selectedText != null && details.selectedText!.isNotEmpty) {
                  Clipboard.setData(ClipboardData(text: details.selectedText!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Text copied to clipboard'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                setState(() {
                  errorMessage = 'Failed to load PDF: ${details.error}';
                });
              },
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    _loadingAnimationController.dispose();
    super.dispose();
  }
}