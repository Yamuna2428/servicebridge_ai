import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import '../services/ai_service.dart';
import '../models/ai_issue_analysis_model.dart';
import 'worker_list_screen.dart';

class AiIssueAnalyzerScreen extends StatefulWidget {
  const AiIssueAnalyzerScreen({super.key});

  @override
  State<AiIssueAnalyzerScreen> createState() => _AiIssueAnalyzerScreenState();
}

class _AiIssueAnalyzerScreenState extends State<AiIssueAnalyzerScreen> {
  final _aiService = AiService();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  final _speech = stt.SpeechToText();

  bool _isLoading = false;
  bool _isListening = false;
  File? _image;
  Uint8List? _imageBytes;
  AiIssueAnalysisModel? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      await _speech.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      // Speech recognition not available
    }
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) {
          if (mounted) {
            setState(() {
              _descriptionController.text = val.recognizedWords;
            });
          }
        },
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition is not available on this device.')),
        );
      }
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _image = File(pickedFile.path);
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _image = null;
      _imageBytes = null;
    });
  }

  Future<void> _analyze() async {
    final text = _descriptionController.text.trim();
    if (text.isEmpty && _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a description or a photo of the problem.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final result = await _aiService.analyzeIssue(text, imageBytes: _imageBytes);
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Issue Analyzer'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.psychology_outlined, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Describe your problem in detail',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gemini AI will analyze it and suggest the right professional and safety steps.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            // Input Area with Mic and Camera
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                color: Colors.grey[50],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Describe your problem or use icons below...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening ? Colors.red : Colors.blue,
                          ),
                          onPressed: _isListening ? _stopListening : _startListening,
                          tooltip: 'Voice Input',
                        ),
                        IconButton(
                          icon: const Icon(Icons.camera_alt_outlined, color: Colors.blue),
                          onPressed: () => _pickImage(ImageSource.camera),
                          tooltip: 'Capture Photo',
                        ),
                        IconButton(
                          icon: const Icon(Icons.photo_library_outlined, color: Colors.blue),
                          onPressed: () => _pickImage(ImageSource.gallery),
                          tooltip: 'Pick from Gallery',
                        ),
                        const Spacer(),
                        if (_isListening)
                          const Text(
                            'Listening...',
                            style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_image != null) ...[
              const SizedBox(height: 16),
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(_image!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white.withAlpha(204),
                          child: IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.blue),
                            onPressed: () => _pickImage(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: Colors.white.withAlpha(204),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: _removeImage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _analyze,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Analyze with AI'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[100]!),
                ),
                child: Column(
                  children: [
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _analyze,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ],
            if (_result != null) _buildResult(_result!),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(AiIssueAnalysisModel result) {
    Color urgencyColor;
    switch (result.urgency.toLowerCase()) {
      case 'emergency': urgencyColor = Colors.red; break;
      case 'high': urgencyColor = Colors.orange; break;
      case 'medium': urgencyColor = Colors.blue; break;
      default: urgencyColor = Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('AI Diagnostic Result', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: urgencyColor.withAlpha(26),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: urgencyColor),
              ),
              child: Text(
                result.urgency,
                style: TextStyle(color: urgencyColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildInfoCard('Detected Problem', result.detectedProblem, Icons.search),
        _buildInfoCard('Recommended Service', result.recommendedService, Icons.work_outline),
        _buildInfoCard('AI Explanation', result.explanation, Icons.info_outline),
        
        const SizedBox(height: 16),
        const Text('Safety Precautions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...result.precautions.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(p)),
            ],
          ),
        )),

        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: result.immediateProfessionalHelp ? Colors.red[50] : Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: result.immediateProfessionalHelp ? Colors.red : Colors.blue),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    result.immediateProfessionalHelp ? Icons.warning : Icons.engineering,
                    color: result.immediateProfessionalHelp ? Colors.red : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  const Text('Professional Recommendation', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text(result.professionalRecommendation),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkerListScreen(
                    serviceName: result.recommendedService,
                    isFromAiAnalyzer: true,
                    problemDescription: _descriptionController.text.trim(),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.person_search),
            label: Text('Find ${result.recommendedService}s'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 40),
        const Text(
          'Disclaimer: This is general guidance only and does not replace inspection by a qualified professional.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.blue),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
