---
name: "vhr-be-toolkit"
description: "用于实现或审查 VHR 项目的 Java/后端代码。涵盖分页、权限、异常、国际化、翻译及 vhr-core-starter 工具类。"
---

# VHR 后端工具包

后端开发与审查标准。涵盖 `vhr-core-starter` 工具类、分页、权限、编码规范。

## 核心模块 (vhr-core-starter)

| 模块 | 用途 |
|------|------|
| vhr-core-starter-service | 核心: MyBatis, Redis, Validation, Swagger |
| vhr-core-starter-api | DTOs, VOs, 通用模型 |
| vhr-core-starter-elasticsearch | ES 客户端 |
| vhr-core-starter-mq | 消息队列 |
| vhr-core-starter-xxljob | 定时任务 |

## 认证与网关链路速查

- 登录入口：`vhr-auth-service/auth/login`（`AuthController` -> `AuthServiceImpl` -> `IAuthProvider`）
- 内部登录：`vhr-auth-service/auth/login/inner`（供定时任务/服务内调用）
- 网关鉴权：`vhr-gateway` 的 `VhrAuthHandler` 校验 token、level、菜单权限
- 服务上下文：`AuthenticationTokenFilter` + `TokenUtil` 注入 `VhrUserContext`

后端审查关注：
- 内部调用是否使用 `InnerLoginUtil` 而非伪造 token
- Controller 是否匹配正确权限级别（`LOGIN/PERMISSION/INNER`）
- 不要在日志打印 token、Authorization、完整用户敏感信息

## 启动/测试命令参考

- 单模块测试：`mvn -pl <module> -am test`
- 全量测试：`mvn test`
- 本地启动：`mvn spring-boot:run`

---

## 代码审查清单

### 🔴 阻断项（必须）

#### 安全审查

| 检查项 | 正确模式 | 错误模式 |
|--------|---------|---------|
| 入参模型 | `create(XxxCreateDto dto)` | `create(XxxVo vo)` |
| 权限注解 | `@PermissionCheck(level=PERMISSION, operateIds="...")` | 无注解或仅 `LOGIN` |
| 写操作 | `baseService.save/update/remove` | 直接 Mapper 调用 |
| 硬编码 | 配置文件/常量 | URL/密码在代码中 |

#### 错误消息约束

| 检查项 | 正确模式 | 错误模式 |
|--------|---------|---------|
| code-message.properties | 仅包含服务名-数字编码（如 `svc-10001=...`） | 包含全英文错误提示 |
| valid-message.properties | 包含全英文错误提示（如 `svc-10001=操作成功`） | 仅包含编码无实际文本 |

> **强制约束**：`code-message.properties` 中只能有 `服务名-数字编码` 格式的 key（如 `svc-10001`、`auth-20001`），实际的英文错误提示必须写在 `valid-message.properties` 文件中。

#### 数据权限

| 检查项 | 说明 |
|--------|------|
| 拦截器绕过 | `AdmThreadLocalUtil.addInterceptExclude()` 需要特别审查理由 |
| try/finally | 绕过后必须恢复拦截器 |

### 🟡 重要项（建议）

#### 分页规范

```java
// ✅ 正确
public R<PageResponseVo<XxxVo>> page(@Validated @RequestBody PageParamDto dto) {
    IPage<Xxx> page = service.page(PageUtil.buildPage(dto), wrapper);
    return R.success(PageUtil.build(page));
}

// ❌ 错误
Page.of(page, limit)  // whereItems 不生效
```

#### 注释规范

```java
/**
 * 创建XXX记录
 * @param dto 创建参数
 * @return 创建结果
 */
public R<XxxVo> create(@Validated @RequestBody XxxCreateDto dto) {
```

#### 异常处理

```java
// ✅ 正确
throw new TipsException("svc-10001");  // 带服务前缀
throw new BizException(e);  // 保留原始异常

// ❌ 错误
return R.error("操作失败");  // 不要返回错误字符串
throw new TipsException("21003");  // 缺少服务前缀
```

### 🟢 建议项

- 无 N+1 查询（循环内查询 → 批量查询）
- 循环更新改为批量更新
- 日志不记录敏感数据（token/密码）

---

## 快速参考

### 响应封装

```java
R.success(result)
R.error(code, message)
```

