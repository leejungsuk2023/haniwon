import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  String _filterStatus = 'pending';

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('구매 승인 관리'),
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
                DropdownMenuItem(value: 'pending', child: Text('대기 중')),
                DropdownMenuItem(value: 'approved', child: Text('승인됨')),
                DropdownMenuItem(value: 'completed', child: Text('완료')),
                DropdownMenuItem(value: 'rejected', child: Text('거부됨')),
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
            .collection('purchases')
            .where('status', isEqualTo: _filterStatus)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final purchases = snapshot.data?.docs ?? [];

          if (purchases.isEmpty) {
            return Center(
              child: Text(_getStatusText(_filterStatus) + ' 구매가 없습니다.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: purchases.length,
            itemBuilder: (context, index) {
              final purchase = purchases[index];
              final data = purchase.data() as Map<String, dynamic>;
              return _buildPurchaseCard(context, authProvider, purchase.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildPurchaseCard(
    BuildContext context,
    AuthProvider authProvider,
    String purchaseId,
    Map<String, dynamic> data,
  ) {
    final productName = data['productName'] ?? '';
    final points = data['points'] ?? 0;
    final status = data['status'] ?? 'pending';
    final patientId = data['patientId'] ?? '';
    final createdAt = data['createdAt'] as Timestamp?;
    final rejectionReason = data['rejectionReason'] ?? '';

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
                      Text(
                        productName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('clinics')
                            .doc(authProvider.clinicId)
                            .collection('patients')
                            .doc(patientId)
                            .get(),
                        builder: (context, snapshot) {
                          final patientName =
                              (snapshot.data?.data() as Map<String, dynamic>?)?['name'] ??
                                  '환자 정보 없음';
                          return Row(
                            children: [
                              const Icon(Icons.person, size: 16),
                              const SizedBox(width: 4),
                              Text(patientName),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.account_balance_wallet, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$points P',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (createdAt != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('yyyy-MM-dd HH:mm').format(createdAt.toDate()),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            if (rejectionReason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '거부 사유: $rejectionReason',
                        style: TextStyle(color: Colors.red[700], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () =>
                        _showRejectDialog(context, authProvider, purchaseId, productName, data),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text('거부'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _approvePurchase(context, authProvider, purchaseId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('승인'),
                  ),
                ],
              ),
            ],
            if (status == 'approved') ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _completePurchase(context, authProvider, purchaseId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.done_all),
                  label: const Text('완료 처리'),
                ),
              ),
            ],
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
        text = '대기 중';
        icon = Icons.pending;
        break;
      case 'approved':
        color = const Color(0xFF2E7D32);
        text = '승인됨';
        icon = Icons.check_circle;
        break;
      case 'completed':
        color = Colors.green;
        text = '완료';
        icon = Icons.done_all;
        break;
      case 'rejected':
        color = Colors.red;
        text = '거부됨';
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
        return '대기 중';
      case 'approved':
        return '승인됨';
      case 'completed':
        return '완료';
      case 'rejected':
        return '거부됨';
      default:
        return status;
    }
  }

  Future<void> _approvePurchase(
    BuildContext context,
    AuthProvider authProvider,
    String purchaseId,
  ) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('updatePurchaseStatus');

      final result = await callable.call({
        'purchaseId': purchaseId,
        'clinicId': authProvider.clinicId,
        'status': 'approved',
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.data['message'] ?? '구매가 승인되었습니다.')),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('승인 실패: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('승인 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRejectDialog(
    BuildContext context,
    AuthProvider authProvider,
    String purchaseId,
    String productName,
    Map<String, dynamic> purchaseData,
  ) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('구매 거부'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$productName 구매를 거부하시겠습니까?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: '거부 사유',
                border: OutlineInputBorder(),
                hintText: '거부 사유를 입력해주세요',
              ),
              maxLines: 3,
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
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('거부 사유를 입력해주세요.')),
                );
                return;
              }

              try {
                final functions = FirebaseFunctions.instance;
                final callable = functions.httpsCallable('updatePurchaseStatus');

                final result = await callable.call({
                  'purchaseId': purchaseId,
                  'clinicId': authProvider.clinicId,
                  'status': 'rejected',
                  'rejectionReason': reasonController.text,
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.data['message'] ?? '구매가 거부되었습니다. 포인트가 환불되었습니다.'),
                    ),
                  );
                }
              } on FirebaseFunctionsException catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('거부 실패: ${e.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('거부 실패: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('거부'),
          ),
        ],
      ),
    );
  }

  Future<void> _completePurchase(
    BuildContext context,
    AuthProvider authProvider,
    String purchaseId,
  ) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('updatePurchaseStatus');

      final result = await callable.call({
        'purchaseId': purchaseId,
        'clinicId': authProvider.clinicId,
        'status': 'completed',
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.data['message'] ?? '구매가 완료 처리되었습니다.')),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('완료 처리 실패: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('완료 처리 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
