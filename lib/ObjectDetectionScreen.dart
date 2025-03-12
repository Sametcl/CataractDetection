import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:tflite_v2/tflite_v2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ObjectDetectionScreen extends StatefulWidget {
  const ObjectDetectionScreen({super.key});

  @override
  _ObjectDetectionScreenState createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  String _resultText = "";

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    await Tflite.loadModel(
      model: "assets/modelv2.tflite",
      labels: "assets/labels.txt",
    );
  }

  Future<void> _selectCamera() async {
    // Görüntüyü doğrudan kameradan seç
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      // Görüntüyü doğrudan kırpma işlemine yönlendir
      final croppedImage = await _cropImage(pickedFile);

      if (croppedImage != null) {
        final fileImage = File(croppedImage.path);
        setState(() {
          _image = fileImage;
        });
        detectImage(fileImage);
      }
    }
  }

  Future<void> _selectImageFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final croppedImage = await _cropImage(pickedFile);
      if (croppedImage != null) {
        final fileImage = File(croppedImage.path);
        setState(() {
          _image = fileImage;
        });
        detectImage(fileImage);
      }
    }
  }

  Future<CroppedFile?> _cropImage(XFile image) async {
    return await ImageCropper().cropImage(
      sourcePath: image.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Fotoğraf Düzenleme',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Kırp',
        ),
      ],
    );
  }

  Future<void> detectImage(File image) async {
    var recognitions = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 2,
      threshold: 0.05,
      imageMean: 0.0,
      imageStd: 255.0,
    );

    setState(() {
      _resultText = recognitions != null && recognitions.isNotEmpty
          ? recognitions.map((result) {
        var label = result['label'] as String;
        var confidence = result['confidence'] as double;
        return '%${(confidence * 100).toStringAsFixed(0)} $label';
      }).join(' | ')
          : 'Sonuç bulunamadı.';
    });

    final imageUrl = await uploadImage(image);
    saveToFirestore(imageUrl, _resultText, DateTime.now().toString());
  }

  Future<String> uploadImage(File image) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');
    final snapshot = await ref.putFile(image);
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> saveToFirestore(String imageUrl, String result, String date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('queries')
          .add({
        'image': imageUrl,
        'result': result,
        'date': date,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Arka plan rengi beyaz
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_image != null)
              Image.file(
                _image!,
                height: 250,
                width: 250,
                fit: BoxFit.cover,
              )
            else
              Image.asset(
                'assets/upload.png', // Varsayılan görsel yolu
                height: 250,
                width: 250,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 20),
            Text(
              _resultText,
              style: const TextStyle(
                color: Colors.black, // Yazı rengi siyah
                fontSize: 18, // Yazı boyutu büyütüldü
                fontWeight: FontWeight.bold, // Yazı bold yapıldı
              ),
            ),
            const SizedBox(height: 30), // Görsel ile butonlar arasındaki boşluk
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _selectCamera,
                  icon: const Icon(Icons.camera_alt, color: Colors.white), // Simgenin rengi siyah
                  label: const Text(
                    'Kamera ile çek',
                    style: TextStyle(color: Colors.white), // Yazının rengi siyah
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // Buton rengi mavi
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Border radius
                    ),
                    elevation: 0, // Gölge kaldırıldı
                    minimumSize: const Size(150, 50), // Buton genişlik ve yükseklik
                  ),
                ),
                const SizedBox(width: 20), // Butonlar arası mesafe
                ElevatedButton.icon(
                  onPressed: _selectImageFromGallery,
                  icon: const Icon(Icons.photo, color: Colors.white), // Simgenin rengi siyah
                  label: const Text(
                    'Galeriden seç',
                    style: TextStyle(color: Colors.white), // Yazının rengi siyah
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // Buton rengi mavi
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Border radius
                    ),
                    elevation: 0, // Gölge kaldırıldı
                    minimumSize: const Size(150, 50), // Buton genişlik ve yükseklik
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20), // Butonlar altındaki ekstra boşluk
          ],
        ),
      ),
    );
  }
}