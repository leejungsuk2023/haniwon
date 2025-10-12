import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// 샘플 데이터를 Firebase에 추가하는 스크립트
///
/// 실행 방법:
/// ```
/// dart run add_sample_data.dart
/// ```

Future<void> main() async {
  print('🚀 Firebase 초기화 중...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;

  print('📄 샘플 데이터 파일 읽기...');
  final file = File('sample_data.json');
  final jsonString = await file.readAsString();
  final data = json.decode(jsonString) as Map<String, dynamic>;

  final clinicId = 'clinic1';
  final clinicData = data['clinics']['clinic1'] as Map<String, dynamic>;

  print('\n🏥 한의원 정보 추가 중...');
  await firestore.collection('clinics').doc(clinicId).set({
    'name': clinicData['name'],
    'address': clinicData['address'],
    'phone': clinicData['phone'],
    'createdAt': Timestamp.fromDate(DateTime.parse(clinicData['createdAt'])),
  });
  print('   ✅ 한의원 정보 추가 완료');

  // 환자 데이터 추가
  print('\n👤 환자 데이터 추가 중...');
  final patients = clinicData['patients'] as Map<String, dynamic>;
  for (var entry in patients.entries) {
    final patientId = entry.key;
    final patient = entry.value as Map<String, dynamic>;

    await firestore
        .collection('clinics')
        .doc(clinicId)
        .collection('patients')
        .doc(patientId)
        .set({
      'name': patient['name'],
      'phone': patient['phone'],
      'birth': patient['birth'],
      'gender': patient['gender'],
      'address': patient['address'],
      'points': patient['points'],
      'visits': patient['visits'],
      'lastVisit': Timestamp.fromDate(DateTime.parse(patient['lastVisit'])),
      'createdAt': Timestamp.fromDate(DateTime.parse(patient['createdAt'])),
    });
    print('   ✅ ${patient['name']} 추가 완료');
  }

  // 케어 플랜 추가
  print('\n📋 케어 플랜 추가 중...');
  final carePlans = clinicData['carePlans'] as Map<String, dynamic>;
  for (var entry in carePlans.entries) {
    final planId = entry.key;
    final plan = entry.value as Map<String, dynamic>;

    final quests = (plan['quests'] as List).map((q) {
      final quest = q as Map<String, dynamic>;
      return {
        'id': quest['id'],
        'title': quest['title'],
        'completed': quest['completed'],
        if (quest['completedAt'] != null)
          'completedAt': Timestamp.fromDate(DateTime.parse(quest['completedAt'])),
      };
    }).toList();

    await firestore
        .collection('clinics')
        .doc(clinicId)
        .collection('carePlans')
        .doc(planId)
        .set({
      'patientId': plan['patientId'],
      'title': plan['title'],
      'description': plan['description'],
      'status': plan['status'],
      'quests': quests,
      'progress': plan['progress'],
      'createdAt': Timestamp.fromDate(DateTime.parse(plan['createdAt'])),
      if (plan['completedAt'] != null)
        'completedAt': Timestamp.fromDate(DateTime.parse(plan['completedAt'])),
    });
    print('   ✅ ${plan['title']} 추가 완료');
  }

  // 제품 추가
  print('\n🛍️ 제품 데이터 추가 중...');
  final products = clinicData['products'] as Map<String, dynamic>;
  for (var entry in products.entries) {
    final productId = entry.key;
    final product = entry.value as Map<String, dynamic>;

    await firestore
        .collection('clinics')
        .doc(clinicId)
        .collection('products')
        .doc(productId)
        .set({
      'name': product['name'],
      'description': product['description'],
      'price': product['price'],
      'points': product['points'],
      'stock': product['stock'],
      'category': product['category'],
      'imageUrl': product['imageUrl'],
      'createdAt': Timestamp.fromDate(DateTime.parse(product['createdAt'])),
    });
    print('   ✅ ${product['name']} 추가 완료');
  }

  // 구매 데이터 추가
  print('\n💳 구매 데이터 추가 중...');
  final purchases = clinicData['purchases'] as Map<String, dynamic>;
  for (var entry in purchases.entries) {
    final purchaseId = entry.key;
    final purchase = entry.value as Map<String, dynamic>;

    final purchaseData = {
      'productId': purchase['productId'],
      'productName': purchase['productName'],
      'patientId': purchase['patientId'],
      'points': purchase['points'],
      'status': purchase['status'],
      'createdAt': Timestamp.fromDate(DateTime.parse(purchase['createdAt'])),
    };

    if (purchase['approvedAt'] != null) {
      purchaseData['approvedAt'] =
          Timestamp.fromDate(DateTime.parse(purchase['approvedAt']));
    }
    if (purchase['rejectedAt'] != null) {
      purchaseData['rejectedAt'] =
          Timestamp.fromDate(DateTime.parse(purchase['rejectedAt']));
    }
    if (purchase['completedAt'] != null) {
      purchaseData['completedAt'] =
          Timestamp.fromDate(DateTime.parse(purchase['completedAt']));
    }
    if (purchase['rejectionReason'] != null) {
      purchaseData['rejectionReason'] = purchase['rejectionReason'];
    }

    await firestore
        .collection('clinics')
        .doc(clinicId)
        .collection('purchases')
        .doc(purchaseId)
        .set(purchaseData);
    print('   ✅ ${purchase['productName']} 구매 추가 완료');
  }

  // 게시글 및 댓글 추가
  print('\n💬 커뮤니티 게시글 추가 중...');
  final posts = clinicData['posts'] as Map<String, dynamic>;
  for (var entry in posts.entries) {
    final postId = entry.key;
    final post = entry.value as Map<String, dynamic>;

    await firestore
        .collection('clinics')
        .doc(clinicId)
        .collection('posts')
        .doc(postId)
        .set({
      'title': post['title'],
      'content': post['content'],
      'authorId': post['authorId'],
      'authorName': post['authorName'],
      'likeCount': post['likeCount'],
      'commentCount': post['commentCount'],
      'createdAt': Timestamp.fromDate(DateTime.parse(post['createdAt'])),
    });
    print('   ✅ ${post['title']} 추가 완료');

    // 댓글 추가
    if (post['comments'] != null) {
      final comments = post['comments'] as Map<String, dynamic>;
      for (var commentEntry in comments.entries) {
        final commentId = commentEntry.key;
        final comment = commentEntry.value as Map<String, dynamic>;

        await firestore
            .collection('clinics')
            .doc(clinicId)
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .set({
          'content': comment['content'],
          'authorId': comment['authorId'],
          'authorName': comment['authorName'],
          'createdAt': Timestamp.fromDate(DateTime.parse(comment['createdAt'])),
        });
      }
      print('      💬 댓글 ${comments.length}개 추가 완료');
    }
  }

  print('\n✨ 모든 샘플 데이터 추가 완료!');
  print('\n📊 추가된 데이터 요약:');
  print('   - 환자: ${patients.length}명');
  print('   - 케어 플랜: ${carePlans.length}개');
  print('   - 제품: ${products.length}개');
  print('   - 구매: ${purchases.length}건');
  print('   - 게시글: ${posts.length}개');

  print('\n🌐 관리자 페이지에서 확인하세요: http://localhost:8080');

  exit(0);
}
