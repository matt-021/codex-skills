# pan-fetch

`pan-fetch.ps1` 用于半自动处理百度网盘项目下载：

1. 打开分享链接
2. 复制提取码到剪贴板
3. 监听下载目录
4. 下载完成后自动移动到目标目录
5. 对 `zip` 自动解压；若系统安装了 `7z`，也可解压 `7z/rar`

## 示例

```powershell
.\tools\pan-fetch.ps1 `
  -Url "https://pan.baidu.com/s/1NHWTOVNSLkGgnlZA3T2ArQ?pwd=wfzl" `
  -Pwd "wfzl" `
  -Target "."
```

## 常用参数

- `-Target`：下载完成后移动到的目录，默认当前目录
- `-DownloadsDir`：监听的下载目录，默认 `$HOME\Downloads`
- `-TimeoutMinutes`：等待下载完成的超时时间
- `-NoOpenBrowser`：不自动打开浏览器
- `-NoClipboard`：不复制提取码
- `-NoExtract`：不自动解压

## 注意

- 这个脚本不绕过百度网盘网页/客户端流程
- 你仍需要手动完成网页登录、提取码确认、点击下载
- 如果下载目录不是系统默认的 `Downloads`，请显式传 `-DownloadsDir`
