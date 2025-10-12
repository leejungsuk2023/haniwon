import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';

/// 관리자 웹 - 채팅 관리 화면
class ChatManagementScreen extends StatefulWidget {
  const ChatManagementScreen({super.key});

  @override
  State<ChatManagementScreen> createState() => _ChatManagementScreenState();
}

class _ChatManagementScreenState extends State<ChatManagementScreen> {
  String? _selectedChatRoomId;
  String? _selectedPatientName;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅 관리'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: authProvider.clinicId == null
          ? const Center(child: Text('로그인 정보가 없습니다'))
          : Row(
              children: [
                // 왼쪽: 채팅방 목록 (환자 목록)
                Expanded(
                  flex: 1,
                  child: _buildChatRoomList(authProvider),
                ),
                
                const VerticalDivider(width: 1),
                
                // 오른쪽: 채팅 내용
                Expanded(
                  flex: 2,
                  child: _selectedChatRoomId == null
                      ? const Center(
                          child: Text(
                            '채팅할 환자를 선택하세요',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : _buildChatRoomDetail(authProvider),
                ),
              ],
            ),
    );
  }

  /// 채팅방 목록 (환자별)
  Widget _buildChatRoomList(AuthProvider authProvider) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clinics')
          .doc(authProvider.clinicId)
          .collection('chatRooms')
          .orderBy('lastMessageAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('오류: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final chatRooms = snapshot.data?.docs ?? [];

        if (chatRooms.isEmpty) {
          return const Center(
            child: Text('아직 채팅방이 없습니다'),
          );
        }

        return ListView.builder(
          itemCount: chatRooms.length,
          itemBuilder: (context, index) {
            final chatRoom = chatRooms[index];
            final data = chatRoom.data() as Map<String, dynamic>;

            return _buildChatRoomListItem(
              chatRoomId: chatRoom.id,
              patientId: data['patientId'] ?? '',
              clinicName: data['clinicName'] ?? '환자',
              lastMessage: data['lastMessage'] ?? '',
              lastMessageAt: data['lastMessageAt'] as Timestamp?,
              unreadCount: data['unreadCount'] ?? 0,
            );
          },
        );
      },
    );
  }

  /// 채팅방 목록 아이템
  Widget _buildChatRoomListItem({
    required String chatRoomId,
    required String patientId,
    required String clinicName,
    required String lastMessage,
    required Timestamp? lastMessageAt,
    required int unreadCount,
  }) {
    final isSelected = _selectedChatRoomId == chatRoomId;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('clinics')
          .doc(Provider.of<AuthProvider>(context, listen: false).clinicId)
          .collection('patients')
          .doc(patientId)
          .get(),
      builder: (context, snapshot) {
        final patientName = snapshot.hasData
            ? (snapshot.data!.data() as Map<String, dynamic>?)?['name'] ?? '이름 없음'
            : '로딩 중...';

        return Container(
          color: isSelected ? Colors.green.withValues(alpha: 0.1) : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF2E7D32),
              child: Text(
                patientName.isNotEmpty ? patientName[0] : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              patientName,
              style: TextStyle(
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (lastMessageAt != null)
                  Text(
                    _formatTimestamp(lastMessageAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                if (unreadCount > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            onTap: () {
              setState(() {
                _selectedChatRoomId = chatRoomId;
                _selectedPatientName = patientName;
              });
            },
          ),
        );
      },
    );
  }

  /// 채팅 상세 화면
  Widget _buildChatRoomDetail(AuthProvider authProvider) {
    return Column(
      children: [
        // 헤더
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF2E7D32),
                child: Text(
                  _selectedPatientName != null && _selectedPatientName!.isNotEmpty
                      ? _selectedPatientName![0]
                      : '?',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _selectedPatientName ?? '환자',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // 메시지 목록
        Expanded(
          child: _buildMessageList(authProvider),
        ),

        // 메시지 입력
        _buildMessageInput(authProvider),
      ],
    );
  }

  /// 메시지 목록
  Widget _buildMessageList(AuthProvider authProvider) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clinics')
          .doc(authProvider.clinicId)
          .collection('chatRooms')
          .doc(_selectedChatRoomId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('오류: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data?.docs ?? [];

        if (messages.isEmpty) {
          return const Center(
            child: Text('메시지가 없습니다. 첫 메시지를 보내보세요!'),
          );
        }

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final data = message.data() as Map<String, dynamic>;

            final isAdmin = data['senderId'] != null &&
                data['senderId'].toString().contains('admin');

            return _buildMessageBubble(
              text: data['text'] ?? '',
              imageUrl: data['imageUrl'],
              type: data['type'] ?? 'text',
              isAdmin: isAdmin,
              createdAt: data['createdAt'] as Timestamp?,
            );
          },
        );
      },
    );
  }

  /// 메시지 말풍선
  Widget _buildMessageBubble({
    required String text,
    String? imageUrl,
    required String type,
    required bool isAdmin,
    required Timestamp? createdAt,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isAdmin) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, color: Colors.grey, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.5,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: type == 'image'
                        ? Colors.transparent
                        : (isAdmin ? const Color(0xFF2E7D32) : Colors.grey[200]),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isAdmin ? const Radius.circular(18) : const Radius.circular(4),
                      bottomRight: isAdmin ? const Radius.circular(4) : const Radius.circular(18),
                    ),
                  ),
                  child: type == 'image' && imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Text(
                          text,
                          style: TextStyle(
                            color: isAdmin ? Colors.white : Colors.black87,
                            fontSize: 15,
                            height: 1.3,
                          ),
                        ),
                ),
                if (createdAt != null) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: EdgeInsets.only(
                      right: isAdmin ? 8 : 0,
                      left: isAdmin ? 0 : 8,
                    ),
                    child: Text(
                      DateFormat('HH:mm').format(createdAt.toDate()),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 메시지 입력 필드
  Widget _buildMessageInput(AuthProvider authProvider) {
    final messageController = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: '메시지를 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  _sendMessage(authProvider, text.trim());
                  messageController.clear();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () {
                final text = messageController.text.trim();
                if (text.isNotEmpty) {
                  _sendMessage(authProvider, text);
                  messageController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 메시지 전송
  Future<void> _sendMessage(AuthProvider authProvider, String message) async {
    if (_selectedChatRoomId == null || message.trim().isEmpty) {
      return;
    }

    try {
      // 1. 메시지 추가
      await FirebaseFirestore.instance
          .collection('clinics')
          .doc(authProvider.clinicId)
          .collection('chatRooms')
          .doc(_selectedChatRoomId)
          .collection('messages')
          .add({
        'text': message,
        'senderId': 'admin_${authProvider.user?.uid ?? 'unknown'}',
        'senderName': '관리자',
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'text',
      });

      // 2. 채팅방 업데이트 (lastMessage, unreadCount 증가)
      await FirebaseFirestore.instance
          .collection('clinics')
          .doc(authProvider.clinicId)
          .collection('chatRooms')
          .doc(_selectedChatRoomId)
          .update({
        'lastMessage': message,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount': FieldValue.increment(1), // 👈 안 읽은 메시지 증가
      });

      print('✅ 관리자 메시지 전송 완료 (unreadCount 증가)');
    } catch (e) {
      print('❌ 메시지 전송 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('메시지 전송 실패: $e')),
        );
      }
    }
  }

  /// 타임스탬프 포맷팅
  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) {
      return '방금 전';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}시간 전';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else {
      return DateFormat('MM/dd').format(date);
    }
  }
}

