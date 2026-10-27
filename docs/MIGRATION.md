# 五系統合併遷移指南

本倉庫 <https://github.com/vv0101v01/fiveinone> 是目前五成員 MoonBit
專案。MoonBit module/import 身份為 `vv0101v01/cubical-hermitian`，
不需要將 package 路徑改成 GitHub 倉庫名稱。整體現況見
[STATUS](STATUS.md)。

本倉庫以聯邦方式合併五個 MoonBit 系統：

| 上游 | 凍結版本 | 合併後位置 |
|---|---|---|
| `vv0101v01/algorithms02` / cubical-hermitian | 第十三期工作樹 | 根套件 + `algebra/` + `cmd/main` |
| `vv0101v01/algorithm03` / symlib | `05232fd` | `symlib/` + `cmd/symdemo` + `cmd/symbench` |
| `vv0101v01/algorithm01` / semiring-lab | `6a208f4` | `semiring/*` + `cmd/semiringreport` |
| `vv0101v01/algo` / moon-algebra | `427135faf8492f5433baba8077d4dc139282291f` | `finalg/` + `finalg/*` |
| `vv0101v01/algo4` / catmath | `3b3deaa9706ee5a3543c0fe0ac897167669e26a4` | `catmath/` + `cmd/catmath` |

## Import path 對照

### cubical-hermitian（不變）

| 舊路徑 | 新路徑 |
|---|---|
| `vv0101v01/cubical-hermitian` | `vv0101v01/cubical-hermitian` |
| `vv0101v01/cubical-hermitian/algebra` | 不變（精確 BigInt 代數） |

### algorithm03 / symlib

| 舊路徑 | 新路徑 |
|---|---|
| `arena/symlib` | `vv0101v01/cubical-hermitian/symlib` |
| `cmd/main` | `cmd/symdemo` |
| `cmd/bench` | `cmd/symbench` |

### algorithm01 / semiring-lab

通則：`arena/semiring-lab/<pkg>` 改為
`vv0101v01/cubical-hermitian/semiring/<pkg>`。

| 舊套件 | 新套件 |
|---|---|
| `arena/semiring-lab/algebra` | `vv0101v01/cubical-hermitian/semiring/algebra` |
| `arena/semiring-lab/matrix` | `vv0101v01/cubical-hermitian/semiring/matrix` |
| `arena/semiring-lab/monoid` | `vv0101v01/cubical-hermitian/semiring/monoid` |
| `arena/semiring-lab/graph` | `vv0101v01/cubical-hermitian/semiring/graph` |
| `arena/semiring-lab/spline` | `vv0101v01/cubical-hermitian/semiring/spline` |
| `arena/semiring-lab/trop` | `vv0101v01/cubical-hermitian/semiring/trop` |
| `arena/semiring-lab/nf` | `vv0101v01/cubical-hermitian/semiring/nf` |
| `arena/semiring-lab/cat` | `vv0101v01/cubical-hermitian/semiring/cat` |
| `arena/semiring-lab/app` | `vv0101v01/cubical-hermitian/semiring/app` |
| `arena/semiring-lab/bp` | `vv0101v01/cubical-hermitian/semiring/bp` |
| `arena/semiring-lab/ratelimit` | `vv0101v01/cubical-hermitian/semiring/ratelimit` |
| `arena/semiring-lab/io` | `vv0101v01/cubical-hermitian/semiring/io` |
| `arena/semiring-lab/sim` | `vv0101v01/cubical-hermitian/semiring/sim` |
| `arena/semiring-lab/par` | `vv0101v01/cubical-hermitian/semiring/par` |
| `arena/semiring-lab/par_host` | `vv0101v01/cubical-hermitian/semiring/par_host`（native-only） |
| `arena/semiring-lab/examples` | `vv0101v01/cubical-hermitian/semiring/examples` |
| `cmd/report` | `cmd/semiringreport`（native-only） |

### algo / moon-algebra

通則：`moon-algebra` 改為
`vv0101v01/cubical-hermitian/finalg`，子路徑不變。例如：

| 舊路徑 | 新路徑 |
|---|---|
| `moon-algebra` | `vv0101v01/cubical-hermitian/finalg` |
| `moon-algebra/num` | `vv0101v01/cubical-hermitian/finalg/num` |
| `moon-algebra/linalg` | `vv0101v01/cubical-hermitian/finalg/linalg` |
| `moon-algebra/finite` | `vv0101v01/cubical-hermitian/finalg/finite` |
| `moon-algebra/cat` | `vv0101v01/cubical-hermitian/finalg/cat` |
| `moon-algebra/hott` | `vv0101v01/cubical-hermitian/finalg/hott` |
| `moon-algebra/verify` | `vv0101v01/cubical-hermitian/finalg/verify` |

`modules`、`geometry`、`scheme`、`port`、`testutil` 依同一通則。
上游 module-level `warnings = "-implicit_impl_as_method"` 沒有搬入；
本 module 改以 finalg 套件內的明確 `pub extend` 保留方法面。

### algo4 / catmath

