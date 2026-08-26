# SetTimer

SetTimer 是一款原生 Windows / Linux 桌面间歇计时器。配置训练时长、休息时长和组数后，应用会自动完成准备、训练、休息、下一组和完成提醒。

当前版本使用 Python、PySide6 和 Qt Quick/QML 实现，不依赖浏览器、WebView 或本地服务。

## 功能

- 准备、训练、休息、暂停和完成状态清晰可见；
- 训练时间、休息时间、训练组数和准备倒计时可配置；
- 最后 3 秒提示、阶段提示音和可选中文语音播报；
- 暂停后可直接继续，或使用 3 秒继续倒计时；
- 浅色、深色和跟随系统主题；
- 窗口置顶、训练页全屏和活动期间防休眠；
- 设置使用 Qt `QSettings` 自动保存；
- 内置 Noto Sans SC，避免 Linux 缺少中文字体时显示方框；
- `Space`、`R`、`Esc`、`F`、`M` 桌面快捷键。

计时核心使用注入的单调时钟和绝对截止时间。界面刷新延迟不会延长阶段，暂停/继续也不会累计漂移。

## 开发环境

需要 Python 3.10 或更高版本。

```bash
python3 -m venv .venv
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -e '.[dev]'
make run
```

Windows PowerShell 使用：

```powershell
py -3.10 -m venv .venv
.venv\Scripts\python -m pip install --upgrade pip
.venv\Scripts\python -m pip install -e ".[dev]"
.venv\Scripts\python -m settimer
```

Linux 的中文语音依赖系统可用的 Qt 文本转语音后端；Ubuntu 可选安装 `speech-dispatcher`。没有语音后端时，计时和提示音仍可正常工作。

## 检查与测试

```bash
make check
```

该命令执行：

- Ruff 格式检查和代码规范检查；
- Pyright 严格类型检查；
- `qmllint` 零警告检查；
- 单元测试和控制层集成测试。

测试使用可控的假时钟，不包含真实 `sleep()`。如需查看分支覆盖率：

```bash
make coverage
```

## 打包

在目标平台执行：

```bash
make package
```

PyInstaller 会先运行完整质量检查，再将当前平台版本输出到 `dist/SetTimer/`。Windows 构建会生成 Windows 可执行文件，Linux 构建会生成 Linux 目录分发包；发布包应分别在对应平台构建和验证。

部分精简 Linux/WSL 环境缺少 Qt XCB 或语音系统库。正式 Linux 构建应在带桌面运行库的目标发行版或匹配的构建容器中完成。

## 快捷键

| 快捷键 | 操作 |
| --- | --- |
| `Space` | 开始 / 暂停 / 继续 |
| `R` | 完成后再来一次；训练中打开结束确认 |
| `Esc` | 从设置返回，或关闭当前弹窗 |
| `F` | 训练页切换全屏 |
| `M` | 临时静音 / 恢复声音 |

## 工程结构

```text
src/settimer/
├── application/       Qt 控制器、界面格式化和播报协调
├── domain/            与 Qt 无关的计时状态机、模型和语义事件
├── services/          时钟、设置、声音、语音和系统防休眠适配
├── ui/                Qt Quick/QML 页面和原生组件
├── assets/            图标、字体及字体许可证
└── main.py            桌面应用入口

tests/
├── unit/              计时、格式化和设置测试
└── integration/       控制器流程测试
```

计时业务规则只存在于 `domain` 层；QML 负责布局、交互和动画，33 ms 的界面更新定时器只触发刷新，不作为经过时间的事实来源。
