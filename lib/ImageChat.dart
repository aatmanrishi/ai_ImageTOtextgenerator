import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ImageChat extends StatefulWidget {
  const ImageChat({super.key});

  @override
  State<ImageChat> createState() => _ImageChatState();
}

class _ImageChatState extends State<ImageChat> {
  XFile? pickImage;
  String myText = '';
  bool loader = false;
  final TextEditingController _promptController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Replace with your actual API key!  **Crucially**
  final String apiKey = 'AIzaSyClFQxzrP3r_m-LqbUpueyz0DgI4WXzKpU';
  late GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-pro', // Or another suitable model
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        maxOutputTokens: 150,
        temperature: 0.7, // Adjust as needed
        responseMimeType: 'text/plain',
      ),
    );
  }

  Future getImage() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        pickImage = pickedImage;
      });
    }
  }

  Future uploadAndGenerate() async {
    if (pickImage == null) {
      setState(() {
        myText = 'Please select an image.';
      });
      return;
    }

    final prompt = _promptController.text;
    if (prompt.isEmpty) {
      setState(() {
        myText = 'Please enter a prompt.';
      });
      return;
    }

    setState(() {
      loader = true;
      myText = '';
    });

    try {
      final imageBytes = File(pickImage!.path).readAsBytesSync();
      final base64Image = base64Encode(imageBytes);

      final content = Content.multi([
        TextPart('data:image/jpeg;base64,$base64Image'),
        TextPart(prompt),
      ]);

      final result = await _model.generateContent([content]);
      setState(() {
        myText = result.text ?? 'No response from model.';
        loader = false;
      });
    } catch (e) {
      setState(() {
        myText = 'Error: $e';
        loader = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Descriptor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            pickImage == null
                ? Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey), // Grey border
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(child: Text('No Image Selected')),
                  )
                : Image.file(
                    File(pickImage!.path),
                    height: 200,
                    fit: BoxFit.cover,
                  ),
            const SizedBox(height: 20),
            TextField(
              controller: _promptController,
              decoration:
                  const InputDecoration(hintText: 'Enter your prompt...'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: getImage,
              child: const Text('Select Image'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: uploadAndGenerate,
              child: const Text('Generate Description'),
            ),
            const SizedBox(height: 20),
            Visibility(
              visible: loader,
              child: const CircularProgressIndicator(),
            ),
            if (!loader)
              Text(
                myText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }
}
