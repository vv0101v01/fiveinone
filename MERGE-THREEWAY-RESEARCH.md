# algorithm01 × algorithm02(cubical-hermitian) × algorithm03(symlib) 三方合併重新評估

日期：2026-10-27

基準版本：

- `algorithm01/semiring-lab`：GitHub `vv0101v01/algorithm01`，`main@6a208f4`
- `algorithm02/cubical-hermitian`：第十三期整合版本（本地整合提交 `f3a8238`）
- `algorithm03/symlib`：GitHub `vv0101v01/algorithm03`，`main@05232fd`
- 前版兩倉研究：`MERGE-SYMLIB-RESEARCH.md`（本文新增 algorithm01 後重新裁決）

## 一、先給答案：我支持合併嗎？

## 支持，但只支持「聯邦式三方合併」，不支持攤平式大融合。

我的評分為：

- **三方聯邦式合併：支持，8/10。**
- 只把三個 repo 放在同一 Git monorepo、保持三個 MoonBit module：**中度支持，6/10。**
- 新建一個中性 umbrella module、把 cubical root 也搬入子套件：**可以，6.5/10，但遷移成本較高。**
- 把三邊攤平進 cubical root／現有 algebra、做成單一巨型套件：**反對，2/10。**
- 三者永遠完全分開：**4/10。維護最簡單，但浪費最有價值的橋接能力。**

我支持的首選形狀是：

```text
vv0101v01/cubical-hermitian          現有 cubical 根套件，不搬
├── algebra/                         現有精確 BigInt 代數，不搬、不改名
├── symlib/                          algorithm03 根套件整包搬入
├── semiring/                        algorithm01 命名空間
│   ├── algebra/                     半環 traits/實例（與 /algebra 分開）
│   ├── matrix/
│   ├── monoid/
│   ├── graph/
│   ├── spline/
│   ├── trop/
│   ├── nf/
│   ├── cat/
│   ├── app/
│   ├── bp/
│   ├── ratelimit/
│   ├── io/
│   ├── sim/
│   ├── par/
│   ├── par_host/                    第二階段，native/async
│   └── examples/
├── bridge/                          三方橋接，單向依賴三邊
└── cmd/
    ├── main/                        現有 cubical 90/90 登記
    ├── symdemo/
    ├── symbench/
    ├── semiringreport/              第二階段
    └── showcase/
```

### 為甚麼加入 algorithm01 後，我反而更支持合併？

三者各自回答一個核心問題：

| 支柱 | 核心問題 | 代表能力 |
|---|---|---|
| cubical-hermitian | 路徑、等式與高維結構怎樣計算？ | cubical 內核、Kan、NbE、Glue/ua、精確代數、Hermitian 譜、BDD/DRUP |
| symlib | 有限結構何時相同？有甚麼對稱？ | 圖規範標號、自同構群、Schreier–Sims、軌道、有限範疇、Yoneda、G-集 |
| semiring-lab | 沿所有路徑聚合時，最佳／可達／總和是甚麼？ | 半環矩陣星閉包、最短路、Pareto、熱帶幾何、Kleene 正規形、因子圖推論 |

它們不是三堆不相干的算法，而是三種「路徑代數」：

1. **cubical paths**：路徑本身是等式證明，可逆、可合成、可升到高維。
2. **graph/category paths**：路徑在圖、自由範疇與有限範疇中合成。
3. **semiring paths**：路徑不再只問存在與否，而以半環把所有路徑聚合成距離、機率、瓶頸、計數或 Pareto 前沿。

再由 symlib 回答「哪些路徑／標號在對稱下其實是同一個」，便形成完整的

> **生成路徑 → 以代數聚合路徑 → 以對稱與規範形判定等價 → 把結果升回型別／範疇／譜結構。**

這就是我支持三方合併而不只是兩兩合併的根本理由。

### 我支持的條件

支持不是無條件。必須同時滿足：

