# Fable5Skills — Fable Thinking 技能庫

把 Fable 5（distinguished-engineer 等級模型）的工作思考方法萃取成 **15 個不綁定任何專案的技能**，讓中階工程師與較小的模型（Sonnet 級）在**任何專案**都能以相同紀律進行除錯、擴充、驗證與研究。

> A project-agnostic skill library that extracts Fable-class working methodology into 15 portable skills, so mid-level engineers and Sonnet-class models can debug, extend, validate, and research at the same standard — in any project.

## 這個庫防什麼？

四個代價最高的失敗模式（founding pain points，2026-07-13）：

| # | 失敗模式 | 主防技能 |
|---|---|---|
| P1 | 宣稱完成但沒驗證（「已修好」但根本沒跑過） | fable-verification-standards |
| P2 | 幻覺 API／路徑／旗標（runbook 看起來對但跑不動） | fable-ground-truth |
| P3 | 淺層修補不找根因（try/except 滅音、改測試遷就） | fable-debugging-playbook |
| P4 | 未經要求的重寫／破壞既有功能 | fable-scope-and-change-control |

## 安裝（專案隔離，不動全域）

**一行安裝，免 clone**——在**目標專案的根目錄**執行：

```bash
curl -fsSL https://raw.githubusercontent.com/Adaimade/Fable5Skills/main/install.sh | sh -s -- install
```

腳本會自動下載庫的 tarball 到暫存目錄、安裝進該專案的 `.claude/skills/`、用完即焚。其他子指令同理（`status` / `off` / `on` / `remove`）。

已 clone 的話也可以本地執行：

```bash
sh /path/to/Fable5Skills/install.sh install   # 裝進該專案的 .claude/skills/
sh /path/to/Fable5Skills/install.sh status    # 看裝了什麼、版本是否落後
sh /path/to/Fable5Skills/install.sh off       # 暫時停用（A/B 測試用）
sh /path/to/Fable5Skills/install.sh on        # 重新啟用
sh /path/to/Fable5Skills/install.sh remove    # 從該專案移除
```

保證：只碰目標專案的 `.claude/`；絕不動專案自己的非 fable 技能；不會覆蓋無戳記（可能被改過）的 fable-* 目錄（需 `--force`）。

## 15 個技能

完整索引（每技能一句話＋防線對照）見 **[.claude/skills/README.md](.claude/skills/README.md)**。分層速覽：

- **入口**：`fable-operating-core` — 主循環＋不可妥協守則＋路由表，從這裡開始
- **核心紀律**（8）：ground-truth · verification-standards · scope-and-change-control · debugging-playbook · failure-archaeology · codebase-archaeology · environment-recon · diagnostics-and-measurement
- **進階**（5）：hypothesis-and-experiment · first-principles-analysis · hard-problem-campaign · orchestration-and-delegation · reporting-and-writing
- **元**：`fable-skill-authoring-and-frontier` — 如何以同標準擴充本庫＋開放前沿問題

每個技能：英文正文（模型遵循度最佳）＋開頭繁中摘要；YAML frontmatter 帶觸發情境描述；附「何時不該用我、該用哪個兄弟技能」；結尾 Provenance 段列出易漂移事實的重新驗證指令。11 個附帶腳本全部實測過。

## 品質保證

以多代理工作流建成（2026-07-13/14）：15 位平行作者 → 3 位審查員（事實查核／教義一致性／可用性）→ 1 位修正員。審查發現 1 blocking + 7 important + 2 minor，全部修正；15/15 通過自帶檢查器：

```bash
cd .claude/skills && sh fable-skill-authoring-and-frontier/scripts/check-skill.sh */SKILL.md
```

## 維護原則

- **One home per fact**：每個事實只有一個家，其他地方用交叉引用，絕不複製
- 真實 session 撞上本庫本應防住的失敗 → 那是本庫的 **bug**，對負責的技能提報（見 fable-skill-authoring-and-frontier §6）
- 尚未驗證的想法一律標 open/candidate，不准超賣
- 庫本身是否真的改變模型行為，仍是**開放問題**（有可證偽的驗收標準，見 frontier 技能）——尚未實戰驗證
