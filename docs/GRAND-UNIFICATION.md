# 大一統研究地圖與首個實作切片

最後聯網檢索：2026-10-27。本文是成邦後的中央研究與設計文檔，
不回寫五個成員的成邦前 `README.md`。文獻優先採用正式期刊、
專書與作者 arXiv 頁；2025–2026 的新論文只作前沿方向標記，
不把尚未沉澱的預印本主張當作已定論的基礎。

## 結論先行：大一統不是把五套表示壓成一套

文獻給出的共同形狀不是「找一個萬能資料型別」，而是：

1. **語法／理論**可用 Lawvere theory、operad、monad 與其模型
   範疇來比較；
2. **邏輯／子型別**可由子物件、謂詞與其 Heyting／residuated
   結構來解釋；
3. **幾何**可由 Spec、賦值、初始形式與 tropicalization 把代數
   物件送到組合幾何；
4. **計算**則靠每套表示自己的規範形、判定器和證書，不靠
   跨界的口頭等價。

因此 golden 的大一統路線維持五成員真身與唯一 `bridge/`：
每個圖表只在明示的有限共同片段成立，並在報告中保留方向、
前提、成本和反例。本輪先落地兩條最能由現有 API 精確支撐的
軸：有限 Heyting 邏輯子型化，以及有界熱帶角點軌跡。

## 五個成員在大一統中的角色

| 成員 | 理論角色 | 本輪實際接口 |
|---|---|---|
| cubical root＋精確 `algebra/` | 計算性同倫／型別語義、Face 命題、精確有理與 p-進賦值來源 | `QPoly` 的 p-進 tropicalization；既有 Face/ROBDD 仍是 Boolean 極限 |
| symlib | 有限範疇、預層、群作用、圖與範疇不變量 | 有限拓撲的 thin category、skeleton 與分量互校 |
| semiring | 冪等／熱帶半環、路徑代數、Boolean 閉包、Newton 細分 | Boolean 傳遞閉包；`BPoly` 的對偶與平衡檢查 |
| finalg | 有限域多項式、理想與 Gröbner 基、有限 Spec | 拓撲的譜實例；理想生成元與 Gröbner 基的角點樣本細化 |
| catmath | 有限範疇、有限拓撲、同調與型別論模型 | `FinTop` 的開集、內部、連續性與 T0 商 |
| bridge | 只負責可證偽的共同片段、共同不變量與證書 | 新的 Heyting 與 tropical reports、`check_*`、wbtest 與證書 |

## 去重審計與八成驗收判定（2026-10-27）

### 判定口徑

「百分之幾的大一統」沒有脫離分母的數學意義。本專案採用的
分母是：**五個現有系統之間可相容、可有限表示、且能保留原生
語義差異的共同片段**。它不是五套原生功能逐行互相覆蓋的
比例，也不是「全部數學」的比例；按後兩種口徑，本倉沒有
達到八成，也不應以假等價追逐八成。

每個定理族在量表只計一次。converter、report、一般
`check_*`、聚合範例、certificate 與 wbtest 是同一圖表的
不同工程層，不因包裝層數重複加分。成員真身內的獨立算法
例如兩套 SNF、三套有限範疇表示、exact/finite 多項式引擎，
是差分 oracle，不是應刪除的複製品；要收攏的是 bridge 對
它們的正本比較定理，而不是消滅來源實作。

### 本輪實際去重

