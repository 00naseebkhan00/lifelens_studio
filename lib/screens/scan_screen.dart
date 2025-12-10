import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/gemini_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  Uint8List? selectedImageBytes;
  String? _mimeType;
  String? _analysisText;
  bool _isLoading = false;

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final file = result.files.single;

      String mime = 'image/png';
      final ext = file.extension?.toLowerCase();
      if (ext == 'jpg' || ext == 'jpeg') {
        mime = 'image/jpeg';
      } else if (ext == 'png') {
        mime = 'image/png';
      }

      setState(() {
        selectedImageBytes = file.bytes;
        _mimeType = mime;
        _analysisText = null;
      });
    }
  }

  Future<void> analyzeImage() async {
    if (selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick an image first.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _analysisText = null;
    });

    try {
      final text = await GeminiService.analyzeImage(
        selectedImageBytes!,
        mimeType: _mimeType ?? 'image/png',
      );

      setState(() {
        _analysisText = text;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error from AI: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Mode 🔍'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF050814),
              Color(0xFF090F26),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                children: [
                  // Top image card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.white.withOpacity(0.03),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : pickImage,
                          child: const Text('Pick Image'),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 220,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: Colors.white.withOpacity(0.02),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: selectedImageBytes != null
                              ? Image.memory(
                                  selectedImageBytes!,
                                  fit: BoxFit.contain,
                                )
                              : const Center(
                                  child: Text(
                                    'No image selected yet.',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.white60,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        if (selectedImageBytes != null)
                          ElevatedButton(
                            onPressed: _isLoading ? null : analyzeImage,
                            child: const Text('Analyze with AI'),
                          ),
                        if (_isLoading) ...[
                          const SizedBox(height: 12),
                          const CircularProgressIndicator(),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Result card
                  if (_analysisText != null && !_isLoading)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.white.withOpacity(0.03),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI Insight',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _analysisText!,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: _GeminiBadge(),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GeminiBadge extends StatelessWidget {
  const _GeminiBadge();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.9,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white24),
          color: Colors.white.withOpacity(0.05),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.auto_awesome, size: 16),
            SizedBox(width: 6),
            Text(
              'Powered by Google Gemini',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}