1. **保留套件邊界**：cubical root、精確 algebra、symlib、semiring 子套件不互相攤平。
2. **橋接只放上層 `bridge/`**：三個支柱不得為了展示而互相反向依賴。
3. **semiring 數學核心先入，native host 後入**：`par_host` 與 `cmd/semiringreport` 牽涉唯一外部依賴 `moonbitlang/async`，應第二階段單獨決策。
4. **治理工具先泛化**：架構與符號審計必須能處理約 25 個套件、泛型方法、`pub(all)` 與 `pub(open) trait`，不能合併後降低現行紀律。
5. **產品身份要擴寬**：合併後不再只是「一個 cubical type theory 專案」，而是一個 MoonBit 結構算法平台；`ratelimit` 等應用套件應明確標成外圍應用，不得偽裝成內核。

若目標是維持一個非常聚焦的 cubical 內核產品，我會改投反對把 algorithm01 的應用／host 層納入同一身份；但若目標是建立長期累積的數學算法 monorepo，三方合併是合理方向。

---

## 二、重新盤點：algorithm01 是甚麼？

`algorithm01` 的 MoonBit module 是 `arena/semiring-lab`，不是單一套件，而是一個已模組化的半環算法實驗室：

- 版本 `0.1.0`，Apache-2.0。
- `preferred_target = "native"`。
- 唯一外部 module 依賴：`moonbitlang/async@0.22.5`，只供 `par_host`。
- 15 個 library packages，另加 `examples` 與 `cmd/report`，共 17 份 `moon.pkg`。
- 61 個 `.mbt`，16,532 行；17 個測試檔，158 個 native 測試。
- 17 份 generated interfaces，共約 1,439 行；粗計 547 個 `pub fn` 行、56 個 structs、3 個 enums、10 個公開 traits。
- 文件：`README.md` 378 行、`docs/DESIGN.md` 915 行、可重跑生成的 `REPORT.md` 717 行／19 節。

### 本地實跑（非只引用 README 宣稱）

已在新 clone 上核實：

- 首次因 registry 尚無 `moonbitlang/async` 而需 `moon update`；更新後：
- `moon fmt --check`：通過。
- `moon check --deny-warn`：native / js / wasm / wasm-gc 四 target 全通過。
- `moon test`：**158/158**（native）。
- 原倉工作樹保持乾淨（`.mooncakes` 為依賴快取）。

### algorithm01 套件分層

| 層 | 套件 | 與三方平台的關係 |
|---|---|---|
| 數學核心 | `algebra` | `Semiring`、`IdempotentSemiring`、`StarSemiring`、`TropicalSemiring`、`Monoid` 等 10 個 traits，Trop/Prob/Bool/Counting/Pareto/Bottleneck、定律檢查器與 Ops 計數。是 semiring 支柱地基。 |
| 線性／路徑計算 | `matrix`、`graph`、`monoid`、`app` | 泛型稠密/CSR 矩陣、Kleene 星閉包、Dijkstra/APSP/Pareto、prefix scan、代數路徑問題多實作仲裁。與 cubical 精確矩陣、symlib 圖論互補最強。 |
| 幾何／範疇／正規形 | `trop`、`cat`、`nf`、`bp`、`spline` | 熱帶多項式與對偶曲線、集合值矩陣/自由範疇/Maslov 去量子化、regex-DFA 與冪等半環正規形、因子圖 BP、樣條。是「正規形與範疇化」樞紐。 |
| 效能基礎設施 | `par`、`sim`、`io` | 後端抽象縫、時鐘/快取模擬、邊表快速載入。可服務三邊 benchmark，但目前 `par_for` 多數 target 仍是誠實序行，不應誇大成真並行。 |
| 宿主／應用外圍 | `par_host`、`ratelimit`、`cmd/report` | native async 檔讀、GCRA 限流器、約 70 秒報告生成器。工程價值真實，但與 cubical 內核距離最遠，須分階段與分身份管理。 |

---

## 三、三方規模與合併後體量

