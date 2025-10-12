import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';

/// 식단 관리 화면
/// 한의학적 속성을 가진 식단 CRUD 관리
class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  String _searchQuery = '';
  String _filterNature = '전체'; // 전체, 따뜻함, 차가움, 중성

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('식단 관리'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton.icon(
              onPressed: () => _addSampleRecipes(context, authProvider),
              icon: const Icon(Icons.upload_file),
              label: const Text('샘플 식단 추가'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showAddRecipeDialog(context, authProvider),
              icon: const Icon(Icons.add),
              label: const Text('식단 추가'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색 및 필터
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                // 검색
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '식단 이름 검색...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // 성질 필터
                DropdownButton<String>(
                  value: _filterNature,
                  items: ['전체', '따뜻함', '차가움', '중성']
                      .map((nature) => DropdownMenuItem(
                            value: nature,
                            child: Row(
                              children: [
                                Icon(
                                  _getNatureIcon(nature),
                                  size: 16,
                                  color: _getNatureColor(nature),
                                ),
                                const SizedBox(width: 8),
                                Text(nature),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _filterNature = value ?? '전체';
                    });
                  },
                ),
              ],
            ),
          ),
          // 레시피 목록
          Expanded(
            child: authProvider.clinicId == null
                ? const Center(child: Text('로그인 정보가 없습니다'))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('clinics')
                        .doc(authProvider.clinicId)
                        .collection('recipes')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('오류: ${snapshot.error}'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var recipes = snapshot.data?.docs ?? [];

                      // 검색 필터 적용
                      if (_searchQuery.isNotEmpty) {
                        recipes = recipes.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name = (data['name'] as String? ?? '').toLowerCase();
                          return name.contains(_searchQuery);
                        }).toList();
                      }

                      // 성질 필터 적용
                      if (_filterNature != '전체') {
                        recipes = recipes.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return data['nature'] == _filterNature;
                        }).toList();
                      }

                      if (recipes.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.restaurant_menu_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty || _filterNature != '전체'
                                    ? '검색 결과가 없습니다'
                                    : '등록된 식단이 없습니다',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '오른쪽 상단의 "식단 추가" 버튼을 눌러 시작하세요',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400,
                          mainAxisExtent: 350,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = recipes[index];
                          final data = recipe.data() as Map<String, dynamic>;
                          return _buildRecipeCard(context, recipe.id, data, authProvider);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(
    BuildContext context,
    String recipeId,
    Map<String, dynamic> data,
    AuthProvider authProvider,
  ) {
    final name = data['name'] as String? ?? '이름 없음';
    final nature = data['nature'] as String? ?? '중성';
    final imageUrl = data['imageUrl'] as String?;
    final ingredients = data['ingredients'] as List? ?? [];
    final efficacy = data['efficacy'] as List? ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.restaurant_menu, size: 48, color: Colors.grey),
                        ),
                      );
                    },
                  )
                : Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.restaurant_menu, size: 48, color: Colors.grey),
                    ),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 이름 및 성질
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getNatureColor(nature).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _getNatureColor(nature)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getNatureIcon(nature),
                              size: 12,
                              color: _getNatureColor(nature),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              nature,
                              style: TextStyle(
                                fontSize: 11,
                                color: _getNatureColor(nature),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 재료 개수
                  if (ingredients.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.list, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          '재료 ${ingredients.length}개',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  // 효능 (최대 2개)
                  if (efficacy.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: efficacy.take(2).map((e) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            e.toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const Spacer(),
                  // 버튼들
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showEditRecipeDialog(
                          context,
                          authProvider,
                          recipeId,
                          data,
                        ),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('수정'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2E7D32),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _confirmDelete(
                          context,
                          authProvider,
                          recipeId,
                          name,
                        ),
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('삭제'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addSampleRecipes(BuildContext context, AuthProvider authProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('샘플 식단 추가'),
        content: const Text(
          '10개의 샘플 식단를 추가하시겠습니까?\n\n'
          '포함 레시피:\n'
          '• 대추생강차 (따뜻함)\n'
          '• 삼계탕 (따뜻함)\n'
          '• 오미자차 (차가움)\n'
          '• 녹두죽 (차가움)\n'
          '• 팥죽 (중성)\n'
          '• 연근조림 (중성)\n'
          '• 당귀계란탕 (따뜻함)\n'
          '• 도라지배즙 (중성)\n'
          '• 미역국 (차가움)\n'
          '• 인삼닭죽 (따뜻함)',
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
                  Text('샘플 식단 추가 중...'),
                ],
              ),
            ),
          ),
        ),
      );

      final sampleRecipes = [
        {
          "name": "대추생강차",
          "nature": "따뜻함",
          "imageUrl": "https://images.unsplash.com/photo-1564890369478-c89ca6d9cde9?w=400",
          "ingredients": ["대추 10개", "생강 3쪽 (약 30g)", "물 1L", "꿀 2큰술 (선택)"],
          "steps": [
            "대추는 깨끗이 씻어 칼집을 2-3군데 넣습니다.",
            "생강은 깨끗이 씻어 얇게 슬라이스합니다.",
            "냄비에 물 1L를 넣고 대추와 생강을 넣습니다.",
            "중불로 끓기 시작하면 약불로 줄여 20분간 더 끓입니다.",
            "불을 끄고 10분간 우려낸 후 체에 거릅니다.",
            "따뜻할 때 꿀을 넣어 마십니다."
          ],
          "efficacy": ["소화 촉진", "기력 회복", "면역력 강화", "감기 예방", "몸을 따뜻하게 함"]
        },
        {
          "name": "삼계탕",
          "nature": "따뜻함",
          "imageUrl": "https://images.unsplash.com/photo-1597773150796-e5c14ebecbf5?w=400",
          "ingredients": ["영계 1마리 (600-700g)", "찹쌀 1/2컵", "수삼 2뿌리", "대추 5개", "밤 3개", "마늘 5쪽", "대파 1대", "소금 약간"],
          "steps": [
            "영계는 깨끗이 손질하고 내장을 제거합니다.",
            "찹쌀은 30분 정도 물에 불립니다.",
            "닭의 뱃속에 불린 찹쌀, 수삼, 대추, 밤, 마늘을 넣습니다.",
            "다리를 실로 묶어 내용물이 빠지지 않게 합니다.",
            "냄비에 닭을 넣고 물을 자작하게 붓습니다.",
            "센 불에서 끓기 시작하면 중불로 줄여 1시간 30분간 푹 끓입니다.",
            "소금으로 간하고 대파를 송송 썰어 올립니다."
          ],
          "efficacy": ["기력 회복", "원기 보충", "면역력 강화", "피로 해소", "기혈 보충"]
        },
        {
          "name": "오미자차",
          "nature": "차가움",
          "imageUrl": "https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400",
          "ingredients": ["오미자 30g", "물 2L", "꿀 3큰술"],
          "steps": [
            "오미자를 깨끗이 씻어 물기를 뺍니다.",
            "오미자를 물 2L에 담가 냉장고에서 8시간 이상 우립니다.",
            "체에 거르고 씨를 제거합니다.",
            "꿀을 넣어 잘 저어 섞습니다.",
            "냉장 보관하며 차갑게 마십니다."
          ],
          "efficacy": ["갈증 해소", "폐 기능 강화", "기침 완화", "피로 회복", "간 기능 개선"]
        },
        {
          "name": "녹두죽",
          "nature": "차가움",
          "imageUrl": "https://images.unsplash.com/photo-1569441830-5ba31f6adc2c?w=400",
          "ingredients": ["녹두 1컵", "쌀 1/2컵", "물 6컵", "소금 약간"],
          "steps": [
            "녹두와 쌀을 깨끗이 씻어 각각 2시간 불립니다.",
            "불린 녹두를 믹서에 물 2컵과 함께 곱게 갈아줍니다.",
            "냄비에 간 녹두, 불린 쌀, 물 4컵을 넣고 센 불로 끓입니다.",
            "끓어오르면 약불로 줄이고 자주 저으며 30분간 끓입니다.",
            "농도를 보며 물을 추가하고 소금으로 간합니다.",
            "부드럽고 걸쭉해지면 완성입니다."
          ],
          "efficacy": ["열 내림", "해독 작용", "부기 제거", "피부 진정", "여름철 보양"]
        },
        {
          "name": "팥죽",
          "nature": "중성",
          "imageUrl": "https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400",
          "ingredients": ["팥 2컵", "찹쌀가루 1컵", "소금 1작은술", "설탕 3큰술", "물 8컵"],
          "steps": [
            "팥을 깨끗이 씻어 물 6컵을 붓고 센 불로 끓입니다.",
            "끓어오르면 약불로 줄여 1시간 정도 푹 삶습니다.",
            "팥이 무르면 체에 내려 팥고물을 만듭니다.",
            "냄비에 팥고물과 물 2컵을 넣고 끓입니다.",
            "찹쌀가루에 물을 조금씩 넣어 새알심을 빚습니다.",
            "끓는 팥죽에 새알심을 넣고 떠오를 때까지 끓입니다.",
            "소금과 설탕으로 간을 맞춥니다."
          ],
          "efficacy": ["이뇨 작용", "부기 제거", "해독 작용", "소화 촉진", "기력 보충"]
        },
        {
          "name": "연근조림",
          "nature": "중성",
          "imageUrl": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400",
          "ingredients": ["연근 300g", "간장 3큰술", "올리고당 2큰술", "참기름 1큰술", "깨소금 1작은술", "물 1컵"],
          "steps": [
            "연근은 껍질을 벗기고 5mm 두께로 썰어 식초물에 담가둡니다.",
            "냄비에 연근과 물 1컵을 넣고 5분간 데칩니다.",
            "간장, 올리고당, 물 1/2컵을 넣고 중불에서 끓입니다.",
            "국물이 자작해질 때까지 15분간 조립니다.",
            "참기름을 두르고 약불에서 윤기가 나도록 볶습니다.",
            "깨소금을 뿌려 완성합니다."
          ],
          "efficacy": ["폐 기능 강화", "기침 완화", "소화 촉진", "지혈 작용", "피부 개선"]
        },
        {
          "name": "당귀계란탕",
          "nature": "따뜻함",
          "imageUrl": "https://images.unsplash.com/photo-1587486936397-f6c5c0e8ca63?w=400",
          "ingredients": ["당귀 10g", "계란 2개", "대추 5개", "황기 10g", "물 1L", "흑설탕 2큰술"],
          "steps": [
            "당귀와 황기를 깨끗이 씻어 물기를 뺍니다.",
            "대추는 씻어 칼집을 2-3군데 넣습니다.",
            "냄비에 당귀, 황기, 대추, 물을 넣고 센 불로 끓입니다.",
            "끓어오르면 약불로 줄여 30분간 달입니다.",
            "한약재를 건져내고 국물만 남깁니다.",
            "계란을 풀어 천천히 부어 저어줍니다.",
            "흑설탕을 넣어 녹인 후 따뜻할 때 마십니다."
          ],
          "efficacy": ["혈액 순환", "빈혈 개선", "생리통 완화", "피부 윤기", "기혈 보충"]
        },
        {
          "name": "도라지배즙",
          "nature": "중성",
          "imageUrl": "https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=400",
          "ingredients": ["도라지 200g", "배 2개", "생강 10g", "꿀 3큰술", "물 1컵"],
          "steps": [
            "도라지는 껍질을 벗기고 소금물에 주물러 쓴맛을 뺍니다.",
            "배는 껍질을 벗기고 씨를 제거한 후 큼직하게 자릅니다.",
            "생강은 깨끗이 씻어 얇게 슬라이스합니다.",
            "믹서에 도라지, 배, 생강, 물 1컵을 넣고 곱게 갈아줍니다.",
            "체에 한번 걸러 과육을 제거합니다.",
            "꿀을 넣어 잘 섞은 후 차갑게 보관합니다.",
            "하루 2-3회, 한 컵씩 마십니다."
          ],
          "efficacy": ["기관지 개선", "기침 완화", "가래 제거", "목 통증 완화", "폐 기능 강화"]
        },
        {
          "name": "미역국",
          "nature": "차가움",
          "imageUrl": "https://images.unsplash.com/photo-1626804475297-41608ea09aeb?w=400",
          "ingredients": ["불린 미역 100g", "쇠고기 100g", "참기름 2큰술", "국간장 2큰술", "다진 마늘 1큰술", "물 6컵", "소금 약간"],
          "steps": [
            "미역은 물에 불려 적당한 크기로 자릅니다.",
            "쇠고기는 한입 크기로 썰어 국간장, 다진 마늘로 밑간합니다.",
            "냄비에 참기름을 두르고 쇠고기를 볶습니다.",
            "미역을 넣고 함께 볶아줍니다.",
            "물 6컵을 붓고 센 불로 끓입니다.",
            "끓어오르면 중불로 줄여 20분간 더 끓입니다.",
            "소금과 국간장으로 간을 맞춥니다."
          ],
          "efficacy": ["산후 조리", "혈액 정화", "요오드 보충", "갑상선 기능", "변비 개선"]
        },
        {
          "name": "인삼닭죽",
          "nature": "따뜻함",
          "imageUrl": "https://images.unsplash.com/photo-1547592166-b62e7f5c8f06?w=400",
          "ingredients": ["닭 가슴살 200g", "쌀 1컵", "수삼 2뿌리", "대추 5개", "물 8컵", "소금 약간", "참기름 1큰술"],
          "steps": [
            "쌀은 깨끗이 씻어 30분 불립니다.",
            "닭 가슴살은 한입 크기로 썰고 수삼은 얇게 슬라이스합니다.",
            "대추는 씨를 제거하고 잘게 썹니다.",
            "냄비에 참기름을 두르고 닭고기를 볶습니다.",
            "쌀을 넣고 함께 볶아줍니다.",
            "물 8컵을 붓고 센 불로 끓입니다.",
            "끓어오르면 수삼과 대추를 넣고 약불로 줄입니다.",
            "자주 저어가며 40분간 끓이고 소금으로 간합니다."
          ],
          "efficacy": ["기력 회복", "면역력 강화", "원기 보충", "피로 해소", "소화 촉진"]
        }
      ];

      final batch = FirebaseFirestore.instance.batch();
      final recipesCollection = FirebaseFirestore.instance
          .collection('clinics')
          .doc(authProvider.clinicId)
          .collection('recipes');

      for (var recipe in sampleRecipes) {
        final docRef = recipesCollection.doc();
        batch.set(docRef, {
          ...recipe,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ 샘플 식단 10개가 추가되었습니다!'),
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

  void _showAddRecipeDialog(BuildContext context, AuthProvider authProvider) {
    _showRecipeDialog(context, authProvider, null, null);
  }

  void _showEditRecipeDialog(
    BuildContext context,
    AuthProvider authProvider,
    String recipeId,
    Map<String, dynamic> existingData,
  ) {
    _showRecipeDialog(context, authProvider, recipeId, existingData);
  }

  void _showRecipeDialog(
    BuildContext context,
    AuthProvider authProvider,
    String? recipeId,
    Map<String, dynamic>? existingData,
  ) {
    final nameController = TextEditingController(text: existingData?['name'] ?? '');
    final imageUrlController = TextEditingController(text: existingData?['imageUrl'] ?? '');
    String selectedNature = existingData?['nature'] ?? '중성';

    // Convert Lists to String for editing
    final ingredientsController = TextEditingController(
      text: (existingData?['ingredients'] as List?)?.join('\n') ?? '',
    );
    final stepsController = TextEditingController(
      text: (existingData?['steps'] as List?)?.join('\n') ?? '',
    );
    final efficacyController = TextEditingController(
      text: (existingData?['efficacy'] as List?)?.join('\n') ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(recipeId == null ? '레시피 추가' : '식단 수정'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 식단 이름
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '식단 이름 *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 성질 선택
                  DropdownButtonFormField<String>(
                    value: selectedNature,
                    decoration: const InputDecoration(
                      labelText: '한의학적 성질 *',
                      border: OutlineInputBorder(),
                    ),
                    items: ['따뜻함', '차가움', '중성'].map((nature) {
                      return DropdownMenuItem(
                        value: nature,
                        child: Row(
                          children: [
                            Icon(
                              _getNatureIcon(nature),
                              size: 16,
                              color: _getNatureColor(nature),
                            ),
                            const SizedBox(width: 8),
                            Text(nature),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedNature = value ?? '중성';
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // 이미지 URL
                  TextField(
                    controller: imageUrlController,
                    decoration: const InputDecoration(
                      labelText: '이미지 URL',
                      border: OutlineInputBorder(),
                      hintText: 'https://example.com/image.jpg',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 재료 (한 줄에 하나씩)
                  TextField(
                    controller: ingredientsController,
                    decoration: const InputDecoration(
                      labelText: '재료 (한 줄에 하나씩) *',
                      border: OutlineInputBorder(),
                      hintText: '예: 대추 10개\n생강 3쪽\n물 1L',
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
                  // 조리법 (한 줄에 한 단계씩)
                  TextField(
                    controller: stepsController,
                    decoration: const InputDecoration(
                      labelText: '조리법 (한 줄에 한 단계씩) *',
                      border: OutlineInputBorder(),
                      hintText: '예: 대추와 생강을 깨끗이 씻습니다.\n물에 넣고 중불로 끓입니다.',
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
                  // 효능 (한 줄에 하나씩)
                  TextField(
                    controller: efficacyController,
                    decoration: const InputDecoration(
                      labelText: '한의학적 효능 (한 줄에 하나씩)',
                      border: OutlineInputBorder(),
                      hintText: '예: 소화 촉진\n기력 회복\n면역력 강화',
                    ),
                    maxLines: 4,
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
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('식단 이름을 입력하세요')),
                  );
                  return;
                }

                // Convert multiline text to lists
                final ingredients = ingredientsController.text
                    .split('\n')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                final steps = stepsController.text
                    .split('\n')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                final efficacy = efficacyController.text
                    .split('\n')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                if (ingredients.isEmpty || steps.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('재료와 조리법은 필수입니다')),
                  );
                  return;
                }

                final recipeData = {
                  'name': name,
                  'nature': selectedNature,
                  'imageUrl': imageUrlController.text.trim(),
                  'ingredients': ingredients,
                  'steps': steps,
                  'efficacy': efficacy,
                  'updatedAt': FieldValue.serverTimestamp(),
                };

                try {
                  if (recipeId == null) {
                    // Add new recipe
                    recipeData['createdAt'] = FieldValue.serverTimestamp();
                    await FirebaseFirestore.instance
                        .collection('clinics')
                        .doc(authProvider.clinicId)
                        .collection('recipes')
                        .add(recipeData);
                  } else {
                    // Update existing recipe
                    await FirebaseFirestore.instance
                        .collection('clinics')
                        .doc(authProvider.clinicId)
                        .collection('recipes')
                        .doc(recipeId)
                        .update(recipeData);
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          recipeId == null
                              ? '✅ 식단이 추가되었습니다'
                              : '✅ 식단이 수정되었습니다',
                        ),
                        backgroundColor: const Color(0xFF2E7D32),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('오류: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: Text(recipeId == null ? '추가' : '수정'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    AuthProvider authProvider,
    String recipeId,
    String recipeName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('식단 삭제'),
        content: Text('정말로 "$recipeName" 식단을 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('clinics')
                    .doc(authProvider.clinicId)
                    .collection('recipes')
                    .doc(recipeId)
                    .delete();

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ 식단이 삭제되었습니다'),
                      backgroundColor: Color(0xFF2E7D32),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('오류: $e'),
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
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Color _getNatureColor(String nature) {
    switch (nature) {
      case '따뜻함':
        return Colors.orange;
      case '차가움':
        return Colors.blue;
      case '중성':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getNatureIcon(String nature) {
    switch (nature) {
      case '따뜻함':
        return Icons.local_fire_department;
      case '차가움':
        return Icons.ac_unit;
      case '중성':
        return Icons.balance;
      default:
        return Icons.circle;
    }
  }
}
