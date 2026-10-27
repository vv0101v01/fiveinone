# Bridge：三支柱跨界橋接

`bridge/` 是單向整合層，只能依賴 cubical root、精確 `algebra/`、`symlib/` 與
`semiring/*`，三支柱不得反向 import bridge。橋接不合併或改名任何支柱的原生
型別：每項結果先以來源世界的型別表達，再由另一世界的判定器或規範形式重驗。

| 橋 | 輸入 → 輸出 | 誠實邊界 |
|---|---|---|
| 置換/wiring | `symlib.Perm ↔ cubical.Wiring/Equiv`、`CMat` 置換矩陣與群平均 | 帶號 wiring 的底置換與每輸出號列分開讀回；S4 全 24 元及 16 個 Bool 值逐一核驗 |
| 加權有向圖 | semiring CSR 圖 → support＋頂點簽名顏色 → symlib colored 搜尋 → 雙權重逐邊精確過濾 | 顏色只剪候選，從不取代精確權重檢查；群平均只在枚舉完整時可宣稱投影器 |
| 複矩陣 | cubical `CMat` → 非零支撐色圖 → 候選置換 → 逐元近似保存 | 浮點保存沿用 cubical 既有容差，不包裝成精確證明 |
| 自由範疇 | semiring DAG 路徑 → symlib `FinCat` | 合成以刪去重複中點的路徑串接；非 DAG 直接拒絕，不截斷無限路徑集 |
| 熱帶指派 | `trop_det`／Hungarian 最佳值 ↔ symlib 全置換 | 枚舉均設 cap；最佳指派在同時行列對稱的共軛下核驗封閉 |
| 熱帶化 | 精確 `QPoly` → p-進係數賦值 → semiring `UniPoly` | 零係數送至熱帶 +∞；只陳述已驗算例（`(x−2)(x−4)` 在 p=2 得根 1、2） |
| Face 半環 | cubical `Face` → canonical ROBDD 包裝 `FaceClass` | 不得以 Face AST 結構等值冒充語義等值；⊕=∨、⊗=∧、0=⊥、1=⊤，由 semiring 定律檢查器重驗 |
| 胞腔對稱 | 2-胞腔正方形關聯圖（維數色）→ symlib 保色自同構 | 這是有限關聯圖包裝，不宣稱 cubical 高維胞腔的完整分類 |
| 統一證書 | 三支柱原生結果 → `BridgeCertificate` | 只統一總控與顯示，不抹除各支柱原生證書內容 |

`cmd/showcase` 執行全部第一批橋的穿越檢查，另展示有向加權 C4：
對稱數 4、可達有序對 16、有限距離和 24、群平均跡 1 且為投影器。
