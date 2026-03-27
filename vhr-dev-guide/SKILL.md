---
name: "vhr-dev-guide"
description: "VHR 开发统一入口。根据任务类型路由到开发、审查、设计、排查等专业 skill。"
---

# VHR 开发指南

统一入口，根据任务类型路由到对应的专业 skill。

## 前置约束（强制）

- 注释必须详细，所有方法必须有注释。
  - Java 方法必须有 Javadoc。
  - 前端导出函数/组件必须有 JSDoc。
  - 复杂逻辑必须补充行内注释，说明“为什么这样做”。
- 所有文件必须使用 UTF-8 编码，禁止出现中文乱码；提交前需确认中文显示正常。

## 快速路由

| 任务类型 | 使用 Skill |
|---------|-----------|
| 代码审查 / PR 审查 | vhr-code-review |
| Vue/前端开发 | vhr-fe-toolkit |
| Java/后端开发 | vhr-be-toolkit |
| 新功能设计 | vhr-project-design |
| 列表页（vxe-table） | vhr-fe-vxe-table |
| 分页接口 | vhr-be-pagination |
| 元数据/低代码 | vhr-meta-dev |
| 问题排查 | vhr-troubleshooting |
| Git 日报 | vhr-git-daily-report |

## 常见工作流

### 新功能开发

```
1. 设计阶段 → vhr-project-design
2. 后端开发 → vhr-be-toolkit + vhr-be-pagination
3. 前端开发 → vhr-fe-toolkit + vhr-fe-vxe-table
4. 代码审查 → vhr-code-review
```

### 代码审查

```
1. 加载 vhr-code-review 确定审查格式
2. 前端代码 → vhr-fe-toolkit checklist
3. 后端代码 → vhr-be-toolkit checklist
4. 输出审查报告
```

### 问题排查

```
1. vhr-troubleshooting 查找常见问题
2. 对应 toolkit 查看 API/组件详情
```

## 通用规范（所有 Skill 适用）

### 注释规范
- Java: 所有 public 方法必须有 Javadoc
- Vue: 所有导出函数/组件必须有 JSDoc
- 复杂逻辑必须有行内注释说明"为什么"

### 安全规范
- 禁止硬编码 URL、凭据、配置
- 写操作必须有权限校验
- 入参使用 DTO，禁止 VO/Entity 直接入参

### 枚举规范
- 新增业务枚举默认实现 `LabelEnum` 并提供 `label` 字段
- 非 `LabelEnum` 枚举需在代码中写明原因，并在审查结论中记录

### 复用规范
- 优先使用已有组件/工具类
- 创建新的前先确认无现成方案

## 核心模块速查

| 模块 | 位置 | 用途 |
|------|------|------|
| vhr-core-starter-service | 核心 | MyBatis/Redis/Validation |
| vhr-core-starter-api | DTOs | 通用 VO/DTO/Entity |
| ui-modules | 前端 | 公共组件/Hooks |
| vhr-ui-components | 前端 | 业务组件库 |

## 认证链路速查（开发/审查必看）

- 外部登录：前端登录页 -> `/vhr-auth-service/auth/login` -> `AuthController.login` -> `AuthServiceImpl.login` -> `IAuthProvider`（按 `auth_type` 分发）
- 访问鉴权：网关 `VhrAuthHandler` 校验 `Authorization: Bearer <token>`，再按接口 level + 菜单权限放行
- 服务内上下文：`AuthenticationTokenFilter` -> `TokenUtil.getUser` -> `VhrUserContext`
- 内部登录：`InnerLoginUtil.login` -> `InnerLoginFeign` -> `/auth/login/inner`

关键文件：
- `vhr-auth/vhr-auth-service/src/main/java/com/ciicsh/vhr/auth/web/AuthController.java`
- `vhr-auth/vhr-auth-service/src/main/java/com/ciicsh/vhr/auth/service/impl/AuthServiceImpl.java`
- `vhr-gateway/src/main/java/com/ciicsh/vhr/handler/VhrAuthHandler.java`
- `vhr-core-starter/vhr-core-starter-service/src/main/java/com/ciicsh/core/service/security/filter/AuthenticationTokenFilter.java`
- `vhr-core-starter/vhr-core-starter-service/src/main/java/com/ciicsh/core/service/security/utils/InnerLoginUtil.java`

## 前端公共组件速查（ui-modules）

- 公共组件根路径：`*/ui-modules/`
- 参考样本：`vhr-frontend-base/web-base-qiankun/ui-modules/`
- 通用组件目录：`components/`（如 `top-bar`、`dialog-frame`、`loading`、`tags-bar`、`print-dialog`、`privacy-statement`）
- 业务组件目录：`business-components/`（如 `org-tree-select-dialog`）
- 元组件目录：`meta-components/`（如 `basic-list-card`、`meta-button`）
- 配套模块：`common/`、`hooks/`、`directives/`、`serve/`、`router/`、`store/`

开发/审查规则：
- 新功能优先复用 `ui-modules`，禁止重复造轮子
- API 必须走 `ui-modules/serve/axios.js` 和 `src/serve/api.js`
- 涉及鉴权请求必须保证 `Authorization: Bearer` 头可用

## 启动与构建命令速查

前端（各 `*frontend` 基本一致，查看各自 `package.json`）：
- `npm run start`：本地开发
- `npm run testing`：测试环境构建
- `npm run build`：生产构建
- `npm run lint`：前端规范修复
- `npm run check`：依赖安全审计

后端（Maven/Spring Boot 工程）：
- 常见测试：`mvn test`
- 常见启动：`mvn spring-boot:run`
- 按模块执行：`mvn -pl <module> -am test`

## 快速诊断

```bash
# 服务健康检查
curl http://gateway/service/actuator/health

# 查看最近错误
grep -r "ERROR" logs/ | tail -20
```