| 發現 | 處置 |
|---|---|
| `free_category.mbt` 的 `same_path` 與既有 `int_arrays_equal` 完全同義 | 刪私有複本，統一呼叫 `int_arrays_equal` |
| tropical bridge 自帶試除法 `is_prime_i32`，其餘 bridge 已用 `@fnum.is_prime` | 刪私有複本，p-進報告與舊 tropical bridge 統一用 finalg/num 的素性判定 |
| Heyting 報告在已取得 topology 報告後，再重算同一 Boolean 閉包 | 改為繼承 `topology.semiring_closure_ok` |
| 舊 `check_tropical_bridges` 與第三波重複檢查同一 `(x-2)(x-4)` 的 2-進根 | p-進幾何正本收攏到 `padic_tropical_hypersurface_report`；舊檢查只保留指派、永久式與行列式 |
| `bridge_certificates()` 原把註冊表計數、finalg verify 與 catmath registry 的原生健康檢查也列作證書 | 三者保留原函數與 wbtest，但退出大一統證書分母 |
| 第一波整數矩陣證書已被第二波 `IntegerMatrixFederationReport` 包含 | 保留第一波函數作 adapter 煙霧檢查，正本證書只列第二波報告 |
| 二元 BPoly 附帶檢查原本只取第一個合資格生成元 | 改為彙總全部合資格生成元，避免欄位名承諾大於實際檢查 |
| 缺口 `UNI-002`／`BRG-007`、以及 `BRG-005`／`GU-001` 內容重疊 | 分別以 `BRG-007`、`GU-001` 為正本，其餘只保留併入指向 |

去重後 `bridge_certificates()` 是 **16 項跨成員語義證書**。
原有公共函數沒有因證書去重而刪除，所以這是證據分母收攏，
不是削弱覆蓋；被包含的 adapter 檢查仍可直接呼叫，也仍在
wbtest 源碼中。

### 不適合升格、已降格處理的內容

- Hom-count 特徵多項式只是去範疇化不變量，可作 observable，
  不作有限範疇等價證據。
- `F_p[x] -> Q[x]` 的代表元提升不是環同態，只作係數截面。
- finalg 閉包範疇不存在一般可枚舉回表方向，不補造逆轉換。
- Face 有界格的 star 恆為 top、固定正方形胞腔只是展示；
  兩者保留作範例，不計作一般胞腔／傳播理論已統一。
- lex Gröbner 基只給有界角點必要條件的細化，不升格為
  tropical basis 或完整 tropical variety。
- STLC 的 raw 範形不作全面相等宣稱；只在顯式 unit-η
  completion 後比較。這些都是理論邊界，不得為了百分比
  刪除反例欄位。

### 共同片段大一統量表

| 面向 | 權重 | 得分 | 判定依據與主要扣分 |
|---|---:|---:|---|
| 直接 3＋2 架構與治理 | 10 | 10 | 單 module、五真身、唯一 bridge、無橫向 production import、單一註冊／證書／showcase |
| 有限範疇與預序 | 10 | 9 | 三表示、自由 DAG 範疇、Hom／可達／skeleton／components；未及一般函子與 presheaf 圖表 |
| 有限對稱、群與 G-集 | 10 | 9 | 置換／wiring、圖與矩陣對稱、Cayley、Burnside 與投影器；受枚舉 caps 限制 |
| 精確／有限多項式與整數矩陣 | 12 | 11 | 約化同態、根與 Hensel、SNF/HNF、rank、charpoly/minpoly、有限 cokernel；多變量精確共同表示仍缺 |
| 邏輯與語義子型別 | 10 | 9 | Boolean Face/ANF 與有限 Heyting 開謂詞子型別均有窮舉圖表；未及一般語法子型別與 presheaf 子物件分類子 |
| 有限拓撲與 Spec | 8 | 7 | Alexandrov↔thin category、T0、components、Spec 轉置序；只及有限譜片段 |
| 動力與同調 | 8 | 7 | 功能圖不變量、`F_p` Betti、整數 SNF 同調片段；未及一般導出函子／導出範疇 |
| 型別論共同片段 | 8 | 6 | S¹ 繞數與窄 STLC（明示 unit-η 差異）；cubical 依賴核心的大部分高階結構仍是成員原生領域 |
| 熱帶幾何 | 10 | 6 | 單變量 p-進角點、指派、BPoly 細分與有界多變量樣本；缺賦值 Gröbner、完整多面體簇、tropical ideals 與概形化 |
| 序半環與路徑語義 | 6 | 5 | Boolean 星閉包、Face 半環與熱帶路徑已接通；矩陣 residuals／一般 quantale 未實作 |
| 報告與證書模型 | 4 | 3 | 16 項正本語義證書與分欄報告；尚無版本、序列化、摘要與離線重驗 envelope |
| 本樹運行與外證據 | 4 | 0 | 本階段嚴格 compile-only；沒有現行五成員樹的測試執行、proof 或 hosted CI 證據 |
| **合計** | **100** | **82** |  |