| 項目 | cubical | symlib | semiring-lab | 粗合計 |
|---|---:|---:|---:|---:|
| `.mbt` 檔案 | 112 | 33 | 61 | **206** |
| `.mbt` 行數 | 71,816 | 12,037 | 16,532 | **100,385** |
| 測試檔 | 30 | 4 | 17 | 51 |
| 既有 test blocks | 111 | 67 | 158 native / 154 wasm | 336（跨 target 最大口徑） |
| 實體 library/cmd 套件 | 3 | 3 | 17 | 未計 bridge/showcase 共 23 |

合併後物理套件約為：

- cubical：root、algebra、cmd/main（3）
- symlib：symlib、cmd/symdemo、cmd/symbench（3）
- semiring：16 個 library/examples 套件 + cmd/semiringreport（17）
- 新增：bridge、cmd/showcase（2）

**合計約 25 個實體套件。**

需誠實區分 target 測試口徑：

- 現行 cubical／symlib 以 wasm 為主：111 + 67。
- semiring 在 wasm-gc 為 154，native 多出 4 個 host 測試為 158。
- 因此未來合併 module 若保留 `preferred_target="wasm"`，既有測試的算術總數約為 **332**，另加 bridge 測試；不能把不同 target 數字無說明地相加成單次 336。
- `cmd/semiringreport` 在三方原型中重跑需 66.2 秒，不宜列入每次快速閘門。

### 三方資料模型並不重複

三邊至少有五種矩陣／圖表示，均有存在理由：

| 表示 | 所屬 | 係數／語義 |
|---|---|---|
| `CMat` | cubical root | Double 複數、Hermitian 譜與投影 |
| `QMat`/BigInt 矩陣工具 | cubical algebra | 精確有理／代數數計算 |
| `Graph` | symlib | 無向、無權簡單圖；同構與自同構 |
| `Mat[E]`、`Csr[E]` | semiring matrix | 任意半環係數；星閉包與稀疏路徑 |
| `Graph` | semiring graph | 有向、帶權 CSR；距離、閉包、Pareto |
| `DiGraph`/`SetMat` | semiring cat | DAG 自由範疇、集合值路徑證人 |

這不是「重寫一份統一矩陣就能消掉」的重複，而是三種數學世界。正確做法是**轉換函數與橋接定理**，不是強行共用一個底層型別。

---

## 四、三組兩兩關係

### 4.1 cubical × semiring-lab

#### 互補

1. **面格就是冪等半環的一個候選模型**
   - cubical 的 `Face` 是有界分配格，join/meet 天然給出冪等半環結構（方向依偏序約定）。
   - 未來 bridge 可用 wrapper 把 `Face` 送入 semiring 定律檢查器，並以半環矩陣閉包處理胞腔可達性／系統相容傳播。
   - 這不是現有 API 已完成的事，但數學對接點非常具體。

2. **精確多項式 × 熱帶幾何**
   - cubical algebra 有 BigInt 有理、多元多項式、因式分解與實根隔離。
   - semiring trop 有 Newton 多邊形、熱帶根、熱帶曲線對偶與 balancing。
   - 只需一層 valuation／係數投影 adapter，便可把普通多項式送去 tropicalization，比較「精確因式分解」與「熱帶根重數／細分」。

3. **兩種矩陣世界**
   - cubical QMat 回答場上的精確線性代數；semiring Mat 回答無減法世界中的路徑聚合。
   - Maslov dequantization 是兩者的概念橋：普通加乘在極限下變成 min-plus。semiring cat 已有實作，cubical algebra 可提供精確對照組。

4. **約束求解的另一支**
   - cubical 已有 BDD、DPLL/DRUP、HOU 與系統補全。
   - semiring bp 在因子圖上做 sum-product / max-product；同一棵樹上 BP 精確、暴力邊際可仲裁。
   - 合併後可形成「精確決策（BDD/SAT）× 代數推論（BP）× 有限極限（CSP）」的約束工具箱，但三者語義不同，不能混稱同一個 solver。

5. **樣條與多項式立方**
   - spline 的仿射遞迴由 monoid scan 加速；cubical 的多項式立方與 Kan 填充是精確邊界世界。
   - 短期只能共用測試／量測方法；若要把 Double 樣條送入精確有理多項式驗證，需新增有理化與誤差證書，不能直接宣稱已打通。

#### 重疊

