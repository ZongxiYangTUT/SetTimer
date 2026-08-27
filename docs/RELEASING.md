# Windows 发布流程

SetTimer 使用语义化版本和 Conventional Commits。`pyproject.toml` 与
`src/settimer/__init__.py` 中的版本号必须一致。

## 准备版本

1. 将版本号更新为 `MAJOR.MINOR.PATCH`；
2. 将本次变更整理到 `CHANGELOG.md`；
3. 运行 `scripts\check.ps1` 并检查最终差异；
4. 创建一个聚焦的发布提交。

发布依赖固定在 `requirements-release.txt`。新环境可执行：

```powershell
py -3.13 -m venv .venv
.venv\Scripts\python -m pip install -r requirements-release.txt
.venv\Scripts\python -m pip install -e .
winget install --id JRSoftware.InnoSetup -e -s winget
```

## 生成并验证安装包

```powershell
.\scripts\build-release.ps1 -Version 0.1.0
```

脚本会依次执行完整质量检查、PyInstaller 打包、Kokoro 模型校验、Inno Setup
编译以及静默安装、启动、卸载冒烟测试。最终文件输出到 `release\`，并生成
`SHA256SUMS.txt`。

安装器采用每用户安装，不请求管理员权限。完整安装默认部署离线语音包；精简安装
只部署主程序并使用 Windows 系统声音。卸载时保留用户设置、训练历史和离线模型。

## 发布

```powershell
git tag -a v0.1.0 -m "SetTimer 0.1.0"
git push origin v0.1.0
```

推送 `v*` 标签后，GitHub Actions 会在干净的 Windows 环境重新构建并发布安装包。
正式公开分发前应为安装器配置受信任的 Authenticode 代码签名证书；未签名版本可能
触发 Windows SmartScreen 提示。
