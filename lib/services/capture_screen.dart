import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'gemini_service.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  Uint8List? selectedImageBytes;

  bool _isLoading = false;
  String? _rawText;
  String? _title;
  String? _description;
  String? _vibeFilter;
  List<String> _tips = [];
  String? _errorText;
  String? _mimeType;

  bool _showStyled = true; // toggle Original / Styled

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
        _rawText = null;
        _title = null;
        _description = null;
        _vibeFilter = null;
        _tips = [];
        _errorText = null;
        _showStyled = true;
      });
    }
  }

  Future<void> analyzeWithAI() async {
    if (selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick an image first.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _rawText = null;
      _title = null;
      _description = null;
      _vibeFilter = null;
      _tips = [];
      _errorText = null;
    });

    try {
      final text = await GeminiService.analyzeImage(
        selectedImageBytes!,
        mimeType: _mimeType ?? 'image/png',
      );

      final parsed = _parseAnalysis(text);

      setState(() {
        _rawText = text;
        _title = parsed['title'] as String?;
        _description = parsed['description'] as String?;
        _tips = (parsed['tips'] as List<String>?) ?? [];
        _vibeFilter = _pickVibeFromText(text);
        _showStyled = true;
      });
    } catch (e) {
      setState(() {
        _errorText = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error from AI, see details below.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Parse AI text into title, description and tips (with fallback).
  Map<String, dynamic> _parseAnalysis(String text) {
    final lines = text.split('\n');

    String? title;
    final descLines = <String>[];
    final tips = <String>[];

    bool inTips = false;

    for (var raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      if (title == null) {
        title = line.replaceAll('*', '').trim();
        continue;
      }

      final lower = line.toLowerCase();
      if (lower.startsWith('tips')) {
        inTips = true;
        continue;
      }

      if (inTips) {
        if (line.startsWith('-')) {
          tips.add(line.substring(1).trim());
        } else {
          tips.add(line);
        }
      } else {
        descLines.add(line);
      }
    }

    var description = descLines.join(' ');

    // Fallback: if no tips yet, look for "Tips:" inside full text
    if (tips.isEmpty) {
      final lowerFull = text.toLowerCase();
      final idx = lowerFull.indexOf('tips:');
      if (idx != -1) {
        final after = text.substring(idx + 'tips:'.length).trim();
        final sentences = after.split(RegExp(r'[.!?]'));
        for (final raw in sentences) {
          final s = raw.trim();
          if (s.length < 8) continue;
          tips.add(s);
          if (tips.length >= 4) break;
        }
      }
    }

    return {
      'title': title ?? 'Photo analysis',
      'description': description,
      'tips': tips,
    };
  }

  /// Vibe picker based on keywords.
  String _pickVibeFromText(String text) {
    final lower = text.toLowerCase();

    if (lower.contains('night') ||
        lower.contains('dark') ||
        lower.contains('street') ||
        lower.contains('neon')) {
      return 'Midnight Street Glow';
    }
    if (lower.contains('sunset') ||
        lower.contains('golden') ||
        lower.contains('warm')) {
      return 'Golden Hour Warmth';
    }
    if (lower.contains('baby') ||
        lower.contains('child') ||
        lower.contains('family')) {
      return 'Soft Family Dream';
    }
    if (lower.contains('food') ||
        lower.contains('dish') ||
        lower.contains('meal') ||
        lower.contains('plate')) {
      return 'Foodie Pop';
    }
    if (lower.contains('city') ||
        lower.contains('buildings') ||
        lower.contains('urban')) {
      return 'Urban Story';
    }
    if (lower.contains('portrait') || lower.contains('face')) {
      return 'Crisp Portrait Focus';
    }
    if (lower.contains('landscape') ||
        lower.contains('mountain') ||
        lower.contains('sky') ||
        lower.contains('nature')) {
      return 'Cinematic Nature View';
    }

    return 'Clean Neutral Look';
  }

  /// Build filtered image based on selected vibe + toggle.
  Widget _buildFilteredImage() {
    if (selectedImageBytes == null) {
      return const SizedBox.shrink();
    }

    // 🔥 IMPORTANT CHANGE: use BoxFit.contain so whole image is visible
    final baseImage = ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.memory(
        selectedImageBytes!,
        fit: BoxFit.contain,
      ),
    );

    if (!_showStyled || _vibeFilter == null) {
      return baseImage;
    }

    Color tint;
    switch (_vibeFilter) {
      case 'Midnight Street Glow':
        tint = Colors.blueGrey.shade700;
        break;
      case 'Golden Hour Warmth':
        tint = Colors.orangeAccent.shade200;
        break;
      case 'Soft Family Dream':
        tint = Colors.pinkAccent.shade100;
        break;
      case 'Foodie Pop':
        tint = Colors.redAccent.shade200;
        break;
      case 'Urban Story':
        tint = Colors.teal.shade300;
        break;
      case 'Crisp Portrait Focus':
        tint = Colors.deepPurple.shade200;
        break;
      case 'Cinematic Nature View':
        tint = Colors.greenAccent.shade200;
        break;
      default:
        tint = Colors.white.withOpacity(0.0);
    }

    if (tint.opacity == 0.0) {
      return baseImage;
    }

    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        tint.withOpacity(0.25),
        BlendMode.softLight,
      ),
      child: baseImage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Mode 📸'),
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
                  // Image + controls card
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
                        if (selectedImageBytes != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ChoiceChip(
                                label: const Text('Original'),
                                selected: !_showStyled,
                                onSelected: (val) {
                                  setState(() {
                                    _showStyled = !val;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('Styled'),
                                selected: _showStyled,
                                onSelected: (val) {
                                  setState(() {
                                    _showStyled = val;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        Container(
                          height: 230,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: Colors.white.withOpacity(0.02),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: selectedImageBytes != null
                              ? _buildFilteredImage()
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
                            onPressed: _isLoading ? null : analyzeWithAI,
                            child: const Text('Analyze Photo Style'),
                          ),
                        if (_isLoading) ...[
                          const SizedBox(height: 12),
                          const CircularProgressIndicator(),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Analysis card
                  if (!_isLoading &&
                      selectedImageBytes != null &&
                      (_title != null || _errorText != null))
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
                          if (_title != null) ...[
                            Text(
                              _title!,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (_vibeFilter != null)
                              Text(
                                'Vibe filter: $_vibeFilter',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white70,
                                ),
                              ),
                            const SizedBox(height: 10),
                            if (_description != null &&
                                _description!.isNotEmpty)
                              Text(
                                _description!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            const SizedBox(height: 12),
                            const Text(
                              'Tips:',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (_tips.isEmpty)
                              const Text(
                                '- No tips parsed. Try another photo or re-analyze.',
                                style: TextStyle(fontSize: 14),
                              )
                            else
                              ..._tips.map(
                                (t) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    '- $t',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            const _GeminiBadge(),
                          ],
                          if (_errorText != null) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Debug info:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                            Text(
                              _errorText!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
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