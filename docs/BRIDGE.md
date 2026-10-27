# Bridge：唯一的五成員聯邦核心

`bridge/` 是 `golden` 內唯一的跨成員整合層。它由原三支柱橋
**就地擴張**而成：cubical、symlib、semiring 的既有橋保留原位，
再以 `federation_*.mbt` 直接加入 finalg 與 catmath。已刪除的
`unified/` 疊加層不再存在，也沒有第二套註冊表、證書或展示入口。

```text
cubical root + algebra ─┐
symlib ─────────────────┤
semiring/* ─────────────┼─> bridge/（唯一五成員聯邦核心）─> cmd/showcase
finalg/ + finalg/* ─────┤
catmath/ ───────────────┘
```

五個成員不作橫向 production import，也不反向 import
`bridge/`。bridge 不合併、不改名、不升格任何成員的原生型別；
每個圖表都標明方向、輸入前提、輸出語義、成本或不受支援片段，
再優先以來源成員自己的判定器、規範形式或共同不變量重驗。

本階段全部新舊測試源碼只編譯、不執行，所以本文所述
`check_*` 與 18 項 `bridge_certificates()` 是已實作且能通過
`--deny-warn` 編譯的檢查程式，不冒充現行五成員樹的運行期證據。

## 「疊加」與「直接 3＋2」的分別

|  | 疊加式（已撤銷） | 直接 3＋2（現行） |
|---|---|---|
| 結構 | `三支柱 → bridge → unified → cmd/unified`，finalg/catmath 只進上層 | `五成員 → bridge → cmd/showcase` |
| 權責 | bridge 與 unified 都像「聯邦核心」，註冊／證書分兩處 | bridge 是唯一註冊、轉換、報告與證書入口 |
| 依賴 | 五成員查詢要穿過三聯邦層，層級由歷史而非語義產生 | 依賴圖直接反映五成員現況 |
| 演化 | 新橋要先決定屬三方還是五方，容易重複包裝 | 舊三支柱檔案與新 `federation_*` 檔案在同層分工 |
| 好處 | 唯一潛在好處是把歷史三方 API 完全凍結在下層 | 本倉不需要對外凍結該分界；同包內仍可由檔名保留出處 |

因此疊加層沒有保留價值：它增加表面積，卻不增加語義隔離。成員
邊界由 namespace 與 `architecture.json` 管制，不需多造一個套件層。

## 註冊表

`bridge/federation_registry.mbt` 提供：

| API | 作用 |
|---|---|
| `federation_members()` | 五成員的穩定 id、顯示名、namespace、來源、provenance 與摘要 |
| `federation_member_count()` | 成員數，現為 5 |
| `federation_member_ids()` | 穩定 id 列表 |
| `federation_namespaces()` | 五成員在本 module 內的 namespace |

`architecture.json` 仍是 package/component 邊界與層級的權威來源；
註冊表是程式可讀的聯邦清單，不取代架構審計。

## 原三支柱橋（保留原位）

| 橋 | 輸入 → 輸出 | 誠實邊界 |
|---|---|---|
| 置換／wiring | `symlib.Perm ↔ cubical.Wiring/Equiv`、`CMat` 置換矩陣與群平均 | 帶號 wiring 的底置換與每輸出號列分開讀回；S4 全 24 元及 16 個 Bool 值逐一核驗 |
| 加權有向圖 | semiring CSR 圖 → support＋頂點簽名顏色 → symlib colored 搜尋 → 雙權重逐邊精確過濾 | 顏色只剪候選，從不取代精確權重檢查；群平均只在枚舉完整時可宣稱投影器；`canonical_encoding` 只是診斷鍵，不是完整加權有向標準形 |
| 複矩陣 | cubical `CMat` → 非零支撐色圖 → 候選置換 → 逐元近似保存 | 浮點保存沿用 cubical 既有容差，不包裝成精確證明 |
| 自由範疇 | semiring DAG 路徑 → symlib `FinCat` | 非 DAG 直接拒絕，不截斷無限路徑集 |
| 熱帶指派 | `trop_det`／Hungarian 最佳值 ↔ symlib 全置換 | 枚舉設 cap；只核有限枚舉片段 |
| 熱帶化 | 精確 `QPoly` → p-進賦值 → semiring `UniPoly` | 零係數送至熱帶 +∞；橋只核已陳述的根多重集片段 |
| Face 半環 | cubical `Face` → canonical ROBDD 包裝 `FaceClass` | 不以 Face AST 結構相等冒充語義相等；⊕=∨、⊗=∧、0=⊥、1=⊤ |
| 胞腔對稱 | 2-胞腔正方形關聯圖（維數色）→ symlib 保色自同構 | 有限關聯圖包裝，不宣稱高維胞腔完整分類 |

