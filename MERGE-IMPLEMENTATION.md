# 三方聯邦合併實施紀錄

本文件記錄 `MERGE-THREEWAY-RESEARCH.md` 方案 A 的實際落實進度與驗收證據。

## Phase T0 — 基線回復與凍結（完成）

- cubical-hermitian 第十三期工作樹已在本地重新建立 Git 基線：`c52b450`。
- algorithm03 重新 clone 核實上游 `main@05232fd`，與本地來源樹逐檔相同（排除 `_build`/`.git`）。
- algorithm01 核實 `main@6a208f4`。
- 基線檢查：
  - cubical：`moon fmt --check`、`moon check --deny-warn`、架構檢查、符號審計（3523 符號）通過；
  - algorithm03：`moon fmt --check`、`moon check --deny-warn`、`moon test` **67/67**；
  - algorithm01：`moon fmt --check`、`moon check --deny-warn`、`moon test` **158/158**。

## Phase T1 — 治理工具泛化（完成）

- `tools/arch_check.py`：
  - package 由 manifest 最長路徑推導，不再硬編碼 root/algebra/cmd-main；
  - 名稱解析順序由 production + test-scoped import 的傳遞閉包推導；
  - `moon.pkg` 區分 production import 與 `for "wbtest"` import；
  - manifest file patterns 支援 `!` 排除；
  - `.mooncakes`/`.moonagent`/`target`/`_build` 不納入套件盤點；
  - 宣告掃描支援泛型函數與 traits；
  - component 可明示 `observer`。
- `tools/audit_spec.py`：
  - 解析 `pub(all)`、`pub(open) trait`、`pub fn[...]`、泛型型別、trait 方法及 `pub impl`；
  - 分類改為 `(package, symbol, kind)`，避免三支柱同名符號混淆；
  - 已登記 symlib 七個規格族、semiring 十六個套件族與三方橋接族的雙語定義。
- 基線回歸：泛化後 cubical 仍為 **3523** 符號，架構與審計均通過。

## Phase T2 — 機械搬移（完成）

- T2a（提交 `06eeb04`）：algorithm03 根套件原封搬至 `symlib/`，cmd 改為
  `cmd/symdemo` 與 `cmd/symbench`，只改兩個 cmd 的 import 前綴；
  `moon test symlib` **67/67**，全域 check、arch、audit 通過（4055 符號）。
- T2b（提交 `4ae5f7e`）：algorithm01 的 15 個非 host 套件原封搬至
  `semiring/*`，只改 `moon.pkg` 的 module 前綴，主 module 未引入 async；
  semiring wasm-gc **154/154**；js/wasm/wasm-gc/native
  `moon check --deny-warn`、arch、audit 通過（4901 符號）。
- 兩個搬移提交均未改上游 `.mbt` 算法來源；生成的 `.mbti` 全部由
  `moon info` 重生。

## Phase T3 — 文件與入口整合（完成；最終數字見文末）

- algorithm03 長文遷至 `docs/symlib.md`，命令改為 `cmd/symdemo`/`cmd/symbench`。
- algorithm01 的 README、DESIGN、REPORT 遷至 `docs/semiring/`，加上合併後
  路徑橫幅；REPORT 明確標為慢閘門重生成物。
- 新增 `docs/MIGRATION.md`：三邊 import 對照、兩份 algebra 消歧、monoid/monad
  正名、target 與 async 邊界。
- 頂層 `README.mbt.md` 改為三支柱入口；權威符號數字仍以生成的雙語附錄為準。

## Phase T4-pre — colored graph search 前置（提交 `4c03808`）

- `symlib/search.mbt` 的搜尋上下文新增正規化頂點顏色；初始精煉由度數秩與
  固定顏色標籤合成，候選自同構逐點驗證保色。
- `automorphism_group_colored`、`colored_canonical_key` 與
  `isomorphic_colored` 已公開；canonical key 同時包含規範位置顏色與鄰接編碼。
- 測試錨點：C4 無色群階 8，顏色 `[0,1,0,1]` 群階 4，顏色
  `[0,0,0,1]` 群階 2；symlib **69/69**。

