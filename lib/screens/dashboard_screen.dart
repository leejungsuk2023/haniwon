import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import 'patients_screen.dart';
import 'purchases_screen.dart';
import 'products_screen.dart';
import 'community_screen.dart';
import 'invitation_codes_screen.dart';
import 'quest_management_screen.dart';
import 'admin_chat_screen.dart';
import 'recipes_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardHome(),
    const PatientsScreen(),
    const InvitationCodesScreen(),
    const QuestManagementScreen(),
    const RecipesScreen(),
    const AdminChatScreen(),
    const PurchasesScreen(),
    const ProductsScreen(),
    const CommunityScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.selected,
            backgroundColor: const Color(0xFF2E7D32),
            selectedIconTheme: const IconThemeData(color: Colors.white),
            selectedLabelTextStyle: const TextStyle(color: Colors.white),
            unselectedIconTheme: const IconThemeData(color: Colors.white70),
            unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
            leading: Column(
              children: [
                const SizedBox(height: 16),
                const Icon(
                  Icons.local_hospital,
                  size: 40,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                const Text(
                  '한의원 관리',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
            trailing: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    authProvider.user?.displayName ?? '관리자',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () async {
                      await authProvider.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacementNamed('/');
                      }
                    },
                    tooltip: '로그아웃',
                  ),
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('대시보드'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('환자 관리'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.vpn_key),
                label: Text('초대코드'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.list_alt),
                label: Text('퀘스트 관리'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.restaurant_menu),
                label: Text('식단 관리'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.chat),
                label: Text('채팅'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.shopping_cart),
                label: Text('구매 승인'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory),
                label: Text('상품 관리'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.forum),
                label: Text('커뮤니티'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main Content
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  Future<void> _addSampleData(BuildContext context, AuthProvider authProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('샘플 데이터 추가'),
        content: const Text(
          '테스트용 샘플 데이터를 추가하시겠습니까?\n\n'
          '추가될 데이터:\n'
          '• 환자 4명\n'
          '• 초대코드 4개\n'
          '• 케어 플랜 3개\n'
          '• 제품 6개\n'
          '• 구매 내역 3건\n'
          '• 게시글 2개',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('추가'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final clinicId = authProvider.clinicId ?? 'clinic1';

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('샘플 데이터 추가 중...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Add clinic info if not exists
      await firestore.collection('clinics').doc(clinicId).set({
        'name': '서울 한의원',
        'address': '서울시 강남구 테헤란로 123',
        'phone': '02-1234-5678',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Add patients
      final patients = {
        'patient1': {'name': '김민수', 'chartNumber': 'C001', 'phone': '010-1234-5678', 'points': 150, 'visits': 5},
        'patient2': {'name': '이지은', 'chartNumber': 'C002', 'phone': '010-2345-6789', 'points': 200, 'visits': 8},
        'patient3': {'name': '박준호', 'chartNumber': 'C003', 'phone': '010-3456-7890', 'points': 80, 'visits': 3},
        'patient4': {'name': '정수아', 'chartNumber': 'C004', 'phone': '010-4567-8901', 'points': 50, 'visits': 2},
      };

      for (var entry in patients.entries) {
        await firestore
            .collection('clinics')
            .doc(clinicId)
            .collection('patients')
            .doc(entry.key)
            .set({
          'name': entry.value['name'],
          'chartNumber': entry.value['chartNumber'],
          'phone': entry.value['phone'],
          'birth': '1990-01-01',
          'gender': '남성',
          'address': '서울시',
          'points': entry.value['points'],
          'visits': entry.value['visits'],
          'lastVisit': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Add invitation codes
      final invitationCodes = {
        'code1': {'code': 'A3K9P2', 'patientId': 'patient1'},
        'code2': {'code': 'H7M4X5', 'patientId': 'patient2'},
        'code3': {'code': 'R8N2Q6', 'patientId': 'patient3'},
        'code4': {'code': 'T5W9L3', 'patientId': 'patient4'},
      };

      for (var entry in invitationCodes.entries) {
        final expiresAt = DateTime.now().add(const Duration(days: 30));
        await firestore
            .collection('clinics')
            .doc(clinicId)
            .collection('invitationCodes')
            .doc(entry.key)
            .set({
          'code': entry.value['code'],
          'patientId': entry.value['patientId'],
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(expiresAt),
        });
      }

      // Add care plans
      await firestore.collection('clinics').doc(clinicId).collection('carePlans').doc('plan1').set({
        'patientId': 'patient1',
        'title': '요통 집중 관리 프로그램',
        'description': '만성 요통 개선을 위한 4주 케어 플랜',
        'status': 'active',
        'quests': [
          {'id': 'q1', 'title': '매일 아침 스트레칭 10분', 'completed': true},
          {'id': 'q2', 'title': '침 치료 주 2회 받기', 'completed': false},
          {'id': 'q3', 'title': '한약 복용 아침/저녁', 'completed': false},
        ],
        'progress': 33,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await firestore.collection('clinics').doc(clinicId).collection('carePlans').doc('plan2').set({
        'patientId': 'patient2',
        'title': '불면증 개선 케어',
        'description': '수면의 질 향상을 위한 2주 집중 관리',
        'status': 'active',
        'quests': [
          {'id': 'q4', 'title': '취침 2시간 전 스마트폰 사용 금지', 'completed': true},
          {'id': 'q5', 'title': '매일 족욕 15분', 'completed': true},
          {'id': 'q6', 'title': '이완 차 마시기', 'completed': true},
        ],
        'progress': 100,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add products
      final products = [
        {'id': 'prod1', 'name': '프리미엄 홍삼 진액', 'price': 89000, 'points': 180, 'stock': 15},
        {'id': 'prod2', 'name': '녹용 보약', 'price': 250000, 'points': 500, 'stock': 3},
        {'id': 'prod3', 'name': '쑥뜸 세트', 'price': 35000, 'points': 70, 'stock': 0},
        {'id': 'prod4', 'name': '대추차', 'price': 18000, 'points': 36, 'stock': 25},
        {'id': 'prod5', 'name': '침구 세트', 'price': 45000, 'points': 90, 'stock': 8},
        {'id': 'prod6', 'name': '어혈 개선 환', 'price': 65000, 'points': 130, 'stock': 12},
      ];

      for (var product in products) {
        await firestore
            .collection('clinics')
            .doc(clinicId)
            .collection('products')
            .doc(product['id'] as String)
            .set({
          'name': product['name'],
          'description': '${product['name']} 설명',
          'price': product['price'],
          'points': product['points'],
          'stock': product['stock'],
          'category': '건강식품',
          'imageUrl': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Add purchases
      await firestore.collection('clinics').doc(clinicId).collection('purchases').doc('pur1').set({
        'productId': 'prod1',
        'productName': '프리미엄 홍삼 진액',
        'patientId': 'patient1',
        'points': 180,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await firestore.collection('clinics').doc(clinicId).collection('purchases').doc('pur2').set({
        'productId': 'prod4',
        'productName': '대추차',
        'patientId': 'patient2',
        'points': 36,
        'status': 'approved',
        'createdAt': FieldValue.serverTimestamp(),
        'approvedAt': FieldValue.serverTimestamp(),
      });

      await firestore.collection('clinics').doc(clinicId).collection('purchases').doc('pur3').set({
        'productId': 'prod2',
        'productName': '녹용 보약',
        'patientId': 'patient3',
        'points': 500,
        'status': 'rejected',
        'rejectionReason': '재고 부족',
        'createdAt': FieldValue.serverTimestamp(),
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      // Add posts
      await firestore.collection('clinics').doc(clinicId).collection('posts').doc('post1').set({
        'title': '요통에 좋은 스트레칭 방법',
        'content': '오랜 시간 앉아있는 분들을 위한 간단한 요추 스트레칭을 소개합니다.',
        'authorId': 'patient1',
        'authorName': '김민수',
        'likeCount': 12,
        'commentCount': 2,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await firestore
          .collection('clinics')
          .doc(clinicId)
          .collection('posts')
          .doc('post1')
          .collection('comments')
          .add({
        'content': '오늘부터 따라해봐야겠어요!',
        'authorId': 'patient2',
        'authorName': '이지은',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await firestore
          .collection('clinics')
          .doc(clinicId)
          .collection('posts')
          .doc('post1')
          .collection('comments')
          .add({
        'content': '저도 요통이 심했는데 도움 됐어요!',
        'authorId': 'patient3',
        'authorName': '박준호',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await firestore.collection('clinics').doc(clinicId).collection('posts').doc('post2').set({
        'title': '불면증 개선 후기',
        'content': '2주간 케어 플랜 따라하니 정말 효과가 있네요! 족욕이 특히 도움됐어요.',
        'authorId': 'patient2',
        'authorName': '이지은',
        'likeCount': 8,
        'commentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ 샘플 데이터가 성공적으로 추가되었습니다!'),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('대시보드'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '환영합니다, ${authProvider.user?.displayName ?? '관리자'}님',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _addSampleData(context, authProvider),
                  icon: const Icon(Icons.add_circle),
                  label: const Text('샘플 데이터 추가'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 통계 카드
            SizedBox(
              height: 200,
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 1.5,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStatCard(
                    title: '총 환자 수',
                    icon: Icons.people,
                    color: Colors.blue,
                    stream: FirebaseFirestore.instance
                        .collection('clinics')
                        .doc(authProvider.clinicId)
                        .collection('patients')
                        .snapshots(),
                    valueBuilder: (snapshot) =>
                        snapshot.data?.docs.length.toString() ?? '0',
                  ),
                  _buildStatCard(
                    title: '활성 케어 플랜',
                    icon: Icons.assignment_turned_in,
                    color: Colors.green,
                    stream: FirebaseFirestore.instance
                        .collection('clinics')
                        .doc(authProvider.clinicId)
                        .collection('carePlans')
                        .where('status', isEqualTo: 'active')
                        .snapshots(),
                    valueBuilder: (snapshot) =>
                        snapshot.data?.docs.length.toString() ?? '0',
                  ),
                  _buildStatCard(
                    title: '대기 중인 구매',
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                    stream: FirebaseFirestore.instance
                        .collection('clinics')
                        .doc(authProvider.clinicId)
                        .collection('purchases')
                        .where('status', isEqualTo: 'pending')
                        .snapshots(),
                    valueBuilder: (snapshot) =>
                        snapshot.data?.docs.length.toString() ?? '0',
                  ),
                  _buildStatCard(
                    title: '총 상품 수',
                    icon: Icons.inventory_2,
                    color: Colors.purple,
                    stream: FirebaseFirestore.instance
                        .collection('clinics')
                        .doc(authProvider.clinicId)
                        .collection('products')
                        .snapshots(),
                    valueBuilder: (snapshot) =>
                        snapshot.data?.docs.length.toString() ?? '0',
                  ),
                  _buildStatCard(
                    title: '재고 부족 상품',
                    icon: Icons.warning,
                    color: Colors.red,
                    stream: FirebaseFirestore.instance
                        .collection('clinics')
                        .doc(authProvider.clinicId)
                        .collection('products')
                        .where('stock', isLessThanOrEqualTo: 5)
                        .snapshots(),
                    valueBuilder: (snapshot) =>
                        snapshot.data?.docs.length.toString() ?? '0',
                  ),
                  _buildStatCard(
                    title: '커뮤니티 게시글',
                    icon: Icons.forum,
                    color: Colors.teal,
                    stream: FirebaseFirestore.instance
                        .collection('clinics')
                        .doc(authProvider.clinicId)
                        .collection('posts')
                        .snapshots(),
                    valueBuilder: (snapshot) =>
                        snapshot.data?.docs.length.toString() ?? '0',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // 📊 케어 플랜 완료율 차트
            _buildCarePlanCompletionChart(authProvider),

            const SizedBox(height: 48),

            // 📈 일별 구매 추세 차트
            _buildPurchaseTrendChart(authProvider),

            const SizedBox(height: 48),

            // 🏆 인기 상품 차트
            _buildPopularProductsChart(authProvider),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required IconData icon,
    required Color color,
    required Stream<QuerySnapshot> stream,
    required String Function(AsyncSnapshot<QuerySnapshot>) valueBuilder,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 40, color: color),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  snapshot.hasData ? valueBuilder(snapshot) : '...',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 📊 케어 플랜 완료율 차트
  Widget _buildCarePlanCompletionChart(AuthProvider authProvider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '환자별 케어 플랜 완료율',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('clinics')
                    .doc(authProvider.clinicId)
                    .collection('carePlans')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('케어 플랜 데이터가 없습니다'),
                    );
                  }

                  // 환자별로 케어 플랜 그룹화
                  final carePlans = snapshot.data!.docs;
                  final Map<String, List<int>> patientProgress = {};

                  for (var doc in carePlans) {
                    final data = doc.data() as Map<String, dynamic>;
                    final patientId = data['patientId'] ?? '';
                    final progress = (data['progress'] ?? 0) as num;

                    if (!patientProgress.containsKey(patientId)) {
                      patientProgress[patientId] = [];
                    }
                    patientProgress[patientId]!.add(progress.toInt());
                  }

                  // 평균 완료율 계산
                  final List<BarChartGroupData> barGroups = [];
                  int index = 0;

                  patientProgress.forEach((patientId, progressList) {
                    final avgProgress =
                        progressList.reduce((a, b) => a + b) / progressList.length;

                    barGroups.add(
                      BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: avgProgress,
                            color: const Color(0xFF2E7D32),
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    );
                    index++;
                  });

                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 100,
                      barGroups: barGroups,
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}%',
                                style: const TextStyle(fontSize: 12),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final patientIds = patientProgress.keys.toList();
                              if (value.toInt() < patientIds.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '환자${value.toInt() + 1}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 20,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📈 일별 구매 추세 차트
  Widget _buildPurchaseTrendChart(AuthProvider authProvider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '최근 7일 구매 추세',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('clinics')
                    .doc(authProvider.clinicId)
                    .collection('purchases')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // 최근 7일 날짜 생성
                  final now = DateTime.now();
                  final Map<String, int> dailyCounts = {};

                  for (int i = 6; i >= 0; i--) {
                    final date = now.subtract(Duration(days: i));
                    final dateKey = DateFormat('MM/dd').format(date);
                    dailyCounts[dateKey] = 0;
                  }

                  // 구매 데이터 집계
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final createdAt = data['createdAt'] as Timestamp?;

                    if (createdAt != null) {
                      final date = createdAt.toDate();
                      final dateKey = DateFormat('MM/dd').format(date);

                      if (dailyCounts.containsKey(dateKey)) {
                        dailyCounts[dateKey] = dailyCounts[dateKey]! + 1;
                      }
                    }
                  }

                  // LineChart 데이터 생성
                  final spots = <FlSpot>[];
                  final dates = dailyCounts.keys.toList();

                  for (int i = 0; i < dates.length; i++) {
                    spots.add(FlSpot(i.toDouble(), dailyCounts[dates[i]]!.toDouble()));
                  }

                  return LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: const Color(0xFF2E7D32),
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 12),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < dates.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    dates[value.toInt()],
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🏆 인기 상품 차트
  Widget _buildPopularProductsChart(AuthProvider authProvider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '인기 상품 TOP 5',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('clinics')
                    .doc(authProvider.clinicId)
                    .collection('purchases')
                    .where('status', whereIn: ['approved', 'completed'])
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('구매 데이터가 없습니다'),
                    );
                  }

                  // 상품별 구매 횟수 집계
                  final Map<String, int> productCounts = {};
                  final Map<String, String> productNames = {};

                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final productId = data['productId'] ?? '';
                    final productName = data['productName'] ?? '알 수 없음';

                    productCounts[productId] = (productCounts[productId] ?? 0) + 1;
                    productNames[productId] = productName;
                  }

                  // TOP 5 추출
                  final sortedProducts = productCounts.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  final top5 = sortedProducts.take(5).toList();

                  if (top5.isEmpty) {
                    return const Center(
                      child: Text('구매 데이터가 없습니다'),
                    );
                  }

                  // BarChart 데이터 생성
                  final barGroups = <BarChartGroupData>[];
                  for (int i = 0; i < top5.length; i++) {
                    barGroups.add(
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: top5[i].value.toDouble(),
                            color: Colors.orange,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      barGroups: barGroups,
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 12),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < top5.length) {
                                final productId = top5[value.toInt()].key;
                                final productName = productNames[productId] ?? '';
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    productName.length > 8
                                        ? '${productName.substring(0, 8)}...'
                                        : productName,
                                    style: const TextStyle(fontSize: 11),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
