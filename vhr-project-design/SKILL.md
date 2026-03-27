---
name: "vhr-project-design"
description: "用于编码前规划新功能/模块。涵盖数据模型、API 设计、权限及设计检查清单。"
---

# VHR 项目设计

VHR 功能设计方法论。编码前输出可执行的设计产物。

## 设计流程

```
需求 → 数据模型 → API 与权限 → 查询设计 → 前端 → 审查
```

## 设计输入

- 用户故事（3-5 个关键流程）
- 关键实体和字段（多语言？字典？文件？）
- 权限需求（菜单编码、按钮权限）
- 列表页需求（过滤、排序、导出、树选择）
- 非功能需求（性能、审计、异步）

## 设计输出

### 1. 数据模型
- 表：主键、索引、约束
- 多语言字段：长度 × 4
- 审计字段：createdBy, createdTime, updatedBy, updatedTime
- 树形结构：tree_code（4字符/层级）或 tree_id（短横线连接）

### 2. API 设计模板

| 项目 | 内容 |
|------|------|
| 端点 | GET/POST /xx/page |
| 权限 | @PermissionCheck(level=..., operateIds=...) |
| 入参 | PageParamDto / XxxCreateDto / XxxUpdateDto |
| 出参 | R<PageResponseVo<XxxVo>> / R<XxxDetailVo> |
| 错误码 | svc-10001=... (在 code-message.properties) |

### 3. 查询设计

**过滤字段模板：**
| 字段 | 列名 | DataType | 操作符 | 多值 | 组件 |
|------|------|----------|--------|------|------|
| 名称 | name | TEXT | like | 否 | FilterInput |
| 类型 | type | DICT@XxxType | in | 是 | FilterSelect |
| 日期 | createTime | DATE | between | 是 | FilterDatePicker |

**排序字段：** 白名单允许的列

### 4. 前端设计

- 路由：meta.menuCode
- 布局：pageLayout-* 容器
- 表格：vhr-vxe-table + vhr-pagination
- 权限：useElementAuth / v-perm

## 关键决策

### 字段类型
| 类型 | 过滤操作符 |
|------|------------|
| INT/FLOAT/DATE | between |
| TEXT/LANG | like |
| DICT@*/BIZ@*/SRC@* | in, like |
| FILE | isnull/notnull |
| BOOLEAN | eq |

### 权限级别
| 级别 | 场景 |
|------|------|
| LOGIN | 任意已登录用户 |
| PERMISSION | 需要特定权限 |
| INNER | 服务内部调用 |

## 相关 Skills

- 后端: vhr-be-toolkit, vhr-be-pagination
- 前端: vhr-fe-toolkit, vhr-fe-vxe-table
- 元数据: vhr-meta-dev
