---
name: "vhr-git-daily-report"
description: "导出多个项目某作者在时间段内的 Git 提交，并按天汇总生成 Markdown 文档。需要批量生成个人日报/周报或跨仓库统计时调用。"
---

# VHR Git Daily Report

该技能用于在“当前目录下存在多个 Git 项目”的场景中，批量导出某个人在指定时间段内的提交记录，并基于提交内容按天汇总，输出可直接作为日报/周报素材的 Markdown 文档。

## 何时调用

- 一次性统计多个仓库（或一个仓库内多个子仓库）的个人提交
- 需要按天汇总提交内容，用于日报/周报/阶段总结
- 需要把 git log 先导出为结构化数据（JSONL），再做二次分析/加工

## 输出物

- 一键输出：Markdown 文档（项目工时记录格式：按天 + 工时表格，不按项目分组，默认去重）
- 可选输出：JSONL（结构化数据，便于二次分析）

## 一键：直接生成按天汇总 Markdown（推荐）

脚本位置：tools/git_daily_report/run_report.py

### 示例

在仓库根目录执行（root 默认是当前目录）：

PowerShell（推荐）：

```powershell
python tools/git_daily_report/run_report.py `
  --author "张三|zhangsan@company.com" `
  --since "2026-01-01" `
  --until "2026-01-31" `
  --all `
  --no-merges `
  --output "out/git_daily_report_zhangsan_202601.md"
```

最近两周（默认 last-days=14），只要提供 author：

```powershell
python tools/git_daily_report/run_report.py `
  --author "温旭冬" `
  --output "out/git_daily_report_wenxudong_last2w.md"
```

### 关键参数

- --author：git log 的 author 匹配串（支持正则；可写“姓名|邮箱”）
- --since / --until：时间范围；不传时使用 --last-days（默认 14）
- --output：写入 Markdown 文件；不传则仅输出到控制台
- --format：输出格式（默认 timesheet；可选 flat）
- --no-dedup：关闭去重（默认按天对“工作内容”去重）
- --all：可选，统计所有分支
- --no-merges：可选，剔除 merge 提交
- --max-depth：可选，限制扫描深度（默认 6）
- --ignores：可选，额外忽略目录名（逗号分隔）
- --export-jsonl：可选，同时落一份 JSONL（便于二次分析）

## 分步：先导出 JSONL，再汇总 Markdown（可选）

脚本位置：

- tools/git_daily_report/export_git_logs.py
- tools/git_daily_report/daily_summary.py

### 示例

PowerShell（推荐）：

```powershell
python tools/git_daily_report/export_git_logs.py `
  --author "张三|zhangsan@company.com" `
  --since "2026-01-01" `
  --until "2026-01-31" `
  --output "out/git_logs_zhangsan_202601.jsonl" `
  --all `
  --no-merges
```

```powershell
python tools/git_daily_report/daily_summary.py `
  --input "out/git_logs_zhangsan_202601.jsonl" `
  --output "out/git_daily_report_zhangsan_202601.md" `
  --timesheet
```

如需在文档中包含提交 body（较长，适合需要详细素材时）：

```powershell
python tools/git_daily_report/daily_summary.py `
  --input "out/git_logs_zhangsan_202601.jsonl" `
  --output "out/git_daily_report_zhangsan_202601.md" `
  --include-body
```

## 约定与提示

- “多个项目”识别规则：扫描目录树，发现包含 .git 的目录即认为是一个 Git 项目，并停止继续深入该目录
- JSONL 中如出现 type=error 记录，汇总文档末尾会输出“导出/解析错误”便于排查
- 如需要更复杂的归类（按模块/关键字/需求号聚合），建议基于 JSONL 再扩展汇总脚本即可
