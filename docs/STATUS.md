# 目前狀態（權威快照）

> 最後全面盤點：2026-10-28。本文只記錄「現在這棵工作樹已經有什麼、
> 已驗證到哪裏」；成員 README、上游數字與舊期證據不能取代本文。
> 🚧 **工程缺口正本：[工程缺口與待辦登記](ENGINEERING-GAPS.md)**；先看該表頂部「現行重點工程缺口」。所有測試執行已暫停並移至該表文末，不列現行優先次序。

## 儲存倉與模組身份

| 項目 | 目前值 |
|---|---|
| GitHub 儲存倉 | <https://github.com/vv0101v01/fiveinone> |
| 預設分支 | `main` |
| 本工作樹 | 直接 3＋2 五成員聯邦；原 `bridge/` 就地擴張，獨立 `unified/` 疊加層已刪除 |
| MoonBit module | `vv0101v01/cubical-hermitian` |
| module 版本 | `0.0.1`（尚未建立 Git tag／GitHub Release） |
| 固定工具鏈 | `.moon-toolchain`：`moon 0.1.20261023`、`moonc v0.10.17+d971670cd`；Linux x86_64 MoonBit/core archive digest pin，見 `tools/install_moonbit.sh` |
| 第三方依賴 | 只有 `moonbitlang/async@0.22.5`，且只供 native-only `semiring/par_host` |

## 五個成員與唯一整合層

| 成員 | 來源／provenance | MoonBit namespace | 成邦前文檔 |
|---|---|---|---|
| cubical/Hermitian 與精確代數 | cubical-hermitian 原始根套件 | 根套件、`algebra/` | 根 [README](../README.md)；長文根 SPEC／GUIDE |
| 有限對稱 | algorithm03 `05232fd` | `symlib/` | [`symlib/README.md`](../symlib/README.md) |
| 半環實驗室 | algorithm01 `6a208f4` | `semiring/*` | [`semiring/README.md`](../semiring/README.md) |
| moon-algebra | algo `427135faf8492f5433baba8077d4dc139282291f` | `finalg/`、`finalg/*` | [`finalg/README.md`](../finalg/README.md) |
| catmath | algo4 `3b3deaa9706ee5a3543c0fe0ac897167669e26a4` | `catmath/` | [`catmath/README.md`](../catmath/README.md) |

原三支柱橋與新 `federation_*.mbt` 同在 `bridge/`；它是唯一
五成員註冊、轉接、共同不變量報告與證書層。`cmd/showcase/`
直接展示這個 bridge；舊 `unified/`、`cmd/unified/` 已刪除。
跨成員圖表的方向、前提與邊界見 [BRIDGE](BRIDGE.md)，兩個新成員
在聯邦內的位置另見 [FINALG](FINALG.md) 與 [CATMATH](CATMATH.md)。

2026-10-27 再完成聯網文獻研究、第三波大一統切片與五個
GU 有限核心，詳見 [GRAND-UNIFICATION](GRAND-UNIFICATION.md)：
多變量 p-進 valued initial forms、Boolean／有界 tropical
矩陣 quantale residuals、representable presheaf sieves、
有限 blueprints，以及兩條可執行 theory morphisms 的模型
限制／反射。完整 tropical variety、一般賦值 Gröbner 基、
tropical ideals、blueprint／band schemes、一般 presheaf
子物件與一般 STLC 子型別仍是明示缺口，沒有以有限片段
改名冒充。

同日先完成去重與 v1 驗收審計（證書收攏為 16 項、82/100），
其後把五個 GU 定理族各加入一項正本證書，並為全部證書
加入不另列證的 v1 envelope。現行證書為 **21 項**。按
「五成員可相容有限共同片段」作分母、且運行證據分項計
0 的同一量表覆核，現況為 **87/100**；這不是五成員全部
原生功能的覆蓋率。

## 目前規模

本文與根 README 使用同一組機器可核查數字，由
`tools/doc_check.py`、`tools/arch_check.py` 與
`tools/audit_spec.py --check` 核對：

- 39 packages
- 48 components
- 330 `.mbt` files
- 135,683 `.mbt` lines
- 6,610 public symbols