## 第一波直接聯邦轉接

| 介面 | 方向 | 精確語義 |
|---|---|---|
| `fincat_to_catmath_category` / `catmath_category_to_fincat` | symlib ↔ catmath | 有限範疇表精確互換；合成表必須轉置以對齊索引約定 |
| `fincat_to_finalg_category` / `catmath_category_to_finalg_category` | 表格範疇 → finalg/cat | 以物體／態射索引呈現為閉包字典範疇；不可合成或越界呼叫會 abort |
| `catmath_fin_group_to_symlib_perm_group` | catmath → symlib | Cayley 左正則表示；先以 catmath 群檢查器重驗乘法表 |
| `symlib_perm_group_to_catmath_fin_group` | symlib → catmath | 只列舉不超過 `cap` 的小群；超限回 `None` |
| `qpoly_to_finalg_univariate` | 精確 `algebra/` → finalg | 只接受整係數 `QPoly`，逐係數模約化；非整有理係數回 `None` |
| `finalg_univariate_to_qpoly` | finalg → 精確 `algebra/` | 只接受單變量多項式，取 `[0,m)` 代表元提升；不是環同態 |
| `integer_matrix_normal_form_report` | finalg × catmath | 比較兩套 SNF 不變因子，並附 finalg HNF 與冪等性 |
| `integer_matrix_charpoly_cross_check_mod` | 精確代數 × finalg | Q 特徵多項式模素數後對照有限域特徵多項式；要求 `p>n` |
| `winding_of_*` / `*_of_winding` | cubical × finalg/hott × catmath | 只對齊 S¹ 整數繞數，不聲稱三套型別論相同 |

三套有限範疇的合成索引不可同位複製：

- symlib：`comp[f*nmor+g] = f∘g`；
- catmath：`comp[a][b] = b∘a`；
- finalg/cat：`compose(g, f) = g∘f`。

## 由相容片段推導的第二波定理／報告／演算法

第二波並非只搬表示，而是把共同不變量做成報告結構與聚合檢查：

