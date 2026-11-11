# مدار | نیت و نوا

اپ Flutter فارسی و آفلاین برای فال‌های شاعرانه و سروده‌هایی با الهام از هرمزگان. نمونه‌های شعر این پروژه تألیفی‌اند و به‌عنوان شعر محلی مستند معرفی نمی‌شوند.

## اجرا

با Flutter stable (Dart 3.3 یا جدیدتر) نصب‌شده:

```sh
flutter create --platforms=android --org ir.madar --project-name madar --overwrite /tmp/madar-scaffold
# اگر پروژه را از آرشیو استخراج می‌کنید، کپی پوشهٔ android تولیدشده را روی android پروژه قرار دهید.
flutter pub get
flutter run
```

در GitHub Actions گردش‌کار `.github/workflows/build_apk.yml` زیرساخت Android/Gradle را آماده کرده و APK انتشار را به‌صورت artifact بارگذاری می‌کند. مسیر خروجی محلی: `build/app/outputs/flutter-apk/app-release.apk`.
