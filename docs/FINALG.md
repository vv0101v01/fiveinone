# finalg 支柱（上游 `algo` / `moon-algebra`）

`finalg/` 是上游 <https://github.com/vv0101v01/algo> 在
`427135faf8492f5433baba8077d4dc139282291f` 的 namespace 搬入。
上游 module 名是 `moon-algebra`；在 golden 內的根 package 是：

```text
vv0101v01/cubical-hermitian/finalg
```

算法檔案按原 package 邊界機械搬移；整合層只重寫 `moon.pkg`
import 前綴、為 trait 方法加明確 `pub extend`，以及在
`finalg/cat` 增加一個泛型窄域構造函數 `category_of`。

## Package 圖

| Golden package | 內容 | 生產依賴 |
|---|---|---|
| `finalg/num` | 模算術、egcd、素性、因數分解、CRT | — |
| `finalg/linalg` | F_p 稠密矩陣、RREF、rank、nullspace、solve | `num` |
| `finalg` | Ring/Field、IntMod、多變量 Poly、Gröbner、理想、SNF/HNF/RCF/ANF | `num`、`linalg` |
| `finalg/finite` | 結構常數有限代數、理想、根、局部化與有限環結構 | `num`、`linalg`、`finalg` |
| `finalg/modules` | 有限模、對偶、射影性、逆向系統與層式黏合 | `num`、`linalg`、`finite` |
| `finalg/geometry` | 有限代數簇、點與維數 | `num`、`linalg`、`finalg`、`finite` |
| `finalg/scheme` | 有限 Spec、局部資料與概形式黏合 | `num`、`linalg`、`finite` |
| `finalg/hott` | 雙向等價、S¹/商 HIT 計算模型、截斷與重寫 | `num`、`finalg`、`finite` |
| `finalg/cat` | 閉包字典 Category/Groupoid、delooping、path category、K 類 | `num` |
| `finalg/port` | MoonBit 式簽名的靜態接口移植報告 | — |
| `finalg/testutil` | 確定性隨機與 fixture 工具 | `num`、`finite`（其他 package 只在 test scope 使用） |
| `finalg/verify` | `proof_enabled=true` 的合約整數算術 | — |

`finalg` 內部子套件仍以 `@poly` 引用根 package，但完整路徑已改為
`vv0101v01/cubical-hermitian/finalg`。上游數學長文見 [finalg/README](../finalg/README.md)。完整逐符號清單不在本文手抄，
以生成的 [SPEC-APPENDIX](../SPEC-APPENDIX.md) 與各
`pkg.generated.mbti` 為準。

## 與精確 `algebra/` 的分工

兩者不是同一套多項式表示：

- `algebra/` 是 BigInt 有理係數的精確代數，核心單變量型別是
  `QPoly`，另有多變量符號多項式與代數數／Jordan 工具；
- `finalg/` 是 32 位元模數的有限域／`Z/mZ` 多變量多項式與
  Gröbner 工具，核心型別是 `Poly`。

兩邊只在 [`bridge/`](BRIDGE.md) 對接：單變量片段定義誠實的
代表元提升與整係數模約化，並進一步核對乘法、導數、求值、根像與
Hensel 單根候選；本文件不宣稱 `F_m[x]` 可以同態提升到 `Q[x]`。

## Proof 資產

下列上游資產已連同 `verify/arith.mbt` 與契約檔搬入：

- `finalg/verify/arith.mbtp`
- `finalg/prelude/moonbit_builtin_prelude.mlw`
- `finalg/why3-user.conf`
- `finalg/prove.sh`

`prove.sh` 已重基到 golden 根目錄與 `finalg/verify`，並在臨時
副本中把上游 Why3 config 的字面 `/home/user` 前綴換成執行者的
`$HOME`。本階段沒有執行 `moon prove`；一般 `moon check` 通過
不等於八個 proof goals 已在本環境重證。這項外部工具鏈工作
登記在 [ENGINEERING-GAPS](ENGINEERING-GAPS.md)。

## 測試定位

上游 11 份 `*_test.mbt`／`*_wbtest.mbt` 已原位搬入各 finalg
package。依本階段指示，只在 compile-only 閘門中以
`moon test --build-only` 編譯，不執行。未來運行階段入口是
`GOLDEN_RUN_TESTS=1 sh tools/check_full.sh`。
