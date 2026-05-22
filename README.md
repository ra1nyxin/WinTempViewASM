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

已内置的目标根目录包括以下大类。固定规则以缓存、日志、Crashpad、GPUCache、Code Cache、临时目录和可再生成数据为主，部分聊天数据、回收站和大体量本地数据由对应大分类控制。
固定规则会默认覆盖常见系统盘和 D/E/F/G/H/I/J 等常见数据盘路径，不提供额外盘符勾选项；用户只需要勾选 Windows、浏览器、应用、开发工具、聊天数据、游戏平台、媒体工具、回收站这些大分类，对应分类下的 C/D/E/F/G/H/I/J 固定目标会一起参与扫描和清理。

- Windows 系统缓存：用户临时目录、本机临时目录、INetCache、WebCache、缩略图缓存、WER、CrashDumps、DirectX Shader Cache、NVIDIA DXCache/GLCache/ComputeCache、AMD DxCache/GLCache、Vulkan shader cache、Intel shader cache、Delivery Optimization、Windows Update 下载缓存、FontCache、Prefetch、CBS 日志、DISM 日志、Panther 日志、ProgramData WER、NVIDIA 驱动下载器缓存、GeForce Experience CefCache 和回收站根目录。
- 浏览器缓存：Chrome、Edge、Firefox、Brave、Opera、Opera GX、Vivaldi、Yandex、Naver Whale、Cent Browser、Arc、CocCoc、Waterfox、LibreWolf、QQ 浏览器、搜狗浏览器、360 极速浏览器、360 安全浏览器、360 ChromeX、Maxthon、2345 浏览器、猎豹浏览器、UC 浏览器、夸克浏览器、百度浏览器。覆盖默认 Profile 与部分 Profile 1/Profile 2/Profile 3/Profile 4/Profile 5 的 Cache、Code Cache、GPUCache，以及 Brave/Vivaldi 等浏览器的额外 Profile 变体和 Chromium 系浏览器的 Crashpad 或 Crash Reports。额外覆盖 C/D/E/F/G 盘常见便携或独立安装目录中的 Chrome、Edge、QQBrowser、360Chrome、Quark Browser User Data Cache。
- 办公、协作和效率软件：WPS Office、WPS Cloud、金山 PDF、腾讯文档、钉钉、飞书、Lark、Slack、Teams、Teams classic、Zoom、Skype、LINE、Viber、Element、Mattermost、Notion、Figma、Obsidian、Canva、Typora、XMind、蓝湖、Pixso、MasterGo、亿图图示、MindMaster、幕布、Joplin、Zotero、Evernote/印象笔记、Thunderbird、Mailspring、Todoist、Trello、Miro、Linear、网易邮箱大师、有道词典、有道云笔记、有道翻译、滴答清单、百度 Hi、千牛、语雀、PowerToys、OneDrive、Office、Outlook、Everything、Motrix、uTools、Snipaste、PicGo。覆盖应用缓存、WebView 缓存、Code Cache、GPUCache、Crashpad、日志、临时目录、邮件客户端缓存和 Office 文档缓存。额外覆盖 D/E 盘常见安装目录中的 WPS Office、DingTalk、Feishu、TencentDocs 缓存和日志。
- 网盘、同步和下载工具：百度网盘、阿里云盘、夸克网盘、115 网盘、天翼云盘、和彩云、坚果云、Google Drive for desktop、Dropbox、MEGAsync、Box Drive、Syncthing、迅雷、IDM、qBittorrent。覆盖本地 Cache、Local Cache、GPUCache、Code Cache、Crashpad、下载器临时目录、Profiles Cache、Browser Cache、同步工具缓存和日志目录。额外覆盖 D/E/F/G 盘常见安装目录中的 BaiduNetdisk、AliyunDrive、QuarkNetdisk、Thunder、IDM、qBittorrent 缓存、临时目录和日志。
- 通信和聊天数据：微信、QQ、QQNT、TIM、QQ 频道、企业微信、腾讯会议、WhatsApp Desktop、Telegram、Signal。覆盖文档目录中的聊天数据根目录、AppData/LocalCache 数据、Cache、CefCache、GPUCache、Crashpad、XPlugin logs、普通日志和会议客户端缓存。额外覆盖 D/E 盘常见安装目录中的 WeChat、QQ、WeCom 缓存和日志。聊天数据大分类默认不勾选。
- 安全、驱动、远控、代理和设备工具：腾讯柠檬、腾讯电脑管家、360 安全卫士、360 杀毒、火绒、鲁大师、驱动精灵、Driver Booster、联想电脑管家、华为电脑管家、小米助手、华为手机助手、360 压缩、ToDesk、向日葵、RustDesk、Parsec、AnyDesk、TeamViewer、Clash for Windows、Clash Verge、v2rayN、Netch。覆盖日志、缓存、临时目录、下载目录、代理客户端运行日志和崩溃目录。额外覆盖 D 盘常见安装目录中的 ToDesk、SunloginClient、Clash 日志和缓存。
- 输入法和中文常用客户端：搜狗输入法、QQ 输入法、百度输入法、讯飞输入法、Foxmail、阿里旺旺、ClassIn、腾讯课堂、超星、希沃、有道精品课、东方财富、同花顺、腾讯元宝、Kimi、百度 Comate。覆盖缓存、日志、Code Cache、GPUCache 和 Crashpad。
- AI、开发和 API 工具：VS Code、Cursor、Windsurf、Trae、Visual Studio、JetBrains、本地 JetBrains Toolbox、Android Studio、GitHub Desktop、SourceTree、TortoiseGit、Cmder、Postman、Apifox、ApiPost、Insomnia、GitKraken、Claude、ChatGPT、Perplexity、LM Studio、Ollama。覆盖 CachedData、Cache、Code Cache、GPUCache、Crashpad、日志、工具箱缓存、Android Studio 缓存和本地开发工具缓存。额外覆盖 D/E 盘常见便携目录中的 VSCode data user-data Cache、JetBrains system caches、Postman Cache、Apifox Cache。
- 开发语言、包管理器和构建缓存：npm、npm local cache、pip、uv、pipx、Rye、NuGet、Gradle、Gradle wrapper/daemon/native/buildOutputCleanup、Fabric Loom、ForgeGradle、NeoForge Gradle、Quilt Loom、Architectury Loom、Paperweight、MinecraftDev、MCreator、Maven、本地 Maven wrapper 相关目录、Yarn、Yarn Berry、pnpm、Cargo registry/git、rustup downloads/tmp、Poetry、Conda、Hugging Face、Android build/Gradle cache、Go build cache、Go module cache、Docker Desktop、Docker Desktop logs、Docker buildx、Bazel、node-gyp、Electron、Playwright、Selenium、Cypress、Turbo/Turborepo、Vite、Expo、Prisma、PyTorch、pre-commit、vcpkg downloads、Conan、Composer、RubyGems、Dart Pub、.NET HTTP cache、Bun、Deno、Ruff、mypy、ccache、sccache、Ninja build logs、Emscripten cache。额外覆盖 D/E/F/G/H/I/J 盘常见开发目录中的 nodejs cache、node_modules/.cache、Android .gradle 和 Android build-cache。
- 国产开发工具链：微信开发者工具、HBuilderX、DevEco Studio、Taro、uni-app。覆盖 Cache、Code Cache、GPUCache、日志和本地构建缓存目录。
- 游戏平台和启动器：Steam shadercache/htmlcache/appcache/depotcache/logs/dumps、Epic Games Launcher webcache/logs/crashes、Battle.net cache/logs、EA Desktop cache/logs、Ubisoft Connect cache/logs、Riot Client logs/crashes、GOG Galaxy webcache/logs、Rockstar Games Launcher、FiveM、Xbox Gaming App、Xbox App、WeGame、QQ 游戏、网易 UU、网易游戏平台、MuMu 模拟器、雷电模拟器、BlueStacks、Nox、米哈游/HoYoPlay 相关 web cache/logs/GPUCache、Roblox cache/logs、Minecraft logs/cache/crash-reports/webcache、Modrinth、CurseForge、PrismLauncher、MultiMC、ATLauncher、GDLauncher、Lantern、Playnite、Heroic Games Launcher、Overwolf、itch、Paradox Launcher。额外覆盖 D/E/F/G/H/I/J 盘常见游戏安装目录中的 Steam、SteamLibrary、Epic Games Launcher、WeGame、Battle.net、Ubisoft Game Launcher、GOG Galaxy、网易游戏平台、MuMu、LDPlayer 的缓存、日志、shadercache、depotcache、downloading 和 webcache 目录。
- 媒体、设计和创作工具：Spotify、网易云音乐、QQ 音乐、百度音乐、酷狗、酷我、AIMP、foobar2000、mpv、腾讯视频、爱奇艺、优酷、芒果 TV、搜狐视频、PPTV、哔哩哔哩、AcFun、抖音、快手、虎牙、斗鱼、喜马拉雅、荔枝、PotPlayer、VLC、CapCut、剪映、Clipchamp、Filmora、Movavi、Camtasia、Snagit、Adobe Media Cache、Adobe Peak Files、Adobe Creative Cloud、After Effects Disk Cache、DaVinci Resolve CacheClip/logs、Blender temp/cache、OBS logs/crash dumps、HandBrake logs、Audacity SessionData、Shotcut cache、Kdenlive cache、GIMP temp、Inkscape cache、Krita cache、paint.net temp、ShareX logs、ScreenToGif temp、XnViewMP cache。额外覆盖 D/E/F/G/H/I/J 盘常见创作软件数据目录中的 Adobe Common Media Cache、Adobe Peak Files、剪映/Jianying、CapCut 的缓存和日志目录，并覆盖 D/E 盘常见安装目录中的 QQMusic、网易云音乐、酷狗、腾讯视频、爱奇艺、优酷、抖音、虎牙、斗鱼缓存。
- 游戏和图形开发工具：Unity cache、Unity shader cache、Unity Asset Store cache、Unreal DerivedDataCache、Unreal logs、Epic Unreal DDC。覆盖可再生成缓存、shader cache、日志和派生数据缓存。额外覆盖 D/E/F/G/H/I/J 盘常见 Unity cache/ShaderCache 和 UnrealEngine DerivedDataCache/Logs 目录。

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

## 自动发布

仓库内置 GitHub Actions workflow：`.github/workflows/release.yml`。

自动发布触发方式：

- push 到 `main` 分支。
- 在 GitHub Actions 页面手动运行 `Build release` workflow。

发布流程：

- workflow 在 `windows-latest` 上安装或启用 MinGW-w64 GCC。
- 使用 `windres` 编译资源文件。
- 使用静态优化 release 命令编译 `winTempView.exe`。
- 读取已有 GitHub Release，按 `v0.1.x` 自动递增 patch 版本号。
- 创建新的 GitHub Release，并上传 `winTempView.exe` 作为 Release 资产。

项目只使用 `main` 分支发布，不需要本地创建 tag 或推送 tag。

## 仓库结构

```text
.
├── Makefile
├── README.md
├── build_command_doc.txt
├── .github
│   └── workflows
│       └── release.yml
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