### 驗收結論

**可以確定：按上述共同片段口徑，本系統已達約 82%，可作
「大一統 v1」收貨。** 82 分已同時扣除尚無運行證據的 4 分，
因此它不是把編譯成功誤作測試全過；它表示架構上沒有再靠
疊加層、共同私有表示或假等價才能前進的結構性阻塞，各大
共同軸都已有可執行定理／演算法，餘下主要是可逐項擴展的
覆蓋缺口。

現行 `bridge/` 以枚舉式有限表示能合理追求的上限約為
**85–90%**：運行期證據、賦值 Gröbner、quantale residuals
與 presheaf Heyting 可再增加分數，但一旦引入一般賦值域、
blueprints/bands、無限範疇或完整導出／同倫語義，分母亦
會擴大，因此 100% 不是有意義的目標。若把五成員全部原生
功能互覆蓋當分母，本輪不宣稱八成；該口徑既不需要，也會
迫使系統抹除已明示的非等價。

## 文獻軸一：內部邏輯、Heyting 代數與邏輯子型化

範疇邏輯的基本事實是：topos 中任一物件的子物件偏序
`Sub(X)` 是 Heyting 代數；子物件分類子把子物件表示為到
`Ω` 的態射。這也是內部直覺主義邏輯的命題代數。拓撲版本更
直接：開集以交、併為格運算，蘊含是
`U ⇒ V = int((X \ U) ∪ V)`；有限空間必為 Alexandrov 空間，
開集恰是專化預序的上集。

語義子型別（semantic subtyping）則把型別解釋為集合，並以
集合包含定義子型別，令 union、intersection、negation 有
集合論語義。本專案在這之上作一個有限而可不變量化的收窄：
只允許**可觀測謂詞**，即可觀測拓撲的開集；於是：

```text
refinement subtype U <: V   ⟺   U ⊆ V
meet  = U ∩ V
join  = U ∪ V
U ⇒ V = int((X \ U) ∪ V)
¬U    = U ⇒ ∅
```

集合補集未必可觀測，所以這個子型別格一般是 Heyting 而非
Boolean。這正是 Boolean Face 語義與拓撲內部邏輯之間誠實的
差別，不以「補集」冒充 pseudocomplement。

本輪實作在 `bridge/federation_heyting.mbt`：

- `fintop_open_masks` 枚舉最多 16 點的開集 mask；
- `fintop_interior_mask` 以主上集 `↑x ⊆ S` 直接算內部，並
  與 catmath 的閉包補集算法逐 mask 對齊；
- `fintop_open_subtype_of`、meet、join、implication、negation
  只接受開 refinement predicates；
- `finite_heyting_topology_report` 在最多 12 點、64 個開集
  的片段窮舉格律、子型別上下界、Heyting 伴隨
  `W∩U ⊆ V ⟺ W ⊆ (U⇒V)`、modus ponens、pseudocomplement
  與 Boolean 特徵；
- 聚合範例包含非 Boolean 的三點鏈加孤點、Boolean 離散拓撲，
  以及 finalg 有限 Spec 轉成的 Alexandrov 拓撲。

這不是替 cubical 或 catmath 的 STLC 宣稱一般子型別系統；
它是任何此類擴展都必須尊重的有限語義子型別格。真正的
型別層子型別、型別推斷與相干 coercion 仍未實作。

