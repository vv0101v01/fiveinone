# 貢獻與維護流程

本倉目前是單一 MoonBit module 的聯邦體。提交前請先讀
[目前狀態](docs/STATUS.md)、[工程缺口](docs/ENGINEERING-GAPS.md)與
[文檔索引](docs/README.md)。

## 本地環境

已驗證組合：

- `moon 0.1.20261023`
- `moonc v0.10.17+d971670cd`
- Python 3（文檔、架構與規格審計工具）

首次取得第三方依賴：

```bash
git clone https://github.com/vv0101v01/golden.git
cd golden
moon update
```

`moonbitlang/async@0.22.5` 只供 native-only 的 `semiring/par_host`；不要把
async、檔案系統或宿主 API 引進 portable 核心。

## 架構規則

- cubical root、精確 `algebra/`、`symlib/`、`semiring/*`、`finalg/` 與
  `finalg/*`、`catmath/` 五個來源系統保持分立。
- 所有跨成員依賴只可放入唯一的 `bridge/`；不得再建疊加整合包。
  五個成員不得為方便而互相匯入或共用私有表示。
- `finalg/testutil` 只能作 test-support；生產 `moon.pkg` 不得 import 它。
- 兩同名 `algebra` 在 import、範例與文件必須完整消歧：
  `vv0101v01/cubical-hermitian/algebra` 與
  `vv0101v01/cubical-hermitian/semiring/algebra`。
- 新 `.mbt` 檔要登記到 `architecture.json` 所屬組件；新 package 要同時
  補 `moon.pkg`、架構說明、規格族與測試定位。
- 新限制、cap、近似或受信欄位必須同時登記到
  `docs/ENGINEERING-GAPS.md`，不得只藏在程式註解。

## 生成檔規則

公共介面變動後依序執行：

```bash
moon info
python3 tools/audit_spec.py --write
```

- 不手改 `pkg.generated.mbti`。
- 不手改 `SPEC-APPENDIX.md`、`SPEC-APPENDIX.en.md` 的
  `APPENDIX:BEGIN/END` 生成區；要改分類或文字，先改存在規格正文的
  symbol family，再重跑審計工具。
- `semiring/REPORT.md` 頂部是人工快照橫幅；慢閘門先輸出到暫存檔，
  審查後只替換正文。

## 檢查層級

只改文檔時至少：

```bash
python3 tools/doc_check.py
python3 tools/arch_check.py
python3 tools/audit_spec.py --check
```

一般程式變動跑目前的 compile-only 閘門：

```bash
sh tools/check_compile.sh
# sh tools/check_fast.sh 是同一閘門的相容別名
```

它涵蓋格式、生成介面 drift、文檔／架構／規格審計、四 target
`moon check --deny-warn`、wasm-gc/native 的
`moon test --build-only`（編譯全部測試源碼但不執行），以及所有
portable 執行檔與 native 慢報告的 `moon build`。

目前專案負責人已明示把真正執行測試延到下一期。未獲指示前，不得
直接跑 `moon test`（非 `--build-only`）、`moon run`、benchmark、
`moon prove` 或慢報告並把結果混入本期證據。未來運行期使用：

```bash
GOLDEN_RUN_TESTS=1 sh tools/check_full.sh
GOLDEN_RUN_SMOKE=1 sh tools/check_slow.sh > /tmp/REPORT.generated.md
```

未設環境開關時，`check_full.sh` 會在執行任何測試前拒絕；
`check_slow.sh` 只建置 report。此政策關閉前，PR／回覆只能寫
「compile-only 通過」，不得寫「測試通過」。

未來運行期各 target 測試數字要分列；不要把 wasm-gc 與 native 相加，也不得沿用舊三系統的 336／340 作為五系統預期總數。

## 可選 pre-commit hook

```bash
git config core.hooksPath .githooks
```

hook 只做提交前快速防線，不取代 `check_compile.sh`／CI；實際範圍見
`.githooks/README.md`。

## 文檔同步檢查表

- 現在事實：`docs/STATUS.md`、根 README。
- 新限制或待辦：`docs/ENGINEERING-GAPS.md`。
- 新檔案：`docs/README.md` 索引與分類。
- 使用者可見變更：`CHANGELOG.md`。
- 架構邊界：`ARCHITECTURE.md`、`architecture.json`、`AGENTS.md`。
- 每個成員的成邦前 `README.md` 不回填成邦後成果；決策史只更新
  `docs/MIGRATION.md`，不另建 MERGE 研究檔。
- `AGENTS.md`、`SPEC.md`、`GUIDE.md` 只可存在於倉庫根目錄。

## 尚未自動化的事

GitHub branch protection、required checks、舊倉 Archive、Release/tag 與
倉庫頁面設定都需要管理員在 GitHub 操作；程式碼合併本身不會完成這些事。
未完成前要在缺口登記保留「待外部」，不得在回覆中宣稱已封存或已強制 CI。
