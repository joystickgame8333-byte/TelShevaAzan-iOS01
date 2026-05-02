# Build IPA Without A Mac

بما أن عندك TrollStore، نحتاج فقط ملف IPA مبني لـ iPhone. لا نحتاج نشر App Store.

## الطريقة الأسهل: GitHub Actions

1. ارفع محتوى هذا المجلد إلى GitHub repository:

```text
TelShevaAzan-iOS
```

2. افتح GitHub:

```text
Actions > Build unsigned IPA > Run workflow
```

3. بعد انتهاء البناء، نزّل artifact:

```text
TelShevaAzan-unsigned-ipa
```

4. فك الضغط وستجد:

```text
TelShevaAzan-unsigned.ipa
```

5. أرسل الملف للآيفون وثبته عبر TrollStore.

## مهم

هذا IPA غير موقّع للـ App Store. هذا مقصود لأنه موجه لـ TrollStore.

إذا GitHub Actions فشل، أرسل لي نص الخطأ وسأعدّل ملف البناء حسبه.
