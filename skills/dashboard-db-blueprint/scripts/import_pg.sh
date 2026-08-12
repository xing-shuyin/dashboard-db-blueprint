#!/usr/bin/env bash
# import_pg.sh —— 建库 + 导入全注释 DDL + 校验（阶段 5）
# 用法: ./scripts/import_pg.sh <schema.sql> [DB_NAME]
# 环境变量: PGHOST(默认localhost) PGUSER(默认postgres) PGPASSWORD(默认12345678)
set -euo pipefail

SCHEMA_SQL="${1:?用法: import_pg.sh <schema.sql> [DB_NAME]}"
DB="${2:-${PGDATABASE:-talent_compass_hebust}}"
PGHOST="${PGHOST:-localhost}"
PGUSER="${PGUSER:-postgres}"
export PGPASSWORD="${PGPASSWORD:-12345678}"

echo "==> 目标数据库: ${DB} @ ${PGHOST} (user=${PGUSER})"

# 幂等重建数据库
psql -h "$PGHOST" -U "$PGUSER" -tAc "SELECT 1 FROM pg_database WHERE datname='${DB}'" | grep -q 1 \
  && psql -h "$PGHOST" -U "$PGUSER" -c "DROP DATABASE IF EXISTS ${DB} WITH (FORCE);" >/dev/null
psql -h "$PGHOST" -U "$PGUSER" -c "CREATE DATABASE ${DB} ENCODING 'UTF8' TEMPLATE template0;" >/dev/null
echo "==> 数据库已重建，导入 DDL ..."

# 导入（ON_ERROR_STOP=1：任一语句失败即终止）
if ! psql -h "$PGHOST" -U "$PGUSER" -d "$DB" -v ON_ERROR_STOP=1 -f "$SCHEMA_SQL" 2> /tmp/pg_import_err.log; then
  echo "!! 导入失败，错误摘要:"; grep -iE 'error|fatal' /tmp/pg_import_err.log | head -10
  exit 1
fi
echo "==> 导入成功"

# 校验
echo "==> 校验:"
psql -h "$PGHOST" -U "$PGUSER" -d "$DB" -c "
SELECT '业务表' AS 类型, COUNT(*) FROM information_schema.tables WHERE table_schema='tc' AND table_type='BASE TABLE'
UNION ALL SELECT '视图', COUNT(*) FROM information_schema.tables WHERE table_schema='tc' AND table_type='VIEW';"
psql -h "$PGHOST" -U "$PGUSER" -d "$DB" -tAc "
SELECT '有注释表='||(SELECT COUNT(*) FROM pg_description d JOIN pg_class c ON c.oid=d.objoid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='tc' AND c.relkind='r' AND d.objsubid=0)
     ||' 有注释列='||(SELECT COUNT(*) FROM pg_attribute a JOIN pg_class c ON c.oid=a.attrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='tc' AND c.relkind='r' AND a.attnum>0 AND NOT a.attisdropped AND (SELECT count(*) FROM pg_description d WHERE d.objoid=a.attrelid AND d.objsubid=a.attnum)>0);"
echo "==> 完成: psql -h $PGHOST -U $PGUSER -d $DB"
