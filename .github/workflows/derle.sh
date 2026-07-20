#!/bin/bash
set -e

echo "=== 1. Proje ZIP Dosyası Ayıklanıyor ==="
if [ -f "seray_saglikv1.46.zip" ]; then
    mkdir -p ham_ayiklama
    unzip -q seray_saglikv1.46.zip -d ham_ayiklama
    
    if [ -f "ham_ayiklama/pubspec.yaml" ]; then
        mv ham_ayiklama projem
    else
        mkdir -p projem
        mv ham_ayiklama/* projem/ 2>/dev/null || mv ham_ayiklama projem
    fi
    echo "Kaynak dosyalar başarıyla ayıklandı."
else
    echo "HATA: seray_saglikv1.46.zip bulunamadı!"
    exit 1
fi

echo "=== 2. Modern ve Sıfır Bir Proje Üretiliyor ==="
flutter create --platforms=android yeni_temiz_proje

echo "=== 3. Kaynak Kodlar Yeni Yapıya Aktarılıyor ==="
rm -rf yeni_temiz_proje/lib yeni_temiz_proje/pubspec.yaml
cp -r projem/lib yeni_temiz_proje/
cp projem/pubspec.yaml yeni_temiz_proje/

if [ -d "projem/assets" ]; then
    cp -r projem/assets yeni_temiz_proje/
fi

echo "=== 4. Modern Gradle Ayarları Yapılandırılıyor ==="
cat << 'EOF' > yeni_temiz_proje/android/app/build.gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

android {
    namespace "com.example.seray_saglik_asistanim"
    compileSdk 36

    compileOptions {
        coreLibraryDesugaringEnabled true
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId "com.example.seray_saglik_asistanim"
        minSdkVersion 23
        targetSdkVersion 36
        versionCode 1
        versionName "1.0.0"
        multiDexEnabled true
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
        }
    }
}

dependencies {
    coreLibraryDesugaring "com.android.tools:desugar_jdk_libs:2.1.4"
}
EOF

echo "=== 5. Bağımlılıkler Yükleniyor ve APK Derleniyor ==="
cd yeni_temiz_proje
flutter pub get
flutter build apk --release

echo "=== 6. Son Paketleme İşlemleri Yapılıyor ==="
VERSION=$(grep 'version:' pubspec.yaml | sed 's/version: //' | sed 's/+.*//' | tr -d ' ' | tr -d '\r')
SUPER_ZIP_NAME="seray_saglik_HEPS_ICINDE_v${VERSION}.zip"
cp build/app/outputs/flutter-apk/app-release.apk "../seray_saglik_asistanim_v${VERSION}.apk"
cd ..
zip -r "${SUPER_ZIP_NAME}" "./seray_saglik_asistanim_v${VERSION}.apk" yeni_temiz_proje/lib yeni_temiz_proje/pubspec.yaml .github
echo "İşlem tamamlandı, paket hazır: ${SUPER_ZIP_NAME}"
