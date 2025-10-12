# 🛡️ 한의원 관리자 웹

PC에서 사용하는 관리자 전용 웹 애플리케이션

## 🚀 시작하기

### 1. 관리자 계정 등록

```bash
# setup_admin.dart에서 Google UID 수정 후:
dart run setup_admin.dart
```

### 2. 관리자 웹 실행

```bash
cd admin_web
flutter run -d chrome --web-port=8080
```

## 🔐 로그인

1. Google로 로그인
2. 등록된 관리자만 접근 가능

## ✨ 기능

- 📊 대시보드: 실시간 통계
- 👥 환자 관리: 추가/삭제/포인트 조정
- 📋 케어 플랜 (구현 예정)
- ✅ 구매 승인 (구현 예정)
- 📦 상품 관리 (구현 예정)
- 🛡️ 커뮤니티 (구현 예정)

## 📱 모바일 앱과 분리

| 모바일 앱 | 관리자 웹 |
|----------|----------|
| 환자용 | 관리자용 |
| mobile_app_v2/ | admin_web/ |
| Android/iOS | Web (PC) |

Firestore 데이터베이스는 공유합니다.
