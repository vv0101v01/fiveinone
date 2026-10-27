> **文檔治理定位**：本檔是 `catmath/` 成員唯一的 `README.md`，
> 保存成邦前來源、設計與歷史證據；正文的數字與命令按其來源快照
> 理解。成邦後的位置、接口、現況與新限制只記錄於 [CATMATH](../docs/CATMATH.md)、[BRIDGE](../docs/BRIDGE.md) 與 [STATUS](../docs/STATUS.md)，
> 不回寫本成邦前正本。

# catmath — 範疇論與高維代數演算法庫（MoonBit）

> **合併後位置**：本文由 algo4（`3b3deaa9706ee5a3543c0fe0ac897167669e26a4`）
> 原 README 遷移而來，現行正本隨
> <https://github.com/vv0101v01/golden> 維護。函式庫位於倉庫根的
> `catmath/`，執行入口位於 `cmd/catmath/`，套件路徑為
> `vv0101v01/cubical-hermitian/catmath`。本文的 185 項測試與效能
> 數字是上游快照；golden 五系統本期只編譯、未重跑，現況見
> [STATUS](../docs/STATUS.md)，限制見
> [ENGINEERING-GAPS 的 CAT 區](../docs/ENGINEERING-GAPS.md)。


以 MoonBit 實作的範疇論、同倫論與高維代數演算法庫。
所有運算邏輯於**編譯時**經單態化（monomorphization）特化，
實現**零成本抽象**；核心演算法經複雜度精煉
（指數 → 多項式、$O(n^3)$ → $O(n^{2.807})$ 等）。

## 安裝

```bash
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
export PATH="$HOME/.moon/bin:$PATH"
git clone https://github.com/vv0101v01/golden.git
cd golden
moon update
```

## 使用

```bash
# 本期在 golden 根目錄只做 compile-only：
sh tools/check_compile.sh

# 窄範圍編譯 catmath 與其展示：
moon build --deny-warn catmath cmd/catmath bridge cmd/showcase

# 未來運行期（須先獲專案負責人指示）才執行測試與展示：
GOLDEN_RUN_TESTS=1 sh tools/check_full.sh
# benchmark 仍是獨立人工步驟，不屬目前閘門。
```

## 模組地圖

| 模組 | 數學內容 | 核心演算法 |
|---|---|---|
| `category.mbt` | 範疇、函子、自然變換、Yoneda | 同構類枚舉、擬逆驗證 |
| `algebra.mbt` | 群、矩陣、模運算 | 平方–乘冪 $O(\log n)$、Strassen $O(n^{2.807})$、NTT $O(n\log n)$、Karatsuba $O(n^{1.585})$、zeta/Möbius $O(n2^n)$ |
| `topos.mbt` | 預層拓撲斯、子對象分類器 | 篩枚舉、Ω 拉回 |
| `ccc.mbt` | 笛卡爾閉範疇、STLC | 柯里化、de Bruijn 代入 |
| `linear.mbt` | MLL 證明網 | **GMM 收縮準則 $O(n^2)$**（對 DR switching $O(2^p n)$）、切消除 |
| `homott.mbt` | HoTT：$S^1$ 路徑代數 | 編碼–解碼 $\pi_1(S^1)\cong\mathbb{Z}$ |
| `derived.mbt` | 導出代數幾何：Dold–Kan、Tor | Moore 複形、正則化、bar 分解 |
| `operad.mbt` | 對稱 operad、結合多面體 | $\gamma$ 合成、$End_X$ 窮舉、Catalan 計數 |
| `homotopy_algebra.mbt` | $A_\infty$ 代數、同倫轉移 | $m_3$ 轉移、Stasheff 五邊形、Massey 積 |
| `topology.mbt` | 有限拓撲（Alexandrov 對應） | Warshall 閉包、$T_0$ 化、同胚搜尋 |
| `free.mbt` | 自由幺半群/自由群、伴隨 | $O(n)$ 棧歸一、萬有性質驗證 |
| `groupoid.mbt` | 群胚、交叉模 | $\pi_0/\pi_1$ 計算 |
| `cohomology.mbt` | 群上同調（bar 分解） | $H^n(G,M)$ 維數 |
| `galois.mbt` | Galois 範疇 | 傳遞 $G$-集 ↔ 子群共軛類 |
| `tannaka.mbt` | Tannaka–Krein 對偶 | 交換子計算、$\mathrm{Aut}^\otimes(\omega)$ |
| `pseudo.mbt` | 偽函子 $B\mathcal{G}\to\mathcal{Cat}$ | 嚴格化（上循環 → 餘邊界） |
| `flat.mbt` | 平坦函子 | 拉回保持、餘篩選判定 |
| `systems.mbt` | 動力系統（函子 ℕ→Set） | Floyd 龜兔 $O(\mu{+}\lambda)$、環分解 $O(n)$、二進制提升 $O(\log m)$ |
| `algorithms.mbt` | 複雜度比較樞紐 | 各演算法 naive 對照 + 步數計數 |
| `zerocost.mbt` | 零成本抽象示範 | trait 單態化、`#inline` |
| `canonical.mbt` | **規範形式總彙（五大範疇）** | Smith 範形、βη-長範式、骨架、core、Read 樹規範化、特徵標分解 |

## 複雜度降低（上游基準快照；golden 本期未重測）

```
pow_mod_refined           55 ns     pow_mod_naive        374 µs   (≈6800×)
poly_mul_ntt             298 µs     poly_mul_naive       3.25 ms   (≈11×)
zeta_sos                 2.4 µs     zeta_naive            64 µs    (≈27×)
gmm_parsing_polynomial   1.0 µs     dr_switching_exp.    2.45 ms   (≈2450×)
ds_iterate_binary_lifting 19 ns     ds_iterate_naive     1.47 ms   (≈78000×)
conjugacy_canonical_n2   7.4 µs     conjugacy_permutation 60.8 ms  (≈8200×)
tree_canon_read_nlogn    4.0 µs     tree_canon_enum.      6.4 ms    (≈1600×)
generic_sum              317 ns     specialized_sum      317 ns    (零成本)
```

## 數學文件

見 [MATH.md](MATH.md)——全部定義、定理與公式
（LaTeX 風格），按模組分節。

## 許可

Apache-2.0
