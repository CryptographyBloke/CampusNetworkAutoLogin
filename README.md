# 🏫 校园网全自动登录与热点助手 (Windows 专版)

![Windows](https://img.shields.io/badge/OS-Windows_10%20%7C%2011-blue)
![PowerShell](https://img.shields.io/badge/Script-PowerShell%20%7C%20VBS-4ca3dd)
![License](https://img.shields.io/badge/License-MIT-green)

这是一个专为 Windows 用户打造的校园网自动化脚本工具。它能够在电脑开机或从**休眠/睡眠唤醒**时，在后台绝对静默地完成校园网的网页认证，并在外网连通后，利用 UI 自动化技术强行突破 Windows 系统的安全限制，为你自动开启"移动热点"。

## ✨ 核心特性

* **🔍 动态 IP 抓取**：自动识别系统当前分配的 `10.x.x.x` 内网 IP，适应校园网 DHCP 动态分配。
* **🛡️ 绕过前端直连**：跳过繁琐的 Web 页面和反调试陷阱，直接向底层接口 (`quickauth.do`) 发送 GET 握手请求。
* **🤖 智能网络嗅探**：自带网络状态探测，确保真实连通外网后再执行后续操作。
* **🔓 突破 API 限制**：采用"物理外挂"级别的 UI 自动化方案，盲敲键盘开启热点，完美绕过微软对后台脚本开启热点的权限封锁。
* **👻 绝对静默运行**：配合 VBS 引导脚本，全程无命令行黑框闪烁，告别打扰。

---

## 🛠️ 安装与配置

### 1. 准备脚本文件

克隆或下载本仓库，将以下两个文件放置在电脑中一个固定的全英文路径下（例如 `D:\Scripts\NetworkAuto\`）：

* `AutoLogin.ps1` （核心逻辑）
* `RunLogin.vbs` （静默引导）

### 2. 修改核心参数 (`AutoLogin.ps1`)

右键使用记事本或 IDE 打开 `AutoLogin.ps1`，修改以下信息为你自己的参数：

```powershell
# 1. 替换登录链接中的账号、密码和硬件信息
$loginUrl = "http://10.101.2.194:6060/quickauth.do?userid=你的账号@yd&passwd=你的密码&wlanuserip=$myIP&wlanacname=HSD-BRAS-2&mac=你的MAC地址&vlan=你的VLAN值"

# 2. 【关键】校准你的 Tab 步数
# 测试方法：按 Win+R 运行 ms-settings:network-mobilehotspot
# 双手离开鼠标，按键盘 Tab 键，数一数按几次能把焦点正好移动到"移动热点"的开/关按钮上。
$tabCount = 3  # 将这里的数字替换为你测出来的步数
```

> 注：`@yd` 为中国移动后缀，联通通常为 `@lt`，电信为 `@dx`，请根据实际情况修改。

### 3. 配置 VBS 引导路径

打开 `RunLogin.vbs`，将其中的路径替换为你实际存放 `.ps1` 文件的**绝对路径**：

```vbscript
objShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File ""D:\你的具体路径\AutoLogin.ps1""", 0, False
```

---

## 🚀 部署：设置任务计划（极其重要）

为了让"UI 自动化"按键生效，**脚本必须在你进入桌面后运行**。请使用 Windows 任务计划程序进行如下配置：

1. 按 `Win + S` 搜索并打开**任务计划程序**。
2. 点击右侧**创建任务**，按以下选项配置：
   * **常规**：名称填入 `CampusAutoNet`，勾选**"只在用户登录时运行"**和**"使用最高权限运行"**。
   * **触发器**：新建触发器，选择**"工作站解锁时"**（针对所有用户）。
   * **操作**：新建操作，程序或脚本填 `wscript.exe`，添加参数填 `"D:\你的具体路径\RunLogin.vbs"`（注意保留双引号）。
   * **条件**：取消勾选"只有在交流电源下才启动"和"只有在网络可用时启动"。
3. 保存并输入管理员密码确认。

---

## 💡 常见问题 (FAQ)

**Q：唤醒电脑后，校园网连上了，但是热点没开，或者系统设置弹出来一下就关了？**

> **A：** 这通常是因为焦点错位导致了"吞键"。请检查 `$tabCount` 的数值是否准确。另外，如果你电脑刚唤醒时非常卡顿，可以尝试将脚本中 `Start-Sleep -Seconds 4`（呼出设置面板后的等待时间）改长一些，比如改为 6 秒。

**Q：运行脚本报红字错误？**

> **A：** 请确保 `AutoLogin.ps1` 文件的编码格式为`带有 BOM 的 UTF-8`，否则 PowerShell 可能无法正确解析脚本中的中文字符和双引号。

**Q：脚本支持非 `10.x.x.x` 网段的校园网吗？**

> **A：** 支持，但需要手动修改脚本顶部抓取 IP 的正则表达式 `$_.IPAddress -like '10.*'`，使其匹配你们学校的内网 IP 段（如 `192.168.*` 或 `172.*`）。

---

## 📜 免责声明

本项目仅供学习 PowerShell 自动化与 Windows 系统机制交流使用。请合理使用网络资源，遵守所在学校或机构的网络使用规范。