- 「algebra」一詞在兩邊完全不同：
  - cubical `algebra/`：域、環、多項式、代數數等精確計算；
  - semiring `semiring/algebra/`：trait 階梯與半環／么半群實例。
- 兩邊都有 `Rat`、矩陣、圖與正規形語言，但數域、精度及問題不同。
- cubical 以 wasm 為 preferred target；semiring 上游以 native 為 preferred target。
- cubical 儘量把宿主能力排除在核心外；semiring `par_host` 導入 async 與檔案系統。

### 4.2 symlib × semiring-lab

這組互補最直接，幾乎可立即產生新功能：

| 主題 | symlib | semiring-lab | 合併增益 |
|---|---|---|---|
| 圖 | 無向無權、規範形、Aut 群 | 有向帶權、APSP、Pareto、閉包 | 同一圖同時回答「對稱是甚麼」與「最佳路徑是甚麼」 |
| 範疇 | 一般有限範疇、預層、Yoneda、Kan | DAG 自由範疇、集合值矩陣 | 具體路徑範疇可嵌入一般有限範疇並互校 hom 集／路徑數 |
| 群 | 有限置換群、Schreier–Sims | 群元星和、循環群半環實例 | 可研究群代數、置換表示與加權 Cayley 圖 |
| 正規形 | 圖規範標號、marks 向量 | DFA 最小化、冪等半環多項式正規形 | 有限結構至少有三種可比較的規範形機器 |
| 搜尋／CSP | 有限極限 CSP | 因子圖 BP、代數路徑仲裁 | 精確列舉、極限語義與訊息傳遞互校 |

#### 最重要限制

- symlib 的圖自同構搜尋只懂無色簡單圖；semiring 圖有方向、多維權重與邊次序。橋接可先忘記成支撐圖找候選、再加權篩選，但這不是有色圖搜尋的完整替代品。
- semiring `cat` 的自由範疇要求 DAG；symlib FinCat 可有環。嵌入方向是 semiring→symlib，反向不能假裝任意有限範疇都是 DAG 自由範疇。
- 術語必須正名：
  - **monoid = 么半群**（algorithm01）
  - **monad = 單子／單子函子**（algorithm03）
  兩邊文件目前都用「單子」譯法，合併文件若不統一，讀者會誤以為同一概念。

### 4.3 cubical × symlib

維持前版結論，最有價值橋接依次為：

1. `Perm ↔ Wiring/Equiv` 與 Glue/ua 證書；
2. CMat／投影子的置換穩定子與群平均投影；
3. Face、BDD、CNF、DTerm DAG 的對稱削減（須有色搜尋）；
4. FinCat／預層與 cubical 範疇的有限見證；
5. 胞複形圖譜、G-集與同倫商。

semiring 加入後，cubical×symlib 不再只是二邊互補，因為 semiring 為它們提供了「加權路徑／星閉包」這條第三軸：圖對稱可用於壓縮路徑問題，路徑閉包又可反過來產生範疇與面格問題。

---

## 五、合併方式重新評分

### 方案 A：同一 repo + 同一 MoonBit module，命名空間聯邦（推薦）

- 現有 cubical module 續存。
- algorithm03 放 `symlib/`。
- algorithm01 放 `semiring/*`。
- `bridge/` 單向依賴三邊。
- semiring host 層第二階段。

優點：

- Moon 套件路徑天然隔離兩份 `Graph`、兩份 `algebra` 與各種 `Rat`。
- bridge 可直接 import 三邊型別，無跨已發布 module 版本問題。
- 一次工具治理可覆蓋全部套件。
- algorithm01 既有套件不必再拆。

缺點：

- module 名稱 `cubical-hermitian` 對 umbrella 身份偏窄。
- import path 對 algorithm01/03 是 breaking change。
- 若納入 async，整個 module 多一個 registry 依賴。

**結論：支持，8/10。**

### 方案 B：新建中性 umbrella module

例：新建 `vv0101v01/structural-algorithms`，把 cubical root 移到 `cubical/`，再放 `symlib/`、`semiring/*`。

優點：產品命名最乾淨，三支柱形式平等。

