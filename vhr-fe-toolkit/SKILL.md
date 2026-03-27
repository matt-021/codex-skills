---
name: "vhr-fe-toolkit"
description: "Use when implementing or reviewing VHR Vue front-end modules, including api client usage, permissions, vxe-table list integration, and project conventions."
---


# VHR 前端工具包（含列表落地要点）

## 快速参考

| 类别 | 关键路径 |
|---|---|
| HTTP 封装 | `%common%/utils/axios.js` |
| API 客户端 | `src/serve/api.js`（自动生成） |
| 表格 Hooks | `%common%/hooks` -> `useVxeTableHooks` |
| 权限 | `%common%/hooks/common`、`v-perm` |
| 组件 | `%common%/components`、`vhr-vxe-table` |

## 路径别名

| 别名 | 指向 |
|---|---|
| `@` | `src` |
| `%common%` | `ui-modules` |
| `_less` | `ui-modules/assets/styles` |
| `_assets` | `ui-modules/assets` |

## 1. 列表页标准接入（msg-log 模式）

```js
import { reactive, ref } from 'vue'
import { useVxeTableHooks } from '%common%/hooks'
import api from '@/serve/api'

const tableRef = ref(null)
const tableHooks = reactive({
  ...useVxeTableHooks(api.serviceRequest.mq.TransMessage.page, {
    tableRef,
    immediate: false,
    extraParams: ref({})
  })
})

tableHooks.limit = 20
tableHooks.filters = []
```

推荐：
- 大数据量列表默认 `immediate: false`
- 列定义独立到 `config.js`
- 交互后通过 hooks 触发查询，避免手写重复分页逻辑

## 2. API 调用规范

```js
import api from '@/serve/api'

const pageRes = await api.serviceRequest.mq.TransMessage.page(pageDto)
await api.serviceRequest.mq.TransMessage.resendMessage({ messageId })
```

禁止：
- 绕过 `src/serve/api.js` 直接 new axios
- 在页面内硬编码网关 URL

## 2.1 国际化文案规范（强制）

- 前端新增按钮、标题、提示语必须写入多语言文件（`src/lang/zhCn|zhTw|en`）
- 模板中通过 `$t('xxx')` 或 `i18n.global.t('xxx')` 取值，禁止硬编码中文
- 代码审查时将“新增文案未入 i18n”判定为至少重要问题；影响主流程时按阻断处理

## 3. 列表列与筛选规范

以 `msg-log/config.js` 为参考：
- `DICT@*`：`FilterSelect + operator: in`
- `TEXT/SRC@PERSON`：`FilterInput + operator: like`
- `DATE`：`FilterDatePicker(datetimerange)`

同时保证：
- `filter: true` 时必须配 `params` + `filterRender`
- `formatter` 做文本兜底（优先 `xxxText`）

## 4. 审查清单（优先检查）

- 是否使用统一 API 客户端
- 列表请求体是否包含 `page/limit/whereItems/orderItems`
- `asc` 是否字符串 `'true'/'false'`
- `in/between` 值是否按 `A,B` / `start,end` 约定
- 是否存在重复列定义（如同字段重复配置）

## 4.1 公共组件复用清单（强制）

- 公共组件来源：`*/ui-modules/components`
- 业务组件来源：`*/ui-modules/business-components`
- 元组件来源：`*/ui-modules/meta-components`
- 公共逻辑来源：`*/ui-modules/hooks`、`*/ui-modules/common`
- 禁止在业务页面重复实现已有通用组件（如顶部栏、弹窗框架、标签栏、加载器）

常用公共组件（参考 `web-base-qiankun/ui-modules/components`）：
- `top-bar`、`navigation`、`tags-bar`
- `dialog-frame`、`popup-container`
- `loading`、`print-dialog`、`privacy-statement`
- `search-item`、`tool-bar`、`table-header-transfer`

## 4.2 登录鉴权链路（前端侧）

- 登录接口：`/vhr-auth-service/auth/login`
- 登录成功后存储：`access_token`、`vhr-admid`
- 请求拦截：从 sessionStorage 读取 `access_token` 并写入 `Authorization: Bearer <token>`
- 登出接口：`/vhr-auth-service/auth/logout`

审查重点：
- 不允许绕过公共 `axios` 封装直接发请求
- 不允许手写网关绝对地址（必须走前缀与环境变量）
- 不允许在控制台/日志打印 token 与完整用户敏感信息

## 4.3 前端命令约定

- 开发：`npm run start`
- 测试构建：`npm run testing`
- 生产构建：`npm run build`
- 规范修复：`npm run lint`
- 安全审计：`npm run check`

## 5. 权限与安全

- 路由 `meta.menuCode` 对齐后端菜单编码
- 按钮用 `v-perm` 或 `useElementAuth`
- 不打印 token/userInfo 等敏感信息

## 6. 相关技能

- 列表深度实践：`vhr-fe-vxe-table`
- 分页后端契约：`vhr-be-pagination`
- 代码审查：`vhr-code-review`
