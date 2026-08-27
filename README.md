# SetTimer

SetTimer 是一款原生 Windows 桌面间歇计时器。配置训练时长、休息时长和组数后，应用会自动完成准备、训练、休息、下一组和完成提醒。

当前版本使用 Python、PySide6 和 Qt Quick/QML 实现，不依赖浏览器、WebView 或本地服务。
当前开发、测试、打包和发布只面向 Windows 10/11；Linux 支持暂缓。

## 功能

- 准备、训练、休息、暂停和完成状态清晰可见；
- 以图标、状态色和进度动画为主要反馈，减少非必要说明文字；
- 训练时间、休息时间和训练组数可在主页直接滚动设置，准备倒计时可在设置页配置；
- 最后 3 秒提示、阶段提示音和可选中文语音播报；
- 暂停后可直接继续，或使用 3 秒继续倒计时；
- 训练中的停止按钮需要长按完成进度环，避免误触且不打断界面；
- 自动保存完成和中断的训练记录，按日期分组并统计本周次数与总用时；记录向左滑动后，可点击红色垃圾桶按钮删除；
- 采用定稿的纯黑高对比界面，训练、休息和暂停分别使用绿、蓝、橙状态色；
- 窗口置顶、训练页全屏和活动期间防休眠；
- 设置使用 Qt `QSettings` 自动保存，历史记录写入系统应用数据目录；
- 内置 Noto Sans SC，确保中文显示一致；
- `Space`、`R`、`Esc`、`F`、`M`、`H` 桌面快捷键。

计时核心使用注入的单调时钟和绝对截止时间。界面刷新延迟不会延长阶段，暂停/继续也不会累计漂移。

## Windows 开发环境

需要 Windows 10/11 和 Python 3.10 或更高版本。在 PowerShell 中执行：

```powershell
py -3 -m venv .venv
.venv\Scripts\python -m pip install --upgrade pip
.venv\Scripts\python -m pip install -e ".[dev]"
.venv\Scripts\python -m settimer
```

## 检查与测试

```powershell
.\scripts\check.ps1
```

该命令执行：

- Ruff 格式检查和代码规范检查；
- Pyright 严格类型检查；
- `qmllint` 零警告检查；
- 单元测试和控制层集成测试。

测试使用可控的假时钟，不包含真实 `sleep()`。如需查看分支覆盖率：

```powershell
.venv\Scripts\python -m coverage run -m unittest discover -s tests
.venv\Scripts\python -m coverage report
```

每项开发完成后应同步整理相关文档，使用 Conventional Commits 创建聚焦提交，并将当前分支推送到已配置的远端。

## 打包

在 Windows PowerShell 中执行：

```powershell
.\scripts\package.ps1
```

PyInstaller 会先运行完整质量检查，再将 Windows 版本输出到 `dist/SetTimer/`，并启动成品确认主窗口能够正常打开。发布包应在 Windows 目标环境中构建和验证。

`SetTimer` 当前使用目录分发模式。发布或复制时必须保留整个 `dist/SetTimer/` 目录，不能只复制其中的 `SetTimer.exe`。

## 快捷键

| 快捷键 | 操作 |
| --- | --- |
| `Space` | 开始 / 暂停 / 继续 |
| `R` | 完成后再来一次；训练中直接结束 |
| `Esc` | 从设置返回，或关闭当前弹窗 |
| `F` | 训练页切换全屏 |
| `M` | 临时静音 / 恢复声音 |
| `H` | 从主页打开历史记录 |

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
