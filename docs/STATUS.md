# 目前狀態（權威快照）

> 最後全面盤點：2026-10-27。本文只記錄「現在這棵工作樹已經有什麼、
> 已驗證到哪裏」；成員 README、上游數字與舊期證據不能取代本文。
> 未完成事項集中在 [工程缺口與待辦登記](ENGINEERING-GAPS.md)。

## 儲存倉與模組身份

| 項目 | 目前值 |
|---|---|
| GitHub 儲存倉 | <https://github.com/vv0101v01/golden> |
| 預設分支 | `main` |
| 已公開的遠端 `main` | `9452cb94a441ffe17b082c09cd8ee351c4c96c89`（三系統首次公開樹；本輪五成員樹以推送後遠端回讀為準） |
| 本工作樹 | 直接 3＋2 五成員聯邦；原 `bridge/` 就地擴張，獨立 `unified/` 疊加層已刪除 |
| MoonBit module | `vv0101v01/cubical-hermitian` |
| module 版本 | `0.0.1`（尚未建立 Git tag／GitHub Release） |
| 已驗證工具鏈 | `moon 0.1.20261023`、`moonc v0.10.17+d971670cd` |
| 第三方依賴 | 只有 `moonbitlang/async@0.22.5`，且只供 native-only `semiring/par_host` |

儲存倉名是 `golden`，但 import 身份刻意保留
`vv0101v01/cubical-hermitian`，避免為改倉名或加入新成員而重寫
全部 package 路徑。

## 五個成員與唯一整合層

| 成員 | 來源／provenance | golden namespace | 成邦前文檔 |
|---|---|---|---|
| cubical/Hermitian 與精確代數 | 既有 golden 根套件 | 根套件、`algebra/` | 根 [README](../README.md)；長文根 SPEC／GUIDE |
| 有限對稱 | algorithm03 `05232fd` | `symlib/` | [`symlib/README.md`](../symlib/README.md) |
| 半環實驗室 | algorithm01 `6a208f4` | `semiring/*` | [`semiring/README.md`](../semiring/README.md) |
| moon-algebra | algo `427135faf8492f5433baba8077d4dc139282291f` | `finalg/`、`finalg/*` | [`finalg/README.md`](../finalg/README.md) |
| catmath | algo4 `3b3deaa9706ee5a3543c0fe0ac897167669e26a4` | `catmath/` | [`catmath/README.md`](../catmath/README.md) |

原三支柱橋與新 `federation_*.mbt` 同在 `bridge/`；它是唯一
五成員註冊、轉接、共同不變量報告與證書層。`cmd/showcase/`
直接展示這個 bridge；舊 `unified/`、`cmd/unified/` 已刪除。
跨成員圖表的方向、前提與邊界見 [BRIDGE](BRIDGE.md)，兩個新成員
在聯邦內的位置另見 [FINALG](FINALG.md) 與 [CATMATH](CATMATH.md)。

## 目前規模

本文與根 README 使用同一組機器可核查數字，由
`tools/doc_check.py`、`tools/arch_check.py` 與
`tools/audit_spec.py --check` 核對：

- 39 packages
- 48 components
- 320 `.mbt` files
- 129,914 `.mbt` lines
- 6,259 public symbols

逐套件符號數以 [SPEC-APPENDIX](../SPEC-APPENDIX.md) 的生成清單
為準。bridge 套件現有 385 個分類符號，包含原三支柱橋、直接
聯邦轉接器、第二波推導報告與 18 項聚合證書入口。

## 本階段驗證證據：compile-only

依負責人的明確指示，本階段保留／搬入全部新舊測試源碼，但
**不執行**單元測試、showcase、demo、benchmark、慢報告或 proof。
現行完整驗收命令是：

```bash
sh tools/check_compile.sh
```

它包括 `moon fmt --check`、生成介面與三個治理工具、四個 target
（wasm／wasm-gc／js／native）的 `moon check --deny-warn`、
wasm-gc 與 native 的 `moon test --build-only --deny-warn`
（只編譯測試源碼，不跑 test block），以及 portable 執行檔和
native report 的 `moon build`。

完整 `sh tools/check_compile.sh` 已於 2026-10-27 在本輪
五成員工作樹以 exit 0 完成；推送前另會在重建的 Git 樹重跑，
以同時核對生成 `.mbti` 無漂移。即使完整閘門通過，也只證明
compile-only，不是任何測試已通過。

下列數字是**五成員整合前的舊三系統樹歷史證據**，不能當作目前
五成員樹已實跑：

| 舊三系統閘門（歷史） | 結果 |
|---|---|
| wasm-gc | 336 / 336 tests passed |
| native | 340 / 340 tests passed（多 4 個 native-only `par_host` 測試） |
| `cmd/main` | 90 / 90 內置驗收 |
| 舊 `cmd/showcase` | 5 / 5 橋接驗收 |
| `cmd/symdemo`、`cmd/symbench` | exit 0 |

兩個 target 的歷史測試總數不可相加。進入運行期的唯一入口是
未來獲授權後執行 `GOLDEN_RUN_TESTS=1 sh tools/check_full.sh`；
慢報告同樣需要 `GOLDEN_RUN_SMOKE=1`。

## 本次整合落地內容

- `algo` 的 12 個 packages 機械搬入 `finalg/`，內部依賴 DAG、
  11 份上游 test/wbtest、proof 契約、Why3 prelude/config 與
  已重基的 `prove.sh` 一併保留；明確 `pub extend` 取代上游
  module-level warning 抑制。
- `algo4` 函式庫與 23 份 test/wbtest 搬入單一 `catmath/`
  library，原同包 `main` 拆至 `cmd/catmath`。
- 直接聯邦橋已實作五成員註冊表，以及有限範疇、群與 G-集、
  `QPoly`/finalg 多項式、整數矩陣、布林函數、有限拓撲／Spec、
  功能圖動力、`F_p`/整數同調片段、S¹ 繞數與窄片段 STLC 的
  轉換、報告、檢查和證書。
- STLC 橋保留一處真實語義差異：cubical 的 unit-η 在 catmath
  raw 範形沒有對應塌縮；報告同時記錄 raw equality 與顯式
  completion，不製造假等價。
- 成員成邦前文檔已回收到各成員根目錄的一份 `README.md`；
  `AGENTS.md`、`SPEC.md`、`GUIDE.md` 只在聯邦首領根目錄保存；
  成邦後事項集中到本文件、BRIDGE、FINALG、CATMATH、MIGRATION
  與工程缺口登記。

## 尚未完成的最重要事項

1. 目前五成員樹尚未執行任何單元或 smoke 測試；這是下一期的
   明確待辦，不可以編譯成功代替。
2. `finalg/verify` 尚未在本環境執行 `moon prove`／Why3；普通
   編譯不等於 proof goals 已重證。
3. `algorithm01`、`algorithm03`、`algo`、`algo4` 的遷移告示
   與 GitHub Archive 均屬外部待辦；本工作樹只更新 golden。
4. Hosted CI 必須以實際 workflow run 證明，不能只憑 workflow
   檔在本機存在便宣稱綠燈。
5. 尚未建立版本 tag、Release、簽章或 SBOM。
6. catmath 仍為單一大 package；是否拆包必須在取得五成員運行
   基線後另行以依賴量測決定。
7. 其餘理論、規模、API 與跨平台限制詳見工程缺口登記。
