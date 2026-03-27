---
name: "vhr-be-pagination"
description: "Use when implementing or troubleshooting VHR PageParamDto pagination APIs, especially whereItems/orderItems parsing and front-end list contract alignment."
---


# VHR 后端分页（按 msg-log 对齐）

适用场景：
- 新增分页接口（`PageParamDto` 入参）
- 排查前端列表“有筛选但后端不生效”问题
- 对齐 `useVxeTableHooks` 生成的请求体

## 1. 标准 Controller 模式

```java
@PostMapping("/page")
public R<PageResponseVo<TransMessageVo>> page(@Validated @RequestBody PageParamDto dto) {
    IPage<TransMessage> page = transMessageService.page(PageUtil.buildPage(dto), wrapper);
    return R.success(PageUtil.build(page));
}
```

约束：
- 必须使用 `@RequestBody PageParamDto`
- 必须走 `PageUtil.buildPage(dto)` / `PageUtil.build(...)`
- 不要自行拼 `Page.of(page, limit)` 绕开统一逻辑

## 2. 与前端列表契约（msg-log 资源示例）

`msg-log` 页面调用：
- 接口：`api.serviceRequest.mq.TransMessage.page`
- URL：`POST /trans-message/page`
- 入参：`PageParamDto`

请求体示例：

```json
{
  "page": 1,
  "limit": 20,
  "orderItems": [{ "column": "createTime", "asc": "false" }],
  "queryItems": {},
  "whereItems": [
    {
      "column": "messageType",
      "operator": "in",
      "value": "SMS,EMAIL",
      "dataType": "DICT@TransMessageType"
    },
    {
      "column": "createBy",
      "operator": "like",
      "value": "张三",
      "dataType": "SRC@PERSON"
    },
    {
      "column": "createTime",
      "operator": "between",
      "value": "2026-02-01 00:00:00,2026-02-15 23:59:59",
      "dataType": "DATE"
    }
  ]
}
```

## 3. whereItems / orderItems 规则

### 3.1 WhereItem

```json
{
  "column": "messageStatus",
  "operator": "in",
  "value": "SUCCESS,FAILED",
  "dataType": "DICT@TransMessageStatus"
}
```

| operator | value 格式 |
|---|---|
| `eq` | 单值 |
| `like` | 单值 |
| `in` | `A,B,C`（逗号拼接） |
| `between` | `start,end` |
| `isnull/notnull` | 通常忽略 value |

### 3.2 OrderItem

```json
{ "column": "createTime", "asc": "false" }
```

注意：`asc` 为字符串 `'true'/'false'`。

## 4. 拦截器侧关键点

统一分页拦截器负责：
- 识别 `PageParam`
- 拼接 `whereItems` 条件
- 追加 `orderItems` 排序
- 生成 count 与分页 SQL

如果筛选不生效，优先核查：
- `column` 是否和 SQL 输出列一致
- `operator` 与 `value` 格式是否匹配
- Mapper 多参数场景下 `PageParam` 是否被正确识别

## 5. 联调排查清单

- 前端是否真的传了 `whereItems/orderItems`
- 后端 Controller 是否 `@RequestBody PageParamDto`
- 排序列是否可映射到查询 SQL 别名
- `in/between` 是否按字符串约定传值
- 是否存在前端字段名与后端列名不一致

## 6. 参考文件

- `vhr-paas/vhr-paas-res/vhr-paas-res-frontend/src/pages/meta-data-config/msg-log/index.vue`
- `vhr-paas/vhr-paas-res/vhr-paas-res-frontend/src/serve/api.js`