## 文獻軸二：熱帶簇、熱帶理想與賦值 Gröbner 理論

Maclagan–Sturmfels 的基本圖像是：多項式經係數賦值送到
熱帶半環，熱帶簇是使初始理想不含單項式的權重集合，也可
看成熱帶超曲面的交。Maclagan–Rincón 的 tropical ideals
進一步在熱帶多項式半環中建立代數基礎：相關簇是有限多面
體複形，理想滿足升鏈條件與弱 Nullstellensatz。Chan–Maclagan
則指出，有效計算不能只用一般 Gröbner 基，必須把係數賦值
納入 Buchberger 理論；他們的動機正是用賦值 Gröbner 基定義
與計算熱帶簇。

概形化方向有三層成熟度：Giansiracusa–Giansiracusa 以半環
概形寫熱帶超曲面的方程並定義 tropicalization functor；
Lorscheid 的 blueprints 把交換環、半環與么半群納入共同
概形論；Baker–Jin–Lorscheid 的 bands／band schemes 是
2025 年期刊化的較新框架，2026 年的極限文則把 Payne 的
tropicalization 極限定理提升到 band schemes。這些是重要
的長期方向，但目前五成員沒有共同的 blueprint／band 表示，
所以本輪不虛構一個同名空殼。

本輪只實作兩個可精確命名的有限片段，位於
`bridge/federation_tropical_varieties.mbt`：

1. **p-進單變量熱帶超曲面**：精確 `QPoly` 以
   `qpoly_tropicalize_padic` 送到 semiring `UniPoly`；在有界
   整數區間直接算最小值至少由兩項取得的角點，並與
   `UniPoly` 的精確有理根清單核對。
2. **多變量有界角點樣本**：finalg `Poly` 的非零有限域係數
   只取平凡賦值 0，支撐送到整數格點上的
   `min_alpha alpha·w`；比較原生成元與 finalg lex Gröbner
   基在最多 4096 個格點上的角點軌跡。基元素仍在同一理想，
   所以 Gröbner 樣本必被生成元樣本包含；報告也雙向檢查
   ideal membership。雙變量時再以 semiring `BPoly` 檢查
   Newton 細分面、對偶 ties、面積與平衡殘差。

明示非宣稱：lex Gröbner 基未必是 tropical basis；有限域
係數的平凡賦值支撐像不是一般賦值域上的完整 tropical
variety；有限格點交集不是多面體扇、tropical ideal、
tropical scheme 或 band scheme。一般賦值 Gröbner 基、
權重初始理想和完整多面體複形列為後續工程缺口。

## 其他已查核但本輪不冒充實作的統一角色

| 方向 | 文獻給出的統一機制 | 目前裁決 |
|---|---|---|
| Lawvere theories／monads／operads | 以模型範疇與 theory morphisms 比較代數理論；Fujii 的框架再把多種 algebraic theory 表示為 monoidal 範疇中的 monoid objects | 未來可作語法軸；現有 symlib/catmath 只有片段表示，未造共同 theory 物件 |
| Quantales／residuated relations | Boolean 矩陣對合成也有 residuation；新近工作把 quantales 表示為 residuated relations 的形式概念格 | 目前只有 Boolean 星閉包與 Heyting 的 meet-residual；矩陣左右 residual 未實作 |
| Presheaf／sieve 子物件 | Ω 在 presheaf topos 中由 sieves 給出，是有限 Heyting 的範疇化版本 | 未來可把開集片語推廣到 symlib presheaves；本輪先做點集 Alexandrov 層 |
| Blueprints／bands／`F_1` 幾何 | 在環、半環、么半群與 hyperfield 之上建立共同概形論 | 長期幾何軸；需先定義有限 blueprint 的乘法么半群與加法關係，不以現有 Spec 改名冒充 |
| Cubical modal type theory | 不同 modes 是 cubical type theory 的副本，由 dependent right adjoints 連接 | 可啟發「成員即 mode」的語言，但目前沒有 mode 形成規則、鎖鑰或相干定理 |
| Derived／homological 統一 | 以鏈複形、導出函子與同調不變量比較代數表示 | 第二波已有有限秩／SNF 片段；未擴成導出範疇 |

