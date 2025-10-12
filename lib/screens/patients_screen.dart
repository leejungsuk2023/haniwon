import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import 'patient_detail_screen.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('환자 관리'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SizedBox(
              width: 300,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '환자 검색',
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  filled: true,
                  fillColor: Colors.white24,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('clinics')
            .doc(authProvider.clinicId)
            .collection('patients')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var patients = snapshot.data?.docs ?? [];

          if (_searchQuery.isNotEmpty) {
            patients = patients.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['name'] ?? '').toString().toLowerCase();
              final chartNumber = (data['chartNumber'] ?? '').toString().toLowerCase();
              final phone = (data['phone'] ?? '').toString().toLowerCase();
              return name.contains(_searchQuery) ||
                     chartNumber.contains(_searchQuery) ||
                     phone.contains(_searchQuery);
            }).toList();
          }

          if (patients.isEmpty) {
            return const Center(child: Text('환자가 없습니다.'));
          }

          return DataTable(
            columns: const [
              DataColumn(label: Text('이름')),
              DataColumn(label: Text('차트번호')),
              DataColumn(label: Text('전화번호')),
              DataColumn(label: Text('포인트')),
              DataColumn(label: Text('가입일')),
              DataColumn(label: Text('작업')),
            ],
            rows: patients.map((patient) {
              final data = patient.data() as Map<String, dynamic>;
              final name = data['name'] ?? '';
              final chartNumber = data['chartNumber'] ?? '';
              final phone = data['phone'] ?? '';
              final points = data['points'] ?? 0;
              final createdAt = data['createdAt'] as Timestamp?;

              return DataRow(
                onSelectChanged: (selected) {
                  if (selected == true) {
                    // 환자 클릭 시 상세 페이지로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientDetailScreen(
                          patientId: patient.id,
                          patientData: data,
                        ),
                      ),
                    );
                  }
                },
                cells: [
                  DataCell(Text(name)),
                  DataCell(Text(chartNumber)),
                  DataCell(Text(phone)),
                  DataCell(Text('$points P')),
                  DataCell(Text(
                    createdAt != null
                        ? DateFormat('yyyy-MM-dd').format(createdAt.toDate())
                        : '',
                  )),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.account_balance_wallet, size: 20),
                          onPressed: () => _showAdjustPointsDialog(
                            context,
                            authProvider,
                            patient.id,
                          name,
                          points,
                        ),
                        tooltip: '포인트 조정',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: () => _confirmDelete(
                          context,
                          authProvider,
                          patient.id,
                          name,
                        ),
                        tooltip: '삭제',
                      ),
                    ],
                  ),
                ),
              ]);
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPatientDialog(context, authProvider),
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.person_add),
        label: const Text('환자 추가'),
      ),
    );
  }

  void _showAddPatientDialog(BuildContext context, AuthProvider authProvider) {
    final nameController = TextEditingController();
    final chartNumberController = TextEditingController();
    final phoneController = TextEditingController();
    final pointsController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('환자 추가'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '이름',
                  border: OutlineInputBorder(),
                  hintText: '홍길동',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: chartNumberController,
                decoration: const InputDecoration(
                  labelText: '차트번호',
                  border: OutlineInputBorder(),
                  hintText: 'C12345',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: '전화번호',
                  border: OutlineInputBorder(),
                  hintText: '010-1234-5678',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pointsController,
                decoration: const InputDecoration(
                  labelText: '초기 포인트',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
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
              if (nameController.text.isEmpty ||
                  chartNumberController.text.isEmpty ||
                  phoneController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('모든 필수 항목을 입력해주세요.')),
                );
                return;
              }

              await FirebaseFirestore.instance
                  .collection('clinics')
                  .doc(authProvider.clinicId)
                  .collection('patients')
                  .add({
                'name': nameController.text,
                'chartNumber': chartNumberController.text,
                'phone': phoneController.text,
                'points': int.tryParse(pointsController.text) ?? 0,
                'visits': 0,
                'lastVisit': FieldValue.serverTimestamp(),
                'createdAt': FieldValue.serverTimestamp(),
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('환자가 추가되었습니다.')),
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
    );
  }

  void _showAdjustPointsDialog(
    BuildContext context,
    AuthProvider authProvider,
    String patientId,
    String name,
    int currentPoints,
  ) {
    final pointsController = TextEditingController();
    String operation = 'add';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('$name 포인트 조정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('현재: $currentPoints P', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('추가'),
                      value: 'add',
                      groupValue: operation,
                      onChanged: (value) => setState(() => operation = value!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('차감'),
                      value: 'subtract',
                      groupValue: operation,
                      onChanged: (value) => setState(() => operation = value!),
                    ),
                  ),
                ],
              ),
              TextField(
                controller: pointsController,
                decoration: const InputDecoration(
                  labelText: '포인트',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                final points = int.tryParse(pointsController.text) ?? 0;
                final adjustValue = operation == 'add' ? points : -points;

                await FirebaseFirestore.instance
                    .collection('clinics')
                    .doc(authProvider.clinicId)
                    .collection('patients')
                    .doc(patientId)
                    .update({'points': FieldValue.increment(adjustValue)});

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('포인트가 ${operation == 'add' ? '추가' : '차감'}되었습니다.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: const Text('조정'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    AuthProvider authProvider,
    String patientId,
    String name,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('환자 삭제'),
        content: Text('$name 환자를 삭제하시겠습니까?'),
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
                  .doc(patientId)
                  .delete();

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('환자가 삭제되었습니다.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