缺點：

- 最大、文件最多、治理最深的 cubical root 要整包搬家；
- `architecture.json`、生成附錄、cmd 與文件中的 module 名全要改；
- 三邊 import path 全破，而方案 A 只破 algorithm01/03；
- 沒有額外數學收益，只是身份重塑。

**結論：若非常重視品牌可選，6.5/10；不建議為改名延誤功能合併。** 更穩妥是先方案 A，將來真要改 module 名再一次過遷移。

### 方案 C：同一 Git repo，三個獨立 MoonBit module

優點：各自 module 名、preferred target、外部依賴與發版節奏不變。

缺點：

- bridge 不能自然地同時 import 三個尚未發布的本地 module；
- 若要橋接，只能發布三個 module 後再建第四個 integration module，或複製程式碼；
- CI、文件與 issue 可集中，但代碼層仍是三個孤島。

**結論：適合「行政合併」，不適合「能力合併」，6/10。**

### 方案 D：只合併 cubical+symlib，semiring 保持外部

優點：延續前版已驗證路線，身份仍偏數學同構／型別論。

缺點：失去 semiring 的加權路徑與熱帶樞紐；未來再合一次又要重做治理。

**結論：5.5/10。比完全分開好，但 algorithm01 出現後不再是最優。**

### 方案 E：三邊攤平／共用根 algebra

例如：

- 把 semiring `algebra` 併現有 `algebra/`
- 把 symlib 與 semiring 的圖、矩陣檔案散入 cubical root
- 強行統一 Graph/Mat/Rat

問題：

- 兩個 `algebra/` 實體路徑直接衝突；同套件內私有名與公開名都要逐一去衝突。
- cubical root 已是強連通的大套件，再吞 28k 行只會放大編譯與治理耦合。
- 精確場代數、Double、半環、圖搜尋的演算法前提不同，統一型別會增加大量難以成立的 trait/轉換義務。
- symlib 與 cubical 已知裸函數 `decompose` 衝突只是冰山一角。

**結論：反對，2/10。**

### 方案 F：三個 repo 保持分開

優點：零遷移、各自 target 與節奏最自由。

缺點：跨倉橋接永遠停在報告層；共同的定律檢查、量測與治理經驗無法複用。

**結論：4/10。只有在決定凍結其中兩倉、只維護一個主產品時才合理。**

---

## 六、三方原型實證

我建立了臨時三方原型 `/tmp/three-way-proto/`（非正式主線）：

- cubical 來源原封不動；
- algorithm03 根套件放入 `symlib/`，cmd 改為 `cmd/symdemo`、`cmd/symbench`；
- algorithm01 16 個 library/examples 套件放入 `semiring/*`，報告器改為 `cmd/semiringreport`；
- 原型版刻意連 `semiring/par_host` 與 `moonbitlang/async@0.22.5` 一起納入，以驗最壞情況；
- algorithm01 與 algorithm03 的 `.mbt` 原始碼未改，只改 `moon.pkg` import 前綴；
- cubical 只在原型 `moon.mod` 增加 async import，仍保留 `preferred_target="wasm"`。

### 原型結果

- `moon check --deny-warn`（全 module，wasm）：通過。
- `moon check --deny-warn --target native`（全 module）：通過。
- semiring 16 套件：
  - native **158/158**；
  - wasm-gc **154/154**。
- symlib + bridge：**68/68**（67 個原測試 + 1 個三方橋接測試）。
- `cmd/symdemo`：可運行。
- `cmd/semiringreport --target native`：成功重生成 717 行報告，原型量得約 66.2 秒。
- 未在原型重跑 cubical 原有慢速 111 個全測試；cubical 原始碼未改，且全 module 兩 target check 已過。正式合併仍必須跑完整閘門。

### 一條真正三方共用的橋接定律

原型新增 `bridge/weighted_graph_symmetry.mbt`：

