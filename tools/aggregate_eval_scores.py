#!/usr/bin/env python3
"""
遍历 eval run 的全部 score 文件，聚合每题分数，输出:
  1. 终端汇总表（按 weighted_score 降序）
  2. JSON 映射文件 scores_map.json（题目 ↔ 分数 ↔ 是否通过）
"""

import json
import statistics
import sys
from pathlib import Path

# ── 默认路径 ──────────────────────────────────────────────
DEFAULT_RUN = (
    "remote/evals/"
    "2026-03-25_231448_rwkv7-2-9b-g1e-20260312-ctx8192-mlx-6bit-zip"
)
PASS_THRESHOLD = 8.0

def main():
    repo_root = Path(__file__).resolve().parent.parent
    run_dir = repo_root / DEFAULT_RUN
    if len(sys.argv) > 1:
        run_dir = Path(sys.argv[1])

    scores_dir = run_dir / "scores"
    if not scores_dir.is_dir():
        print(f"scores 目录不存在: {scores_dir}")
        sys.exit(1)

    score_files = sorted(scores_dir.glob("*_score.json"))
    if not score_files:
        print("未找到任何 score 文件")
        sys.exit(1)

    results: list[dict] = []
    category_stats: dict[str, list[float]] = {}

    for sf in score_files:
        data = json.loads(sf.read_text("utf-8"))
        idx = data["sample_index"]
        name = data["rendering_name"]
        prompt = data["prompt"]
        cat = data["source_category"]

        ws_list = [a["weighted_score"] for a in data["attempt_evals"]]
        mean_ws = round(statistics.mean(ws_list), 2)
        std_ws = round(statistics.stdev(ws_list), 2) if len(ws_list) > 1 else 0.0
        min_ws = min(ws_list)
        max_ws = max(ws_list)

        # 每维度平均
        dims = ["relevance", "quality", "fluency", "satisfaction"]
        dim_means = {}
        for d in dims:
            vals = [a["scores"][d] for a in data["attempt_evals"]]
            dim_means[d] = round(statistics.mean(vals), 2)

        passed = mean_ws >= PASS_THRESHOLD

        row = {
            "sample_index": idx,
            "rendering_name": name,
            "prompt": prompt,
            "category": cat,
            "attempt_scores": ws_list,
            "mean_score": mean_ws,
            "std_dev": std_ws,
            "min_score": min_ws,
            "max_score": max_ws,
            "dim_means": dim_means,
            "pass": passed,
        }
        results.append(row)
        category_stats.setdefault(cat, []).append(mean_ws)

    # 按均分降序
    results.sort(key=lambda r: r["mean_score"], reverse=True)

    # ── 终端输出 ──────────────────────────────────────────
    total = len(results)
    passed_count = sum(1 for r in results if r["pass"])
    failed_count = total - passed_count
    global_mean = round(statistics.mean([r["mean_score"] for r in results]), 2)

    print(f"\n{'=' * 80}")
    print(f"  Eval Scores 汇总  |  共 {total} 题  |  通过(≥{PASS_THRESHOLD}): {passed_count}  |  未通过: {failed_count}  |  全局均分: {global_mean}")
    print(f"{'=' * 80}\n")

    # 按类别统计
    print(f"{'类别':<16} {'数量':>4} {'均分':>6} {'通过':>4} {'通过率':>7}")
    print("-" * 45)
    for cat in sorted(category_stats.keys()):
        scores = category_stats[cat]
        cat_mean = round(statistics.mean(scores), 2)
        cat_pass = sum(1 for s in scores if s >= PASS_THRESHOLD)
        cat_rate = f"{cat_pass / len(scores) * 100:.0f}%"
        print(f"{cat:<16} {len(scores):>4} {cat_mean:>6} {cat_pass:>4} {cat_rate:>7}")
    print()

    # 分数分布
    brackets = [(9, 10, "9-10 优秀"), (8, 9, "8-9  良好"), (7, 8, "7-8  中等"), (0, 7, "<7   较弱")]
    print("分数分布:")
    for lo, hi, label in brackets:
        count = sum(1 for r in results if lo <= r["mean_score"] < hi or (hi == 10 and r["mean_score"] == 10))
        bar = "█" * (count // 2)
        print(f"  {label}: {count:>4}  {bar}")
    print()

    # Top 10 / Bottom 10
    print("── Top 10 ──")
    for r in results[:10]:
        print(f"  [{r['sample_index']:>3}] {r['mean_score']:.2f} ± {r['std_dev']:.2f}  ({r['category']:<14}) {r['rendering_name']}")

    print("\n── Bottom 10 ──")
    for r in results[-10:]:
        flag = "✗" if not r["pass"] else " "
        print(f"  [{r['sample_index']:>3}] {r['mean_score']:.2f} ± {r['std_dev']:.2f}  ({r['category']:<14}) {r['rendering_name']} {flag}")

    # ── 写 JSON ──────────────────────────────────────────
    out_path = run_dir / "scores_map.json"
    # 去掉 prompt（spec.md 会引用，但 map 本身只做索引）
    export = []
    for r in results:
        export.append({
            "sample_index": r["sample_index"],
            "rendering_name": r["rendering_name"],
            "category": r["category"],
            "attempt_scores": r["attempt_scores"],
            "mean_score": r["mean_score"],
            "std_dev": r["std_dev"],
            "min_score": r["min_score"],
            "max_score": r["max_score"],
            "dim_means": r["dim_means"],
            "pass": r["pass"],
        })

    payload = {
        "run_id": run_dir.name,
        "total": total,
        "pass_threshold": PASS_THRESHOLD,
        "passed": passed_count,
        "failed": failed_count,
        "global_mean": global_mean,
        "category_summary": {
            cat: {
                "count": len(scores),
                "mean": round(statistics.mean(scores), 2),
                "passed": sum(1 for s in scores if s >= PASS_THRESHOLD),
            }
            for cat, scores in sorted(category_stats.items())
        },
        "items": export,
    }
    out_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"\n✔ 映射已写入: {out_path}")


if __name__ == "__main__":
    main()