## 後續施工順序

1. **賦值多變量初始形式**：先為精確整係數多變量表示定義
   權重與 p-進係數賦值的共同輸入，再做 initial form 是否
   含單項式的有限權重判定；不可直接把 F_p lex GB 改名。
2. **有限關係 quantale**：為 Boolean 矩陣合成增加左右
   residuals，窮舉伴隨律，並與 symlib 可達性、semiring
   星閉包互校。
3. **Presheaf Heyting**：在有限範疇的 representable 上以
   sieves 建子物件格，檢查 pullback 與 Heyting 運算如何
   退化到本輪 Alexandrov 開集。
4. **有限 blueprint**：只取有限乘法么半群加有限加法關係，
   用 finalg 理想與 semiring 半環各給一個可對照的實例。
5. **Theory/mode 註冊**：在有可執行 theory morphism 前，
   只保留研究登記，不先增加裝飾性的註冊表欄位。

## 核心書目

- Andrew J. Chan, Diane Maclagan, *Gröbner bases over
  fields with valuations*, Mathematics of Computation 88
  (2019), 467–483；[arXiv:1303.0729](https://arxiv.org/abs/1303.0729)。
- Diane Maclagan, Bernd Sturmfels, *Introduction to Tropical
  Geometry*, AMS Graduate Studies in Mathematics 161 (2015)。
- Diane Maclagan, Felipe Rincón, *Tropical ideals*,
  Compositio Mathematica 154 (2018), 640–670；
  [arXiv:1609.03838](https://arxiv.org/abs/1609.03838)。
- Jeffrey Giansiracusa, Noah Giansiracusa, *Equations of
  tropical varieties*, Duke Mathematical Journal 165
  (2016), 3379–3433；[arXiv:1308.0042](https://arxiv.org/abs/1308.0042)。
- Oliver Lorscheid, *The geometry of blueprints. Part I*；
  [arXiv:1103.1745](https://arxiv.org/abs/1103.1745)。
- Matthew Baker, Tong Jin, Oliver Lorscheid, *New building
  blocks for `F_1`-geometry: bands and band schemes*, Journal
  of the London Mathematical Society 111 (2025), e70125；
  [arXiv:2402.09612](https://arxiv.org/abs/2402.09612)。
- Arne Kuhrs, Alejandro Martínez Méndez, Pedro Souza,
  *On Bands and Limit Theorems in Tropical Geometry* (2026
  preprint)；[arXiv:2605.07991](https://arxiv.org/abs/2605.07991)。
- Alain Frisch, Giuseppe Castagna, Véronique Benzaken,
  *Semantic subtyping: dealing set-theoretically with
  function, union, intersection, and negation types*, Journal
  of the ACM 55(4) (2008), 19:1–19:64；
  [doi:10.1145/1391289.1391293](https://doi.org/10.1145/1391289.1391293)。
- Martin Hyland, John Power, *The Category Theoretic
  Understanding of Universal Algebra: Lawvere Theories and
  Monads*, ENTCS 172 (2007), 437–458。
- Soichiro Fujii, *A unified framework for notions of
  algebraic theory*, Theory and Applications of Categories
  34 (2019), 1246–1316；
  [arXiv:1904.08541](https://arxiv.org/abs/1904.08541)。
- Saunders Mac Lane, Ieke Moerdijk, *Sheaves in Geometry and
  Logic: A First Introduction to Topos Theory*, Springer
  (1992)。
- Frederik Lerbjerg Aagaard, Magnus Baunsgaard Kristensen,
  Daniel Gratzer, Lars Birkedal, *Unifying Cubical and
  Multimodal Type Theory*, Logical Methods in Computer
  Science 20(4) (2024)。
