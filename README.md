# TelShevaAzan iOS Prototype

Current app version: `0.2.3 (9)`

مشروع iPhone أولي لتطبيق أذان تل السبع.

## ماذا يحتوي؟

- SwiftUI app
- مواقيت تل السبع لشهر مايو 2026 كنموذج أولي
- المصدر المنطقي: توقيت المسجد الأقصى الدهري + دقيقتين لبئر السبع/تل السبع + ساعة التوقيت الصيفي
- الصلاة القادمة والعد التنازلي
- أزرار اليوم السابق / اليوم / اليوم التالي
- يدعم iOS 15 وما فوق كبداية مناسبة لـ TrollStore
- WidgetKit extension للشاشة الرئيسية بحجم صغير ومتوسط

## إخراج IPA

ملف `.ipa` لا يمكن بناؤه بشكل صحيح من Windows. تحتاج:

1. Mac
2. Xcode
3. Apple Developer account أو توقيع محلي للتجربة

افتح:

```text
TelShevaAzan.xcodeproj
```

ثم من Xcode:

1. اختر target `TelShevaAzan`
2. افتح `Signing & Capabilities`
3. اختر Team الخاص بك
4. غيّر Bundle Identifier إذا لزم:

```text
com.yourname.TelShevaAzan
```

5. من القائمة:

```text
Product > Archive
```

ثم:

```text
Distribute App > Ad Hoc / Development
```

## ملاحظة

هذا Prototype. للتطبيق النهائي نحتاج إدخال جدول السنة كاملًا، ثم إضافة WidgetKit والتنبيهات.
