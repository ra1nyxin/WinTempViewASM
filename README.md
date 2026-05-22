# WinTempViewASM

WinTempViewASM 是一个使用 x64 汇编、MinGW-w64 GCC 和原生 Win32 API 编写的 Windows 垃圾/缓存清理工具。界面为原生 GUI，核心目标是提供可审计、无托管运行时依赖的缓存扫描、空间预估和清理能力。

项目当前处于原型迭代阶段，适合用于学习 Win64 ABI、Win32 GUI、Unicode API、后台线程和文件系统清理逻辑，也可以作为轻量级 Windows 清理工具继续扩展。

## 功能

- 原生 Win32 GUI，使用 Unicode `W` 版 API。
- 控件字体使用 Windows 10/11 常见中文 UI 字体 `Microsoft YaHei UI`，不依赖外部字体文件。
- 支持按大分类选择清理范围：Windows、浏览器、应用、开发工具、聊天数据、游戏平台、媒体工具、回收站。
- 支持目标扫描、空间预估和真实清理。
- 扫描结果显示文件数、目录数、跳过数，以及预计可释放空间。
- 预计可释放空间使用 `MB / GB` 双格式显示，并保留两位小数。
- 清理任务运行在后台线程，进度通过窗口消息回传 UI 线程，避免界面卡死。
- 清理进度显示已处理项数和剩余项数，不显示预计时间。
- 启动时在程序所在目录生成 `winTempView-log-YYYY-MMDD_HHMMSS.txt` 实时日志，便于排查启动、建窗、扫描和清理流程。
- 可执行文件内嵌 `requireAdministrator` manifest，启动时默认请求管理员权限。

## 清理策略

- 扫描和清理流程分离，执行清理前弹出确认。
- 清理时只删除目标根目录下的内容，不删除目标根目录本身。
- 清理入口路径必须通过安全校验：拒绝盘符根、UNC 根、过短路径、通配符路径和不明确路径。
- 目标根目录和递归子项都会跳过 symlink、junction、reparse point。
- 路径拼接或搜索模板超过内部缓冲区时直接跳过，避免对截断路径执行操作。
- 字符串转换失败时会清空目标缓冲区，避免复用旧路径或旧文本。
- 子控件句柄、后台线程退出、日志句柄和 GDI 字体资源都有基础容错处理。
- `聊天数据` 和 `回收站` 默认不勾选，勾选对应大分类后才参与清理。

## 稳定性与安全加固

WinTempViewASM 的清理逻辑围绕“固定目标根目录、先扫描、后清理”的模型实现，并加入了多层边界处理：

- 路径安全校验：清理入口会拒绝盘符根目录、UNC 根目录、过短路径、包含 `*` 或 `?` 的通配符路径，以及无法确认语义的异常路径。
- 根目录保护：清理流程只删除目标根目录下的子项，不删除目标根目录本身，避免把规则入口目录整体移除。
- reparse point 保护：目标根目录和递归子项都会检查 `FILE_ATTRIBUTE_REPARSE_POINT`，遇到 symlink、junction、mount point 等重解析点时跳过。
- 目录属性校验：清理前会重新读取目标属性，目标不存在、不是目录或属性异常时跳过，不进入删除流程。
- 路径长度处理：内部路径缓冲区使用固定边界，子路径拼接或搜索模板超过缓冲区时跳过当前目标或子项，避免对截断路径执行扫描或删除。
- 递归深度限制：扫描和清理递归都有最大深度限制，防止异常目录结构造成过深递归。
- 扫描数量限制：扫描阶段设置最大访问项数，超过限制后标记为截断，避免超大目录让 UI 等待过久。
- 后台线程处理：扫描、预估和清理都在 worker 线程中执行，UI 更新通过 `PostMessageW` 回到窗口线程，降低界面卡死概率。
- 退出同步：窗口关闭时会请求 worker 停止，退出前等待 worker 收尾，减少日志写入、窗口消息和线程句柄之间的竞态。
- 空窗口句柄保护：字体设置、按钮启停、文本更新和复选框初始化等 GUI 操作会检查 HWND，子控件创建失败时不会继续对空句柄发送消息。
- 字符串转换保护：UTF-8 与 UTF-16 转换前会清空目标缓冲区，转换失败时不会复用旧路径或旧 UI 文本。
- 日志容错：启动日志实时写入并刷新到磁盘，用于定位启动、建窗、扫描、清理和 worker 收尾流程中的问题。
- 资源释放：程序退出时释放创建的 GDI 字体对象，线程句柄和日志文件句柄也会在对应生命周期内关闭。
- 大小格式化保护：预计可释放空间格式化时处理极端大值，避免整数乘法或除法异常影响扫描结果输出。
- 删除结果统计：清理阶段统计删除文件数、删除目录数、失败数和跳过数，失败项不会中断整个清理流程。

## 当前目标范围

已内置的目标根目录包括：

