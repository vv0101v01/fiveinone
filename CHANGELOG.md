# 變更紀錄

本檔只記錄使用者可見的發佈與治理變更。模組目前仍為 `0.0.1`，尚無
Git tag 或 GitHub Release；見 [工程缺口 REL-003](docs/ENGINEERING-GAPS.md)。

## Unreleased — 直接 3＋2 五成員聯邦與文檔治理（2026-10-27；2026-10-28 維護更新）

- 新增 `.moon-toolchain` 與 `tools/install_moonbit.sh`：CI 固定安裝 `moon 0.1.20261023`/`moonc v0.10.17+d971670cd`，並在 Linux x86_64 安裝前驗證 MoonBit/core archives SHA-256；compile gate 另檢查實際 moon/moonc 版本。跨平台固定安裝及 latest canary 仍是 ENG-003 後續事項。
- 新增 `docs/API-STABILITY.md`，先定義 0.x 期間 Experimental 預設、Test-support 範圍與 1.0 Stable allowlist 前置條件；未把現有 API 宣稱穩定。
- `semiring/par_host` 改以原子建立的專用 temp directory、CreateNew/0600 分片檔，錯誤不再忽略，並在 defer 清理；runtime 雙程序驗收仍因暫停政策未執行。
- 把 weighted graph 欄位 `canonical_encoding` 的文檔界定為 support-graph 診斷鍵，不是完整加權有向圖的 canonical form。

- 把 `algo`（`moon-algebra`）的 12 個 packages 組合為第四成員
  `finalg/`，連同全部 test/wbtest 與 `finalg/verify` 的 Why3 proof
  資產；import 主前綴為 `vv0101v01/cubical-hermitian/finalg`。
- 把 `algo4` 的 catmath 函式庫組合為第五成員 `catmath/`，保留全部
  test/wbtest；原同 package executable 拆至 `cmd/catmath`。
- 不在三聯邦之上另疊五聯邦層：原 `bridge/` 就地擴張為唯一
  五成員聯邦核心，`cmd/showcase` 直接列出五成員註冊表與現行
  21 項跨成員語義證書（證書函數已編譯，本期尚未執行）。
- bridge 新增並推導有限範疇／群／G-集、多項式模約化、整數
  矩陣、布林函數、有限拓撲／Spec、功能圖動力、有限同調與窄
  STLC 的轉換、共同不變量報告及交叉核對；每個接口明示方向、
  前提與非等價邊界。
- 完成 2026-10-27 大一統聯網文獻研究並寫入
  `docs/GRAND-UNIFICATION.md`，梳理五成員在型別邏輯、有限
  範疇、半環／有向量化、古典代數幾何與範疇模型中的角色。
- bridge 第三波加入有限 Heyting 開集／可觀測 refinement
  子型別格，以及 p-進單變量熱帶超曲面與多變量有界
  Gröbner-細化角點樣本；完整 tropical variety、賦值
  Gröbner 基、blueprints／bands 與一般子型別仍列為 GU 缺口。
- 完成定理／演算法去重審計：bridge 內同義 helper、重複
  p-進範例與歷史證書累計已收攏；按可相容有限共同片段且
  運行證據計 0 的量表評為 82/100，作大一統 v1 收貨口徑。
- bridge 第四波完成 GU 五個有限核心：多變量 valued
  initial forms、Boolean／有界 tropical 矩陣 quantale
  residuals、representable presheaf sieves、有限
  blueprints 與兩條 theory morphisms 的模型限制／反射；
  證書增至 21 項，另加不另列證的 v1 certificate
  envelopes。同一量表覆核為 87/100；一般 valued
  Gröbner、tropical varieties/ideals、blueprint/band
  schemes 與一般子型別仍明確未完成。
- 為跨套件唯讀表示只加所屬成員內的窄域 constructor／copy
  函數（catmath 的 G-集、鏈複形與 STLC 建構子，cubical root 的
  `LTy`／`Term` 建構子），不把成員型別放寬為 `pub(all)`。
- 文檔改為「每個成員根目錄一份 `README.md` 保存成邦前正本；
  成邦後事項只寫中央文檔」。`AGENTS.md`、`SPEC.md`、
  `GUIDE.md` 只留首領根目錄；獨立 MERGE 研究檔已濃縮到
  `docs/MIGRATION.md` 後刪除。
- `architecture.json`、生成介面、雙語規格附錄與文檔數字更新至
  39 packages／48 components／330 個 `.mbt`／135,485 行／
  6,610 個公開符號；finalg 以明確 `pub extend` 取代上游的
  module-level warning 抑制。
- 工程缺口入口已置頂至根 README、文檔索引與 STATUS；
  所有測試、proof、coverage 與 runtime workflow 改列
  「已暫停／非現行優先」，集中移到工程缺口表文末。
- 檢查政策維持 compile-only：`tools/check_compile.sh` 編譯全部
  測試源碼但不執行；`check_full.sh` 須 `GOLDEN_RUN_TESTS=1`
  才真正執行測試與 smoke，`check_slow.sh` 須
  `GOLDEN_RUN_SMOKE=1` 才執行慢報告。
- compile-only CI workflow 維持 push／PR；runtime tests 與 slow
  report 只保留 manual 入口。待運行證據與新邊界登記為
  `ENG-009`、`FIN-*`、`CAT-*`、`UNI-*`、`BRG-*`、`GU-*`。
- 本 Unreleased 的新增公共符號來自 finalg／catmath 導入、窄域
  interop 與 bridge；五個成員的算法主體不作語義改寫。已知
  理論、上限與 abort 邊界按原狀態登記，沒有因文檔更新而宣稱
  解決。

## 首次公開三合一聯邦體（2026-10-27）

- 內容包括 cubical root、精確 `algebra/`、`symlib/`、`semiring/*`、
  單向 `bridge/` 與五個 `cmd/*` 入口。
- 治理基線：25 個 MoonBit 套件、34 個組件、215 個 `.mbt`、
  101,847 行、5,054 個公共符號。
- 實跑基線：wasm-gc 336/336、native 340/340、`cmd/main` 90/90、
  `cmd/showcase` 5/5。
- MoonBit module 名維持 `vv0101v01/cubical-hermitian`，不改變 import 路徑。
