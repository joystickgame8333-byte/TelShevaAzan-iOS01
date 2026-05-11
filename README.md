# TelShevaAzan iOS Prototype

Current app version: `0.6.41 (132)`

مشروع iPhone أولي لتطبيق أذان تل السبع.

## ماذا يحتوي؟

- SwiftUI app
- مواقيت تل السبع لشهر مايو 2026 كنموذج أولي
- المصدر المنطقي: توقيت المسجد الأقصى الدهري + دقيقتين لبئر السبع/تل السبع + ساعة التوقيت الصيفي
- الصلاة القادمة والعد التنازلي
- أزرار اليوم السابق / اليوم / اليوم التالي
- يتبع وضع النظام تلقائيًا بين الليل والنهار
- يدعم iOS 15 وما فوق كبداية مناسبة لـ TrollStore
- WidgetKit extension يعرض الصلاة القادمة والوقت والباقي عليها للشاشة الرئيسية وشاشة القفل في iOS 16
- تنبيهات محلية للصلوات القادمة بعد موافقة المستخدم

## إخراج IPA

ملف `.ipa` لا يمكن بناؤه بشكل صحيح من Windows. تحتاج:

1. Mac
2. Xcode
3. Apple Developer account أو توقيع محلي للتجربة

للتعديل المحلي افتح المشروع بعد توليده من `project.yml`. ملف `TelShevaAzan.xcodeproj` الموجود في الريبو قد يكون قديماً إذا لم يتم توليده من جديد.

على GitHub Actions يتم حذف المشروع القديم وتوليده تلقائياً عبر XcodeGen قبل البناء، لذلك مصدر الحقيقة للنسخة والتارغتات هو:

```text
project.yml
```

إذا كنت على Mac وتريد فتحه يدوياً:

```text
xcodegen generate
open TelShevaAzan.xcodeproj
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

هذا Prototype. للتطبيق النهائي نحتاج إدخال جدول السنة كاملًا، ثم تحسين التنبيهات بالأذان وخيارات ما قبل الصلاة.
