import 'package:eyedetection/HomePage.dart';
import 'package:eyedetection/LoginPage.dart';
import 'package:eyedetection/ObjectDetectionScreen.dart';
import 'package:eyedetection/RegisterPage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cataract Detection',

      debugShowCheckedModeBanner:false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => HomePage(),
        '/eyetest':(context) =>ObjectDetectionScreen(),
      },
    );
  }
}
