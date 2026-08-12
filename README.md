# dashboard-db-blueprint

**从网页驾驶舱/大屏项目 → 一套不重复、逻辑正确的数据库 → 好看的 ER 图**（通用方法论，不绑定任何行业业务）。

## 这是什么

把"一堆 HTML 驾驶舱页面"变成"一套可落库的数据库 + 可视化 ER 图"的 pi-agent skill。6 个阶段：

| 阶段 | 产出 |
|------|------|
| 1 页面图表清点 | 每页图表清单（标题/口径卡/JS 数据结构/图表类型） |
| 2 逐页数据表分析 | `table/<序号>_<页面>.md`（每页一档，逐图表数据表） |
| 3 统筹总表 | 全站数据表索引 + 按域分组清单 + ER 关联 + 标准系统表 |
| 4 数据库设计 | 事实表 + 派生视图 + 受控冗余 + 统一字典（不重复法则） |
| 5 DDL + 导入 PG | 全量中文表/列注释的 PostgreSQL DDL，一键建库导入校验 |
| 6 ER 图导出 | 分域 Mermaid PNG + dbdiagram.io DBML + HTML 画廊 |

## 快速开始

```bash
# 1. 清点页面图表
python3 scripts/extract_charts.py <页面.html> [更多...]

# 2. 按 templates/ 模板写 table/*.md 与 数据库设计.md

# 3. 生成带全量注释的 DDL（db/<系统>_schema.sql）

# 4. 导入本地 PostgreSQL（连接参数可用环境变量覆盖）
./scripts/import_pg.sh db/<系统>_schema.sql

# 5. 分域 ER 图（需 Node.js）
./scripts/render_er.sh db/er
```

## 目录

```
├── SKILL.md                    # skill 主文件（pi-agent 加载）
├── scripts/
│   ├── extract_charts.py       # 页面图表清点（标题/口径卡/JS数据/图表类型）
│   ├── import_pg.sh            # 建库+导入全注释DDL+校验（幂等）
│   └── render_er.sh            # 分域 mermaid→PNG + HTML 画廊
├── templates/                  # 页面数据表/统筹总表/数据库设计/ER分域 模板
└── references/EXAMPLE.md       # 落地案例（教育领域，业务名词仅作示范）
```

## 安装为 pi-agent skill（pi package）

```bash
# 方式一：从 npm registry 安装（推荐）
pi install npm:dashboard-db-blueprint

# 方式二：从 GitHub 安装
pi install git:github.com/xing-shuyin/dashboard-db-blueprint

# 方式三：本地路径（开发调试）
pi install /Volumes/P/project/dashboard-db-blueprint
```

安装后通过 `/skill:dashboard-db-blueprint` 或任务自动匹配加载。发布到 npm：`npm publish`（包名 `dashboard-db-blueprint`，已标记 `pi-package` 关键词，可在 [pi.dev/packages](https://pi.dev/packages) 画廊检索）。

## 关键设计原则（通用）

1. **事实表 + 派生视图分离**：聚合指标一律 `v_*` 视图，不落库（不重复）
2. **受控冗余 ≤3 处**：仅高频分组字段，标注单向同步维护
3. **统一字典**：固定枚举全部进 `sys_dict_item`
4. **快照主-明细**：任意维度集合，历史只追加
5. **部分唯一索引**：同一时刻至多一条"生效中"关系
6. **全注释 DDL**：每表每列中文 COMMENT，可审计可交接

## License

MIT