### 分页

```java
public R<PageResponseVo<XxxVo>> page(PageParamDto dto) {
    IPage<Xxx> page = service.page(PageUtil.buildPage(dto), wrapper);
    return R.success(PageUtil.build(page));
}
```

### 用户上下文

```java
VhrUserContext.getVhrUser()
BaseContext.get()
```

### 断言工具

```java
AssertUtil.notBlank(param, "param.required");
AssertUtil.isTrue(condition, "condition.failed");
```

### 缓存

```java
@Autowired CacheManager cacheManager;
@Autowired RedisUtil redisUtil;
```

### 文件下载

```java
DownloadUtil.downloadFile(response, file, fileName);
```

---

## 权限级别

| 级别 | 用途 |
|------|------|
| LOGIN | 已登录用户即可 |
| PERMISSION | 需要特定权限 |
| INNER | 服务间调用 |

```java
@PermissionCheck(level = UserLevelEnum.PERMISSION, operateIds = "module:action")
```

---

## DTO/VO 命名规范

| 类型 | 命名 | 用途 |
|------|------|------|
| 入参 | `*Dto` | QueryDto, CreateDto, UpdateDto |
| 出参 | `*Vo` | XxxVo, XxxDetailVo |
| 实体 | 继承 `ExtendEntity` | 业务实体 |

注解要求：
- `@Tag(name = "模块名")`
- `@Schema(description = "字段说明")`

## 枚举规范

- 新增业务枚举必须实现 `com.ciicsh.core.base.enums.LabelEnum`。
- 枚举项必须提供 `label`（建议配合 `@Getter`、`@AllArgsConstructor`）。
- 如确有技术原因不能实现 `LabelEnum`，需在代码注释中说明理由并在评审中显式确认。

---

## 校验规范

```java
@NotBlank(message = "{name.required}")
@Size(max = 100, message = "{name.length}")
@LangLength(max = 100)  // 多语言字段
private String name;
```

消息定义在 `valid-message.properties`。

---

## 多语言与翻译

| 规则 | 说明 |
|------|------|
| 数据库字段长度 | 原长度 × 4 |
| 实体校验 | `@LangLength` |
| 实体翻译 | `@Translate(dataType, tableId, fieldId)` |

```java
@Translate(dataType = DataTypeEnum.DICT, tableId = "dict_code", fieldId = "item_code")
private String status;

@Translate(dataType = DataTypeEnum.LANG, tableId = "table_name", fieldId = "field_name")
private String description;
```

返回前翻译：
```java
TranslateUtil.objects(list)
TranslateUtil.page(page)
TranslateUtil.detail(obj)
```

---

## 数据权限

拦截器自动处理：
- `DataScopeInterceptor` / `AdmInterceptor` 自动注入 SQL 过滤

⚠️ 绕过拦截器的代码需要特别审查：
```java
try {
    AdmThreadLocalUtil.addInterceptExclude();
    // 业务代码
} finally {
    AdmThreadLocalUtil.removeInterceptExclude();  // 必须恢复
}
```

---

## 树形工具

| 类型 | 用途 | 方法 |
|------|------|------|
| tree_code | 4字符/层级（字典/资源） | `TreeUtil.generateTreeCode` |
| tree_id | ID 用"-"连接（组织/岗位） | `TreeUtil.generateTreeId` |

---

## 可选组件

通过注解启用：
- `@EnableCaptchaConfiguration` - 验证码
- `@EnableFileStorageConfiguration` - 文件存储
- `@EnableMailConfiguration` - 邮件
- `@EnableSmsConfiguration` - 短信

---

## 常见错误

| 错误 | 正确做法 |
|------|---------|
| `Page.of(page, limit)` | `PageUtil.buildPage(dto)` |
| 直接 Mapper 写操作 | 使用 BaseService 方法 |
| 硬编码错误消息 | 使用 `code-message.properties` |
| `BizException` 不传原异常 | `new BizException(e)` |
| 日志记录敏感数据 | 移除 token/密码日志 |
| 无理由绕过拦截器 | 必须有合理说明 + try/finally |

---

## 相关 Skills

- 代码审查: vhr-code-review
- 分页详解: vhr-be-pagination
- 设计: vhr-project-design
- 元数据: vhr-meta-dev
