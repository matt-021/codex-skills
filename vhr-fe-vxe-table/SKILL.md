---
name: "vhr-fe-vxe-table"
description: "Use when implementing or reviewing VHR front-end list pages with vxe-table and useVxeTableHooks, especially filter/pagination/sort/query payload alignment."
---


# VHR vxe-table 列表实践（按 msg-log 重梳理）

基于页面：`vhr-paas-res-frontend/src/pages/meta-data-config/msg-log`

适用目标：
- 新建一个标准列表页（筛选 + 分页 + 排序 + 行操作）
- 审查列表请求参数是否符合后端分页模型
- 复用 `msg-log` 的列筛选与展示模式

## 1. 最小列表骨架（资源示例）

```vue
<template>
  <vhr-vxe-table
    ref="tableRef"
    showPagination
    show-overflow
    :data="tableHooks.list"
    :hooks="tableHooks"
  >
    <vhr-vxe-column
      v-for="column in columns"
      :field="column.field"
      :title="column.label"
      :width="column.width"
      :filter="column.filter"
      :filter-render="column.filterRender"
      :params="column.params"
      :formatter="column.formatter || ''"
      align="center"
    />
  </vhr-vxe-table>
</template>

<script setup>
import { reactive, ref } from 'vue'
import { useVxeTableHooks } from '%common%/hooks'
import api from '@/serve/api'

const tableRef = ref(null)
const options = {
  tableRef,
  immediate: false,
  extraParams: ref({})
}

const tableHooks = reactive({
  ...useVxeTableHooks(api.serviceRequest.mq.TransMessage.page, options)
})

tableHooks.limit = 20
tableHooks.filters = []
</script>
```

关键点：
- `tableRef` 必传给 hooks 的 `options`
- `immediate: false` 用于避免页面首开即无条件查询
- 列定义统一放 `config.js`，组件只负责渲染与交互

## 2. 列筛选配置（msg-log 资源示例）

```js
export const columns = [
  {
    label: '消息类型',
    field: 'messageType',
    filter: true,
    params: { dataType: 'DICT@TransMessageType', operator: 'in' },
    filterRender: { name: 'FilterSelect' }
  },
  {
    label: '消息状态',
    field: 'messageStatus',
    filter: true,
    params: { dataType: 'DICT@TransMessageStatus', operator: 'in' },
    filterRender: { name: 'FilterSelect' }
  },
  {
    label: '创建时间',
    field: 'createTime',
    filter: true,
    params: { dataType: 'DATE' },
    filterRender: {
      name: 'FilterDatePicker',
      props: {
        type: 'datetimerange',
        valueFormat: 'YYYY-MM-DD HH:mm:ss',
        format: 'YYYY-MM-DD HH:mm:ss'
      }
    }
  },
  {
    label: '创建人',
    field: 'createBy',
    filter: true,
    params: { dataType: 'SRC@PERSON', operator: 'like' },
    filterRender: { name: 'FilterInput' }
  }
]
```

映射规则：
- 字典型：`DICT@xxx + FilterSelect + operator: in`
- 人员/文本：`SRC@PERSON/TEXT + FilterInput + operator: like`
- 时间区间：`DATE + FilterDatePicker(datetimerange)`

## 3. 请求体对齐（重点）

列表请求需对齐后端分页模型（由 `useVxeTableHooks` 组装）：

```json
{
  "page": 1,
  "limit": 20,
  "orderItems": [{ "column": "createTime", "asc": "false" }],
  "queryItems": {},
  "whereItems": [
    {
      "column": "messageStatus",
      "operator": "in",
      "value": "SUCCESS,FAILED",
      "dataType": "DICT@TransMessageStatus"
    }
  ]
}
```

注意：
- 多值 `in` 走逗号拼接字符串
- 时间区间值通常为 `"start,end"`（由筛选器值转换）
- `asc` 是字符串 `'true'/'false'`，不是布尔值

## 4. 列展示与行操作实践

### 4.1 文本兜底显示
- 优先展示 `xxxText`
- 无文本时回落到原始字段值

### 4.2 操作列
- `重试`：状态为 `SUCCESS` 时禁用
- `请求/结果/错误`：统一抽屉查看 JSON，使用格式化函数容错

## 5. 常见问题清单（Review 用）

- `filterRender.name` 与 `params.dataType` 不匹配
- 配置了 `filter: true` 但缺少 `params` 或 `filterRender`
- `id` 等精确字段误用 `like`（应按业务改 `in` 或精确比较）
- 首屏慢：忘记按需设置 `immediate: false`
- 列重复：`config.js` 中出现同字段重复定义（如 `payload`）

补充审查：
- 列表页必须复用 `ui-modules` 公共 hooks/组件，避免自建重复表格基座
- 请求必须走公共 axios 拦截器，确保自动注入 `Authorization: Bearer <token>`
- 若列表涉及权限按钮，需配合 `v-perm` 或统一权限 hooks

## 6. 本页参考文件

- `vhr-paas/vhr-paas-res/vhr-paas-res-frontend/src/pages/meta-data-config/msg-log/index.vue`
- `vhr-paas/vhr-paas-res/vhr-paas-res-frontend/src/pages/meta-data-config/msg-log/config.js`