| 舊路徑／入口 | 新路徑／入口 |
|---|---|
| `vv0101v01/algo4`（根 library 檔案） | `vv0101v01/cubical-hermitian/catmath` |
| 上游根 package 的 `moon run`／`fn main` | `moon run cmd/catmath`（未來 smoke 期） |
| 同包 struct literal 建構 `Arrow`／`FinGroup`／`FinMonoid`／`FreeMonoid`／`IntMat` | `arrow_of`／`fin_group_of`／`fin_monoid_of`／`free_monoid_of`／`int_mat_of` |

Algo4 上游 `preferred_target="native"` 是其獨立 module 的偏好；
併入後由本 module 的 `preferred_target="wasm"` 管轄。catmath
package 本身不宣告 native-only；本階段以四 target `moon check`
作可攜性編譯邊界。

## 兩個 `algebra` 不得混淆

- `vv0101v01/cubical-hermitian/algebra`：精確 BigInt 有理數、多項式、
  代數數、根隔離、Jordan 與 Jacobi。
- `vv0101v01/cubical-hermitian/semiring/algebra`：半環/么半群 traits、
  熱帶與 Pareto 等半環載體、定律檢查器。

橋接代碼同時使用兩者時，必須明示別名（例如 `@exactalg` 與
`@semialg`），不要依賴套件 basename 的預設別名。

## 術語正名

- **monoid = 么半群**（semiring 支柱）；
- **monad = 單子／單子函子**（symlib 支柱）；
- `semiring/app` 的 `app` 是 algebraic path problem，不是應用程式；
- `semiring/ratelimit` 是外圍應用套件，不屬 cubical 內核。

## Target 與依賴

- 主 module 的 `preferred_target` 保持 `wasm`，延續 cubical/symlib／
  moon-algebra；algo4 的獨立 native 偏好不沿用作本 module 的邊界。
- `semiring/par_host` 與 `cmd/semiringreport` 以
  `supported_targets: "native"` 隔離；其他 target 會整包跳過。
- 主 module 在 Phase T5 起只有一個外部依賴
  `moonbitlang/async@0.22.5`，只服務 `par_host`。cubical root、精確
  algebra、symlib 與 semiring 核心均不得 import 它。
- 首次在新環境解析依賴可能要先執行 `moon update`。

## 常用命令

本階段唯一自動閘門是 compile-only；它編譯全部測試源碼但不執行
任何 test block 或 smoke 程式：

```bash
git clone https://github.com/vv0101v01/fiveinone.git
cd fiveinone
moon update
sh tools/check_compile.sh
```

只想重編某個新支柱及其測試源碼時可用：

```bash
moon check --deny-warn finalg finalg/num finalg/linalg finalg/finite   finalg/modules finalg/geometry finalg/scheme finalg/hott finalg/cat   finalg/port finalg/testutil finalg/verify
moon test --build-only --deny-warn finalg catmath bridge
moon build --deny-warn cmd/catmath cmd/showcase
```

未來獲指示進入運行期後，才執行：

```bash
GOLDEN_RUN_TESTS=1 sh tools/check_full.sh
GOLDEN_RUN_SMOKE=1 sh tools/check_slow.sh > /tmp/REPORT.generated.md
```

舊三系統樹的 wasm-gc 336/336、native 340/340 是歷史基線，不得
改寫成目前五系統樹的預期測試數；五系統總數須待運行期由測試
執行器實數回填。

## 決策史（取代已刪除的獨立 MERGE 研究檔）

早期研究與施工文件曾分別保存為兩方、三方、五方研究快照。為免
同一決策在多份文件中漂移，現只保留下列權威摘要；原始量測仍可
來源 SHA 記錄於成員 provenance 與相關遷移文件。

1. **兩方／三方階段採「同 module、成員真身、單向橋」方案**：
   cubical 保持根套件，symlib 與 semiring 保持獨立 namespace，
   跨界語義只進 `bridge/`；此樹以 `9452cb9…` 首次公開。
2. **五方施工先驗證來源映射**：algo 的 12-package DAG 原樣成為
   `finalg/`；algo4 的單一大 package 成為 `catmath/` library，
   同包 executable 拆到 `cmd/catmath/`；公開面不足只以所屬
   package 的窄域 constructor 或明確 `pub extend` 補齊。
3. **初版曾把五方接口疊在三方 bridge 之上的 `unified/`**。該作法
   有助分階段施工，但形成兩套整合權責與不必要的依賴鏈。
4. **現行裁決改為直接 3＋2**：撤銷 `unified/` 與
   `cmd/unified/`，把註冊、轉接、推導報告與證書併入原
   `bridge/`。成員映射、來源保真與語義邊界不變；改變的只是
   聯邦拓撲。完整相容圖表見 [BRIDGE](BRIDGE.md)。

## 舊倉封存狀態

主倉首次公開條件已經滿足，但 `algorithm01`／`algorithm03` 的 README
遷移告示與 GitHub Archive **尚未執行**；`algo`／`algo4` 的五系統
遷移告示也尚未貼到來源倉。現有兩倉的告示定稿與操作順序在
[`LEGACY-ARCHIVE.md`](LEGACY-ARCHIVE.md)，並登記為缺口 REL-001；在兩倉
頁面出現告示且變為 read-only 前，不得宣稱已封存。cubical 來源不再作為
目前五成員專案入口為 `fiveinone`。
