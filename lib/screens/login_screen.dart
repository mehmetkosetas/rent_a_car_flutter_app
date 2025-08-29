// lib/screens/login_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _firebaseApiKey = "AIzaSyAdasdDxAcgzJIUxzSfMtUXb9dkdiNRNHc";

  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
    });
  }

  void _toggleObscure([bool isConfirm = false]) {
    setState(() {
      if (isConfirm) {
        _obscureConfirm = !_obscureConfirm;
      } else {
        _obscurePassword = !_obscurePassword;
      }
    });
  }

  // HTTP REST API ile kayıt
  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('HTTP REST ile kayıt başlatılıyor...');

      final email = _emailCtrl.text.trim();
      final password = _passCtrl.text;
      final name = _nameCtrl.text.trim();

      // Firebase REST API ile kayıt
      final response = await http.post(
        Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_firebaseApiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final uid = data['localId'];
        final idToken = data['idToken'];

        print('REST ile kullanıcı oluşturuldu: $uid');

        // Firestore'a kaydet
        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'email': email,
          'adSoyad': name,
          'rol': 'üye', // Varsayılan olarak üye rolü
          'telefon': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // İlk kullanıcıyı admin yap (test için)
        if (email == 'admin@test.com') {
          await _firestore.collection('users').doc(uid).update({
            'rol': 'admin',
          });
        }

        // Manuel olarak giriş yap
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        final user = _auth.currentUser;
        if (user != null) {
          await user.updateDisplayName(name);
        }

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomeScreen(cars: [], user: user)),
        );
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error']['message']);
      }
    } catch (e) {
      print('Kayıt hatası: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = _mapRestErrorToMessage(e.toString());
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Hata mesajları için yardımcı fonksiyon
  String _mapRestErrorToMessage(String error) {
    if (error.contains('EMAIL_EXISTS')) {
      return 'Bu email zaten kullanımda.';
    } else if (error.contains('WEAK_PASSWORD')) {
      return 'Şifre çok zayıf. En az 6 karakter olmalı.';
    } else if (error.contains('INVALID_EMAIL')) {
      return 'Geçersiz email adresi.';
    }
    return 'Kayıt başarısız. Tekrar deneyin.';
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Giriş işlemi başlatılıyor...');

      final userCred = await _auth.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      final user = userCred.user;
      if (user == null) throw Exception('Kullanıcı bulunamadı!');

      print('Kullanıcı giriş yaptı: ${user.uid}');

      // Kullanıcı dokümanını kontrol et
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        print('Kullanıcı belgesi oluşturuluyor...');
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email ?? '',
          'adSoyad': user.displayName ?? 'Kullanıcı',
          'rol': 'üye',
          'telefon': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(cars: [], user: user)),
      );
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuth hatası: ${e.code}');
      if (!mounted) return;
      setState(() {
        _errorMessage = _mapFirebaseErrorToMessage(e.code);
      });
    } catch (e) {
      print('Genel hata: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Giriş başarısız. Tekrar deneyin.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    print(_isLogin ? "LOGIN çağrıldı" : "REGISTER çağrıldı");

    if (_isLogin) {
      await _login();
    } else {
      await _register();
    }
  }

  String _mapFirebaseErrorToMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Geçersiz email adresi.';
      case 'user-not-found':
        return 'Kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Yanlış şifre.';
      case 'email-already-in-use':
        return 'Bu email zaten kullanımda.';
      case 'weak-password':
        return 'Şifre çok zayıf.';
      case 'permission-denied':
        return 'Veritabanı erişim izni reddedildi.';
      default:
        return 'Bir hata oluştu. ($code)';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF3949AB), Color(0xFF5C6BC0)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo and title section
                      Container(
                        margin: EdgeInsets.only(bottom: 40),
                        child: Column(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Colors.orange, Colors.deepOrange],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.directions_car,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'RentaCar',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Hayallerinizdeki aracı kiralayın',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Form card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        _isLogin
                                            ? Color(0xFF1A237E)
                                            : Colors.deepOrange,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  _isLogin
                                      ? 'Hesabınıza giriş yapın'
                                      : 'Yeni hesap oluşturun',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 32),

                                if (!_isLogin) ...[
                                  _buildTextField(
                                    controller: _nameCtrl,
                                    label: 'Ad ve Soyad',
                                    icon: Icons.person_outline,
                                    validator:
                                        (v) =>
                                            (v == null || v.trim().length < 3)
                                                ? 'En az 3 karakter girin'
                                                : null,
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                _buildTextField(
                                  controller: _emailCtrl,
                                  label: 'Email',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator:
                                      (v) =>
                                          (v == null || !v.contains('@'))
                                              ? 'Geçerli email girin'
                                              : null,
                                ),
                                const SizedBox(height: 20),

                                _buildTextField(
                                  controller: _passCtrl,
                                  label: 'Şifre',
                                  icon: Icons.lock_outline,
                                  obscureText: _obscurePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.grey[600],
                                    ),
                                    onPressed: () => _toggleObscure(false),
                                  ),
                                  validator:
                                      (v) =>
                                          (v == null || v.length < 6)
                                              ? 'En az 6 karakter girin'
                                              : null,
                                ),
                                const SizedBox(height: 20),

                                if (!_isLogin) ...[
                                  _buildTextField(
                                    controller: _confirmCtrl,
                                    label: 'Parolayı Onayla',
                                    icon: Icons.lock_outline,
                                    obscureText: _obscureConfirm,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirm
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: Colors.grey[600],
                                      ),
                                      onPressed: () => _toggleObscure(true),
                                    ),
                                    validator:
                                        (v) =>
                                            (v != _passCtrl.text)
                                                ? 'Şifreler uyuşmuyor'
                                                : null,
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                if (_errorMessage != null) ...[
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.red.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors:
                                          _isLogin
                                              ? [
                                                Colors.orange,
                                                Colors.deepOrange,
                                              ]
                                              : [Colors.blue, Colors.indigo],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_isLogin
                                                ? Colors.orange
                                                : Colors.blue)
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child:
                                        _isLoading
                                            ? SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                                color: Colors.white,
                                              ),
                                            )
                                            : Text(
                                              _isLogin
                                                  ? 'Giriş Yap'
                                                  : 'Kayıt Ol',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                TextButton(
                                  onPressed: _isLoading ? null : _toggleMode,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: Text(
                                    _isLogin
                                        ? 'Hesabınız yok mu? Kayıt Ol'
                                        : 'Hesabınız var mı? Giriş Yap',
                                    style: TextStyle(
                                      color: Color(0xFF1A237E),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }
}