1. 在 **semiring** 中建立有向帶權 4-環 `0→1→2→3→0`；
2. 忘記方向與權重，送入 **symlib** 得到支撐圖 C4 自同構候選，再以熱帶加權鄰接矩陣逐元篩選；
3. 反射被方向排除，只剩 4 個旋轉；
4. 把 4 個 `Perm` 轉成 **cubical** 的 `CMat` 置換矩陣並取群平均；
5. cubical 驗出平均矩陣是投影子、跡為 1。

這條定律三邊缺一不可：

- semiring 提供有向加權圖的資料模型；
- symlib 提供自同構枚舉；
- cubical 提供表示矩陣與投影子驗證。

它證明三方套件不僅能同住，而且已能在不改三邊原碼的情況下組成新能力。

---

## 七、建議目標架構與依賴方向

```text
                         cmd/showcase
                              │
                              ▼
                           bridge/
              ┌────────────┼──────────────┐
              ▼            ▼              ▼
       cubical root     symlib      semiring/*
              │                           │
              ▼             ┌─────────────┼──────────────┐
       algebra/（精確）       ▼             ▼              ▼
                           graph/matrix   trop/cat/nf   app/bp
                                  │             │
                                  └──────► semiring/algebra
```

硬規則：

1. cubical root 只能依賴精確 `algebra/`，不得反向依賴 symlib/semiring。
2. symlib 不依賴 cubical/semiring，保持可獨立理解的有限對稱核心。
3. semiring 內部依賴圖保持原狀，不依賴 cubical/symlib。
4. 所有跨支柱轉換與定理先放 `bridge/`；若某一橋接日後證明屬於某支柱的基礎 API，再以小步重構下放。
5. bridge 匯入兩份 algebra 時必須明示別名，例如 `@exactalg` 與 `@semialg`，禁止靠 basename 自動別名猜測。
6. `cmd/*` 只作驅動與展示，不得成為 library 反向依賴來源。

### package 命名決策

- 保留現有精確套件路徑：`vv0101v01/cubical-hermitian/algebra`
- semiring 半環地基：`vv0101v01/cubical-hermitian/semiring/algebra`
- 不建議把 cubical algebra 改名讓路；它已有較多內部依賴與文件，且 `semiring/` 前綴已足夠消歧。
- `semiring/app` 的 `app` 實為 algebraic path problem，不是手機應用；合併文件須在套件索引註明。第一期不改目錄，避免無謂 import 改動；若將來改名，可改為 `pathproblem`，但不是合併前置條件。
- `semiring/examples` 保持原位，不與 cubical `cmd/main` 的 90 項正式登記混為同一概念。

---

## 八、合併後會得到甚麼功能？

### Day-1：原有能力不刪減，共用一個入口

1. cubical 90/90 正式登記、111 測試、規格與架構治理；
2. symlib 圖同構/自同構證書、群論、有限範疇、Yoneda、G-集、67 測試與 benchmark；
3. semiring 的半環定律、稀疏/稠密矩陣、最短路/Pareto、熱帶幾何、DFA/冪等正規形、自由範疇、BP、樣條與四 target 核心；
4. 一個 showcase 可按「路徑／對稱／聚合」三軸展示同一批有限結構。

### 第一批三方橋接（可直接做，原型已開路）

1. **加權有向圖對稱投影**
   - semiring Graph → 支撐圖 → symlib Aut 候選 → 加權篩選 → cubical CMat 投影／特徵分解。
   - 原型已通過 4-環證書。

2. **圖的一站式報告**
   同一輸入同時輸出：
   - symlib 規範編碼、自同構群階與軌道；
   - semiring APSP、可達閉包、Pareto 前沿；
   - cubical 鄰接矩陣浮點譜／精確特徵量（視表示選 CMat 或 QMat）。
   這是三邊任一原產品都沒有的完整圖分析報告。

3. **熱帶行列式的對稱分析**
   - semiring `trop_assignment` 求最佳指派；
   - symlib `PermGroup` 分析最佳解集合的置換結構與權重矩陣穩定子；
   - cubical 精確 algebra 可作普通行列式／永久式的對照與去量子化前後比較。