## Phase T4 — bridge 與 showcase（提交 `3689431`）

- 新增單向整合套件 `bridge/` 與執行入口 `cmd/showcase`，並新增
  `docs/BRIDGE.md` 明列每座橋的誠實邊界。
- 橋面包括：Perm↔Wiring/Equiv 與置換矩陣/群平均；semiring 加權有向圖及
  cubical 複矩陣的支撐色搜尋＋精確/近似逐元過濾；DAG 自由範疇→FinCat；
  熱帶最佳指派、精確 permanent/determinant 與 QPoly p-進熱帶化；
  Face canonical-BDD 半環；正方形胞腔關聯對稱；統一 `BridgeCertificate`。
- 為保持 root `Ty`、`Dim`、`Face` 不改成 `pub(all)`，只新增窄域公開
  構造函數作為跨套件構造邊界。
- bridge 測試 **2/2**；showcase 輸出 5/5 certificates，旗艦 C4 的
  加權對稱數 4、可達對 16、有限距離和 24，平均置換矩陣為跡 1 投影器；
  架構 **23 packages／32 components／208 files／98,880 lines**，審計
  **5,008 symbols**（bridge 87）。

## Phase T5 — native host 與量測報告（提交 `b403035`）

- algorithm01 `par_host/` 機械搬至 `semiring/par_host/`，`cmd/report/`
  搬至 `cmd/semiringreport/`；`.mbt` 僅改報告自述命令，manifest 只改
  module 前綴。
- 主 module 明示 `moonbitlang/async@0.22.5`；全倉 production manifest 中
  只有 `semiring/par_host` import async。host 與 report 均保留
  `supported_targets: "native"`，四 target `moon check --deny-warn` 通過。
- semiring native **158/158**、wasm-gc **154/154**（差額正是 native-only
  host 的 4 項測試）。
- 慢閘門已在主倉重跑：`cmd/semiringreport` 產生 717 行報告，程式自報
  67,551.77 ms；`docs/semiring/REPORT.md` 已換成該主倉快照並注明慢閘門。
- 治理更新：**25 packages／34 components／215 files／101,847 lines**；
  審計 **5,054 symbols**（par-host 4、report 42）。

## Phase T6 — 舊倉遷移材料（本地完成；遠端待憑證）

- `docs/LEGACY-ARCHIVE.md` 已備妥 algorithm01 與 algorithm03 的 README
  頂部告示全文、主倉新路徑、保留舊 commit/tag 的操作順序，以及
  GitHub Archive 前的驗證清單。
- `docs/MIGRATION.md` 已連結該清單並明言：在主倉實際推送及遠端驗證前，
  不得宣稱舊倉已封存。
- 遠端未竟事項只有三件：以有效憑證推送主倉、把告示提交到兩舊倉、在
  GitHub 封存兩舊倉；令牌只可作單次命令 URL，不寫入檔案或 git config。

## 最終本地驗收彙總

- 治理：**25 packages／34 components／215 `.mbt`／101,847 行**；
  雙語附錄 **5,054 symbols**。`arch_check.py` 與
  `audit_spec.py --check` 通過。
- 編譯：js、wasm、wasm-gc、native 四 target
  `moon check --deny-warn` 通過；`moon fmt --check` 通過。
- 全量測試（單一 target 實跑，不是不同 target 數字相加）：
  wasm-gc **336/336**；native **340/340**。差額 4 是
  `semiring/par_host` 的 native-only 測試。cubical 原第十三期
  root+algebra 111 項已包含在兩次全量實跑中重驗。
- 執行入口：`cmd/main` 定理登記 **90/90**；`cmd/showcase`
  **5/5** bridge certificates；`cmd/symdemo`、`cmd/symbench` 成功。
- 慢閘門：`cmd/semiringreport --target native` 成功產生 717 行，
  程式自報 67,551.77 ms，已保存為 `docs/semiring/REPORT.md` 主倉快照；
  它不進快速閘門。

至此，方案 A 的 T0–T5 與 T6 本地材料均已完成；只剩需使用者憑證的
GitHub 推送與舊倉封存遠端動作。
