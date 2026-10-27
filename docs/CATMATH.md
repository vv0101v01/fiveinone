# catmath 支柱（上游 `algo4`）

`catmath/` 是上游 <https://github.com/vv0101v01/algo4> 在
`3b3deaa9706ee5a3543c0fe0ac897167669e26a4` 的 namespace 搬入，
fiveinone 內完整 package 路徑為：

```text
vv0101v01/cubical-hermitian/catmath
```

上游是單一大型 MoonBit package。本次不按主題硬拆成多個
package：先保留單包邊界，以降低改寫風險。現已加入
`python3 tools/catmath_scc.py` 的生產源碼靜態近似圖；目前 22 個
production `.mbt` 有 44 條跨檔依賴邊，形成 22 個 singleton SCC、
0 個 cyclic SCC。這不是 MoonBit compiler 的依賴圖，且可能漏掉
method dispatch 等隱式依賴，只能協助挑選拆包候選，不能作為安全
拆分證明。依 `AGENTS.md` 的 runtime evidence 要求，實際拆包待
runtime 驗收重新授權後再做；缺口見
[ENGINEERING-GAPS](ENGINEERING-GAPS.md)。

## 內容分域

| 檔案群 | 主題 |
|---|---|
| `category.mbt`、`flat.mbt`、`topos.mbt`、`pseudo.mbt` | 小範疇、函子、等價、Yoneda、元素範疇、預層與偽函子片段 |
| `algebra.mbt`、`free.mbt`、`groupoid.mbt`、`galois.mbt` | 有限群／么半群、自由對象、群胚與 Galois 範疇片段 |
| `derived.mbt`、`cohomology.mbt`、`homotopy_algebra.mbt`、`tannaka.mbt` | 鏈複形、同調／上同調、A∞/同倫代數與 Tannaka 重構檢查 |
| `canonical.mbt`、`algorithms.mbt` | SNF、交換群不變因子、骨架／規範形索引與複雜度改良版算法 |
| `ccc.mbt`、`homott.mbt`、`linear.mbt`、`operad.mbt` | STLC/CC* 模型片段、S¹ HoTT 符號計算、線性邏輯與 operad |
| `systems.mbt`、`topology.mbt`、`zerocost.mbt` | 動力系統、有限拓撲與編譯期求值展示 |

上游導覽與數學定義／定理長文見 [catmath/README](../catmath/README.md) 與 [catmath/MATH](../catmath/MATH.md)。逐符號接口以 [SPEC-APPENDIX](../SPEC-APPENDIX.md) 與
`catmath/pkg.generated.mbti` 為準。`tools/catmath_index_check.py` 會在 compile-only 閘門核對 canonical／derived 索引與 production topic files 的覆蓋及來源標籤；它是治理檢查，不驗證數學敘事真偽。

## 搬移時的唯一結構改動

上游 root package 同時是 library 與 executable，唯一的
`fn main` 位於根檔 `catmath.mbt`。fiveinone 中：

- 21 份上游 production 檔案與 23 份 test/wbtest 檔案搬入
  `catmath/`；
- `catmath/moon.pkg` 改為純 `library`，保留 wbtest 的
  `moonbitlang/core/bench` import；
- `main` 改寫到 `cmd/catmath/main.mbt`，只經公開 API 呼叫；
- `catmath/interop_constructors.mbt` 提供窄域構造／複製函數，
  讓 `cmd/catmath` 與 `bridge/` 不必把表示升成 `pub(all)`；
  直接聯邦階段再加入 `gset_of`、深拷貝 `chain_complex_of`
  與 STLC 的 `stype_*`／`sterm_*`。

因此 `catmath` 現在可被其他 package 正常 import；原來同包的
struct literal 入口改由 `fin_monoid_of`、`free_monoid_of` 等
公開構造函數取代。

## 與另外兩套有限範疇表示的關係

catmath `Category` 使用箭號表與 `comp[a][b] = b∘a` 的
`Option` 合成表。symlib `FinCat` 與 finalg/cat 的閉包字典
`Category[Obj,Hom]` 沒有被合併或改名取代；轉換只在
[`bridge/`](BRIDGE.md) 發生，並明確處理合成索引轉置。

## 測試定位

上游 23 份 test/wbtest 檔案已全部搬入。依本階段指示，
compile-only 閘門只編譯它們，不執行 `moon test` 或
`cmd/catmath`。未來運行階段由
`GOLDEN_RUN_TESTS=1 sh tools/check_full.sh` 一併啟用。
