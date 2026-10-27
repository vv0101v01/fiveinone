# golden — cubical-hermitian 五成員 MoonBit 聯邦

儲存倉：<https://github.com/vv0101v01/golden>。MoonBit module 與全部
import 身份刻意維持 `vv0101v01/cubical-hermitian`；倉庫名 `golden`
不改寫套件身份。

> 🚧 **工程缺口總表（置頂）：[docs/ENGINEERING-GAPS.md](docs/ENGINEERING-GAPS.md)**
> 未完成事項、限制與優先級先看該表頂部摘要。所有測試執行已按
> 負責人決定暫停，移至該表文末，不列現行優先待辦。

本文件同時是儲存倉門面與聯邦首領 cubical 成員的 `README.md`。
cubical 成邦前的長篇技術正本保存在根目錄唯一的
[SPEC.md](SPEC.md) 與 [GUIDE.md](GUIDE.md)；其餘四個成員各在自己的
根目錄保存一份 `README.md`。成邦後事項只寫入中央新文檔，不回寫
成員的成邦前歷史。

## 直接 3＋2，而不是在三聯邦上再疊一層

舊作法是「三聯邦之上再疊五聯邦」：原 `bridge/` 只連 cubical、
symlib、semiring，另外建立 `unified/` 連五者，`unified` 再依賴
`bridge`。這會形成兩個權責重疊的整合層、兩組註冊／證書入口和一條
不必要的依賴鏈。

現行作法是直接把 finalg、catmath 加入同一聯邦：原 `bridge/`
就地擴張為**唯一的五成員聯邦核心**；舊三支柱定理保留原位，新增
`federation_*.mbt` 連接兩個新成員。獨立 `unified/` 與
`cmd/unified/` 已刪除，`cmd/showcase/` 直接展示同一個 bridge。
因此「五聯邦」不是三聯邦的外殼，而是 3＋2 後的單一聯邦。

五個成員仍保留真身與獨立 namespace，彼此不作橫向 production
import；跨成員轉換、共同不變量、交叉核對與推導定理只在
`bridge/` 明示方向、前提、成本與語義邊界。相容性總表見
[docs/BRIDGE.md](docs/BRIDGE.md)。

2026-10-27 的大一統研究、第三波切片與五個 GU 有限核心見
[docs/GRAND-UNIFICATION.md](docs/GRAND-UNIFICATION.md)：多變量
valued initial forms、關係 quantale residuals、presheaf
sieves、有限 blueprints 與 theory morphisms 均已在唯一
bridge 落地；完整 tropical variety、一般賦值 Gröbner 基、
blueprint／band schemes 與一般子型別系統仍屬後續缺口。
同日去重後先以 82/100 作 v1 收貨，GU 施工後按同一
「可相容有限共同片段」口徑覆核為 87/100；這不是全部
原生功能的覆蓋率。

## 五個成員

| 成員 | golden namespace | 成邦前正本 | 主要內容 |
|---|---|---|---|
| cubical／Hermitian 與精確代數（聯邦首領） | 根套件、`algebra/` | 本文件；長文 [SPEC](SPEC.md)、[GUIDE](GUIDE.md) | 依賴 cubical 核心、Kan 操作、計算性 univalence、精確 BigInt 代數與 Hermitian 譜證書 |
| 有限對稱 symlib | `symlib/` | [symlib/README.md](symlib/README.md) | 圖規範形、自同構群、有限範疇、預層、G-集與可執行證書 |
| 半環路徑代數 | `semiring/*` | [semiring/README.md](semiring/README.md) | 半環 traits、稠密／CSR 矩陣星閉包、加權圖、熱帶幾何、正則語言與量測基礎設施 |
| moon-algebra（finalg） | `finalg/`、`finalg/*` | [finalg/README.md](finalg/README.md) | 有限域多項式與 Gröbner 基、有限代數／模、有限幾何與概形、有限 HoTT、範疇化及整數／有限域規範形 |
| catmath | `catmath/`、`cmd/catmath/` | [catmath/README.md](catmath/README.md) | 有限範疇與群胚、自由構造、同調／高維代數、規範形與計算型別論模型 |

中央治理文件只在首領根目錄保存一份：[AGENTS.md](AGENTS.md)、
[SPEC.md](SPEC.md)、[GUIDE.md](GUIDE.md)；英文版與逐符號附錄是同一
中央文檔組的語言／生成附件，不在成員目錄再複製。全倉入口見
[文檔索引](docs/README.md)，權威現況見 [docs/STATUS.md](docs/STATUS.md)。

## 快速開始（本階段只編譯）

```bash
git clone https://github.com/vv0101v01/golden.git
cd golden
export PATH="$HOME/.moon/bin:$PATH"
moon update
sh tools/check_compile.sh
```

目前是 **compile-only** 階段：全部新舊 test/wbtest 源碼都在倉內並經
`moon test --build-only` 編譯，但依負責人指示不執行單元測試、
showcase、demo、benchmark、慢報告或 proof。真正的運行期閘門須
另行獲授權後才啟用，見 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 治理快照

機器清單目前包含 **39 packages、48 components、330 `.mbt` files、
135,485 `.mbt` lines、6,610 public symbols**；數字由
`tools/arch_check.py`、`tools/doc_check.py` 與
`tools/audit_spec.py --check` 交叉核對。架構正本是
[architecture.json](architecture.json) 與
[ARCHITECTURE.md](ARCHITECTURE.md)，逐符號分類見
[SPEC-APPENDIX.md](SPEC-APPENDIX.md)。

早期已公開的三系統樹曾實測 wasm-gc 336/336、native 340/340、
`cmd/main` 90/90 與舊 bridge showcase 5/5；這些是舊樹歷史證據，
不是現行五成員樹的運行期證明。現行樹所有測試執行已暫停，不列現行優先事項；非負責人另行要求，不安排恢復。

## 聯邦首領：cubical 成員概覽

根套件提供 Hermitian 冪等投影與正交特徵空間分解、cubical 區間／
面／系統、Kan comp、類型化 η-long NbE、依賴 Π／Σ 與累積宇宙、
PathP 與 Bool/Nat/List、Circle/Torus HIT、Glue 與計算性 ua、
通用歸納族與有限維 HIT schema、HOAS、ROBDD／DPLL／CDCL 符號
判定，以及模組編譯、工件鏈與成本控制。精確 `algebra/` 提供有理與
代數擴張、廣義特徵空間、Jordan 分解、因式分解、根隔離／分裂域、
根式去嵌套與數值譜層的精確證書影子。

這些敘事的正式邊界以 [SPEC.md](SPEC.md) 第四章及
[工程缺口登記](docs/ENGINEERING-GAPS.md) 為準；本 README 不把有限、
抽樣或表示受限的檢查冒充一般證明。

## 授權

Apache-2.0，見 [LICENSE](LICENSE)。
