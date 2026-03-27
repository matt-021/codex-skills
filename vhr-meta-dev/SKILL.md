---
name: "vhr-meta-dev"
description: "用于低代码/元数据开发。涵盖 DataType、控件、过滤器、实体配置及元数据模板导入。"
---

# VHR 元数据开发

VHR 低代码/元数据功能指南。涵盖字段类型、控件映射、实体配置。

## DataType 分类

| 类型 | 数据库存储 | 过滤器 | 示例 |
|------|------------|--------|------|
| TEXT | VARCHAR | like | 名称, 编码 |
| INT | INT/INTEGER | between | 数量, 年龄 |
| FLOAT | DECIMAL | between | 金额, 比率 |
| DATE | DATE/DATETIME | between | 创建时间 |
| BOOLEAN | TINYINT | eq | 是否启用 |
| LANG | VARCHAR(4x) | like | 多语言文本 |
| DICT@* | VARCHAR | in, like | DICT@Status |
| BIZ@* | VARCHAR | in, like | BIZ@Employee |
| SRC@* | VARCHAR | in, like | SRC@Person |
| FILE | VARCHAR | isnull/notnull | 附件 |

## 控件编码映射

| 控件 | 编码 | DataType |
|------|------|----------|
| 文本输入框 | input | TEXT |
| 整数输入框 | inputIntNum | INT |
| 小数输入框 | inputFloatNum | FLOAT |
| 多行文本 | textarea | TEXT |
| 开关 | switch | BOOLEAN |
| 月份选择器 | monthpicker | DATE (6位) |
| 日期选择器 | datepicker | DATE (8位) |
| 日期时间选择器 | datetimepicker | DATE |
| 树形下拉 | treeDropdown | DICT@*/BIZ@* |
| 列表下拉 | listDropdown | DICT@*/BIZ@* |
| 树形弹窗 | treeDialog | BIZ@*/SRC@* |
| 列表弹窗 | listDialog | BIZ@*/SRC@* |
| 多语言输入框 | langInput | LANG |
| 多语言文本域 | langTextarea | LANG |
| 富文本 | editor | TEXT |
| 文件上传 | file | FILE |
| 图片上传 | image | FILE |

## 实体注解

```java
@Translate(dataType = DataTypeEnum.DICT, tableId = "dict_code", fieldId = "item_code")
private String status;

@Translate(dataType = DataTypeEnum.LANG, tableId = "table_name", fieldId = "field_name")
private String description;

@Translate(dataType = DataTypeEnum.BIZ, tableId = "biz_entity", fieldId = "id")
private String employeeId;
```

## 多语言 V2 规则

1. 数据库字段长度 = 原长度 × 4
2. 实体字段名 = snake_case 字段转 camelCase
3. 校验：使用 `@LangLength`
4. 翻译：`@Translate(dataType = LANG, tableId, fieldId)`

## 过滤器配置

| DataType | 默认操作符 | 渲染器 |
|----------|------------|--------|
| INT/FLOAT/DATE | between | FilterRangeNumber / FilterDatePicker |
| TEXT/LANG | like | FilterInput |
| DICT@*/BIZ@*/SRC@* | in | FilterSelect / FilterTree |
| BOOLEAN | eq | FilterSelect |
| FILE | isnull | FilterSelect |

## 实体 ExtendEntity

业务实体应继承 `ExtendEntity`：
- 动态字段支持
- 多语言处理
- 审计字段

---

## 元数据模板导入

> 业务实体 = 元表(MetaTable)，业务字段 = 元字段(MetaField)

### Excel 模板

文件位置: `业务实体字段/业务实体业务字段模板.xlsx`

### Sheet 0: 元表定义（MetaTable）

| 字段 | 说明 | 必填 |
|------|------|------|
| Object 对象名称 | 业务对象名称 | 是 |
| ObjectCode 对象编码 | 业务对象编码 | 是 |
| 中文 | 元表中文名称 | 是 |
| 繁体 | 元表繁体名称 | - |
| 英文 | 元表英文名称 | - |
| Type 类型 | 记录类型 | - |
| Source 属性 | 属性（SYS/CUSTOM） | - |
| Tree 是否树形 | 是否树形结构 | - |
| Alias | 元表别名/ID | 是 |
| 是否为主实体 | 主元表标识 | - |
| 与主实体的关系 | 关联关系 | - |
| 描述 | 元表描述 | - |
| 父主实体 | 父元表 | - |
| StandardCode 国标编码 | 国标编码 | - |

### Sheet 1: 元字段定义（MetaField）

| 字段 | 说明 | 必填 |
|------|------|------|
| 业务对象编码 | 所属业务对象编码 | 是 |
| 实体名称 | 所属元表名称 | 是 |
| 实体编码 | 所属元表编码 | 是 |
| 字段名 | 字段名（英文） | 是 |
| 字段中文名称 | 元字段中文名 | 是 |
| 字段繁体名称 | 元字段繁体名 | - |
| 字段英文名称 | 元字段英文名 | - |
| DataType 字段类型 | 见上文 DataType 分类 | 是 |
| Comment 描述 | 元字段描述 | - |
| FieldSource 字段属性 | 字段属性 | - |
| 是否必填 | 是否必填 | - |
| 数据类型 | 数据类型 | - |
| 数据类型的值 | 类型的值 | - |
| 长度限制 | 字段长度 | - |
| StandardCode 国标编码 | 国标编码 | - |
| MultiSelect 单选多选 | 选择类型 | - |
| 默认值 | 默认值 | - |
| 获取数据接口 | 数据接口 | - |
| 备注 | 备注 | - |

### 导入接口

```http
POST /importSelf/upload
Content-Type: multipart/form-data
```

- Sheet 0: 元表定义 (MetaTable)
- Sheet 1: 元字段定义 (MetaField)

## 相关 Skills

- 设计: vhr-project-design
- 前端表格: vhr-fe-vxe-table
- 后端工具: vhr-be-toolkit
