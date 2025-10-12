import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String? _clinicId = 'clinic_demo'; // 기본 클리닉 ID
  bool _isAdmin = false;

  User? get user => _user;
  String? get clinicId => _clinicId;
  bool get isAdmin => _isAdmin;
  bool get isAuthenticated => _user != null && _isAdmin;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;

    if (user != null) {
      // 관리자 권한 확인
      await _checkAdminPermission();
    } else {
      _isAdmin = false;
    }

    notifyListeners();
  }

  Future<bool> _checkAdminPermission() async {
    if (_user == null) {
      _isAdmin = false;
      return false;
    }

    try {
      final adminDoc = await _firestore
          .collection('clinics')
          .doc(_clinicId)
          .collection('admins')
          .doc(_user!.uid)
          .get();

      _isAdmin = adminDoc.exists;
      return _isAdmin;
    } catch (e) {
      print('❌ 관리자 권한 확인 오류: $e');
      _isAdmin = false;
      return false;
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      // Web에서는 popup 방식 사용
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();

      await _auth.signInWithPopup(googleProvider);

      // 관리자 권한 확인
      final isAdmin = await _checkAdminPermission();

      if (!isAdmin) {
        await signOut();
        return '관리자 권한이 없습니다.';
      }

      return null; // 성공
    } catch (e) {
      print('❌ 로그인 오류: $e');
      return '로그인 중 오류가 발생했습니다: $e';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _isAdmin = false;
    notifyListeners();
  }
}
