# 文檔索引

本索引是找文件的唯一入口。每份 Markdown 都必須在此歸類，否則
`python3 tools/doc_check.py` 會失敗。

## 文檔分工（直接 3＋2 後的硬規則）

1. **每個成員一份 `README.md`**，放在該成員根目錄，只保存成邦前
   的來源、設計與歷史證據；聯邦首領 cubical 的 README 就是倉庫
   根 `README.md`，其長文由根 SPEC／GUIDE 承擔。
2. **成邦後事項只寫中央新文檔**：現況、橋接、遷移、缺口、發布與
   變更寫入 `docs/` 或根治理文件，不回寫成員成邦前 README。
3. **`AGENTS.md`、`SPEC.md`、`GUIDE.md` 只在首領根目錄各一份**；
   英文版與生成附錄是同一中央文檔組的附件，不在成員目錄複製。
4. 成員可保留真正不重複的技術附件（例如 semiring 的 DESIGN／
   REPORT、catmath 的 MATH），但入口必須是其唯一 README。
5. 舊的獨立 MERGE 研究快照已濃縮到 [MIGRATION](MIGRATION.md)
   的決策史並從工作樹刪除，不再建立平行決策文件。

分類意義：**現行**隨程式／發布狀態同步；**成邦前**只修連結與
出處，不把新成果倒灌；**生成**只可改產生器或人工橫幅；
**長文**可保留跨期脈絡，但現行入口與限制必須可追到中央文檔。

## 從這裏開始

| 文件 | 分類 | 用途 |
|---|---|---|
| [`README.md`](../README.md) | 現行＋首領 README | GitHub 門面、五成員總覽、直接 3＋2 理由與 compile-only 快速開始 |
| [`docs/STATUS.md`](STATUS.md) | 現行 | 權威現況：倉庫身份、規模、已驗證編譯證據 |
| [`docs/ENGINEERING-GAPS.md`](ENGINEERING-GAPS.md) | 現行 | 所有已知缺口、限制、待辦與驗收方向 |
| [`CHANGELOG.md`](../CHANGELOG.md) | 現行 | 面向使用者的發布與重要治理變更 |
| [`CONTRIBUTING.md`](../CONTRIBUTING.md) | 現行 | 建置、閘門、生成檔與文檔維護流程 |
| [`AGENTS.md`](../AGENTS.md) | 現行 | 自動化代理／維護者的全倉工作邊界 |

## 中央架構、指南與規格

| 文件 | 分類 | 用途 |
|---|---|---|
| [`ARCHITECTURE.md`](../ARCHITECTURE.md) | 現行 | 五成員 39 packages／48 components、依賴治理與 compile-only 邊界 |
| [`GUIDE.md`](../GUIDE.md) | 長文 | cubical 核心中文導覽與成邦前開發脈絡 |
| [`GUIDE.en.md`](../GUIDE.en.md) | 長文 | 英文導覽；比中文版精簡，不聲稱逐段對譯 |
| [`SPEC.md`](../SPEC.md) | 現行 | 中文規格正本與誠實邊界 |
| [`SPEC.en.md`](../SPEC.en.md) | 現行 | English specification |
| [`SPEC-APPENDIX.md`](../SPEC-APPENDIX.md) | 生成 | 中文逐符號附錄，勿手改生成區 |
| [`SPEC-APPENDIX.en.md`](../SPEC-APPENDIX.en.md) | 生成 | English generated symbol appendix |

## 五個成員的成邦前文檔

| 文件 | 分類 | 用途 |
|---|---|---|
| `README.md` | 成邦前入口 | cubical 首領入口（同「從這裏開始」的根 README） |
| [`symlib/README.md`](../symlib/README.md) | 成邦前長文 | symlib 符號體系、方法、實測與限制正本 |
| [`semiring/README.md`](../semiring/README.md) | 成邦前長文 | semiring 對外導覽、公共面與驗收數字 |
| [`semiring/DESIGN.md`](../semiring/DESIGN.md) | 成邦前長文 | semiring 設計推導、取捨與限制正本 |
| [`semiring/REPORT.md`](../semiring/REPORT.md) | 生成快照 | native 慢閘門歷史量測；人工橫幅不可被覆蓋 |
| [`finalg/README.md`](../finalg/README.md) | 成邦前長文 | moon-algebra 定義、公式、定理、proof 與測試資產 |
| [`catmath/README.md`](../catmath/README.md) | 成邦前長文 | catmath 導覽、模組地圖與效能快照 |
| [`catmath/MATH.md`](../catmath/MATH.md) | 成邦前長文 | catmath 定義、定理與公式正本 |

## 成邦後中央文檔

| 文件 | 分類 | 用途 |
|---|---|---|
| [`docs/BRIDGE.md`](BRIDGE.md) | 現行 | 唯一五成員 bridge：疊加／直接之別、相容圖表、推導定理與邊界 |
| [`docs/GRAND-UNIFICATION.md`](GRAND-UNIFICATION.md) | 現行 | 2026-10-27 聯網文獻研究、五成員角色、GU 五個有限核心、定理／演算法去重、82/100 v1 判定與 87/100 覆核 |
| [`docs/FINALG.md`](FINALG.md) | 現行 | finalg 在聯邦內的 package 圖、proof 資產與精確代數分工 |
| [`docs/CATMATH.md`](CATMATH.md) | 現行 | catmath 在聯邦內的內容分域、單包邊界與 executable 拆分 |
| [`docs/MIGRATION.md`](MIGRATION.md) | 現行 | 五來源到 golden 的 import 對照、遷移狀態與決策史 |
| [`docs/LEGACY-ARCHIVE.md`](LEGACY-ARCHIVE.md) | 現行待辦 | 來源倉告示定稿、封存程序與尚未執行的外部步驟 |

## 工具文件

| 文件 | 分類 | 用途 |
|---|---|---|
| [`.githooks/README.md`](../.githooks/README.md) | 現行 | 可選 pre-commit hook 的啟用與實際檢查範圍 |

## 維護流程

1. 現行事實先更新 [STATUS](STATUS.md)；新限制先登記
   [ENGINEERING-GAPS](ENGINEERING-GAPS.md)，再由專門文件連回來。
2. 新 Markdown 必須加入本索引並標分類；成邦前文檔不回填新成果。
3. 公共符號變動先跑 `moon info`，再跑
   `python3 tools/audit_spec.py --write`；不可手改兩份附錄生成區。
4. `semiring/REPORT.md` 更新時保留人工橫幅，只替換生成正文，並
   記錄它仍是機器相依歷史快照。
5. 提交前至少跑 `python3 tools/doc_check.py`；本階段程式變動跑
   `sh tools/check_compile.sh`。真正執行測試的 full 閘門依負責人
   指示延後，見 [CONTRIBUTING](../CONTRIBUTING.md)。
