# iOS 打包与安装

## 为什么需要签名

iPhone 不能直接安装未签名的 `.ipa`。最终安装包必须由 Apple 的证书和描述文件签名，或者在安装时由 AltStore、Sideloadly 一类工具重新签名。

## 路线 A：自己的 iPhone，侧载安装

项目内的 GitHub Actions 工作流或 `scripts/build-unsigned-ipa.sh` 会在 macOS 上生成：

`build/unsigned/YuhunBox-unsigned.ipa`

这个文件需要交给侧载工具，用你的 Apple ID 重新签名后安装。免费 Apple ID 的签名通常需要定期续签。

## 路线 B：Apple Developer，开发或 Ad Hoc 安装

先在 Mac 的 Xcode 中登录 Apple 账号，并确保目标设备已注册。然后执行：

```bash
DEVELOPMENT_TEAM="你的 Team ID" \
PRODUCT_BUNDLE_IDENTIFIER="你的唯一 Bundle ID" \
EXPORT_METHOD="development" \
bash scripts/archive-and-export.sh
```

若已有 Ad Hoc 描述文件并包含目标 iPhone 的 UDID，把 `EXPORT_METHOD` 改为 `ad-hoc`。导出的签名文件位于 `build/signed-*/export/`。

不要把 `.p12`、私钥、密码或 App Store Connect API Key 提交到仓库，也不要在聊天中发送这些凭据。

## 路线 C：TestFlight

需要加入 Apple Developer Program，在 Xcode 中 Archive 后选择 TestFlight & App Store 上传。首次上传前还需要在 App Store Connect 创建应用记录。TestFlight 更适合多台设备和持续测试。


