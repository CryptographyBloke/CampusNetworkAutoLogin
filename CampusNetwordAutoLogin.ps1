Write-Host "等待网络适配器就绪..."
Start-Sleep -Seconds 5

Write-Host "抓取校园网 IP..."
$myIP = (Get-NetIPAddress | Where-Object { $_.AddressFamily -eq 'IPv4' -and $_.IPAddress -like '10.*' } | Select-Object -First 1).IPAddress

if ($myIP) {
    Write-Host "成功拿到内网 IP: $myIP"
    
    # 1. 发送认证请求
    $loginUrl = "http://10.101.2.194:6060/quickauth.do?userid=换成自己账号@yd或lt或dx&passwd=自己密码&wlanuserip=$myIP&wlanacname=HSD-BRAS-2&mac=d4:f3:2d:50:ca:e9&vlan=19971038"
    Write-Host "正在发送静默登录请求..."
    Try { 
        $response = Invoke-WebRequest -Uri $loginUrl -Method Get -UseBasicParsing
        Write-Host "登录状态: $($response.Content)"
    } Catch {
        Write-Host "请求报错: $_"
    }

    # 2. 智能循环判断外网是否连通 (最多等 20 秒)
    Write-Host "正在等待 Windows 识别外部网络，解锁热点开关..."
    $netReady = $false
    for ($i = 0; $i -lt 20; $i++) {
        if (Test-Connection -ComputerName "223.5.5.5" -Count 1 -Quiet -ErrorAction SilentlyContinue) {
            $netReady = $true
            # 这里的 6 秒极其关键！外网通了之后，系统还需要几秒钟把灰色开关解禁
            Write-Host "外网已连通！额外缓冲 6 秒等待系统解禁热点按钮..."
            Start-Sleep -Seconds 15
            break
        }
        Start-Sleep -Seconds 1
    }

    # 3. 如果网络就绪，执行物理外挂（模拟按键）
    if ($netReady) {
        Write-Host "启动 UI 自动化，呼出设置面板..."
        
        # 直接利用系统 URI 协议打开“移动热点”页面
        Start-Process "ms-settings:network-mobilehotspot"
        
        # 给设置窗口 3 秒钟的加载时间
        Start-Sleep -Seconds 3 

        # 创建键盘模拟器
        $wshell = New-Object -ComObject wscript.shell
        
        # 尝试激活设置窗口，确保焦点在最上面
        $wshell.AppActivate("设置") | Out-Null
        $wshell.AppActivate("Settings") | Out-Null
        Start-Sleep -Milliseconds 500

        Write-Host "发送模拟击键..."
        # 这里的按键逻辑：通常打开热点页面后，按 1 次 Tab 键能选中开关，按空格键切换状态。
      
        Start-Sleep -Milliseconds 200
        $wshell.SendKeys(" ")  # 发送空格键开启
        
        # 等待 1 秒钟确认开启，然后 Alt+F4 关闭设置窗口，做到“无痕”
        Start-Sleep -Seconds 1
        $wshell.SendKeys("%{F4}") 
        
        Write-Host "★ 模拟按键执行完毕！★"
    } else {
        Write-Host "网络似乎仍未通畅，热点处于死锁状态，放弃按键。"
    }
} else {
    Write-Host "未获取到校园网 IP，请确认已连接校园网 Wi-Fi。"
}

Write-Host "流程结束，5秒后自动关闭..."
Start-Sleep -Seconds 5