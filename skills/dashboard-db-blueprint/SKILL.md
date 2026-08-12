---
name: dashboard-db-blueprint
description: "通用方法论：从网页驾驶舱/大屏项目产出完整数据底座（业务无关，任何行业适用）。① 依次清点每个页面的每个图表（标题/口径卡/JS数据结构/图表类型）② 为每个图表设计所需数据表并输出每页一个md ③ 统筹全站数据表（域分组+ER关联+标准系统表）④ 设计不重复逻辑正确的数据库（事实表+派生视图+受控冗余+统一字典+快照主-明细）⑤ 生成带全量中文表/列注释的PostgreSQL DDL并导入本地PG ⑥ 分域导出好看的ER图（Mermaid PNG+dbdiagram.io DBML+HTML画廊）。Use when: 统计页面图表数据需求/数据表设计/数据库设计/DDL建库/导入PostgreSQL/导出ER图/驾驶舱数据建模/一人一档系统设计."
argument-hint: "project directory containing dashboard HTML pages"
license: MIT
metadata:
  version: "2.1.0"
  note: "方法论通用，示例中的业务名词(教师/结对等)仅为某一项目落地案例，不构成 skill 约束"
---

# Dashboard → Data Blueprint → Database → ER Diagram（通用版）

把"一堆 HTML 驾驶舱页面"变成"一套可落库的数据库 + 好看的 ER 图"。流程 6 个阶段，**方法论与业务无关**：页面、图表、数据表、字段全部按使用者项目实际清点设计，本 skill 只规定"怎么数、怎么归类、怎么建表、怎么出图"。

> 参考实现：`references/EXAMPLE.tpl`（教育领域"人才罗盘"项目落地案例，含 table/ 30 页文档 + 64 表 DDL + 9 张分域 ER 图，业务名词仅作示范）。

## 何时使用

- 项目里有多个驾驶舱/大屏/工作台 HTML 页面，需统计"每个图表需要什么数据表"
- 需要为页面体系设计一套不重复、逻辑正确的数据库并导入 PostgreSQL
- 需要导出可用于汇报的 ER 图

## 阶段 0 · 准备与参数

```bash
cd <项目目录>
mkdir -p table db db/er
# PG 连接（环境变量可覆盖）：PGHOST PGUSER PGDATABASE PGPASSWORD（默认 localhost/postgres/<库名>/12345678）
```

清点页面：根目录 `*.html` + 子目录页面 + 报告导出页；跳过登录页、公共导航；同内容副本（暗色版/备份）在文档中注明"同构副本"不单独成文。**页面即业务清单**——一个页面 = 一个 md 文档。

## 阶段 1 · 页面图表清点

```bash
python3 scripts/extract_charts.py <页面.html> [更多页面.html ...]
```

脚本输出：h1~h6 标题、`data-tip` 口径卡（数据来源/核算方法/设计目的——页面内置口径，优先引用）、`const/let/var X = ...` 数据结构（图表消费字段）、图表类型关键字（环图/雷达/桑基/地图/力导向/热力/气泡/漏斗/柱线/堆叠）。

## 阶段 2 · 逐页数据表分析 → `table/<序号>_<页面>.md`

模板：`templates/页面数据表模板.tpl`。每页必含：
- 页面概览（源文件/端侧/定位/统计口径）
- 图表清单总览表（# | 图表 | 类型 | 所需数据表）
- 逐图小节：功能与口径 / 所需数据表字段表（字段|类型|说明|来源系统）/ 依赖关联表
- 页面所需数据表汇总（新增/复用）

**表命名规范（通用）**：`{域前缀}_{实体/事件}`，如 `base_*` 主数据、`{域}_*` 事实表、`v_*` 派生视图、`sys_*` 系统表。主键统一 `{实体}_id`。

## 阶段 3 · 统筹总表 → `table/00_数据表统筹总表.md`

模板：`templates/统筹总表模板.tpl`。含：页面→数据表索引、按业务域分组的全站表清单、ER 核心链路（ASCII）、标准系统表、口径统一说明。**统一命名**：同一概念全站一张表，禁止"一图一表"。

