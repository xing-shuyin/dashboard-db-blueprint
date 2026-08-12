---
name: dashboard-db-blueprint
description: "通用方法论：从网页驾驶舱/大屏项目产出完整数据底座（业务无关，任何行业适用）。① 依次清点每个页面的每个图表（标题/口径卡/JS数据结构/图表类型）② 为每个图表设计所需数据表并输出每页一个md ③ 统筹全站数据表（域分组+ER关联+标准系统表）④ 设计不重复逻辑正确的数据库（事实表+派生视图+受控冗余+统一字典+快照主-明细）⑤ 生成带全量中文表/列注释的PostgreSQL DDL并导入本地PG ⑥ 分域导出好看的ER图（Mermaid PNG+dbdiagram.io DBML+HTML画廊）。Use when: 统计页面图表数据需求/数据表设计/数据库设计/DDL建库/导入PostgreSQL/导出ER图/驾驶舱数据建模/一人一档系统设计."
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

- 落地案例：`references/EXAMPLE.md`（教育领域案例，业务名词仅作示范，方法论通用）
- 脚本：`scripts/extract_charts.py`（页面图表清点）、`import_pg.sh`（建库导入校验）、`render_er.sh`（ER 渲染画廊）
- 模板：`templates/`（页面数据表 / 统筹总表 / 数据库设计 / ER 分域）