4. **自由範疇互校**
   - semiring cat 的 DAG 路徑集/路徑數；
   - 轉成 symlib FinCat 後檢查 hom 集基數、合成與 Yoneda 樣本；
   - 再與 cubical 的範疇律登記並列，避免三套「範疇」各說各話。

### 第二批橋接（需要新 API，不得誇大為現有能力）

1. **symlib 有色圖搜尋**
   - 新增 initial-colors 搜尋入口，才能正確處理加權邊、第二維權重、CNF、DTerm 與胞複形標籤；
   - 在此之前，支撐圖候選再篩選只適合中小例子。

2. **Face 半環化**
   - 以 wrapper 證明 Face join/meet 過 semiring 定律檢查；
   - 用半環閉包做胞腔傳播、最小公共面／可達性實驗；
   - 結果只作演算法與證書，不直接改變 cubical 內核換算規則。

3. **普通多項式 tropicalization**
   - cubical QPoly → 選定 valuation → semiring UniPoly/BPoly；
   - 驗證乘法後熱帶根併合、細分對偶與精確因式分解的一致性；
   - 需要先定義有理係數 valuation 與溢位邊界。

4. **HIT／胞複形 × 對稱 × 權重**
   - 以胞腔 incidence 建圖；
   - 對稱由有色自同構找，路徑權重由 semiring 聚合；
   - cubical 驗生成元、邊界與高胞黏合。

5. **定律／證書格式再統一**
   - cubical `CheckResult`、symlib `Cert`、semiring `LawReport` 可以在 bridge/showcase 映射到共同呈現格式；
   - 不建議第一期改三邊原有型別，也不應把三種證書的語義強行宣稱相同。

---

## 九、建議落實路線

### Phase T0：回復與凍結基準

- 先回復 cubical 正式 Git 工作樹基準，確認本地第十三期版本；
- algorithm01 以 `6a208f4`、algorithm03 以 `05232fd` 凍結；
- 三邊各跑自己的完整閘門並保存輸出摘要。

### Phase T1：一次性泛化治理工具

在搬碼前或同一個治理提交中：

1. `tools/arch_check.py` 改為由 `moon.pkg` 所在目錄與最長路徑推導 package，不再硬編碼 root/algebra/cmd-main；
2. `resolution_order` 由 package import DAG 傳遞排序推導；
3. `tools/audit_spec.py` 補：
   - `pub(all)`、`pub(open) trait`；
   - `pub fn[E]`、泛型方法與泛型型別；
   - `(package, symbol)` 分類；
   - semiring 10 個 traits 與其方法登記；
4. 決定 `architecture.json` 以「支柱→組件→套件」三層表示，不把 25 套件全攤成同一個平面。

### Phase T2：兩個機械搬移提交

1. 先搬 algorithm03 至 `symlib/`，驗 67/67；
2. 再搬 algorithm01 核心至 `semiring/*`，暫不搬 `par_host` 與 `cmd/semiringreport`，因此主 `moon.mod` 先不引入 async；
3. semiring 核心驗 wasm-gc 154/154，並做 js/wasm/wasm-gc check；
4. 以 `git subtree` 或等價方式保留上游提交來源，搬移提交只改路徑與 `moon.pkg`；
5. 產生的 `.mbti` 走 `moon info && moon fmt`，禁止手改。

### Phase T3：文件與入口整合

- 頂層 README 改成三支柱地圖，保留三份子文件：
  - symlib 中文長文移到子套件文件位置；
  - semiring `README/DESIGN/REPORT` 放 `semiring/docs/` 或頂層 `docs/semiring/`；
  - REPORT 明確註明由 `cmd/semiringreport` 產生且數字依機器浮動；
- 頂層英文 README 至少補三支柱摘要與包索引；915 行 DESIGN 的完整英譯可後置，不應阻塞代碼合併；
- 統一 monoid/monad 中文術語；
- algorithm01 原 repo 未追蹤 LICENSE 檔（`moon.mod` 已標 Apache-2.0）；合併 repo 的根 LICENSE 覆蓋即可，並保留作者／來源註記。

### Phase T4：橋接與統一展示

