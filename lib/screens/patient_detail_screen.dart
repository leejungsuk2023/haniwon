import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;
  final Map<String, dynamic> patientData;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
    required this.patientData,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.patientData['name']} 님'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: '정보'),
            Tab(icon: Icon(Icons.assignment), text: '케어 플랜'),
            Tab(icon: Icon(Icons.analytics), text: 'AI 분석 리포트'),
            Tab(icon: Icon(Icons.chat), text: '채팅 내역'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(authProvider),
          _buildCarePlanTab(authProvider),
          _buildAIReportTab(authProvider),
          _buildChatTab(),
        ],
      ),
    );
  }

  // [탭 1] 정보/대시보드
  Widget _buildInfoTab(AuthProvider authProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 환자 기본 정보 카드
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '기본 정보',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 32),
                  _buildInfoRow('이름', widget.patientData['name'] ?? '-'),
                  _buildInfoRow('차트번호', widget.patientData['chartNumber'] ?? '-'),
                  _buildInfoRow('전화번호', widget.patientData['phone'] ?? '-'),
                  _buildInfoRow('포인트', '${widget.patientData['points'] ?? 0}P'),
                  _buildInfoRow('방문횟수', '${widget.patientData['visitCount'] ?? 0}회'),
                  _buildInfoRow(
                    '마지막 방문일',
                    widget.patientData['lastVisit'] != null
                        ? DateFormat('yyyy-MM-dd').format(
                            (widget.patientData['lastVisit'] as Timestamp).toDate())
                        : '-',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _editPatient(authProvider),
                        icon: const Icon(Icons.edit),
                        label: const Text('정보 수정'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // 통계 카드
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '총 획득 포인트',
                  '${widget.patientData['totalEarnedPoints'] ?? 0}P',
                  Icons.stars,
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  '총 사용 포인트',
                  '${widget.patientData['totalSpentPoints'] ?? 0}P',
                  Icons.shopping_cart,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // [탭 2] 케어 플랜
  Widget _buildCarePlanTab(AuthProvider authProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 진행 중인 케어 플랜
          const Text(
            '📋 진행 중인 케어 플랜',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('clinics')
                .doc(authProvider.clinicId)
                .collection('carePlans')
                .where('patientId', isEqualTo: widget.patientId)
                .where('status', isEqualTo: 'active')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('에러: ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final activePlans = snapshot.data?.docs ?? [];

              if (activePlans.isEmpty) {
                return Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            '진행 중인 케어 플랜이 없습니다',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _createCarePlan(authProvider),
                            icon: const Icon(Icons.add),
                            label: const Text('새 케어 플랜 생성'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: activePlans.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
                  final completedCount = items.where((item) => item['completed'] == true).length;
                  final totalCount = items.length;
                  final completionRate = totalCount > 0 ? (completedCount / totalCount * 100).toInt() : 0;

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  data['title'] ?? '제목 없음',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _editCarePlan(authProvider, doc.id, data),
                                    icon: const Icon(Icons.edit, size: 18),
                                    label: const Text('수정'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _completeCarePlan(authProvider, doc.id),
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text('완료 처리'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: completionRate / 100,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '완료율: $completionRate% ($completedCount/$totalCount)',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                          const Divider(height: 32),
                          const Text(
                            '퀘스트 목록:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          ...items.asMap().entries.map((entry) {
                            final item = entry.value;
                            return CheckboxListTile(
                              value: item['completed'] ?? false,
                              onChanged: null, // 관리자는 체크 불가
                              title: Text(item['content'] ?? ''),
                              subtitle: Text('${item['points'] ?? 0}P'),
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 40),
          // 완료된 케어 플랜 히스토리
          const Text(
            '✅ 완료된 케어 플랜',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('clinics')
                .doc(authProvider.clinicId)
                .collection('carePlans')
                .where('patientId', isEqualTo: widget.patientId)
                .where('status', isEqualTo: 'completed')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('에러: ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final completedPlans = snapshot.data?.docs ?? [];

              if (completedPlans.isEmpty) {
                return Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        '완료된 케어 플랜이 없습니다',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: completedPlans.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
                  final completedCount = items.where((item) => item['completed'] == true).length;
                  final totalCount = items.length;

                  return Card(
                    elevation: 1,
                    color: Colors.grey[100],
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: Text(data['title'] ?? '제목 없음'),
                      subtitle: Text('완료: $completedCount/$totalCount'),
                      trailing: data['completedAt'] != null
                          ? Text(
                              DateFormat('yyyy-MM-dd').format(
                                (data['completedAt'] as Timestamp).toDate(),
                              ),
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            )
                          : null,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // [탭 3] AI 분석 리포트
  Widget _buildAIReportTab(AuthProvider authProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 최근 식단 기록
          const Text(
            '🍽️ 최근 식단 분석 기록',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('clinics')
                .doc(authProvider.clinicId)
                .collection('mealRecords')
                .where('patientId', isEqualTo: widget.patientId)
                .orderBy('recordedAt', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('에러: ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final mealRecords = snapshot.data?.docs ?? [];

              if (mealRecords.isEmpty) {
                return Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.restaurant_menu_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            '아직 식단 분석 기록이 없습니다',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: mealRecords.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final imageUrl = data['imageUrl'] as String?;
                  final recordedAt = data['recordedAt'] as Timestamp?;
                  final detectedFoods = data['detectedFoods'] as List?;
                  final feedback = data['feedback'] as String?;
                  final recommendedRecipeId = data['recommendedRecipeId'] as String?;
                  final recommendationReason = data['recommendationReason'] as String?;

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 날짜
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 6),
                              Text(
                                recordedAt != null
                                    ? DateFormat('yyyy년 MM월 dd일 HH:mm').format(recordedAt.toDate())
                                    : '날짜 정보 없음',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 이미지와 분석 결과
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 이미지
                              if (imageUrl != null && imageUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imageUrl,
                                    width: 150,
                                    height: 150,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 150,
                                        height: 150,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.error, size: 40, color: Colors.grey),
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(width: 16),

                              // 분석 결과
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 인식된 음식
                                    if (detectedFoods != null && detectedFoods.isNotEmpty) ...[
                                      const Text(
                                        '인식된 음식:',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: detectedFoods.take(10).map((food) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: const Color(0xFF2E7D32)),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  food['name'] ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF2E7D32),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  '${food['nature'] ?? '중성'} | ${((food['confidence'] ?? 0.0) * 100).toStringAsFixed(0)}%',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 12),
                                    ],

                                    // 피드백
                                    if (feedback != null && feedback.isNotEmpty) ...[
                                      const Text(
                                        '한의학적 피드백:',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.blue.shade200),
                                        ),
                                        child: Text(
                                          feedback,
                                          style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.4),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // 추천 식단
                          if (recommendedRecipeId != null) ...[
                            const Divider(height: 24),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF2E7D32)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.restaurant_menu, color: Color(0xFF2E7D32), size: 20),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'AI 추천 식단',
                                        style: TextStyle(
                                          color: Color(0xFF2E7D32),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (recommendationReason != null && recommendationReason.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      recommendationReason,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // [탭 4] 채팅 내역
  Widget _buildChatTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '채팅 내역 기능은 추후 추가됩니다',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // 환자 정보 수정
  void _editPatient(AuthProvider authProvider) {
    final nameController = TextEditingController(text: widget.patientData['name']);
    final chartController = TextEditingController(text: widget.patientData['chartNumber']);
    final phoneController = TextEditingController(text: widget.patientData['phone']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('환자 정보 수정'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '이름',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: chartController,
                decoration: const InputDecoration(
                  labelText: '차트번호',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: '전화번호',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('clinics')
                  .doc(authProvider.clinicId)
                  .collection('patients')
                  .doc(widget.patientId)
                  .update({
                'name': nameController.text,
                'chartNumber': chartController.text,
                'phone': phoneController.text,
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('환자 정보가 수정되었습니다')),
                );
                setState(() {}); // 화면 갱신
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  // 케어 플랜 생성 (임시 - Phase 2에서 개선)
  void _createCarePlan(AuthProvider authProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CarePlanCreationScreen(
          patientId: widget.patientId,
          patientName: widget.patientData['name'] ?? '',
        ),
      ),
    );
  }

  // 케어 플랜 수정 (임시 - Phase 2에서 개선)
  void _editCarePlan(AuthProvider authProvider, String planId, Map<String, dynamic> planData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CarePlanCreationScreen(
          patientId: widget.patientId,
          patientName: widget.patientData['name'] ?? '',
          existingPlanId: planId,
          existingPlanData: planData,
        ),
      ),
    );
  }

  // 케어 플랜 완료 처리
  void _completeCarePlan(AuthProvider authProvider, String planId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('케어 플랜 완료'),
        content: const Text('이 케어 플랜을 완료 처리하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('clinics')
                  .doc(authProvider.clinicId)
                  .collection('carePlans')
                  .doc(planId)
                  .update({
                'status': 'completed',
                'completedAt': FieldValue.serverTimestamp(),
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('케어 플랜이 완료되었습니다')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('완료'),
          ),
        ],
      ),
    );
  }
}

// ========== 케어 플랜 생성/수정 화면 (임시) ==========
class CarePlanCreationScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String? existingPlanId;
  final Map<String, dynamic>? existingPlanData;

  const CarePlanCreationScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    this.existingPlanId,
    this.existingPlanData,
  });

  @override
  State<CarePlanCreationScreen> createState() => _CarePlanCreationScreenState();
}

class _CarePlanCreationScreenState extends State<CarePlanCreationScreen> {
  late TextEditingController _titleController;
  List<Map<String, dynamic>> _selectedQuests = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingPlanData?['title'] ?? '',
    );
    if (widget.existingPlanData != null) {
      _selectedQuests = List<Map<String, dynamic>>.from(
        widget.existingPlanData!['items'] ?? [],
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingPlanId != null ? '케어 플랜 수정' : '케어 플랜 생성'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step 1: 기본 정보
            const Text(
              'Step 1: 기본 정보',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(text: widget.patientName),
              decoration: const InputDecoration(
                labelText: '환자 이름',
                border: OutlineInputBorder(),
              ),
              enabled: false,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '케어 플랜 제목',
                border: OutlineInputBorder(),
                hintText: '예: 정하준 어린이 2차 성장 집중 플랜',
              ),
            ),
            const SizedBox(height: 32),

            // Step 2: 템플릿 불러오기
            const Text(
              'Step 2: 템플릿 불러오기 (선택사항)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _showTemplatePopup(authProvider),
              icon: const Icon(Icons.dashboard_customize),
              label: const Text('템플릿 불러오기'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
            const SizedBox(height: 32),

            // Step 3: 개별 퀘스트 추가
            const Text(
              'Step 3: 개별 퀘스트 추가 (선택사항)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _showQuestPopup(authProvider),
              icon: const Icon(Icons.add_task),
              label: const Text('개별 퀘스트 추가'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
            const SizedBox(height: 32),

            // Step 4: 최종 퀘스트 목록
            const Text(
              'Step 4: 최종 퀘스트 목록',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_selectedQuests.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Center(
                  child: Text(
                    '템플릿 또는 개별 퀘스트를 추가하세요',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._selectedQuests.asMap().entries.map((entry) {
                final index = entry.key;
                final quest = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Text(
                      '${index + 1}.',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    title: Text(quest['content'] ?? ''),
                    subtitle: Text('${quest['points'] ?? 0}P'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _selectedQuests.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              }).toList(),
            const SizedBox(height: 16),
            Text(
              '선택된 퀘스트: ${_selectedQuests.length}개',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 32),

            // Step 5: 생성/저장 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _savePlan(authProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  widget.existingPlanId != null ? '저장' : '생성',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 템플릿 선택 팝업
  void _showTemplatePopup(AuthProvider authProvider) {
    List<String> selectedTemplateIds = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('템플릿 불러오기'),
          content: SizedBox(
            width: 600,
            height: 500,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('clinics')
                  .doc(authProvider.clinicId)
                  .collection('carePlanTemplates')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('에러: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final templates = snapshot.data?.docs ?? [];

                if (templates.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          '템플릿이 없습니다',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '퀘스트 관리에서 템플릿을 먼저 만드세요',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: templates.length,
                        itemBuilder: (context, index) {
                          final template = templates[index];
                          final data = template.data() as Map<String, dynamic>;
                          final questIds = List<String>.from(data['questIds'] ?? []);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: CheckboxListTile(
                              value: selectedTemplateIds.contains(template.id),
                              onChanged: (value) {
                                setDialogState(() {
                                  if (value == true) {
                                    selectedTemplateIds.add(template.id);
                                  } else {
                                    selectedTemplateIds.remove(template.id);
                                  }
                                });
                              },
                              title: Text(
                                data['title'] ?? '제목 없음',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (data['description'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(data['description']),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    '포함된 퀘스트: ${questIds.length}개',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              isThreeLine: data['description'] != null,
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '선택된 템플릿: ${selectedTemplateIds.length}개',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedTemplateIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('템플릿을 선택하세요')),
                  );
                  return;
                }

                // 선택된 템플릿들의 퀘스트를 가져와서 추가
                for (var templateId in selectedTemplateIds) {
                  final templateDoc = await FirebaseFirestore.instance
                      .collection('clinics')
                      .doc(authProvider.clinicId)
                      .collection('carePlanTemplates')
                      .doc(templateId)
                      .get();

                  if (templateDoc.exists) {
                    final templateData = templateDoc.data() as Map<String, dynamic>;
                    final questIds = List<String>.from(templateData['questIds'] ?? []);

                    for (var questId in questIds) {
                      final questDoc = await FirebaseFirestore.instance
                          .collection('clinics')
                          .doc(authProvider.clinicId)
                          .collection('questLibrary')
                          .doc(questId)
                          .get();

                      if (questDoc.exists) {
                        final questData = questDoc.data() as Map<String, dynamic>;
                        
                        // 중복 체크
                        if (!_selectedQuests.any((q) => q['id'] == questId)) {
                          setState(() {
                            _selectedQuests.add({
                              'id': questId,
                              'content': questData['content'],
                              'points': questData['points'],
                              'description': questData['description'] ?? '',
                              'completed': false,
                            });
                          });
                        }
                      }
                    }
                  }
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('템플릿에서 ${_selectedQuests.length}개 퀘스트를 추가했습니다'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: const Text('적용'),
            ),
          ],
        ),
      ),
    );
  }

  // 개별 퀘스트 선택 팝업
  void _showQuestPopup(AuthProvider authProvider) {
    List<String> selectedQuestIds = [];
    String selectedCategory = '전체';
    final categories = ['전체', '💊 약 복용', '🏃 운동', '🌱 생활습관', '🧘 치료', '🥗 식이요법', '📌 기타'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('개별 퀘스트 추가'),
          content: SizedBox(
            width: 700,
            height: 600,
            child: Column(
              children: [
                // 카테고리 필터
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setDialogState(() {
                              selectedCategory = category;
                            });
                          },
                          selectedColor: const Color(0xFF2E7D32),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // 퀘스트 목록
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('clinics')
                        .doc(authProvider.clinicId)
                        .collection('questLibrary')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('에러: ${snapshot.error}'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var quests = snapshot.data?.docs ?? [];

                      // 카테고리 필터링
                      if (selectedCategory != '전체') {
                        quests = quests.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return data['category'] == selectedCategory;
                        }).toList();
                      }

                      if (quests.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                selectedCategory == '전체'
                                    ? '퀘스트가 없습니다'
                                    : '해당 카테고리에 퀘스트가 없습니다',
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '퀘스트 관리에서 퀘스트를 먼저 만드세요',
                                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: [
                          Expanded(
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 2.5,
                              ),
                              itemCount: quests.length,
                              itemBuilder: (context, index) {
                                final quest = quests[index];
                                final data = quest.data() as Map<String, dynamic>;
                                final isSelected = selectedQuestIds.contains(quest.id);
                                final isAlreadyAdded = _selectedQuests.any((q) => q['id'] == quest.id);

                                return Card(
                                  elevation: isSelected ? 4 : 1,
                                  color: isAlreadyAdded
                                      ? Colors.grey[200]
                                      : (isSelected ? const Color(0xFF2E7D32).withOpacity(0.1) : null),
                                  child: InkWell(
                                    onTap: isAlreadyAdded
                                        ? null
                                        : () {
                                            setDialogState(() {
                                              if (isSelected) {
                                                selectedQuestIds.remove(quest.id);
                                              } else {
                                                selectedQuestIds.add(quest.id);
                                              }
                                            });
                                          },
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  data['content'] ?? '',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: isAlreadyAdded ? Colors.grey : null,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isAlreadyAdded)
                                                const Icon(Icons.check_circle, color: Colors.grey, size: 20)
                                              else if (isSelected)
                                                const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 20)
                                              else
                                                Icon(Icons.circle_outlined, color: Colors.grey[400], size: 20),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isAlreadyAdded
                                                      ? Colors.grey
                                                      : const Color(0xFF2E7D32),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '${data['points']}P',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              if (isAlreadyAdded) ...[
                                                const SizedBox(width: 8),
                                                Text(
                                                  '이미 추가됨',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '선택된 퀘스트: ${selectedQuestIds.length}개',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedQuestIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('퀘스트를 선택하세요')),
                  );
                  return;
                }

                // 선택된 퀘스트들을 추가
                for (var questId in selectedQuestIds) {
                  final questDoc = await FirebaseFirestore.instance
                      .collection('clinics')
                      .doc(authProvider.clinicId)
                      .collection('questLibrary')
                      .doc(questId)
                      .get();

                  if (questDoc.exists) {
                    final questData = questDoc.data() as Map<String, dynamic>;
                    
                    // 중복 체크 (이미 위에서 했지만 다시 확인)
                    if (!_selectedQuests.any((q) => q['id'] == questId)) {
                      setState(() {
                        _selectedQuests.add({
                          'id': questId,
                          'content': questData['content'],
                          'points': questData['points'],
                          'description': questData['description'] ?? '',
                          'completed': false,
                        });
                      });
                    }
                  }
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${selectedQuestIds.length}개 퀘스트를 추가했습니다'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }

  // 케어 플랜 저장
  void _savePlan(AuthProvider authProvider) async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('케어 플랜 제목을 입력하세요')),
      );
      return;
    }

    if (_selectedQuests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소 1개 이상의 퀘스트를 선택하세요')),
      );
      return;
    }

    final planData = {
      'title': _titleController.text,
      'patientId': widget.patientId,
      'status': 'active',
      'items': _selectedQuests,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      if (widget.existingPlanId != null) {
        // 수정
        await FirebaseFirestore.instance
            .collection('clinics')
            .doc(authProvider.clinicId)
            .collection('carePlans')
            .doc(widget.existingPlanId)
            .update(planData);
      } else {
        // 생성
        await FirebaseFirestore.instance
            .collection('clinics')
            .doc(authProvider.clinicId)
            .collection('carePlans')
            .add(planData);
      }

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingPlanId != null
                  ? '케어 플랜이 수정되었습니다'
                  : '케어 플랜이 생성되었습니다',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: $e')),
        );
      }
    }
  }
}

