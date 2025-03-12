import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isPasswordVisible = false; // Şifre görünürlük kontrolü
  String? _emailError; // Email hata mesajı
  String? _passwordError; // Şifre hata mesajı
  String? _usernameError; // Kullanıcı adı hata mesajı

  Future<void> register() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _usernameError = null;
    });

    try {
      // Kullanıcıyı Firebase ile kaydetme
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Kullanıcı bilgilerini Firestore'a kaydetme
      await FirebaseFirestore.instance.collection('users').doc(
          userCredential.user?.uid).set({
        'email': _emailController.text,
        'username': _usernameController.text,
        'uid': userCredential.user?.uid,
      });

      // Kayıt başarılı, giriş ekranına yönlendir
      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      print("Hatamız: ${e.code}");
      if (e.code == 'email-already-in-use') {
        setState(() {
          _emailError = 'Bu email zaten kayıtlı.';
        });
      } else if (e.code == 'weak-password') {
        setState(() {
          _passwordError =
          'Şifreniz çok zayıf. Lütfen daha güçlü bir şifre girin.';
        });
      } else if (e.code == 'invalid-email') {
        setState(() {
          _emailError = 'Geçersiz bir email adresi.';
        });
      } else {
        setState(() {
          _emailError = 'Bir hata oluştu, lütfen tekrar deneyin.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Arka plan beyaz
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "KAYIT OL",
                style: TextStyle(
                  fontSize: 32, // Yazı boyutunu artırdık
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // Siyah renkte
                  fontFamily: 'Arial', // Font Arial olarak değiştirildi
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _usernameController,
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  labelText: 'Kullanıcı Adı',
                  labelStyle: const TextStyle(color: Colors.black),
                  // Label siyah yapıldı
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.black), // Çerçeve siyah yapıldı
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.black), // Odaklandığında siyah
                  ),
                  errorText: _usernameError, // Kullanıcı adı hata mesajı
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.black),
                  // Label siyah yapıldı
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.black), // Çerçeve siyah yapıldı
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.black), // Odaklandığında siyah
                  ),
                  errorText: _emailError, // Email hata mesajı
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                cursorColor: Colors.black,
                obscureText: !_isPasswordVisible, // Şifre görünürlük kontrolü
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  labelStyle: const TextStyle(color: Colors.black),
                  // Label siyah yapıldı
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.black), // Çerçeve siyah yapıldı
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.black), // Odaklandığında siyah
                  ),
                  errorText: _passwordError,
                  // Şifre hata mesajı
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons
                          .visibility_off,
                      color: Colors.black, // İkon rengi siyah yapıldı
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible =
                        !_isPasswordVisible; // Şifre görünürlüğünü değiştir
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Buton siyah yapıldı
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: const Text(
                  'Kayıt Ol',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: "Arial",
                    color: Colors.white, // Yazı beyaz
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Zaten üye misiniz?",
                    style: TextStyle(fontWeight: FontWeight.w500,
                        fontFamily: "Arial",
                        color: Colors.black),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text(
                      'Giriş Yapınız',
                      style: TextStyle(fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Arial",
                          color: Colors.black),
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
