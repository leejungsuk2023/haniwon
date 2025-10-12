import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../providers/auth_provider.dart';

class InvitationCodesScreen extends StatefulWidget {
  const InvitationCodesScreen({super.key});

  @override
  State<InvitationCodesScreen> createState() => _InvitationCodesScreenState();
}

class _InvitationCodesScreenState extends State<InvitationCodesScreen> {
  String _filterStatus = 'pending'; // pending, used, expired

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('초대코드 관리'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: DropdownButton<String>(
              value: _filterStatus,
              dropdownColor: const Color(0xFF2E7D32),
              style: const TextStyle(color: Colors.white),
              underline: Container(),
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('사용 대기')),
                DropdownMenuItem(value: 'used', child: Text('사용 완료')),
                DropdownMenuItem(value: 'expired', child: Text('만료됨')),
              ],
              onChanged: (value) {
                setState(() {
                  _filterStatus = value!;
                });
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('clinics')
            .doc(authProvider.clinicId)
            .collection('invitationCodes')
            .where('status', isEqualTo: _filterStatus)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final codes = snapshot.data?.docs ?? [];

          if (codes.isEmpty) {
            return Center(
              child: Text(_getStatusText(_filterStatus) + ' 초대코드가 없습니다.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: codes.length,
            itemBuilder: (context, index) {
              final code = codes[index];
              final data = code.data() as Map<String, dynamic>;
              return _buildCodeCard(context, authProvider, code.id, data);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGenerateCodeDialog(context, authProvider),
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add),
        label: const Text('초대코드 생성'),
      ),
    );
  }

  Widget _buildCodeCard(
    BuildContext context,
    AuthProvider authProvider,
    String codeId,
    Map<String, dynamic> data,
  ) {
    final code = data['code'] ?? '';
    final patientId = data['patientId'] ?? '';
    final status = data['status'] ?? 'pending';
    final createdAt = data['createdAt'] as Timestamp?;
    final expiresAt = data['expiresAt'] as Timestamp?;
    final usedAt = data['usedAt'] as Timestamp?;

    final isExpired = expiresAt != null &&
        expiresAt.toDate().isBefore(DateTime.now()) &&
        status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  code,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.copy, color: Colors.white, size: 20),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: code));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('초대코드가 복사되었습니다.')),
                                    );
                                  },
                                  tooltip: '코드 복사',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildStatusBadge(isExpired ? 'expired' : status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('clinics')
                            .doc(authProvider.clinicId)
                            .collection('patients')
                            .doc(patientId)
                            .get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Text('환자 정보 로딩 중...');
                          }

                          final patientData =
                              snapshot.data?.data() as Map<String, dynamic>?;
                          final patientName = patientData?['name'] ?? '정보 없음';
                          final chartNumber = patientData?['chartNumber'] ?? '';
                          final phone = patientData?['phone'] ?? '';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    patientName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (chartNumber.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '($chartNumber)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (phone.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.phone, size: 16),
                                    const SizedBox(width: 4),
                                    Text(phone),
                                  ],
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (createdAt != null) ...[
                        Row(
                          children: [
                            Icon(Icons.add_circle_outline,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '생성: ${DateFormat('yyyy-MM-dd HH:mm').format(createdAt.toDate())}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                      if (expiresAt != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: isExpired ? Colors.red : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '만료: ${DateFormat('yyyy-MM-dd HH:mm').format(expiresAt.toDate())}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isExpired ? Colors.red : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (usedAt != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.check_circle,
                                size: 16, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              '사용: ${DateFormat('yyyy-MM-dd HH:mm').format(usedAt.toDate())}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.green),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (status == 'pending' && !isExpired)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () =>
                        _confirmDelete(context, authProvider, codeId, code),
                    tooltip: '삭제',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = '사용 대기';
        icon = Icons.pending;
        break;
      case 'used':
        color = Colors.green;
        text = '사용 완료';
        icon = Icons.check_circle;
        break;
      case 'expired':
        color = Colors.red;
        text = '만료됨';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        text = '알 수 없음';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return '사용 대기 중';
      case 'used':
        return '사용 완료된';
      case 'expired':
        return '만료된';
      default:
        return status;
    }
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 헷갈리는 문자 제외 (I, O, 0, 1)
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  void _showGenerateCodeDialog(
      BuildContext context, AuthProvider authProvider) {
    String? selectedPatientId;
    final generatedCode = _generateCode();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('초대코드 생성'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '환자 선택',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('clinics')
                      .doc(authProvider.clinicId)
                      .collection('patients')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final patients = snapshot.data!.docs;

                    return DropdownButtonFormField<String>(
                      value: selectedPatientId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '환자를 선택하세요',
                      ),
                      items: patients.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = data['name'] ?? '';
                        final chartNumber = data['chartNumber'] ?? '';
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text('$name ${chartNumber.isNotEmpty ? '($chartNumber)' : ''}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedPatientId = value;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  '생성될 초대코드',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    generatedCode,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '• 유효기간: 30일\n'
                  '• 일회용 코드입니다\n'
                  '• 환자가 앱에서 입력하여 계정 연동',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
              onPressed: selectedPatientId == null
                  ? null
                  : () async {
                      final expiresAt =
                          DateTime.now().add(const Duration(days: 30));

                      await FirebaseFirestore.instance
                          .collection('clinics')
                          .doc(authProvider.clinicId)
                          .collection('invitationCodes')
                          .add({
                        'code': generatedCode,
                        'patientId': selectedPatientId,
                        'status': 'pending',
                        'createdAt': FieldValue.serverTimestamp(),
                        'expiresAt': Timestamp.fromDate(expiresAt),
                      });

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('초대코드 "$generatedCode"가 생성되었습니다.'),
                            backgroundColor: const Color(0xFF2E7D32),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: const Text('생성'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    AuthProvider authProvider,
    String codeId,
    String code,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('초대코드 삭제'),
        content: Text('초대코드 "$code"를 삭제하시겠습니까?'),
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
                  .collection('invitationCodes')
                  .doc(codeId)
                  .delete();

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('초대코드가 삭제되었습니다.')),
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
