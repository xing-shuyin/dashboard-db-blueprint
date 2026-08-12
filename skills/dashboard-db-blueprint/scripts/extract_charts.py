#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
extract_charts.py —— 从驾驶舱 HTML 页面提取"图表清点"信息（阶段 1）
用法:
  python3 scripts/extract_charts.py <页面.html> [更多.html ...]
输出:
  1) 页面标题(h1~h6)
  2) data-tip 口径卡 (数据来源/核算方法/设计目的) —— 图表的权威口径
  3) JS 数据结构声明 (const/let/var X = ...) —— 图表消费的数据字段
  4) 图表类型关键字命中
"""
import re
import sys
import html as html_mod

CHART_KWS = [
    ("环图/环形", r"donut|ring|arc|gauge|环形"),
    ("雷达", r"radar|雷达"),
    ("地图", r"map|geo|图钉|点位"),
    ("桑基", r"sankey|桑基"),
    ("气泡", r"bubble|气泡"),
    ("散点", r"scatter|散点"),
    ("热力/热图", r"heat|热力|heatmap"),
    ("力导向", r"force|力导向|graph"),
    ("漏斗", r"funnel|漏斗"),
    ("柱状", r"bar|柱"),
    ("折线/趋势", r"trend|line|时序|走势|趋势"),
    ("堆叠", r"stack|堆叠"),
    ("面积", r"area|面积"),
    ("金字塔", r"金字塔|pyramid"),
]

def extract(path):
    try:
        data = open(path, encoding="utf-8").read()
    except Exception as e:
        print(f"[跳过] {path}: {e}")
        return

    print("=" * 60)
    print(f"页面: {path}  ({len(data)} 字节)")
    print("=" * 60)

    # 1) 标题
    heads = re.findall(r"<h([1-6])[^>]*>([^<]{1,60})</h\1>", data)
    print("\n## 标题结构")
    for lv, t in heads:
        t = t.strip()
        if t and "{" not in t and "$" not in t:
            print("  " * int(lv) + f"h{lv} {t}")

    # 2) 口径卡 (data-tip)
    tips = re.findall(r'data-tip="(.*?)"', data, re.S)
    print(f"\n## 口径卡 data-tip × {len(tips)}")
    for t in tips[:40]:
        t2 = html_mod.unescape(re.sub(r"<[^>]+>", " ", t))
        t2 = re.sub(r"\s+", " ", t2).strip()
        if t2:
            print("  -", t2[:200])

    # 3) JS 数据结构
    print("\n## JS 数据结构")
    decls = re.findall(r"^\s*(?:const|let|var)\s+(\w+)\s*=\s*(\[[^;]{0,150}|[{][^;]{0,250})", data, re.M)
    seen = set()
    for n, v in decls:
        if n in seen:
            continue
        seen.add(n)
        v = re.sub(r"\s+", " ", v)
        print(f"  {n} = {v[:140]}")

    # 4) 图表类型
    hits = [k for k, pat in CHART_KWS if re.search(pat, data, re.I)]
    print(f"\n## 图表类型命中: {hits}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    for f in sys.argv[1:]:
        extract(f)
