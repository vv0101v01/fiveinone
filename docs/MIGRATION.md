# 三方合併遷移指南

本倉庫以聯邦方式合併三個 0.x MoonBit 專案：

| 上游 | 凍結版本 | 合併後位置 |
|---|---|---|
| `vv0101v01/algorithms02` / cubical-hermitian | 第十三期工作樹 | 根套件 + `algebra/` + `cmd/main` |
| `vv0101v01/algorithm03` / symlib | `05232fd` | `symlib/` + `cmd/symdemo` + `cmd/symbench` |
| `vv0101v01/algorithm01` / semiring-lab | `6a208f4` | `semiring/*` + `cmd/semiringreport` |

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

- 主 module 的 `preferred_target` 保持 `wasm`，延續 cubical/symlib。
- `semiring/par_host` 與 `cmd/semiringreport` 以
  `supported_targets: "native"` 隔離；其他 target 會整包跳過。
- 主 module 在 Phase T5 起只有一個外部依賴
  `moonbitlang/async@0.22.5`，只服務 `par_host`。cubical root、精確
  algebra、symlib 與 semiring 核心均不得 import 它。
- 首次在新環境解析依賴可能要先執行 `moon update`。

## 常用命令

```bash
# 全倉快速閘門（native 另含 4 個 host 測試）
moon check --deny-warn
moon test --target wasm-gc   # 336/336
moon test --target native     # 340/340

# 有限對稱
moon test symlib
moon run cmd/symdemo

# 半環核心（wasm-gc 154；native 連 host 為 158）
moon test --target wasm-gc semiring/algebra semiring/app semiring/bp semiring/cat semiring/examples semiring/graph semiring/io semiring/matrix semiring/monoid semiring/nf semiring/par semiring/ratelimit semiring/sim semiring/spline semiring/trop

# 慢閘門：19 節半環量測報告
moon run cmd/semiringreport --target native
```

## 舊倉封存狀態

舊倉 README 告示文字與有憑證後的操作順序已備妥於
[`LEGACY-ARCHIVE.md`](LEGACY-ARCHIVE.md)。在主倉實際推送並驗證前，
不得把 algorithm01／algorithm03 宣稱為已在 GitHub 封存。
