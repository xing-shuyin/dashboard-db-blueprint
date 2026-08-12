#!/usr/bin/env bash
# render_er.sh —— 分域 Mermaid ER 图渲染 + 生成画廊（阶段 6）
# 用法: ./scripts/render_er.sh [er目录]  （默认 db/er）
# 依赖: npx @mermaid-js/mermaid-cli（首次运行自动下载 chromium，稍慢）
set -euo pipefail

ER_DIR="${1:-db/er}"
mkdir -p "$ER_DIR"

if ! command -v npx >/dev/null 2>&1; then
  echo "!! 需要 Node.js/npx" >&2; exit 1
fi

echo "==> 渲染 ${ER_DIR}/*.mmd → PNG（白底高清 -w 1500）"
count=0
for f in "$ER_DIR"/*.mmd; do
  [ -e "$f" ] || { echo "    （无 .mmd 文件，跳过）"; break; }
  npx -y @mermaid-js/mermaid-cli -i "$f" -o "${f%.mmd}.png" -b white -w 1500 >/dev/null 2>&1
  echo "    ✓ $(basename "${f%.mmd}").png"
  count=$((count+1))
done
echo "==> 渲染完成 ${count} 张"

# 生成画廊 HTML（内嵌全部 PNG + 图例 + 导出指引）
cat > "$ER_DIR/../ER图.html" <<'HTML'
<!DOCTYPE html><html lang="zh-CN"><head><meta charset="UTF-8">
<title>全站 ER 图</title><style>
body{font-family:"PingFang SC",sans-serif;background:#f5f7fb;color:#1f2d3d;padding:32px 40px}
h1{font-size:22px}.sub{color:#5f7d9c;font-size:13px;margin:4px 0 24px}
.card{background:#fff;border:1px solid #e3e9f2;border-radius:12px;padding:20px 24px;margin-bottom:28px}
.card h2{font-size:16px;margin:0 0 4px}.card .en{color:#8aa0bd;font-size:11px;margin-bottom:14px}
.card img{max-width:100%;height:auto;border:1px solid #edf1f7;border-radius:8px}
.note{font-size:12px;color:#5f7d9c;margin-top:10px;line-height:1.8}code{background:#eef2f8;padding:2px 6px;border-radius:4px}
</style></head><body>
<h1>全站 ER 图</h1><div class="sub">数据库 schema: tc（PostgreSQL）</div>
HTML
for f in "$ER_DIR"/*.png; do
  [ -e "$f" ] || continue
  name=$(basename "${f%.png}")
  echo "<div class='card'><h2>${name}</h2><img src='er/${name}.png'></div>" >> "$ER_DIR/../ER图.html"
done
cat >> "$ER_DIR/../ER图.html" <<'HTML'
<div class="card"><h2>更高清/可编辑导出</h2><div class="note">
① dbdiagram.io：粘贴 <code>db/ER图.dbml</code> → Export PNG/SVG/PDF（全量表，最精美）<br>
② DBeaver / pgModeler 直连数据库自动逆向 ER 图<br>
③ 重渲染：<code>npx @mermaid-js/mermaid-cli -i db/er/&lt;域&gt;.mmd -o out.png -b white -w 2000</code>
</div></div></body></html>
HTML
echo "==> 画廊已生成: $ER_DIR/../ER图.html  (open 即可预览)"