- 搬入原型已驗的加權圖對稱投影；
- 再加 symlib×semiring 圖報告、熱帶指派對稱、自由範疇互校；
- `cmd/showcase` 匯總三邊證書，但數字分欄，不做一個含混的總分；
- 快閘門不跑 66 秒 semiring report；慢閘門／手動 job 才重生成。

### Phase T5：native host 決策

單獨提交討論是否加入：

- `semiring/par_host`
- `cmd/semiringreport`
- `moonbitlang/async@0.22.5`

判準：

- 若平台定位仍是「純算法 library + wasm 優先」，host 可長期留在可選子層，定期以 native CI 編譯；
- 若接受 registry 依賴與 native 工具，完整合併 algorithm01 並把原 repo 封存；
- 不論選哪邊，都不得讓 cubical root／algebra 直接 import async。

### Phase T6：封存舊倉

三方主 repo 完整閘門與一版文件落地後：

- algorithm01、algorithm03 README 加遷移指向並封存；
- 保留舊 tag/commit，不改寫上游歷史；
- 新 import path 文件列明對照表，方便任何既有使用者遷移。

---

## 十、風險與緩解

| 風險 | 嚴重度 | 緩解 |
|---|---|---|
| 25 套件、10 萬行造成治理失控 | 高 | 先泛化 arch/audit 工具；以支柱分組；快／慢 CI 分層。 |
| 產品身份由 cubical 內核稀釋成大雜燴 | 高 | README 首頁明確改為三支柱；core 與 application/host 分級；ratelimit 標外圍應用。 |
| async 成為全 module 供應鏈依賴 | 中高 | 第一階段不引入；host 第二階段單獨決策；CI 快取 registry 並鎖版本。 |
| preferred target 只能選一個 | 中 | 保持 wasm；semiring report/host 明示 `--target native`；四 target check 分開登記。 |
| 兩份 algebra／Graph／Rat 造成文件混淆 | 中 | 路徑前綴、明示 import alias、術語表與包索引；不共用無限定名教學範例。 |
| 加權圖被誤稱為 symlib 原生支援 | 中 | 文件明說目前是支撐候選+篩選；有色搜尋列正式後續工作。 |
| 完整測試時間變長 | 中 | cubical 慢測試本已主導；semiring 核心測試以秒計；66 秒 report 放慢 job。 |
| 三份文件雙語不一致 | 中 | 頂層雙語索引先行，長篇設計文件分期翻譯；數字由工具重生避免手抄漂移。 |
| 舊 import path 失效 | 低至中 | 三專案均在 0.x；給遷移表與封存提示。若 algorithm01/03 已有外部使用者，先發布兼容通知。 |

---

## 十一、最終裁決

### 我支持三方合併。

理由不是「程式都在 MoonBit，所以拼在一起」，而是三者恰好構成一條完整的結構計算鏈：

- **semiring-lab** 說明怎樣把大量路徑聚合成答案；
- **symlib** 說明哪些結構與路徑在對稱及規範形下相同；
- **cubical-hermitian** 說明路徑如何成為型別等式、範疇與譜結構的一部分。

三方原型已經證明：

1. algorithm01 不改 `.mbt` 就能以 `semiring/*` 入住，158/154 測試照過；
2. algorithm03 能以 `symlib/` 入住，67 測試照過；
3. 同一 module 在 wasm 與 native 都能零警告 check；
4. 三邊能合力完成一條原先任何一方都沒有的「加權圖對稱 → 置換表示 → 投影子」定律。

但我的支持有明確邊界：

> **支持把三個專案合成一個有三根支柱的聯邦，不支持把它們熔成一鍋。**

若落實，我建議決策為：

1. **批准三方合併，採方案 A；**
2. 第一波納入 symlib + semiring 非 host 核心 + bridge；
3. `par_host`/報告生成器與 async 另行一票；
4. 合併後對外定位升級為「MoonBit 結構算法平台：同倫路徑、有限對稱、半環路徑代數」，而不是僅稱 cubical 專案。

這樣得到的是一個真正大於三部總和的系統；反之，若攤平、強行統一 Graph/Mat/algebra，或把 host 依賴塞進內核，我會撤回支持。
