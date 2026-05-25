# 🏫 校园网全自动登录与热点助手 (Windows 专版)

![Windows](https://img.shields.io/badge/OS-Windows_10%20%7C%2011-blue)
![PowerShell](https://img.shields.io/badge/Script-PowerShell%20%7C%20VBS-4ca3dd)
![License](https://img.shields.io/badge/License-MIT-green)

这是一个专为 Windows 用户打造的校园网自动化脚本工具。它能够在电脑开机或从**休眠/睡眠唤醒**时，在后台绝对静默地完成校园网的网页认证，并在外网连通后，利用 UI 自动化技术强行突破 Windows 系统的安全限制，为你自动开启"移动热点"。

## ✨ 核心特性

- **🔍 动态 IP 抓取**：自动识别系统当前分配的 `10.x.x.x` 内网 IP，适应校园网 DHCP 动态分配。
- **🛡️ 绕过前端直连**：跳过繁琐的 Web 页面和反调试陷阱，直接向底层接口 (`quickauth.do`) 发送 GET 握手请求。
- **🤖 智能网络嗅探**：自带网络状态探测，确保真实连通外网后再执行后续操作。
- **🔓 突破 API 限制**：采用"物理外挂"级别的 UI 自动化方案，盲敲键盘开启热点，完美绕过微软对后台脚本开启热点的权限封锁。
- **👻 绝对静默运行**：配合 VBS 引导脚本，全程无命令行黑框闪烁，告别打扰。

---

## 📁 文件结构

```
.
├── AutoLogin.ps1   # 核心逻辑脚本
├── RunLogin.vbs    # 静默引导脚本（无黑框）
└── README.md
```

---

## 🛠️ 安装与配置

### 1. 准备脚本文件

克隆或下载本仓库，将所有文件放置在电脑中一个固定的**全英文路径**下，例如：

```
D:\Scripts\NetworkAuto\
```

### 2. 核心脚本 `AutoLogin.ps1`

将以下内容保存为 `AutoLogin.ps1`，并按注释修改你自己的参数：

```powershell
Write-Host "等待网络适配器就绪..."
Start-Sleep -Seconds 5

Write-Host "抓取校园网 IP..."
$myIP = (Get-NetIPAddress | Where-Object {
    $_.AddressFamily -eq 'IPv4' -and $_.IPAddress -like '10.*'
} | Select-Object -First 1).IPAddress

if ($myIP) {
    Write-Host "成功拿到内网 IP: $myIP"

    # ──────────────────────────────────────────────
    # 【必改】将下面 URL 中的账号、密码、MAC、VLAN 换成你自己的
    # 运营商后缀：移动 @yd  联通 @lt  电信 @dx
    # ──────────────────────────────────────────────
    $loginUrl = "http://10.101.2.194:6060/quickauth.do?userid=你的账号@yd&passwd=你的密码&wlanuserip=$myIP&wlanacname=HSD-BRAS-2&mac=你的MAC地址&vlan=你的VLAN值"

    Write-Host "正在发送静默登录请求..."
    Try {
        $response = Invoke-WebRequest -Uri $loginUrl -Method Get -UseBasicParsing
        Write-Host "登录状态: $($response.Content)"
    } Catch {
        Write-Host "请求报错: $_"
    }

    # 智能循环判断外网是否连通（最多等 20 秒）
    Write-Host "正在等待 Windows 识别外部网络，解锁热点开关..."
    $netReady = $false
    for ($i = 0; $i -lt 20; $i++) {
        if (Test-Connection -ComputerName "223.5.5.5" -Count 1 -Quiet -ErrorAction SilentlyContinue) {
            $netReady = $true
            # 外网通了之后，系统还需要几秒钟把灰色开关解禁，此处缓冲 15 秒
            Write-Host "外网已连通！额外缓冲 15 秒等待系统解禁热点按钮..."
            Start-Sleep -Seconds 15
            break
        }
        Start-Sleep -Seconds 1
    }

    if ($netReady) {
        Write-Host "启动 UI 自动化，呼出设置面板..."
        Start-Process "ms-settings:network-mobilehotspot"
        Start-Sleep -Seconds 3

        $wshell = New-Object -ComObject wscript.shell
        $wshell.AppActivate("设置") | Out-Null
        $wshell.AppActivate("Settings") | Out-Null
        Start-Sleep -Milliseconds 500

        Write-Host "发送模拟击键..."
        # ──────────────────────────────────────────────
        # 【可能需要调整】Tab 步数校准说明：
        # 按 Win+R → 输入 ms-settings:network-mobilehotspot → 回车
        # 双手离开鼠标，按 Tab 键，数一数按几次能把焦点移到"移动热点"开关上
        # 将下面的 Tab 发送次数改为你测出来的数字（默认已注释，按需取消）
        # $wshell.SendKeys("{TAB 3}")
        # ──────────────────────────────────────────────

        Start-Sleep -Milliseconds 200
        $wshell.SendKeys(" ")   # 空格键切换热点开关
        Start-Sleep -Seconds 1
        $wshell.SendKeys("%{F4}")  # Alt+F4 无痕关闭设置窗口

        Write-Host "★ 模拟按键执行完毕！★"
    } else {
        Write-Host "网络似乎仍未连通，热点处于死锁状态，放弃按键。"
    }
} else {
    Write-Host "未获取到校园网 IP，请确认已连接校园网 Wi-Fi。"
}

Write-Host "流程结束，5 秒后自动关闭..."
Start-Sleep -Seconds 5
```

### 3. 静默引导脚本 `RunLogin.vbs`

将以下内容保存为 `RunLogin.vbs`，并将路径替换为你实际存放 `.ps1` 文件的**绝对路径**：

```vbscript
Dim objShell
Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File ""D:\你的具体路径\AutoLogin.ps1""", 0, False
Set objShell = Nothing
```

---

## 🚀 部署：设置任务计划（极其重要）

为了让"UI 自动化"按键生效，**脚本必须在你进入桌面后运行**。请使用 Windows 任务计划程序进行如下配置：

1. 按 `Win + S` 搜索并打开**任务计划程序**。
2. 点击右侧**创建任务**，按以下选项配置：

| 选项卡 | 设置项 | 值 |
|--------|--------|----|
| 常规 | 名称 | `CampusAutoNet` |
| 常规 | 运行条件 | 勾选"只在用户登录时运行"+ "使用最高权限运行" |
| 触发器 | 触发方式 | 工作站**解锁**时（针对所有用户） |
| 操作 | 程序 | `wscript.exe` |
| 操作 | 添加参数 | `"D:\你的具体路径\RunLogin.vbs"`（保留双引号） |
| 条件 | 电源 | 取消勾选"只有在交流电源下才启动" |
| 条件 | 网络 | 取消勾选"只有在网络可用时启动" |

3. 保存并输入管理员密码确认。

---

## 💡 常见问题 (FAQ)

**Q：唤醒后校园网连上了，但热点没开，或者设置窗口一闪而过？**

> **A：** 焦点错位导致"吞键"。请测试并校准 `$tabCount` 数值（见脚本注释），或将 `Start-Sleep -Seconds 15` 改得更长（如 20 秒），给卡顿的系统更多缓冲时间。

**Q：运行脚本报红字错误？**

> **A：** 请确保 `AutoLogin.ps1` 的编码格式为**带有 BOM 的 UTF-8**，否则 PowerShell 无法正确解析中文字符和全角引号。在 VS Code 中可通过右下角编码选项切换。

**Q：脚本支持非 `10.x.x.x` 网段的校园网吗？**

> **A：** 支持。修改脚本中抓取 IP 的过滤条件 `$_.IPAddress -like '10.*'`，将其改为你们学校的实际内网 IP 段，例如 `192.168.*` 或 `172.*`。

**Q：为什么用 VBS 而不是直接运行 PS1？**

> **A：** PowerShell 脚本直接触发时会短暂出现黑色命令行窗口。VBS 以 `WindowStyle = 0`（完全隐藏）调起 PowerShell，实现真正的无感后台运行。

---

## 📜 免责声明

本项目仅供学习 PowerShell 自动化与 Windows 系统机制交流使用。请合理使用网络资源，遵守所在学校或机构的网络使用规范。
