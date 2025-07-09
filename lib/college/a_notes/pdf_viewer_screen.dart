// ignore_for_file: avoid_print

import 'package:easy_pdf_viewer/easy_pdf_viewer.dart';
import 'package:flutter/material.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String pdfName; // Added parameter for the PDF name

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.pdfName, // Initialize the PDF name
  });
  
  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  PDFDocument? document;

  void initializePdf() async {
    try {
      document = await PDFDocument.fromURL(widget.pdfUrl);
      setState(() {});
    } catch (e) {
      // Handle the error if the PDF fails to load
      print("Error loading PDF: $e");
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load PDF")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    initializePdf();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 12, 215, 246),
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.5),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.pdfName, // Display the PDF name in the app bar
          style: const TextStyle(
            fontFamily: 'Lobster',
            fontSize: 22,
            color: Color.fromARGB(255, 219, 64, 25),
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 12, 215, 246),
                Color.fromARGB(255, 0, 123, 255),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),  
      body: Container(  
        color: Colors.white,
        child: Center(
          child: document != null
              ? PDFViewer(document: document!)
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text(
                      'Loading PDF...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
