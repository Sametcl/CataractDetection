import 'package:eyedetection/HomePage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';  // Flutter SpinKit import

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false; // Şifre görünürlük kontrolü
  String? _emailError; // Email hata mesajı
  String? _passwordError; // Şifre hata mesajı
  String? _otherError; // Diğer hata mesajı
  String? _ethernet; // İnternet bağlantısı hatası
  bool _isLoading = false; // Yükleme durumu

  Future<void> login() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _otherError = null;
    });

    setState(() {
      _isLoading = true; // Yükleme animasyonunu göster
    });

    try {
      // Bir süre bekleme simülasyonu (2 saniye)
      await Future.delayed(Duration(seconds: 1,milliseconds: 50));

      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        print("Giriş başarılı: ${userCredential.user?.email}");

        // Yükleme animasyonunu gösterip, 2 saniye sonra ana sayfaya yönlendir
        await Future.delayed(Duration(seconds: 2));  // Yükleme animasyonunun ne kadar süre gösterileceği

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      print("Hata: ${e.code}");
      if (e.code == 'invalid-email') {
        setState(() {
          _emailError = 'Geçersiz mail formatı';
        });
      } else if (e.code == 'invalid-credential') {
        setState(() {
          _emailError = 'Mail ve şifre eşleşmiyor';
        });
      } else if (e.code == 'network-request-failed') {
        setState(() {
          _ethernet = 'İnternet bağlantınızı kontrol ediniz';
        });
      } else {
        setState(() {
          _emailError = 'Bir hata oluştu, lütfen tekrar deneyin.';
        });
      }
    } finally {
      setState(() {
        _isLoading = false; // Yükleme animasyonunu gizle
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "GİRİŞ YAP",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Arial',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              TextField(
                controller: _emailController,
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.black),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  errorText: _emailError,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                cursorColor: Colors.black,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  labelStyle: TextStyle(color: Colors.black),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  errorText: _passwordError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
              _isLoading  // Yükleme durumu kontrolü
                  ? const Center(
                child: Column(
                  children: [
                    SpinKitFadingCircle(
                      color: Colors.black,  // Yükleme animasyonu rengi
                      size: 60.0,  // Yükleme animasyonu boyutu
                    ),
                    SizedBox(height: 20),
                    Text('Giriş yapılıyor...', style: TextStyle(color: Colors.black)),
                  ],
                ),
              )
                  : ElevatedButton(
                onPressed: login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: const Text(
                  'Giriş Yap',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: "Arial",
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Bir hesabınız yok mu?",
                    style: TextStyle(fontWeight: FontWeight.w500, fontFamily: "Arial", color: Colors.black),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/register');
                    },
                    child: Text(
                      'Hemen Üye Ol!',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: "Arial", color: Colors.black),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
