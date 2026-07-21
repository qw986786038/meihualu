# iOS 测试设备 UDID

用于 Ad Hoc / Development 描述文件，安装签名包。

| # | UDID |
|---|------|
| 1 | `00008130-001845C00E30001C` |
| 2 | `00008110-000210D20E01801E` |
| 3 | `00008150-001448C12E84401C` |

## 在 Apple Developer 后台添加（必做）

1. 打开 [Certificates, Identifiers & Profiles → Devices](https://developer.apple.com/account/resources/devices/list)
2. 点 **+**，Platform 选 **iOS**，逐个登记上面 3 个 UDID（Name 可自定义，如「测试机1」）
3. 打开 [Profiles](https://developer.apple.com/account/resources/profiles/list)
4. 编辑（或新建）**Ad Hoc** 描述文件：
   - App ID：`com.palsmon.mediarecord.app`
   - Certificates：选分发证书
   - Devices：**勾选**刚添加的 3 台设备
5. **Generate** → **Download** 得到新的 `.mobileprovision`
6. 用新 profile 重新签名 / 重新打 Ad Hoc IPA（无签名包无法直接装到真机）

## 说明

- 当前 GitHub Actions 打的是 **unsigned** IPA，**即使 UDID 已进 profile，无签名包仍无法安装**
- 真机安装需要：含上述设备的 Ad Hoc profile + 对应证书签名后的 IPA