| 報告 | 推導出的可執行圖表 | 邊界 |
|---|---|---|
| 有限範疇 | 有向可達 iff 轉換後 Hom 非空；無向弱分量與對稱 Boolean 閉包一致；法則、iso classes、skeleton、物件／態射數互校 | Hom-count 精確特徵多項式只是去範疇化不變量，不取代範疇本身 |
| 有限群與 G-集 | 原標號 Cayley 左乘是同態；正則表示平均投影秩 1；作用軌道分割；Burnside 平均值與作用平均投影秩＝軌道數 | catmath delooping/abelianization 只用單位元索引 `e=0` 的片段；G-集回程必須攜帶元素次序 |
| 多項式模約化 | 精確乘法、導數、整點求值與模約化交換；分母可逆時有理根像是根；Hensel 單根候選再以精確模 `p²` 驗證 | 只在整係數、明示素數與可逆性片段成立；代表元提升不是同態 |
| 整數矩陣 | 精確 rank/det/trace/charpoly/minimal polynomial、兩邊有限域 rank、SNF、Cayley–Hamilton、有限 cokernel 的 Smith 分解互校 | 非方陣只走適用的 SNF/rank 片段；有限 cokernel 分解需行列式非零等前提 |
| 布林函數 | 真值表 DNF、finalg ANF、cubical Face/ROBDD 在全部 assignments 上同義；ANF 變換為對合；SAT witness 與補集同步 | ANF 字串的 XOR 用互斥析取編碼；窮舉只適合小變量數 |
| 有限拓撲與 Spec | Alexandrov 專化預序 ↔ thin category；Boolean 閉包、T0 商／skeleton／components 互校；finalg Spec 轉置理想包含後逐 mask 對齊開集 | catmath `make_top` 會自反化與傳遞閉包；開集窮舉成本 `2^n`，只用小片段 |
| 功能圖動力 | catmath DynSys 與 semiring 功能圖的環分割、尾距、環長一致；鄰接特徵多項式嚴格等於 `x^(tail)·∏(x^L−1)` | semiring 分解允許 dead end；比較時限定每點恰一出邊；只有真正 permutation 才連到 symlib 置換群 |
| `F_p` 鏈複形 | 形狀、素數與 `∂²=0` 守衛下由邊界矩陣秩以 rank-nullity 算 Betti 數並核 Euler 特徵 | 空 differentials 拒絕；不把有限矩陣秩包裝成一般鏈複形分類 |
| 整數同調片段 | 檢查 `AB=0`、自由秩與 SNF 扭子；模 p Betti 只驗 universal-coefficient 下界 | 模 p 代表元整數提升一般不保 `∂²=0`；不得用等式取代下界 |
| STLC | `SAtom↔LBool`、`SOne↔LUnit`、積與箭頭對應；context 次序反轉而 de Bruijn index 不變；回程只收 cubical η-long 範形 | 拒絕 Bool 字面量與 coe；cubical 有 unit-η 而 catmath raw 範形沒有，故報告同時保存 raw equality 與顯式 unit-η completion，不宣稱 raw 範形全面相等 |

聚合入口是五個 `check_federation_*_derived_*` 函數與五個
wbtest 區塊；它們與先前 13 項共同組成 18 項
`bridge_certificates()`。這些證書統一展示格式，不抹除來源成員的
原生表示，也不把 compile-only 說成已執行。

## 刻意新增的窄域公開面

跨套件 `pub` enum 構造子是唯讀的；為避免把成員型別放寬成
`pub(all)`，只在所屬成員內增加窄域建構函數：

- catmath：原 `arrow_of`、`fin_group_of`、`fin_monoid_of`、
  `free_monoid_of`、`int_mat_of`，再加 `gset_of`、
  深拷貝的 `chain_complex_of` 與 STLC 的 `stype_*`／`sterm_*`；
- cubical root：`lty_*_ctor`、`tm_*_ctor`，刻意不暴露 coe；
- finalg/cat：泛型 `category_of`；
- finalg 受影響套件以明確 `pub extend` 取代上游全 module
  warning 抑制。

這些入口只負責建構或複製既有表示，不改演算法語義。

## 入口、錯誤與成本邊界

- `cmd/showcase` 是唯一聯邦 showcase：先列五成員註冊表，再列
  18 項 bridge 證書。本階段只 `moon build`，不執行。
- bridge 仍有以 `abort` 表達的硬前提（空輸入、非方陣、尺寸、
  素數／DAG、枚舉 cap 與 finalg 閉包範疇不可合成呼叫）。
  它們是明示邊界而非結構化 `Result` API，見
  [ENGINEERING-GAPS 的 API-001](ENGINEERING-GAPS.md)。
- 大量交叉檢查是窮舉式：全 assignments、全 Hom、全群元素或
  `2^n` 子集只適合小有限片段。報告的 `Bool` 欄位只對該輸入
  與明示 cap／前提負責。
- `weighted_graph_report` 仍會重算候選、對稱、投影、閉包與
  特徵多項式；逐段 budget、部分報告、無碰撞精確簽名與一般
  胞腔複形仍在工程缺口登記。

## 編譯驗收

```bash
moon test --build-only --deny-warn bridge --target wasm-gc
moon build --deny-warn cmd/showcase
python3 tools/arch_check.py
sh tools/check_compile.sh
```

未獲運行期授權前，不執行上述 `check_*`、wbtest 或 showcase。
未來入口是 `GOLDEN_RUN_TESTS=1 sh tools/check_full.sh`。
