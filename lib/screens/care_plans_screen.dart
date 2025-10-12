import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';

class CarePlansScreen extends StatefulWidget {
  const CarePlansScreen({super.key});

  @override
  State<CarePlansScreen> createState() => _CarePlansScreenState();
}

class _CarePlansScreenState extends State<CarePlansScreen> {
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('케어 플랜 관리'),
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
                DropdownMenuItem(value: 'all', child: Text('전체')),
                DropdownMenuItem(value: 'active', child: Text('진행 중')),
                DropdownMenuItem(value: 'completed', child: Text('완료')),
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
        stream: _filterStatus == 'all'
            ? FirebaseFirestore.instance
                .collection('clinics')
                .doc(authProvider.clinicId)
                .collection('carePlans')
                .snapshots()
            : FirebaseFirestore.instance
                .collection('clinics')
                .doc(authProvider.clinicId)
                .collection('carePlans')
                .where('status', isEqualTo: _filterStatus)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final plans = snapshot.data?.docs ?? [];

          if (plans.isEmpty) {
            return const Center(child: Text('케어 플랜이 없습니다.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              final data = plan.data() as Map<String, dynamic>;
              return _buildCarePlanCard(context, authProvider, plan.id, data);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, authProvider),
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add),
        label: const Text('케어 플랜 생성'),
      ),
    );
  }

  Widget _buildCarePlanCard(
    BuildContext context,
    AuthProvider authProvider,
    String planId,
    Map<String, dynamic> data,
  ) {
    final title = data['title'] ?? '';
    final patientId = data['patientId'] ?? '';
    final status = data['status'] ?? 'active';
    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
    final completedCount = items.where((item) => item['completed'] == true).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(
          status == 'completed' ? Icons.check_circle : Icons.assignment,
          color: status == 'completed' ? Colors.green : const Color(0xFF2E7D32),
          size: 32,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('clinics')
              .doc(authProvider.clinicId)
              .collection('patients')
              .doc(patientId)
              .get(),
          builder: (context, snapshot) {
            final patientName =
                (snapshot.data?.data() as Map<String, dynamic>?)?['name'] ?? '환자 정보 없음';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('환자: $patientName'),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: items.isNotEmpty ? completedCount / items.length : 0,
                  backgroundColor: Colors.grey[300],
                  color: const Color(0xFF4CAF50),
                ),
                const SizedBox(height: 4),
                Text('$completedCount / ${items.length} 완료'),
              ],
            );
          },
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: status == 'completed' ? Colors.green : Colors.orange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status == 'completed' ? '완료' : '진행 중',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '퀘스트 목록:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...items.map((item) {
                  return CheckboxListTile(
                    value: item['completed'] ?? false,
                    onChanged: null,
                    title: Text(item['title'] ?? ''),
                    dense: true,
                  );
                }).toList(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showEditDialog(context, authProvider, planId, data),
                      icon: const Icon(Icons.edit),
                      label: const Text('수정'),
                    ),
                    const SizedBox(width: 8),
                    if (status == 'active')
                      ElevatedButton.icon(
                        onPressed: () => _completePlan(context, authProvider, planId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text('완료 처리'),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _confirmDelete(context, authProvider, planId, title),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.delete),
                      label: const Text('삭제'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, AuthProvider authProvider) {
    final titleController = TextEditingController();
    String? selectedPatientId;
    List<String> selectedTemplateIds = [];
    List<Map<String, dynamic>> selectedQuests = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('케어 플랜 생성'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 700,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: '플랜 제목',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                          labelText: '환자 선택',
                          border: OutlineInputBorder(),
                        ),
                        items: patients.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem(
                            value: doc.id,
                            child: Text(data['name'] ?? '이름 없음'),
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
                  const SizedBox(height: 24),
                  const Text('📋 템플릿 선택:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('clinics')
                        .doc(authProvider.clinicId)
                        .collection('carePlanTemplates')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      final templates = snapshot.data!.docs;
                      
                      if (templates.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: const Text('⚠️ 템플릿이 없습니다. 퀘스트 관리에서 템플릿을 먼저 만드세요!', style: TextStyle(color: Colors.orange)),
                        );
                      }

                      return Container(
                        height: 150,
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                        child: ListView.builder(
                          itemCount: templates.length,
                          itemBuilder: (context, index) {
                            final template = templates[index];
                            final data = template.data() as Map<String, dynamic>;
                            final questIds = List<String>.from(data['questIds'] ?? []);
                            
                            return CheckboxListTile(
                              value: selectedTemplateIds.contains(template.id),
                              onChanged: (value) async {
                                if (value == true) {
                                  selectedTemplateIds.add(template.id);
                                  // 템플릿의 퀘스트들을 selectedQuests에 추가
                                  for (var questId in questIds) {
                                    final questDoc = await FirebaseFirestore.instance
                                        .collection('clinics')
                                        .doc(authProvider.clinicId)
                                        .collection('questLibrary')
                                        .doc(questId)
                                        .get();
                                    if (questDoc.exists) {
                                      final questData = questDoc.data() as Map<String, dynamic>;
                                      if (!selectedQuests.any((q) => q['id'] == questId)) {
                                        selectedQuests.add({
                                          'id': questId,
                                          'content': questData['content'],
                                          'points': questData['points'],
                                          'description': questData['description'] ?? '',
                                        });
                                      }
                                    }
                                  }
                                } else {
                                  selectedTemplateIds.remove(template.id);
                                  // 템플릿의 퀘스트들을 selectedQuests에서 제거
                                  selectedQuests.removeWhere((q) => questIds.contains(q['id']));
                                }
                                setState(() {});
                              },
                              title: Text(data['title'] ?? ''),
                              subtitle: Text('${questIds.length}개 퀘스트'),
                              dense: true,
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text('🎯 개별 퀘스트 추가:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('clinics')
                        .doc(authProvider.clinicId)
                        .collection('questLibrary')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      final quests = snapshot.data!.docs;
                      
                      if (quests.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: const Text('⚠️ 퀘스트가 없습니다. 퀘스트 관리에서 퀘스트를 먼저 만드세요!', style: TextStyle(color: Colors.orange)),
                        );
                      }

                      return Container(
                        height: 200,
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                        child: ListView.builder(
                          itemCount: quests.length,
                          itemBuilder: (context, index) {
                            final quest = quests[index];
                            final data = quest.data() as Map<String, dynamic>;
                            final isSelected = selectedQuests.any((q) => q['id'] == quest.id);
                            
                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (value) {
                                if (value == true) {
                                  selectedQuests.add({
                                    'id': quest.id,
                                    'content': data['content'],
                                    'points': data['points'],
                                    'description': data['description'] ?? '',
                                  });
                                } else {
                                  selectedQuests.removeWhere((q) => q['id'] == quest.id);
                                }
                                setState(() {});
                              },
                              title: Text(data['content'] ?? ''),
                              subtitle: Text('${data['points']}P'),
                              dense: true,
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text('📝 최종 퀘스트 목록:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: selectedQuests.isEmpty
                        ? const Center(child: Text('퀘스트를 선택하세요', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: selectedQuests.length,
                            itemBuilder: (context, index) {
                              final quest = selectedQuests[index];
                              return Card(
                                child: ListTile(
                                  leading: Text('${index + 1}.', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  title: Text(quest['content']),
                                  subtitle: Text('${quest['points']}P'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        selectedQuests.removeAt(index);
                                      });
                                    },
                                  ),
                                  dense: true,
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text('선택된 퀘스트: ${selectedQuests.length}개', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || selectedPatientId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('플랜 제목과 환자를 선택하세요')),
                  );
                  return;
                }

                if (selectedQuests.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('최소 1개 이상의 퀘스트를 선택하세요')),
                  );
                  return;
                }

                final items = selectedQuests.asMap().entries.map((entry) {
                  return {
                    'id': 'quest_${entry.key}',
                    'content': entry.value['content'],
                    'points': entry.value['points'],
                    'description': entry.value['description'],
                    'completed': false,
                  };
                }).toList();

                await FirebaseFirestore.instance
                    .collection('clinics')
                    .doc(authProvider.clinicId)
                    .collection('carePlans')
                    .add({
                  'title': titleController.text,
                  'patientId': selectedPatientId,
                  'status': 'active',
                  'items': items,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('케어 플랜이 생성되었습니다')),
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

  void _showEditDialog(
    BuildContext context,
    AuthProvider authProvider,
    String planId,
    Map<String, dynamic> data,
  ) {
    final titleController = TextEditingController(text: data['title'] ?? '');
    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
    List<TextEditingController> questControllers = items
        .map((item) => TextEditingController(text: item['title'] ?? ''))
        .toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('케어 플랜 수정'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: '플랜 제목',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '퀘스트 목록:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(questControllers.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: questControllers[index],
                              decoration: InputDecoration(
                                labelText: '퀘스트 ${index + 1}',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                questControllers.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        questControllers.add(TextEditingController());
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('퀘스트 추가'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedItems = questControllers
                    .asMap()
                    .entries
                    .where((entry) => entry.value.text.isNotEmpty)
                    .map((entry) {
                  final originalItem = entry.key < items.length ? items[entry.key] : null;
                  return {
                    'id': originalItem?['id'] ??
                        DateTime.now().millisecondsSinceEpoch.toString() +
                            entry.key.toString(),
                    'title': entry.value.text,
                    'completed': originalItem?['completed'] ?? false,
                  };
                }).toList();

                await FirebaseFirestore.instance
                    .collection('clinics')
                    .doc(authProvider.clinicId)
                    .collection('carePlans')
                    .doc(planId)
                    .update({
                  'title': titleController.text,
                  'items': updatedItems,
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('케어 플랜이 수정되었습니다.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: const Text('수정'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completePlan(
    BuildContext context,
    AuthProvider authProvider,
    String planId,
  ) async {
    await FirebaseFirestore.instance
        .collection('clinics')
        .doc(authProvider.clinicId)
        .collection('carePlans')
        .doc(planId)
        .update({'status': 'completed'});

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('케어 플랜이 완료되었습니다.')),
      );
    }
  }

  void _confirmDelete(
    BuildContext context,
    AuthProvider authProvider,
    String planId,
    String title,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('케어 플랜 삭제'),
        content: Text('$title 케어 플랜을 삭제하시겠습니까?'),
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
                  .delete();

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('케어 플랜이 삭제되었습니다.')),
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
