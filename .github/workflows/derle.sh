#!/bin/bash
set -e

echo "=== 1. Proje ZIP Dosyası Ayıklanıyor ==="
if [ -f "seray_saglikv147.zip" ]; then
    mkdir -p ham_ayiklama
    unzip -q seray_saglikv147.zip -d ham_ayiklama
    
    if [ -f "ham_ayiklama/pubspec.yaml" ]; then
        mv ham_ayiklama projem
    else
        mkdir -p projem
        mv ham_ayiklama/* projem/ 2>/dev/null || mv ham_ayiklama projem
    fi
    echo "Kaynak dosyalar başarıyla ayıklandı."
else
    echo "HATA: seray_saglikv147.zip bulunamadı!"
    exit 1
fi

echo "=== 2. Modern ve Sıfır Bir Proje Üretiliyor ==="
flutter create --platforms=android Akıllı_Sağlik_Asistanım

echo "=== 3. Tüm Kaynak Kodlar ve Assets Eksiksiz Aktarılıyor ==="
rm -rf Akıllı_Sağlik_Asistanim/lib Akıllı_Sağlik_Asistanım/pubspec.yaml
cp -r projem/lib Akıllı_Sağlik_Asistanim/
cp projem/pubspec.yaml Akıllı_Sağlik_Asistanim/

# Son ekran görüntüsündeki fontlar ve tüm assets klasörü buradaki komutla yeni projeye aktarılıyor
if [ -d "projem/assets" ]; then
    cp -r projem/assets Akıllı_Sağlik_Asistanim/
    echo "Assets klasörü başarıyla yeni projeye enjekte edildi."
fi

echo "=== 4. Modern Gradle Ayarları Yapılandırılıyor ==="
cat << 'EOF' > Akıllı_Sağlik_Asistanim/android/app/build.gradle
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

echo "=== 5. Bağımlılıklar Yükleniyor ve APK Derleniyor ==="
cd Akıllı_Sağlik_Asistanım
flutter pub get
flutter build apk --release

echo "=== 6. Tüm Projeyi ve APK'yı Eksiksiz ZIP Paketine Alıyor ==="
VERSION=$(grep 'version:' pubspec.yaml | sed 's/version: //' | sed 's/+.*//' | tr -d ' ' | tr -d '\r')
SUPER_ZIP_NAME="seray_saglik_Hepsi_Yeni_v${VERSION}.zip"

# APK dosyasını ana dizine çıkartıyoruz
cp build/app/outputs/flutter-apk/app-release.apk "../seray_saglik_asistanim_v${VERSION}.apk"
cd ..

# ZIP paketinin içine yeni temiz projenin tüm içeriğini (android altyapısı dahil) eksiksiz koyuyoruz
zip -r "${SUPER_ZIP_NAME}" "./seray_saglik_asistanim_v${VERSION}.apk" Akıllı_Sağlik_Asistanım .github
echo "İşlem başarıyla bitti, tam paket hazır: ${SUPER_ZIP_NAME}"
