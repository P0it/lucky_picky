param(
  [string]$Out = "C:\GitHub\ooloo\build\web-shot.png",
  [int]$Width = 430,
  [int]$Height = 932,
  [int]$ClickX = -1,
  [int]$ClickY = -1
)
# Screenshot the running `flutter run -d chrome` app via Chrome DevTools Protocol.
# Window capture does not work for the flutter_tools Chrome device, so drive it over CDP.
$port = (Get-CimInstance Win32_Process -Filter "Name='chrome.exe'" |
  Where-Object { $_.CommandLine -match 'flutter_tools_chrome_device' -and $_.CommandLine -notmatch '--type=' } |
  ForEach-Object { [regex]::Match($_.CommandLine,'remote-debugging-port=(\d+)').Groups[1].Value } |
  Select-Object -First 1)
if (-not $port) { throw "flutter_tools Chrome device not running" }

$p = (Invoke-RestMethod "http://127.0.0.1:$port/json/list") |
  Where-Object { $_.type -eq 'page' -and $_.url -like '*localhost:*' } | Select-Object -First 1
if (-not $p) { throw "no app page found on CDP port $port" }

$ws = New-Object System.Net.WebSockets.ClientWebSocket
$ct = [Threading.CancellationToken]::None
$ws.ConnectAsync([Uri]$p.webSocketDebuggerUrl, $ct).Wait()

function Send($o) {
  $b = [Text.Encoding]::UTF8.GetBytes(($o | ConvertTo-Json -Depth 10 -Compress))
  $ws.SendAsync([ArraySegment[byte]]::new($b), [Net.WebSockets.WebSocketMessageType]::Text, $true, $ct).Wait()
}
function RecvId($id) {
  $buf = New-Object byte[] 131072
  for ($k = 0; $k -lt 1000; $k++) {
    $ms = New-Object IO.MemoryStream
    do {
      $r = $ws.ReceiveAsync([ArraySegment[byte]]::new($buf), $ct); $r.Wait()
      $ms.Write($buf, 0, $r.Result.Count)
    } while (-not $r.Result.EndOfMessage)
    $j = [Text.Encoding]::UTF8.GetString($ms.ToArray()) | ConvertFrom-Json
    if ($j.id -eq $id) { return $j }
  }
}

$i = 0
Send @{ id = ++$i; method = 'Emulation.setDeviceMetricsOverride'; params = @{ width = $Width; height = $Height; deviceScaleFactor = 2; mobile = $true } }
RecvId $i | Out-Null
Start-Sleep -Seconds 2

if ($ClickX -ge 0) {
  foreach ($t in 'mousePressed', 'mouseReleased') {
    Send @{ id = ++$i; method = 'Input.dispatchMouseEvent'; params = @{ type = $t; x = $ClickX; y = $ClickY; button = 'left'; clickCount = 1 } }
    RecvId $i | Out-Null
  }
  Start-Sleep -Seconds 3
}

Send @{ id = ++$i; method = 'Page.captureScreenshot'; params = @{ format = 'png' } }
$res = RecvId $i
[IO.File]::WriteAllBytes($Out, [Convert]::FromBase64String($res.result.data))

Send @{ id = ++$i; method = 'Emulation.clearDeviceMetricsOverride'; params = @{} }
RecvId $i | Out-Null
$ws.Dispose()
"saved $Out ($((Get-Item $Out).Length) bytes)"
