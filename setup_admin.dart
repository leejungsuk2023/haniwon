import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/firebase_options.dart';

/// 관리자 계정 설정 스크립트
///
/// 사용법:
/// 1. adminUsers 리스트에 관리자 정보 추가
/// 2. dart run setup_admin.dart 실행

void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final firestore = FirebaseFirestore.instance;

  const clinicId = 'clinic_demo';

  // 📝 관리자 목록 (실제 Google UID로 변경하세요)
  final adminUsers = [
    {
      'uid': 'REPLACE_WITH_YOUR_GOOGLE_UID',  // ⚠️ 실제 UID로 변경 필수
      'email': 'admin@example.com',
      'name': '관리자',
      'role': 'admin',
      'createdAt': FieldValue.serverTimestamp(),
    },
  ];

  print('🔧 관리자 계정 설정 시작...\n');

  for (var admin in adminUsers) {
    if (admin['uid'] == 'REPLACE_WITH_YOUR_GOOGLE_UID') {
      print('⚠️  UID를 실제 Google UID로 변경해주세요!');
      print('   Google 로그인 후 Firebase Console에서 UID 확인\n');
      continue;
    }

    try {
      await firestore
          .collection('clinics')
          .doc(clinicId)
          .collection('admins')
          .doc(admin['uid'] as String)
          .set(admin);

      print('✅ 관리자 추가: ${admin['name']} (${admin['email']})');
    } catch (e) {
      print('❌ 오류: $e');
    }
  }

  print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('✨ 완료!');
  print('\n📍 관리자 웹 실행:');
  print('   cd admin_web');
  print('   flutter run -d chrome --web-port=8080');
  print('\n🌐 접속: http://localhost:8080');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
}
