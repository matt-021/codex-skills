---
name: "vhr-troubleshooting"
description: "用于排查 VHR 项目问题。涵盖认证、分页、API 及常见错误模式。"
---

# VHR 问题排查

VHR 开发常见问题及解决方案。

## 认证与权限

### 401 未授权

| 检查项 | 解决方案 |
|--------|----------|
| Token 过期 | 清除存储，重新登录 |
| Token 未发送 | 检查 axios 拦截器 |
| Header 格式错误 | 验证 Authorization 格式 |
| 仅传 query `access_token` | 补充 `Authorization: Bearer <token>`，优先走标准头 |

### 菜单不显示

| 检查项 | 解决方案 |
|--------|----------|
| VUE_APP_SERVICE_ALL | 必须包含 vhr-m01-service |
| menuCode 不匹配 | 路由 meta.menuCode = 后端菜单 ID |
| 用户权限 | 检查用户角色分配 |

### 按钮不显示

| 检查项 | 解决方案 |
|--------|----------|
| 权限码 | 格式：`module:action` |
| 指令使用 | 使用 v-perm 或 useElementAuth |
| 编码拼写错误 | 检查与后端是否完全匹配 |

## 分页问题

### whereItems 不生效

```
原因：未使用 PageUtil.buildPage()
解决：将 Page.of() 替换为 PageUtil.buildPage(dto)
```

### 参数未找到（BindingException）

```
原因：多参数 Mapper，PageParam key 不匹配
解决：检查 @Param 注解，验证拦截器能找到 PageParam
```

### 排序被忽略

```
原因：列名无效或 JSqlParser 解析失败
解决：使用 SQL 输出的列名；复杂 SQL 简化
```

### Count 查询慢

```
原因：SQL 复杂
解决：设置 searchCount=false，或优化 SQL/索引
```

## API 问题

### 404 未找到

| 检查项 | 解决方案 |
|--------|----------|
| 网关配置 | 服务是否注册？ |
| 本地开发 | 检查 VUE_APP_PROXY |
| 路径拼写错误 | 验证 controller mapping |

### CORS 错误

```
原因：缺少 CORS 配置或 origin 错误
解决：检查 WebConfiguration CORS 设置
```

### 网关放行但服务拒绝 / 服务放行但网关拒绝

```
现象：同一 token 在不同入口表现不一致
排查：
1) 网关侧确认是否只认 Authorization 头
2) 服务侧确认是否同时支持 Authorization 和 access_token 参数
3) 前端确认统一从公共 axios 注入 Bearer token
```

### 校验错误

```
原因：缺少 @Validated 或输入无效
解决：添加 @Validated，检查校验注解
```

## 前端问题

### 组件样式异常

```
原因：ui-modules 与 vhr-ui-components 版本不匹配
解决：同步版本，重新构建
```

### 公共组件未生效/找不到

```
原因：ui-modules 子模块未初始化或未更新
解决：执行 module-pull.sh，检查 ui-modules 目录与分支
```

### 弹窗层级问题

```
原因：业务弹窗在组件弹窗下方
解决：在业务弹窗上设置明确的 z-index
```

### VXE 表格不加载

```
原因：API 响应格式不匹配
解决：检查 hook 配置中的 formatResultFn
```

## 后端问题

### 翻译不生效

```
原因：缺少 @Translate 或未调用 TranslateUtil
解决：添加注解，调用 TranslateUtil.objects/page
```

### 数据范围过滤缺失

```
原因：拦截器被绕过或配置错误
解决：检查 DataScopeProperties，验证拦截器是否激活
```

### 事务不回滚

```
原因：异常被捕获但未重新抛出
解决：让异常传播或使用 TransactionAspectSupport
```

## 快速诊断命令

```bash
# 检查服务健康
curl http://gateway/service/actuator/health

# 检查 Redis 连接
redis-cli ping

# 查看最近错误
grep -r "ERROR" logs/ | tail -20
```

## 相关 Skills

- 后端: vhr-be-toolkit, vhr-be-pagination
- 前端: vhr-fe-toolkit, vhr-fe-vxe-table
