import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
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

  final ImagePicker _imagePicker = ImagePicker();
  final String apiKey = 'AIzaSyBjJMO11otAraQm7Cj2qPz9mshODLy7zLE';
  late final GenerativeModel model;

  @override
  void initState() {
    super.initState();
    model = GenerativeModel(
      model: 'gemini-1.5-flash-8b',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 1,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 8192,
        responseMimeType: 'text/plain',
      ),
    );
  }

  Future<void> getImage() async {
    XFile? result = await _imagePicker.pickImage(source: ImageSource.gallery);

    if (result != null) {
      setState(() {
        pickImage = result;
      });
    }
  }

  Future<void> uploadAndGenerate() async {
    if (pickImage == null) return;

    setState(() {
      loader = true;
      myText = '';
    });

    try {
      // Upload the file
      List<int> imageBytes = File(pickImage!.path).readAsBytesSync();
      String base64File = base64.encode(imageBytes);

      final myFile = Content.multi([
        TextPart('data:image/jpeg;base64,$base64File'),
        TextPart('\n\n'),
        TextPart('Can you tell me about the instruments in this photo?')
      ]);

      // Generate content using the model
      final result = await model.generateContent([myFile]);

      setState(() {
        myText = result.text ?? 'No response'; // Adding null check
      });
    } catch (e) {
      setState(() {
        myText = 'Error: $e';
      });
    } finally {
      setState(() {
        loader = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Descriptor'),
      ),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            pickImage == null
                ? Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Text('No Image Selected')),
                  )
                : Image.file(File(pickImage!.path),
                    height: 200, fit: BoxFit.cover),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: getImage,
              child: Text('Select Image'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: uploadAndGenerate,
              child: Text('Generate Description'),
            ),
            SizedBox(height: 20),
            if (loader)
              CircularProgressIndicator()
            else
              Text(myText,
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