逐套件符號數以 [SPEC-APPENDIX](../SPEC-APPENDIX.md) 的生成清單
為準。bridge 套件現有 736 個分類符號，包含原三支柱橋、直接
聯邦轉接器、第二至第四波推導報告、21 項跨成員語義證書
與 certificate envelope 入口。

## 驗證紀錄與測試暫停政策

依負責人決定，全部新舊測試源碼繼續保留，但**所有測試執行
暫停**：不執行單元測試、showcase、demo、benchmark、慢報告、
proof、coverage 或 runtime workflow。這是已決定的非現行
優先事項，不再列作下一期重要待辦。2026-10-28 本次 checkout
compile-only 紀錄使用固定工具鏈：

```bash
sh tools/check_compile.sh
```

它包括 `moon fmt --check`、生成介面與三個治理工具、四個 target
（wasm／wasm-gc／js／native）的 `moon check --deny-warn`、
wasm-gc 與 native 的 `moon test --build-only --deny-warn`
（只編譯測試源碼，不跑 test block），以及 portable 執行檔和
native report 的 `moon build`。

完整 `sh tools/check_compile.sh` 已於 2026-10-28 在本次更新後的
工作樹以 exit 0 完成，工具鏈為 `.moon-toolchain` 鎖定組合；該閘門
包含 fmt、生成介面 drift、文檔／架構／規格審計、四個 target 的
`moon check --deny-warn`、wasm-gc/native `moon test --build-only`，及
所有指定執行檔的 `moon build`。本次結果只對含本輪修改的本地工作樹有效；
沒有更新 GitHub 遠端，也不是 hosted CI 結果。`--build-only` 只編譯 test/wbtest 源碼，
沒有執行任何測試、showcase、smoke、benchmark 或 proof；不可寫成測試通過。

下列數字是**五成員整合前的舊三系統樹歷史證據**，不能當作目前
五成員樹已實跑：

| 舊三系統閘門（歷史） | 結果 |
|---|---|
| wasm-gc | 336 / 336 tests passed |
| native | 340 / 340 tests passed（多 4 個 native-only `par_host` 測試） |
| `cmd/main` | 90 / 90 內置驗收 |
| 舊 `cmd/showcase` | 5 / 5 橋接驗收 |
| `cmd/symdemo`、`cmd/symbench` | exit 0 |

兩個 target 的歷史測試總數不可相加。本節只保存歷史與政策
紀錄；除非負責人日後明確重新授權，否則不安排全倉測試，
也不把測試未執行列入現行工程優先清單。

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
- 第四波 GU 核心只在 `bridge/` 增加 valued initial、
  relation quantale、presheaf sieve、finite blueprint 與
  theory/mode 五份報告／檢查／wbtest，並把共用的 BPoly
  subdivision 檢查抽成單一私有 helper；五成員原生算法
  本體不作語義改寫。
- 成員成邦前文檔已回收到各成員根目錄的一份 `README.md`；
  `AGENTS.md`、`SPEC.md`、`GUIDE.md` 只在聯邦首領根目錄保存；
  成邦後事項集中到本文件、BRIDGE、FINALG、CATMATH、MIGRATION
  與工程缺口登記。

## 工程缺口摘要

詳細 ID、影響與下一步以置頂的
[ENGINEERING-GAPS](ENGINEERING-GAPS.md) 為準。現行實施面
先看 API／錯誤模型與相容政策（`API-001`…`API-003`）、
`par_host` 臨時檔安全（`SEC-002`）、catmath 靜態拆包
量測（`CAT-001`）、bridge 精確色鍵／標準形
（`BRG-001`／`API-005`），以及 `GU-001`…`GU-005`
的一般理論擴張。本文不另建第二份優先清單。

## 已暫停／非現行優先事項

- 所有單元測試、bridge 證書實跑、smoke、demo、benchmark、
  slow report、proof、coverage 與 runtime workflow，均按
  負責人決定暫停；只在工程缺口表文末保留事實紀錄，不排期、
  不占現行工程優先次序。
- 來源倉遷移告示／Archive、版本 tag／Release／簽章／SBOM
  與 GitHub 管理設定屬外部或發佈治理事項，詳列於工程缺口
  表，不在本文重複排序。