## 阶段 4 · 数据库设计 → `数据库设计.md`

模板：`templates/数据库设计模板.tpl`。四条"不重复"法则（与业务无关，任何领域通用）：
1. **事实表**：来源系统的原始业务记录，只追加（append-only）
2. **派生视图**：所有趋势/占比/指数/覆盖率一律 `v_*` 视图，不落聚合表
3. **受控冗余 ≤3 处**：仅高频分组字段，标注"由事实表单向同步维护"
4. **统一字典**：固定枚举全部进 `sys_dict_item`

逻辑正确要点：一实一档一码（业务主键全站唯一）、多段历史关系 + 部分唯一索引（同一时刻至多一条"生效中"）、快照主-明细（任意维度集合）、时间窗口一律由日期字段推导、FK 建表顺序（先被引用表）、事件表禁 UPDATE/DELETE。

## 阶段 5 · 生成 DDL 并导入 PostgreSQL

```bash
./scripts/import_pg.sh db/<系统>_schema.sql   # 建库 + 导入 + 校验（幂等重建 schema）
```

要求：
- 每个表/列都写 `COMMENT ON TABLE/COLUMN`（中文，全量）——"带注释的 DDL"是交付硬指标
- 幂等：`DROP SCHEMA IF EXISTS <schema> CASCADE; CREATE SCHEMA <schema>; SET search_path TO <schema>;`
- 种子数据：字典、组织机构、角色、系统参数（权重/阈值）、菜单
- 少量示例数据供视图/联查验证

导入后必做校验（数量 + 注释覆盖率 + 抽查视图出数）：
```sql
SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='<schema>' AND table_type='BASE TABLE';
SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='<schema>' AND table_type='VIEW';
SELECT * FROM <schema>.v_<核心聚合视图> ...;  -- 验证一人/一实体全景穿透视图出数
```

## 阶段 6 · 导出好看的 ER 图 → `db/`

```bash
./scripts/render_er.sh db/er   # 分域 .mmd → PNG + 生成 ER图.html 画廊（依赖 npx mermaid-cli）
```

要点（实战结论）：
- **不要**把全部 60+ 张表画进一张 Mermaid 图——erDiagram 只能单行排布（星型拓扑全挤一行，很难看）
- **按业务域分图**，每图 ≤10 张表；星型拓扑（一中心多叶子）再拆小图（如成长域拆 2A/2B/2C）
- 每表列字段：`类型 字段名 PK/FK` + 简短注释；关系符 `||--o{` 一对多 / `||--o|` 一对一可选
- 渲染参数：`-b white -w 1500`（白底高清）
- 同时产出 `db/ER图.dbml`（dbdiagram.io DSL，全量表）→ 粘贴 dbdiagram.io 一键导出 PNG/SVG/PDF（最精美）
- 最后生成 `db/ER图.html` 画廊（内嵌全部分域 PNG + 图例 + 导出指引），`open db/ER图.html`

## 交付清单

```
table/00_数据表统筹总表.md       # 统筹：索引 + 全站表清单 + ER + 标准系统表
table/01~NN_<页面>.md           # 每页一档，逐图表数据表
数据库设计.md                     # 设计原则 + 表清单 + 视图 + 索引 + 同步策略
db/<系统>_schema.sql            # 全注释 DDL + 种子数据（可重复导入）
db/ER图.html + db/er/*.png      # 分域 ER 图画廊
db/ER图.dbml                    # dbdiagram.io 全量表（在线高清导出）
```

## 参考

- 落地案例：`references/EXAMPLE.tpl`（教育领域案例，业务名词仅作示范，方法论通用）
- 脚本：`scripts/extract_charts.py`（页面图表清点）、`import_pg.sh`（建库导入校验）、`render_er.sh`（ER 渲染画廊）
- 模板：`templates/`（页面数据表 / 统筹总表 / 数据库设计 / ER 分域，`.tpl` 后缀避免被 pi 误收集为 skill）
