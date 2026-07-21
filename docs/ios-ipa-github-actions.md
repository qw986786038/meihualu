# GitHub Actions / Gitea Actions 打 IPA（无签名）

## 触发

Actions → **Build iOS IPA (unsigned)** → Run workflow

不需要证书、描述文件等 Secrets。

## 产物

Artifacts：`watermark-camera-ipa-unsigned`  
文件名类似：`watermark_camera-unsigned-<run_number>.ipa`

## 说明

- 使用 `flutter build ios --release --no-codesign`，再打成 Payload 结构的 IPA
- **不能**直接安装到未越狱真机，也**不能**直接上架 App Store
- 适合二次签名、归档或交给有证书的环境再签

若需要带签名的正式 IPA，需另配证书 Secrets 的签名 workflow。