- Windows 临时目录、INetCache、WebCache、缩略图、WER、CrashDumps、DirectX/NVIDIA/AMD shader cache、NVIDIA ComputeCache、AMD GLCache、Vulkan/Intel shader cache、DirectX Shader Cache、Delivery Optimization、Windows Update 下载缓存、FontCache、Prefetch、CBS/DISM logs、Panther logs、回收站根目录。
- Chrome、Edge、Firefox、Brave、Opera、Vivaldi、Yandex、Cent、Arc、CocCoc、Waterfox、LibreWolf、QQ 浏览器、搜狗浏览器、360 极速/安全浏览器、Maxthon、2345 浏览器、猎豹浏览器、UC 浏览器缓存，包含部分 Profile 1/Profile 2/Profile 3 缓存、Code/GPUCache 和 Chromium Crashpad/Crash Reports。
- VS Code、Cursor、Windsurf、Trae、JetBrains、Visual Studio、Discord、Teams/Teams classic、Telegram、钉钉、飞书/Lark、WPS、金山 PDF、腾讯文档、Zoom、Skype、LINE、Slack、Postman、Notion、Figma、Obsidian、PowerToys、OneDrive、Office/Outlook、Spotify、GitHub Desktop、Claude、Apifox、Signal、Canva、Typora、Motrix、Everything、ToDesk、向日葵、腾讯柠檬、火绒、360 压缩、搜狗/QQ/百度/讯飞输入法等应用缓存、日志、临时目录和 Crashpad。
- 微信/QQ/QQNT/TIM/QQ 频道/WhatsApp/企业微信/腾讯会议文档和 AppData/LocalCache 数据、缓存、日志、CefCache 和 Crashpad 目录。
- 百度网盘、阿里云盘、夸克网盘、115 网盘、坚果云、迅雷、IDM、qBittorrent、网易云音乐、QQ 音乐、腾讯视频、爱奇艺、优酷、芒果 TV、哔哩哔哩、抖音、PotPlayer、CapCut、剪映、VLC、酷狗、酷我、AIMP 等常用软件数据、缓存、GPUCache、临时目录和日志目录。
- npm、pip、uv、pipx、Rye、NuGet、Gradle、Gradle wrapper/daemon/native、Fabric Loom、ForgeGradle、NeoForge Gradle、Quilt Loom、Architectury Loom、Paperweight、MCreator、Maven、Yarn、pnpm、Cargo/rustup、Poetry、Conda、Hugging Face、Android build/Gradle cache、Go build cache、Go module cache、Docker Desktop/buildx、Bazel、node-gyp、Electron、Playwright、Selenium、PyTorch、pre-commit、vcpkg、Conan、Composer、RubyGems、Dart Pub、.NET HTTP cache、Bun、Deno、Ruff、mypy、ccache/sccache、GitKraken、Insomnia 本地数据。
- Steam shadercache/htmlcache/appcache/depotcache/logs、Epic Games Launcher webcache/logs/crashes、Battle.net cache/logs、EA Desktop cache/logs、Ubisoft Connect cache/logs、Riot Client logs/crashes、GOG Galaxy webcache/logs、Rockstar Games Launcher、FiveM、Xbox Gaming App、WeGame、网易 UU、Roblox、Minecraft logs/cache/crash-reports/webcache、Modrinth、CurseForge、PrismLauncher、MultiMC、ATLauncher、GDLauncher、HoYoPlay。
- Unity cache/shader cache、Unreal DDC/logs、Adobe Media Cache/Peak Files、After Effects Disk Cache、DaVinci Resolve CacheClip/logs、Blender 临时缓存、OBS 日志/crash dumps、HandBrake 日志、NVIDIA 驱动下载器/GFE CefCache。

## 构建

构建依赖为 MinGW-w64，`gcc`、`windres` 和 `mingw32-make` 需位于 `PATH` 中。

日常构建：

```powershell
mingw32-make
```

强制完整重建：

```powershell
mingw32-make -B
```

Release 静态构建：

```powershell
cd src
windres app.rc -O coff -o app.res.o
cd ..
gcc -O2 -s -static -static-libgcc -nostdlib -mwindows "-Wl,-e,WinMainCRTStartup" -o winTempView.exe src/main.S src/app.res.o -luser32 -lgdi32 -lkernel32
```

生成文件：

```text
winTempView.exe
```

## 仓库结构

```text
.
├── Makefile
├── README.md
├── build_command_doc.txt
└── src
    ├── app.manifest
    ├── app.rc
    └── main.S
```

## 贡献

欢迎提交 PR，包括但不限于：

- 扩展新的固定清理规则。
- 改进路径安全校验和文件系统边界处理。
- 优化 Win32 GUI 交互和日志输出。
- 补充虚拟机环境下的清理回归测试记录。
- 改进构建脚本和发布流程。

规则扩展 PR 应说明目标软件、目录用途、默认分类和默认勾选策略。

## 许可证

本项目使用 MIT License，详见 [LICENSE](LICENSE)。
