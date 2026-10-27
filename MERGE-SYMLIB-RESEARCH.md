# algorithm03（`arena/symlib`）× cubical-hermitian 合併研究

日期：2026-10-27  
研究對象：

- 本專案：`vv0101v01/cubical-hermitian`，第十三期後基線 `f3a8238`
- 另一倉庫：[`vv0101v01/algorithm03`](https://github.com/vv0101v01/algorithm03/tree/main)，`main=05232fd`
- 本地研究副本：`/home/user/algorithm03`

> 本報告是合併前研究與原型驗證，不是已完成的正式合併。原型在 `/tmp/cubical-sym-proto` 驗證，主線代碼尚未搬入 symlib。

---

## 0. 結論先行

### 推薦合併方式

**不要把 algorithm03 的檔案攤平抄入 cubical-hermitian root package。** 最穩妥、成本最低、而且已原體驗證的方法是：

1. 以 cubical-hermitian 為合併後主模組；
2. 把 algorithm03 的 root library 原封不動搬成同一 MoonBit module 內的獨立子套件：
   - `symlib/` → `vv0101v01/cubical-hermitian/symlib`
3. algorithm03 的兩個執行入口改名，避免同現有 `cmd/main` 混淆：
   - `cmd/main` → `cmd/symdemo`
   - `cmd/bench` → `cmd/symbench`
4. cubical kernel root **不要反向依賴 symlib**；另外建立高層 `bridge/` 套件，同時 import：
   - cubical root
   - `symlib`
   - `algebra`
5. 再加 `cmd/showcase`，統一跑 cubical 定理表、symlib 證書電池同 bridge 定律。

### 合併後會變成什麼

它不再只是「cubical type theory + Hermitian 投影」或另一邊的「圖自同構庫」，而會變成一個以**規範形、對稱、等價路徑與可驗證證書**為主軸的 MoonBit 計算數學平台：

> **Cubical–Hermitian Symmetry Lab：以規範形判定相等，以群作用理解對稱，以 cubical 路徑承載等價，以精確代數與證書驗證結果。**

同一個有限結構可以跨表示移動：

```text
Graph ──► adjacency QMat ──► characteristic polynomial / spectrum
  │             │
  │             └──► Hermitian projector / spectral decomposition
  ├──► Aut(G), orbits, G-sets, marks
  └──► finite equivalence / wiring ──► ua path in cubical layer

Hermitian matrix ──► support graph ──► permutation symmetry group
       ▲                                      │
       └──── group-averaging projector ◄──────┘

Face / HIT cells / DTerm DAG ──► incidence structure
                              ──► canonical key + automorphism group
```

### 第一版合併實際可得功能

- 原 cubical-hermitian 全部功能：依賴 cubical kernel、NbE、Kan coe/comp、inductive/HIT schema、計算性 univalence、HOU、模組/工件、BDD/CDCL、精確代數、Hermitian/Jacobi；
- 原 algorithm03 全部功能：圖規範形、同構判定、Aut 群、Schreier–Sims、群作用、軌道折疊、G-集/table of marks、有限範疇、預層/Yoneda、Kan 擴張、CSP；
- 新增 bridge 功能：矩陣置換對稱、Perm↔Wiring、圖的精確譜資料、群平均投影、有限範疇形狀對照、統一證書報告。

### 可行性判斷

**高。** 兩邊同為 MoonBit、Apache-2.0、preferred target 同為 wasm；algorithm03 library 本身沒有本地套件依賴。把它的 root 檔案搬到 `symlib/` 後，原型已通過：

- symlib 原始倉庫：`moon fmt --check`、`moon check --deny-warn`、`moon test` **67/67**；
- 搬入 cubical module 後：全模組 `moon check --deny-warn` 通過；
- 子套件測試仍為 **67/67**；
- 一個真正跨套件的矩陣對稱 bridge 原型 **1/1**，連同 symlib 共 **68/68**。

---

## 1. 兩個專案的基線盤點

| 項目 | cubical-hermitian | algorithm03 / symlib |
|---|---:|---:|
| MoonBit module | `vv0101v01/cubical-hermitian` | `arena/symlib` |
| version | `0.0.1` | `0.1.0` |
| license | Apache-2.0 | Apache-2.0（LICENSE 檔案相同） |
| preferred target | wasm | wasm |
| 實體套件 | root、algebra、cmd/main | root、cmd/main、cmd/bench |
| `.mbt` 檔案 | 112 | 33 |
| `.mbt` 行數 | 71,816 | 12,037 |
| library 主體 | root 56,541 行 + algebra 14,541 行 | 26 檔、8,879 行 |
| 測試檔案 | 30 | 4 |
| 測試數 | 111 | 67 |
| 正式登記 | 90 項 CheckResult、101 條 SpecEntry | `prove_all` 20 條全域 Cert，另有依輸入生成的 `prove_graph` / `prove_pair` |
| 公共介面規模 | 3,523 個已審計符號 | `.mbti` 784 行；363 行 `pub fn`、28 個 struct、1 個 enum |
| 執行入口 | `moon run cmd/main` 印 90/90 定理表 | `moon run cmd/main` 演示；`moon run cmd/bench` 基準 |

機械合併後的粗略規模是 **145 個 `.mbt`、約 83,853 行、178 個既有測試**，未計 bridge 新增檔案與測試。

---

## 2. algorithm03 本身做到什麼

algorithm03 的正式名稱是 `symlib`。它不是一般 graph utility，而是一套以圖自同構群為樞紐的有限對稱計算庫。

### 2.1 圖與規範形

- `Graph`：簡單無向圖，鄰接表加 BitVec 行；
- individualization–refinement 搜尋，一次搜尋同時產出：
  - canonical labeling / canonical form / encoding / digest；
  - automorphism generators；
- 四條同構判定通道：
  1. 主搜尋引擎；
  2. 分量分解；
  3. 補圖對偶；
  4. 線圖 + Whitney 定理；
- 顯式同構 `Perm?`，不只是 Boolean 答案。

### 2.2 置換群與群作用

- `Perm`、`PermGroup`；
- 增量 Schreier–Sims、群階、membership sifting、stabilizer、元素列舉；
- 點、序對、邊等 derived actions；
- 軌道、基本域、orbit folding、Burnside 計數；
- 作用廣群與 groupoid cardinality。

### 2.3 G-集與 Burnside 環

- point/pair/edge/induced/coinduced/coset G-sets；
- subgroup conjugacy classes；
- mark vector、table of marks（兩種獨立算法互證）；
- 以 mark vector 判定 G-集同構；
- Cayley 圖、regular representation、Frobenius reciprocity；
- free G-set monad。

### 2.4 有限範疇與 Kan 擴張

- `FinCat`、`FinDiagram`、`FinFunctor`、limits/colimits；
- presheaves 與 Yoneda lemma 的機器驗證；
- comma categories、Lan/Ran Kan extensions；
- `Lan_{1→BG}=G×X`、`Ran_{1→BG}=X^G`；
- CSP 表達成 limit，並與 ListM 回溯搜尋互證。

### 2.5 由定理衍生的捷徑

- 分量分解的 |Aut| 積公式與派生生成元；
- 補圖一次搜尋得兩份規範形；
- Whitney 核階公式，由 |Aut(G)| 推出 |Aut(L(G))|；
- mark vector 免除 |X|! 枚舉；
- canonical fold、PermSet canonical key。

### 2.6 已知邊界

- 圖同構最壞成本仍可指數增長；
- `Graph` 只是簡單、無向、無標籤、無 vertex/edge colors 的圖；
- 不少列舉型 API 以 cap + `abort` 保護；
- `perm_key64` 要求底集 n≤12，連帶限制 G-集/marks/Cayley 的部分路徑；
- `subgroup_classes` 一般只列 ≤2 生成子群，群元素多時退化，mark vector 未必永遠是完整不變量；
- 群階以 Int64 表示，有溢位邊界；
- 動態剪枝 mode 2 的規範形可靠，但自同構生成元可能只生成子群。

另外發現一個文件小不一致：README 與測試稱 `prove_graph` 為 22 條，`theorem.mbt` 檔頭仍寫 21 條；正式搬遷時可順手修正。

---

## 3. cubical-hermitian 與 symlib 的重疊與互補

### 3.1 概念上高度同構的部分

| 主題 | cubical-hermitian | symlib | 合併意義 |
|---|---|---|---|
| 規範形 | NbE η-long normal forms、wiring、BDD、DTerm DAG、DSystem normal form | graph canonical labeling/encoding、mark vector、PermSet key | 可建立統一的「canonical form」設計語言與審計 |
| 等價 | Equiv、Iso、ua、Path/PathP、Glue | graph isomorphism、G-set isomorphism、category isomorphisms | graph 的顯式同構可提升為有限型別 equivalence/path 證書 |
| 範疇化 | Karoubi、face poset、cube category、syntactic CCC、CwF 觀點 | FinCat、limits、presheaf、Yoneda、Lan/Ran、action groupoid | symlib 可把 cubical 的有限範疇直覺變成可窮舉驗證的表格範疇 |
| 群/對稱 | wiring signed permutations、sphere loop representatives、dimension substitutions | 完整 PermGroup、Schreier–Sims、orbits、stabilizers、G-sets | cubical 目前缺少一般有限群引擎；symlib 正好補上 |
| 商 | quotient HIT、propositional truncation、system quotient | orbit quotient、folded graph、action groupoid skeleton | 可研究 coarse quotient 與 homotopy quotient 的橋 |
| 搜索/判定 | BDD、CDCL/DRUP、HOU、conversion case-split | IR graph search、ListM backtracking、CSP limit | 圖對稱可剪 BDD/SAT/DTerm 搜索；SAT/BDD 可反過來解 CSP |
| 證書 | CheckResult、SpecEntry、DRUP、代數證書、Jacobi 證書 | `Cert` 定理電池、雙算法互證 | 可統一成跨域 certificate bundle，但不應把不同證書語意混為一談 |
| 精確代數 | QPoly/QMat、根隔離、分裂域、Jordan、譜投影 | 群、圖、Cayley 圖、G-集 | 圖譜、置換表示、群平均投影、表示分解形成新功能 |

### 3.2 並非同一個「Kan」

必須在文件與命名上分清：

- symlib 的 **Kan extension** 是範疇論 Lan/Ran；
- cubical-hermitian 的 **Kan composition/filling** 是 cubical type theory 的 coe/comp/hcomp。

兩者都值得保留，但不能因同名就宣稱已互相實現。

### 3.3 代碼層面的碰撞很少

以 generated interfaces 做公開名稱交集：

- symlib 與 cubical root 的公開自由函數只發現一個同名：`decompose`；
  - cubical：向量在投影下的正交分解；
  - symlib：圖的連通分量分解；
- symlib 與 algebra 未發現同名公開符號；
- 檔案 basename 除不同目錄下的 `main.mbt` 外沒有 root library 檔案撞名。

但這只表示「搬作子套件」順利，不表示攤平入同一 package 是好主意。symlib 有大量通用名稱，例如 `Graph`、`Perm`、`Cert`、`analyze`、`isomorphic`、`search_graph`；若全放入 root，會污染 cubical 的公共命名空間，又會令測試的 `@symlib` 參照、架構層與審計分類大幅改寫。

---

## 4. 五種合併方式比較

| 方案 | 做法 | 優點 | 缺點 | 評價 |
|---|---|---|---|---|
| A. 攤平入 root package | symlib 26 個 library 檔全抄到 cubical 根目錄 | bridge 可直接用 root 私有細節 | 命名污染、root SCC 再膨脹、架構邊界消失、測試 import 大改、公共 API 混雜 | **不推薦** |
| B. 同 module 子套件 | `symlib/` 成為 cubical module 的獨立 package | 幾乎原碼不改、無同名問題、保留測試與 API、可逐步 bridge | import path 由 `arena/symlib` 變成 `vv0101v01/cubical-hermitian/symlib` | **推薦** |
| C. 保持外部 module 依賴 | cubical 依賴已發布的 `arena/symlib` | symlib API path 不變、倉庫可獨立發布 | 需要發布/版本治理；不是單倉單 module；離線與同步成本較高 | 適合仍要獨立發布 symlib 時 |
| D. Git submodule | algorithm03 原倉嵌作子目錄 | 歷史與邊界最清楚 | Moon 的 nested module 不會自然成為主 module 的 package；開發體驗差 | 不推薦作主方案 |
| E. 選取概念重寫入 kernel | 只把 PermGroup/G-set 等重寫成 DTerm/語義層功能 | 語意最深 | 失去 symlib 已驗證的搜尋性能與 67 個測試，成本最高 | 只適合後期選定題目 |

### 為何以 cubical-hermitian 做主模組

- 規模約為 symlib 六倍；
- 已有 `architecture.json`、符號審計、雙語 SPEC/GUIDE 與 90 項定理表治理；
- algebra 已是實體子套件，主模組已有「root + algebra」先例；
- cubical root 的互相遞迴 kernel 不適宜為遷就 symlib 而整體搬家。

代價是 symlib 的 import path 改變，但 API 的型別與函數名、以及 `@symlib` alias 都可以保留。

---

## 5. 推薦的目標架構

### 5.1 實體套件圖

```text
                         cmd/main ─────► root
                    cmd/symdemo ───────► symlib
                   cmd/symbench ───────► symlib
                    cmd/showcase ──────┬► root
                                       ├► symlib
                                       └► bridge

                              bridge ──┬► root
                                       ├► symlib
                                       └► algebra

                                root ──► algebra

                              symlib      algebra
                           （彼此獨立）  （彼此獨立）
```

原則：

- `symlib` 不知道 cubical kernel；
- `algebra` 不知道 symlib；
- root 不直接知道 symlib；
- 所有跨域轉換集中在 `bridge`；
- 若 bridge 需要 root 尚不能跨套件構造的表示，應在 root 增加小型、已驗證的 smart constructor，而不是把所有 struct 改成 `pub(all)`。

### 5.2 建議目錄

```text
symlib/
  moon.pkg
  pkg.generated.mbti
  action.mbt
  aut.mbt
  bitvec.mbt
  canon.mbt
  cat.mbt
  csp.mbt
  decomp.mbt
  dual.mbt
  fincat.mbt
  fold.mbt
  graph.mbt
  group.mbt
  gset.mbt
  line.mbt
  lut.mbt
  marks.mbt
  monad.mbt
  partition.mbt
  perm.mbt
  permset.mbt
  random.mbt
  report.mbt
  search.mbt
  theorem.mbt
  theorem_all.mbt
  yoneda.mbt
  symlib_test.mbt
  symlib_ext_test.mbt
  symlib_api_test.mbt
  symlib_wbtest.mbt

bridge/
  moon.pkg
  wiring_perm.mbt
  matrix_symmetry.mbt
  graph_spectrum.mbt
  group_projector.mbt
  face_category.mbt
  cell_incidence.mbt
  bridge_laws.mbt
  bridge_wbtest.mbt

cmd/symdemo/
cmd/symbench/
cmd/showcase/

docs/SYMLIB.md
docs/symlib/demo_output.txt
docs/symlib/bench_output.txt
```

`bridge/` 的檔案切分可以按實際實施順序逐個增加，第一版不需要一次建齊所有檔案。

### 5.3 algorithm03 其他檔案如何處理

| algorithm03 檔案 | 合併後處理 |
|---|---|
| root 26 個 library `.mbt` | 搬入 `symlib/`，原則上不改 |
| 4 個測試 `.mbt` | 搬入 `symlib/`，原則上不改 |
| root `moon.pkg` | 搬入 `symlib/moon.pkg` |
| root `pkg.generated.mbti` | 不手搬；於新位置以 `moon info` 重新生成 |
| `cmd/main/*` | 搬入 `cmd/symdemo/`，import path 更新 |
| `cmd/bench/*` | 搬入 `cmd/symbench/`，import path 更新 |
| `README.mbt.md` | 改成 `docs/SYMLIB.md` 或 `symlib/README.md`，更新路徑/命令 |
| `docs/*_output.txt` | 搬到 `docs/symlib/`，或合併後重新產生 |
| `moon.mod` | 不搬；主 module 只保留 cubical 的一份 |
| `LICENSE` | 與主專案相同，不重複搬 |
| `AGENTS.md` | 內容併入主專案 AGENTS 的 symlib 小節，不保留第二份根文件 |
| `.githooks/`、`.github/` | 不直接覆蓋；按主倉現行治理取捨 |

### 5.4 Git 歷史

若要保留 algorithm03 的提交歷史，建議用 subtree/read-tree 方式先把 `05232fd` 快照與歷史導入，再做機械搬位；若只求代碼合併，普通複製也可以，但提交訊息與 `docs/SYMLIB.md` 必須記錄來源倉庫與來源 commit `05232fd`。

無論採哪種方式，第一個合併提交應只做搬位與 import path 改變，不要同時改演算法，以便用 symlib 原 67 個測試證明搬遷無行為改變。

---

## 6. 已完成的原型實證

研究時建立了 `/tmp/cubical-sym-proto`，內容包括：

1. cubical-hermitian 原專案副本；
2. algorithm03 root `.mbt` 原封不動放入 `symlib/`；
3. `cmd/main` 搬成 `cmd/symdemo`；
4. `cmd/bench` 搬成 `cmd/symbench`；
5. 兩個 cmd 的 import 由：
   - `arena/symlib`
   改為：
   - `vv0101v01/cubical-hermitian/symlib`
6. 新增一個 `bridge/` 套件，同時 import cubical root 與 symlib。

結果：

| 驗證 | 結果 |
|---|---|
| algorithm03 原倉 `moon fmt --check` | 通過 |
| algorithm03 原倉 `moon check --deny-warn` | 通過 |
| algorithm03 原倉 `moon test` | 67/67 |
| algorithm03 `moon run cmd/main` | 通過 |
| algorithm03 `moon run cmd/bench` | 通過 |
| 原型全模組 `moon check --deny-warn` | 通過 |
| 原型 `moon test symlib` | 67/67 |
| 原型 `moon test bridge` | 1/1 |
| 原型 `moon test symlib bridge` | 68/68 |
| 原型 `moon run cmd/symdemo` | 通過 |

一個實作細節：若執行套件目錄也叫 `cmd/symlib`，Moon 會警告它與 library package 的預設 alias `symlib` 重複；改名 `cmd/symdemo` 後警告消失。

### 原型 bridge 做了什麼

原型新增了四個跨套件函數：

- `matrix_support_graph(CMat) -> Graph`
- `perm_preserves_matrix(CMat, Perm) -> Bool`
- `matrix_permutation_symmetries(CMat, cap) -> Array[Perm]`
- `check_matrix_symmetry_bridge() -> Bool`

流程是：

1. 把 cubical 的複矩陣非零支撐建成 symlib `Graph`；
2. 用 symlib 算 support graph 的自同構群；
3. 列舉群元素，再用 cubical 的複數近似相等逐項過濾真正保持全部矩陣權重與對角元的置換。

驗證例：

- `[[1,2,0],[2,1,0],[0,0,3]]` 有交換前兩座標的對稱，共 2 個；
- cubical 的 `example_projector()` 支撐圖表面上可交換前兩座標，但兩個非對角權重互為共軛而非相等，所以只剩恆等，共 1 個。

這證明了不只是「兩個 library 可以放在同一 repo」，而是已能用兩邊的公開 API 組成一個任一邊單獨沒有的功能。

---

## 7. 合併後的功能版圖

以下分三層，避免把「放在同一 repo」誤說成「所有深層整合已完成」。

### 7.1 Day-1：機械合併即可用

#### cubical 側原功能

- Hermitian 冪等投影、特徵空間、正交分解與 Kan pruning；
- 簡單型別、依賴型別與 cubical AST 三層 NbE；
- Π/Σ/PathP/Glue/資料/HIT/Universe 的 coe/comp/hcomp；
- 通用 inductive/HIT schema、互歸納、同時 IR、宇宙多態；
- Iso→Equiv→Path、ua、pathToEquiv、一般 lemIso 纖維收縮；
- 球面與圓的代表元分類；
- BDD、DPLL/CDCL/DRUP、face/system 判定；
- 精確有理與代數數、因式分解、根隔離、分裂域、Jordan、Jacobi；
- HOU elaborator、參數化模組、分離編譯、二進位格式、工件完整性鏈。

#### symlib 側原功能

- 圖 canonical form、digest、同構判定與顯式同構；
- Aut 群生成元、群階、軌道、穩定子、元素表；
- 分量分解、補圖對偶、線圖/Whitney 三條衍生通道；
- 群作用、Burnside、orbit folding；
- G-集、mark vector、table of marks、Cayley 圖；
- 有限範疇、limits/colimits、presheaf、Yoneda、Lan/Ran；
- ListM/StateM、單子搜尋與 CSP；
- 22/9/20 型式的定理證書電池（`prove_graph` 依輸入生成）。

#### 統一入口

建議最後形成：

```bash
moon run cmd/main      # cubical 90 項定理表（保持兼容）
moon run cmd/symdemo   # symlib 全模組演示
moon run cmd/symbench  # symlib 基準與衍生演算法對照
moon run cmd/showcase  # 跨域統一報告：cubical + symlib + bridge
moon test              # 全部套件測試
```

### 7.2 Bridge 1.0：最值得先做的跨域功能

#### B1. Perm ↔ Wiring ↔ Equiv/UPath

cubical 的有限型別等價以 signed-permutation `Wiring` 為規範形；symlib 有一般 `Perm` 與 `PermGroup`。

建議新增：

- root 有限層提供已驗證的 `wiring_from_leaf_maps(...) -> Wiring?`；
- bridge 提供：
  - `perm_to_wiring(p, leaf_kinds) -> Wiring?`
  - `wiring_to_perm(w) -> Perm?`（只接受無號、無 Unit 常量葉的片斷）
  - `signed_wiring_perm(w) -> (Perm, Array[Bool])?`
  - `perm_group_of_wirings(...) -> PermGroup`
  - `graph_adjacency_wiring(p, n)`：把頂點置換提升為鄰接矩陣 Bool 葉的座標置換。

新能力：

- symlib 找到的圖同構/自同構，可以變成 cubical 有限宇宙內的 `Equiv` 與 `ua` 路徑；
- 一組 wiring 生成的對稱群可用 Schreier–Sims 算階、軌道與穩定子；
- 可用 PermGroup 的 stabilizer 與 graph Aut 互相差分驗證。

重要邊界：`Wiring` 是「輸出葉引用哪個輸入葉」的映射，座標置換方向必須以定律固定，不能只憑直覺寫 `p.apply(i)`。

#### B2. 矩陣與投影的置換對稱群

把原型擴展到：

- 浮點 `CMat`（近似、探索用）；
- 精確 `QMat`；
- `CertMat` / `QuadC`；
- 後續可再考慮 `AlgMat`。

建議輸出：

- support graph；
- 保持全部 entries 的置換群生成元；
- 座標軌道；
- 兩矩陣之間的 permutation-similarity 判定與顯式置換；
- 每個生成元對應的 permutation matrix `U_p`，並檢查 `U_p H = H U_p`、`U_p† U_p=I`。

第一版原型用「列舉 support Aut 元素再過濾」，小矩陣可行但群大時昂貴。正式版應研究：

- 給 symlib 搜尋加 initial vertex colors，顏色編碼對角元與入/出權重類；或
- 用顏色穩定的編碼圖；或
- 在 PermGroup 上做 partition/entry stabilizer。

不能只看 support 就宣稱矩陣對稱，權重、對角元與方向都必須重驗。

#### B3. Graph → 精確譜資料

bridge 可把：

- `Graph` → adjacency `QMat`；
- `Graph` → Laplacian `QMat`；
- 再用 algebra 算 characteristic polynomial、minimal polynomial、因式分解、實根隔離、Jordan/primary projectors；
- 對 Hermitian/對稱矩陣可用認證 Jacobi 區間。

新能力：

- 圖的精確譜不變量與重標號不變性定律；
- 以譜資料輔助區分圖或作搜尋前篩選；
- Cayley 圖、超方體、Petersen 等圖族可同時給 Aut 群與譜證書。

但譜不是圖同構的完全不變量，cospectral 非同構圖存在；文件中必須寫明它是輔助不變量，不可取代 canonical form。

#### B4. 群平均投影（最能代表合併的旗艦功能）

對有限群的置換表示，定義：

$$
P_G = \frac{1}{|G|}\sum_{g\in G} U_g.
$$

每個 `U_g` 是 permutation matrix，所以 `P_G` 是 Hermitian 冪等投影。對點作用，它投影到在每個 orbit 上常值的向量子空間，秩等於 orbit 數。

bridge 可提供：

- `permutation_matrix_cmat(p) -> CMat`
- `permutation_matrix_qmat(p) -> QMat`
- `group_averaging_projector_cmat(group, cap) -> CMat?`
- `group_averaging_projector_qmat(group, cap) -> QMat?`
- `check_group_averaging_projector(...)`

驗證內容：

- `P²=P`、`P†=P`；
- `trace(P)=#orbits`；
- 每個群元素都與 P 交換；
- image 由 orbit-constant vectors 張成。

這把 symlib 的群作用直接送進 cubical-hermitian 的中心物件——Hermitian projector 與特徵空間分解，是合併後最自然的新定理。

限制：現有做法若列舉群元素，只適合小群；大群要改用 orbit 指標直接建 block-constant matrix，或用生成元與線性方程算不變子空間。

#### B5. Face lattice、有限範疇與 cubical shapes

可以把有限維 face lattice 的 BDD 等價類建成 symlib `FinCat` 的 poset category，驗證：

- ∧ 是 product；
- ∨ 是 coproduct；
- ⊤/⊥ 是 terminal/initial；
- 與 cubical 既有 face poset 定律一致。

再進一步，可把有限截斷的 cube shapes、cell incidence 或 HIT schema 編成有色 incidence 結構，算：

- canonical key；
- cell automorphism group；
- schema 在 cell 重命名下的同構；
- orbit representatives。

限制：symlib `Graph` 目前無向、無色、無序；cell 的維數、方向、參數與邊界次序不能隨便丟失。正式版宜先給 symlib 搜尋加 initial colors，或設計經證明的 rigid gadget 編碼。

#### B6. 統一證書與結構報告

symlib 的 `Cert` 是 `pub(all)`，可由 bridge 構造；cubical 的 `CheckResult` 可跨套件讀取欄位。因此 `cmd/showcase` 或 bridge 可把：

- cubical `run_all_checks()`；
- symlib `prove_all(cap)` 與選定圖的 `prove_graph` / `prove_pair`；
- bridge `check_*`；

統一打印成一份報告。但內部仍應保留來源標籤，因為：

- cubical `CheckResult` 是全域定理表的一項 Boolean 總檢查；
- symlib `prove_graph` 是依某個輸入生成的證書；
- DRUP、代數證書、Jacobi 證書各有自己的 checker 語意。

統一展示不等於把所有證書壓成同一種證明物件。

### 7.3 可以形成的「一站式」新 API

以下為建議設計，不是現有 API：

```moonbit nocheck
let g = @symlib.Graph::petersen()
let aut = @symlib.automorphism_group(g)
let adjacency = @bridge.graph_adjacency_qmat(g)
let charpoly = @algebra.qmat_charpoly(adjacency)
let projector = @bridge.group_averaging_projector_qmat(aut, 1000)
let report = @bridge.analyze_graph(g)
```

一個 `analyze_graph` 將來可一次回傳：

- canonical digest 與 canonical labeling；
- Aut 生成元、群階、頂點/邊軌道；
- G-集與 mark 資料（規模許可時）；
- adjacency/Laplacian 特徵多項式與精確特徵值隔離；
- 群平均投影及其秩；
- 與重標號圖之間的 wiring/Equiv/UPath；
- 一組可重驗的跨域證書。

反方向，一個 `analyze_hermitian` 可回傳：

- projector/譜分解；
- support graph；
- 置換對稱群與座標軌道；
- 與對稱群交換的置換酉矩陣；
- 群平均投影；
- 精確影子與數值殘差。

### 7.4 更深層、適合後期研究的功能

這些不是機械合併後自動出現的，應列為後續期數：

1. **有色圖搜尋**：給 symlib IR 引擎加 vertex colors / ordered incidence，支援矩陣權重、CNF、DTerm DAG、cell complexes。
2. **Face/CNF 對稱剪枝**：把變量、字面與子句建成有色 incidence graph，算 dimension renaming group；用 orbit representatives 改進 BDD subset-DP、case-split 或 CDCL symmetry breaking。DRUP 必須把新增 symmetry-breaking 子句的正當性交代清楚。
3. **DTerm DAG 的重命名規範形**：在 alpha/dimension renaming 下比較項 DAG。現有 hash-cons 是精確結構身分，不會自動給 renaming quotient；有序、有標籤 DAG 的編碼要另行證明。
4. **G-集 → cubical homotopy quotient**：把有限 G-集編成點、作用路徑與相干 2-胞的 HIT，比較 coarse quotient `X/G`、homotopy quotient `X//G` 與 symlib 的 groupoid cardinality。
5. **有限 cubical sets / presheaves**：以 FinCat 的截斷 cube category 與 presheaf/Yoneda 機器研究 representable cubes、cell orbits 與 quotient cell complexes。
6. **表示論分解**：置換表示、regular representation、commutant、isotypic projectors。完整 character theory 需要元素共軛類、cyclotomic/splitting fields 與 character table，是獨立大題目。
7. **HIT/schema 的對稱生成**：用 cell automorphism group 產生等變的 dimension maps 或檢查 schema 在置換座標/參數後是否同構。
8. **工件層整合**：以 canonical digest 作為 graph/cell artifact 的內容鍵，再由既有 CHARTCHN 保存歷史；但 digest 不是密碼雜湊，仍需既有 integrity 設計。

---

## 8. 實施路線建議

### Phase M1：機械搬遷（先證明零行為改變）

工作：

1. 導入 algorithm03 `05232fd`；
2. 建立 `symlib/`、`cmd/symdemo/`、`cmd/symbench/`；
3. 只改 cmd import path；
4. 重新生成三個新套件的 `.mbti`；
5. symlib 文件搬到 `docs/SYMLIB.md` 並記錄來源 commit；
6. 不改 cubical root 的演算法與定理表。

驗收：

- `moon fmt`
- `moon info`
- `moon check --deny-warn`
- `moon test symlib cmd/symdemo cmd/symbench`（或等價 targeted 指令）
- symlib 仍 67/67；
- `moon run cmd/symdemo`、`moon run cmd/symbench` 可跑。

提交建議：一個「import algorithm03 as symlib subpackage」提交，方便審查與回退。

### Phase M2：架構與審計治理

工作：

1. `architecture.json` 新增：
   - package `symlib`（layer 1、無本地依賴）；
   - package `bridge`（layer 3，依賴 root/symlib/algebra；若 M2 尚未建立 bridge，可延至 M3）；
   - packages `cmd-symdemo`、`cmd-symbench`、`cmd-showcase`；
   - component `finite-symmetry`；
   - component `symmetry-bridge`；
   - tests wildcard 擴至 `symlib/*`、`bridge/*`。
2. `tools/arch_check.py` 目前把 package 路徑與 resolution order 硬編成 root/algebra/cmd-main 三套件，必須改為由 manifest 的 package path 與依賴閉包一般化推導。
3. `tools/audit_spec.py`：
   - parser 要支援 symlib 大量使用的 `pub(all) struct/enum`（現行 top-level regex 只認 `pub struct` 等，會漏算）；
   - classify 要改成 package-aware，至少能分開 root 的 `decompose` 與 symlib 的 `decompose`；
   - 新增 symlib/bridge 的規格族與雙語說明，例如：
     - 有限置換與 Schreier–Sims；
     - 圖規範形與自同構搜尋；
     - 群作用、G-集與 Burnside 環；
     - 有限範疇、預層、Yoneda 與 Kan 擴張；
     - 圖衍生通道；
     - 單子搜尋與 CSP；
     - 對稱橋接。
4. 雙附錄重新生成；總符號數會由 3,523 增至約三千九百餘（實際數以修正後 parser 為準）。
5. SPEC/GUIDE/README/ARCHITECTURE/AGENTS 同步套件圖與新命令。

驗收：

- `python3 tools/arch_check.py`
- `python3 tools/audit_spec.py --check`
- 全量 `moon test`，預期至少 178 個既有測試；
- `moon run cmd/main` 仍 90/90（此階段不把 symlib 的依輸入證書硬塞進 90 項總表）。

### Phase M3：Bridge 1.0

優先順序：

1. B2 矩陣置換對稱：先把原型正式化，再做 QMat 精確版；
2. B4 群平均投影：CMat 與 QMat 兩版；
3. B3 Graph→QMat 譜資料；
4. B1 Perm↔Wiring；
5. B5 face poset→FinCat 的小型對照；
6. `cmd/showcase` 統一報告。

每一項都要有 `check_*` 定律與白盒/黑盒測試，並決定是否登記入主 SPEC。建議 bridge 定律先由 showcase 匯總；成熟後再考慮是否把少數全域 bridge 檢查升入 90 項主定理表。

### Phase M4：深層整合研究

候選題目按價值與風險排序：

1. symlib native colored graph search；
2. Face/CNF/BDD 的對稱群與 orbit-quotient DP；
3. HIT cell incidence 的規範形與自同構；
4. G-集到 cubical homotopy quotient；
5. DTerm DAG 的 renaming quotient；
6. 表示論與 isotypic projectors。

每項都應獨立成一期，不宜與機械搬遷混在同一提交。

---

## 9. 風險與不應過度宣稱之處

### 9.1 API 與發布

- `arena/symlib` 的舊 import path 在子套件方案下會改變；若 algorithm03 已有外部使用者，應保留舊倉一段時間並標示遷移。
- 合併後 module 名仍叫 `cubical-hermitian`，但產品範圍已擴大；可先改文件副題，不必第一天就改 module 名稱，否則所有 import 都要再改一次。
- 版本號建議在正式合併後至少升至能反映新增子套件的版次；具體 version 應待發布策略決定。

### 9.2 型別與錯誤處理風格

- symlib 多數公開型別是 `pub(all)`，外部可直接構造未經驗證的 `Graph`、`Perm`、`PermGroup`；bridge 對跨套件輸入要重驗不變量，或只接受由 symlib 構造器產生的值。
- cubical 多數公開 struct 是 readonly，bridge 不能直接構造 `Wiring` 等值；需要 root 提供 smart constructors。
- symlib 多處以 `abort` 表達 cap/前提失敗，cubical 常用 Option/status。第一版 bridge 要嘛先驗證前提，要嘛在文件明示 abort 邊界；長期可為 bridge 設計 status 型 API，但不應為統一風格而大改 symlib 內部。

### 9.3 數學語意

- support graph 的自同構不自動是加權矩陣的對稱；
- 圖譜不決定圖同構；
- mark vector 只在子群共軛類列舉完整時才是完全不變量；
- Kan extension 與 Kan filling 是兩回事；
- orbit quotient 是 0 截斷的粗商，不自動給 cubical homotopy quotient 的高維相干；
- 浮點矩陣的「對稱」只是 eps 近似，證書級結論應走 QMat/CertMat 精確版；
- graph search、HOU、BDD/SAT 與精確代數各自的最壞成本邊界在合併後仍然存在。

### 9.4 工具與維護

- cubical 全量測試本身已很長；symlib 的 67 個測試只增加數秒，但 bridge 若把昂貴 kernel 定律與圖搜尋相乘，成本可失控，定律必須選小而具代表性的例子。
- 雙語 SPEC 與逐符號附錄是本專案的治理承諾；新增約四百個 symlib 公共宣告後，分類工作不可省略，否則 audit 會失去意義。
- algorithm03 的 README 很完整，但路徑、命令與「本庫」敘事都要改寫，不能原樣當主 README。

---

## 10. 最終建議

值得合併，而且合併的數學理由充分：兩邊都在做「有限結構的規範形、等價與證書」，只是 cubical-hermitian 偏向依賴型別/路徑/譜投影，symlib 偏向置換群/圖/有限範疇。它們不是兩個無關 library 硬拼，而是同一套「結構、對稱與等價」世界觀的兩個半邊。

建議的執行決策是：

1. **主模組**：保留 `vv0101v01/cubical-hermitian`；
2. **algorithm03**：成為 `symlib/` 子套件；
3. **第一提交**：只搬遷，67/67 原測試保綠；
4. **第二提交**：架構與審計工具一般化、雙語文件同步；
5. **第三階段**：建立 `bridge/`，先做矩陣對稱、群平均投影、圖譜與 Perm↔Wiring；
6. **統一入口**：新增 `cmd/showcase`，不要破壞既有 `cmd/main` 的 90/90 語意；
7. **深層題目**：有色圖、SAT/BDD 對稱、HIT 商與表示論分期處理。

合併後最準確的一句話定位是：

> **一個以 cubical 路徑與 Hermitian 投影為連續/型別論一端、以圖規範形與有限群作用為離散/組合一端，並由精確代數、有限範疇與可驗證證書連起來的 MoonBit 計算數學系統。**
