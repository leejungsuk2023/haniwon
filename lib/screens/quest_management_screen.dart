import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';

class QuestManagementScreen extends StatefulWidget {
  const QuestManagementScreen({super.key});

  @override
  State<QuestManagementScreen> createState() => _QuestManagementScreenState();
}

class _QuestManagementScreenState extends State<QuestManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filterCategory = 'all';

  final List<String> _categories = [
    'medication',
    'exercise',
    'lifestyle',
    'therapy',
    'diet',
    'other',
  ];

  final Map<String, String> _categoryNames = {
    'all': '전체',
    'medication': '💊 약 복용',
    'exercise': '🏃 운동',
    'lifestyle': '🌱 생활습관',
    'therapy': '🧘 치료',
    'diet': '🥗 식이요법',
    'other': '📌 기타',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('퀘스트 관리'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '퀘스트 라이브러리'),
            Tab(text: '템플릿'),
          ],
        ),
        actions: [
          if (_tabController.index == 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: DropdownButton<String>(
                value: _filterCategory,
                dropdownColor: const Color(0xFF2E7D32),
                style: const TextStyle(color: Colors.white),
                underline: Container(),
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('전체')),
                  ..._categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(_categoryNames[category] ?? category),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _filterCategory = value!;
                  });
                },
              ),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuestLibrary(authProvider),
          _buildTemplates(authProvider),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showCreateQuestDialog(context, authProvider);
          } else {
            _showCreateTemplateDialog(context, authProvider);
          }
        },
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? '퀘스트 추가' : '템플릿 생성'),
      ),
    );
  }

  // ==================== 퀘스트 라이브러리 ====================
  Widget _buildQuestLibrary(AuthProvider authProvider) {
    return StreamBuilder<QuerySnapshot>(
      stream: _filterCategory == 'all'
          ? FirebaseFirestore.instance
              .collection('clinics')
              .doc(authProvider.clinicId)
              .collection('questLibrary')
              .orderBy('createdAt', descending: true)
              .snapshots()
          : FirebaseFirestore.instance
              .collection('clinics')
              .doc(authProvider.clinicId)
              .collection('questLibrary')
              .where('category', isEqualTo: _filterCategory)
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('오류: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final quests = snapshot.data?.docs ?? [];

        if (quests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.list_alt, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('퀘스트가 없습니다.', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: quests.length,
          itemBuilder: (context, index) {
            final quest = quests[index];
            final data = quest.data() as Map<String, dynamic>;
            return _buildQuestCard(context, authProvider, quest.id, data);
          },
        );
      },
    );
  }

  Widget _buildQuestCard(BuildContext context, AuthProvider authProvider, String questId, Map<String, dynamic> data) {
    final content = data['content'] ?? '';
    final points = data['points'] ?? 0;
    final description = data['description'] ?? '';
    final category = data['category'] ?? 'other';
    final categoryIcon = _categoryNames[category]?.split(' ').first ?? '📌';

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showEditQuestDialog(context, authProvider, questId, data),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(categoryIcon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(content, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(12)),
                    child: Text('${points}P', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _showEditQuestDialog(context, authProvider, questId, data),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    onPressed: () => _confirmDeleteQuest(context, authProvider, questId, content),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 템플릿 ====================
  Widget _buildTemplates(AuthProvider authProvider) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clinics')
          .doc(authProvider.clinicId)
          .collection('carePlanTemplates')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('오류: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final templates = snapshot.data?.docs ?? [];

        return Column(
          children: [
            // 상단 버튼 영역
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showCreateTemplateDialog(context, authProvider),
                    icon: const Icon(Icons.add),
                    label: const Text('새 템플릿 생성'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
            // 템플릿 목록
            Expanded(
              child: templates.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bookmarks_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            '템플릿이 없습니다',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '새 템플릿 생성 버튼을 눌러 템플릿을 만드세요',
                            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: templates.length,
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        final data = template.data() as Map<String, dynamic>;
                        return _buildTemplateCard(context, authProvider, template.id, data);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTemplateCard(BuildContext context, AuthProvider authProvider, String templateId, Map<String, dynamic> data) {
    final title = data['title'] ?? '';
    final description = data['description'] ?? '';
    final questIds = List<String>.from(data['questIds'] ?? []);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const Icon(Icons.bookmarks, color: Color(0xFF2E7D32), size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(description, style: TextStyle(color: Colors.grey[600])),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(12)),
              child: Text('${questIds.length}개 퀘스트', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('포함된 퀘스트:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                ...questIds.map((questId) {
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('clinics').doc(authProvider.clinicId).collection('questLibrary').doc(questId).get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final questData = snapshot.data?.data() as Map<String, dynamic>?;
                      if (questData == null) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, size: 20, color: Color(0xFF4CAF50)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(questData['content'] ?? '', style: const TextStyle(fontSize: 14))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(8)),
                              child: Text('${questData['points']}P', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(onPressed: () => _showEditTemplateDialog(context, authProvider, templateId, data), icon: const Icon(Icons.edit), label: const Text('수정')),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _confirmDeleteTemplate(context, authProvider, templateId, title),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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

  // ==================== 다이얼로그 ====================
  void _showCreateQuestDialog(BuildContext context, AuthProvider authProvider) {
    final contentController = TextEditingController();
    final pointsController = TextEditingController(text: '10');
    final descriptionController = TextEditingController();
    String selectedCategory = 'medication';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('새 퀘스트 추가'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: contentController, decoration: const InputDecoration(labelText: '퀘스트 내용', hintText: '예: 아침 약 복용', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(controller: pointsController, decoration: const InputDecoration(labelText: '포인트', border: OutlineInputBorder(), suffixText: 'P'), keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: '카테고리', border: OutlineInputBorder()),
                  items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(_categoryNames[cat] ?? cat))).toList(),
                  onChanged: (value) => setState(() => selectedCategory = value!),
                ),
                const SizedBox(height: 16),
                TextField(controller: descriptionController, decoration: const InputDecoration(labelText: '설명 (선택사항)', border: OutlineInputBorder()), maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            ElevatedButton(
              onPressed: () async {
                if (contentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('퀘스트 내용을 입력하세요')));
                  return;
                }
                try {
                  await FirebaseFirestore.instance.collection('clinics').doc(authProvider.clinicId).collection('questLibrary').add({
                    'content': contentController.text,
                    'points': int.tryParse(pointsController.text) ?? 10,
                    'description': descriptionController.text,
                    'category': selectedCategory,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('퀘스트가 추가되었습니다')));
                  }
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditQuestDialog(BuildContext context, AuthProvider authProvider, String questId, Map<String, dynamic> data) {
    final contentController = TextEditingController(text: data['content'] ?? '');
    final pointsController = TextEditingController(text: (data['points'] ?? 10).toString());
    final descriptionController = TextEditingController(text: data['description'] ?? '');
    String selectedCategory = data['category'] ?? 'medication';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('퀘스트 수정'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: contentController, decoration: const InputDecoration(labelText: '퀘스트 내용', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(controller: pointsController, decoration: const InputDecoration(labelText: '포인트', border: OutlineInputBorder(), suffixText: 'P'), keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: '카테고리', border: OutlineInputBorder()),
                  items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(_categoryNames[cat] ?? cat))).toList(),
                  onChanged: (value) => setState(() => selectedCategory = value!),
                ),
                const SizedBox(height: 16),
                TextField(controller: descriptionController, decoration: const InputDecoration(labelText: '설명', border: OutlineInputBorder()), maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            ElevatedButton(
              onPressed: () async {
                if (contentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('퀘스트 내용을 입력하세요')));
                  return;
                }
                try {
                  await FirebaseFirestore.instance.collection('clinics').doc(authProvider.clinicId).collection('questLibrary').doc(questId).update({
                    'content': contentController.text,
                    'points': int.tryParse(pointsController.text) ?? 10,
                    'description': descriptionController.text,
                    'category': selectedCategory,
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('퀘스트가 수정되었습니다')));
                  }
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
              child: const Text('수정'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteQuest(BuildContext context, AuthProvider authProvider, String questId, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('퀘스트 삭제'),
        content: Text('정말로 "$content" 퀘스트를 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('clinics').doc(authProvider.clinicId).collection('questLibrary').doc(questId).delete();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('퀘스트가 삭제되었습니다')));
                }
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showCreateTemplateDialog(BuildContext context, AuthProvider authProvider) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    List<String> selectedQuestIds = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('새 템플릿 생성'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 600,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: '템플릿 이름', hintText: '예: 목 디스크 회복 플랜', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextField(controller: descriptionController, decoration: const InputDecoration(labelText: '설명 (선택사항)', border: OutlineInputBorder()), maxLines: 2),
                  const SizedBox(height: 16),
                  const Align(alignment: Alignment.centerLeft, child: Text('퀘스트 선택:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('clinics').doc(authProvider.clinicId).collection('questLibrary').orderBy('createdAt', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      final quests = snapshot.data!.docs;
                      if (quests.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange)),
                          child: const Text('⚠️ 먼저 퀘스트 라이브러리에서 퀘스트를 추가하세요!', style: TextStyle(color: Colors.orange)),
                        );
                      }
                      return Container(
                        height: 300,
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                        child: ListView.builder(
                          itemCount: quests.length,
                          itemBuilder: (context, index) {
                            final quest = quests[index];
                            final data = quest.data() as Map<String, dynamic>;
                            return CheckboxListTile(
                              value: selectedQuestIds.contains(quest.id),
                              onChanged: (value) => setState(() => value == true ? selectedQuestIds.add(quest.id) : selectedQuestIds.remove(quest.id)),
                              title: Text(data['content'] ?? ''),
                              subtitle: Text('${data['points']}P'),
                              dense: true,
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text('선택된 퀘스트: ${selectedQuestIds.length}개', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('템플릿 이름을 입력하세요')));
                  return;
                }
                if (selectedQuestIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('최소 1개 이상의 퀘스트를 선택하세요')));
                  return;
                }
                try {
                  await FirebaseFirestore.instance.collection('clinics').doc(authProvider.clinicId).collection('carePlanTemplates').add({
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'questIds': selectedQuestIds,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('템플릿이 생성되었습니다')));
                  }
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
              child: const Text('생성'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTemplateDialog(BuildContext context, AuthProvider authProvider, String templateId, Map<String, dynamic> data) {
    final titleController = TextEditingController(text: data['title'] ?? '');
    final descriptionController = TextEditingController(text: data['description'] ?? '');
    List<String> selectedQuestIds = List<String>.from(data['questIds'] ?? []);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('템플릿 수정'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 600,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: '템플릿 이름', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextField(controller: descriptionController, decoration: const InputDecoration(labelText: '설명', border: OutlineInputBorder()), maxLines: 2),
                  const SizedBox(height: 16),
                  const Align(alignment: Alignment.centerLeft, child: Text('퀘스트 선택:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('clinics').doc(authProvider.clinicId).collection('questLibrary').orderBy('createdAt', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      final quests = snapshot.data!.docs;
                      return Container(
                        height: 300,
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                        child: ListView.builder(
                          itemCount: quests.length,
                          itemBuilder: (context, index) {
                            final quest = quests[index];
                            final data = quest.data() as Map<String, dynamic>;
                            return CheckboxListTile(
                              value: selectedQuestIds.contains(quest.id),
                              onChanged: (value) => setState(() => value == true ? selectedQuestIds.add(quest.id) : selectedQuestIds.remove(quest.id)),
                              title: Text(data['content'] ?? ''),
                              subtitle: Text('${data['points']}P'),
                              dense: true,
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text('선택된 퀘스트: ${selectedQuestIds.length}개', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('템플릿 이름을 입력하세요')));
                  return;
                }
                if (selectedQuestIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('최소 1개 이상의 퀘스트를 선택하세요')));
                  return;
                }
                try {
                  await FirebaseFirestore.instance.collection('clinics').doc(authProvider.clinicId).collection('carePlanTemplates').doc(templateId).update({
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'questIds': selectedQuestIds,
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('템플릿이 수정되었습니다')));
                  }
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
              child: const Text('수정'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteTemplate(BuildContext context, AuthProvider authProvider, String templateId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('템플릿 삭제'),
        content: Text('정말로 "$title" 템플릿을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('clinics').doc(authProvider.clinicId).collection('carePlanTemplates').doc(templateId).delete();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('템플릿이 삭제되었습니다')));
                }
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

