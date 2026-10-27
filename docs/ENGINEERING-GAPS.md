# 工程缺口、未完善之處與待辦登記

> 最後全面盤點：2026-10-27。本文是全倉缺口的中央索引，不取代各支柱的
> 詳細限制章節。新增已知限制時先在此登記，再連回擁有該限制的文件或程式。
> [目前狀態](STATUS.md) 只寫已完成與已驗證的事實。

## 🚧 現行重點工程缺口（先看這裏）

- **公共 API 與安全**：`API-001` 結構化錯誤模型、`API-002`
  共用 budget／outcome、`API-003` 相容與穩定分級，以及
  `SEC-002` 的 `par_host` 臨時檔安全。
- **套件與 bridge 實施債**：`CAT-001` 已新增 catmath 靜態 SCC
  量測；實際拆包仍受 runtime 驗收暫停約束。`BRG-001`／`API-005`
  已改用無雜湊有向加權精確顏色及完整 canonical encoding；尚待
  runtime 差分／碰撞驗收。其餘按下方分域表處理。
- **理論擴張**：`GU-001`…`GU-005` 已完成有限核心；一般
  valued Gröbner、多面體 tropical variety、任意 presheaf
  子物件、blueprint／band 幾何與一般 theory／mode 仍在
  GU 分域表，不以有限片段冒充完成。
- **發佈與外部治理**：`REL-001`、`REL-003`、`REL-004` 屬來源倉遷移、版本與 GitHub 管理事項，分列於發佈分域表。

所有測試、smoke、proof、coverage 與 runtime workflow 已
按負責人決定暫停，集中移到文末「已暫停／非現行優先」；
不要再把測試未執行列入上述現行工程排序。

## 狀態與優先級

| 標記 | 意思 |
|---|---|
| `已關閉` | 本次更新已落地並有本倉證據 |
| `部分完成` | 可實作部分已落地；明確列出尚待驗收或外部決策的部分 |
| `待實作` | 可在本倉內完成，但尚未完成 |
| `待外部` | 需要儲存倉管理員或其他儲存倉操作 |
| `已接受` | 有意保留的設計／理論邊界；只能擴展範圍，不能靠換說法消除 |
| `研究級` | 需要新算法、形式化或研究工作，沒有可信的短工期 |
| `已暫停` | 負責人已決定不執行、不排期；只保存事實紀錄，不列現行優先級 |

優先級：`P0` 會阻止可信發佈；`P1` 應在下一個功能期前處理；`P2` 是
可維護性／規模工作；`P3` 是研究或長期擴展。目前沒有已知的 P0 正確性
缺陷；「沒有登記」不等於形式證明了不存在缺陷。`已暫停` 項目不使用
現行 P 級排序；文末括號內的原 P 級只作歷史對照。

## 本次已關閉項目

| ID | 關閉內容 | 證據 |
|---|---|---|
| DOC-001 | 主倉推送前敘事已從現行文件移除；首次公開提交由 STATUS 與遷移決策史記錄 | [STATUS](STATUS.md)、[MIGRATION](MIGRATION.md) |
| DOC-002 | 獨立合併研究快照已濃縮入遷移決策史並從工作樹刪除，現況只由 STATUS 承擔 | [MIGRATION](MIGRATION.md)、[STATUS](STATUS.md) |
| DOC-003 | 中央文檔索引、現況、缺口登記、貢獻流程與 CHANGELOG 已建立 | [文檔索引](README.md)、[CONTRIBUTING](../CONTRIBUTING.md)、[CHANGELOG](../CHANGELOG.md) |
| DOC-004 | `AGENTS.md` 已更新為五成員＋唯一 bridge 的直接 3＋2 全圖 | [AGENTS](../AGENTS.md) |
| ENG-000 | fast／full／slow 檢查入口已腳本化；文檔連結、索引與治理數字有機器閘門 | `tools/check_*.sh`、`tools/doc_check.py` |
| DOC-005 | MoonBit 模組描述與關鍵字已更新為五系統聯邦 | `moon.mod` |
| INT-000 | algo 的 12 個 packages、algo4 函式庫與兩者全部 test/wbtest 已機械搬入；finalg 以明確 `pub extend` 取代全域 warning 抑制，catmath executable 已拆至 `cmd/catmath`，五系統接口先集中施工，現已併入唯一 `bridge/` | [BRIDGE](BRIDGE.md)、[MIGRATION](MIGRATION.md) |

| GU-001…005（有限核心） | 多變量 valued initial forms、Boolean／有界 tropical relation quantales、representable sieves、finite blueprints 與兩條 theory morphisms 已在唯一 `bridge/` 落地；一般理論餘項留在下方 GU 表，不以有限核心改名結案 | `bridge/federation_valued_initial.mbt`、`federation_relation_quantale.mbt`、`federation_presheaf_heyting.mbt`、`federation_blueprint.mbt`、`federation_theory_modes.mbt`、[GRAND-UNIFICATION](GRAND-UNIFICATION.md) |
| BRG-007 | bridge 證書已有 v1 envelope、canonical length-prefixed 序列化、雙 FNV-1a 摘要與 registry 重驗 API；envelope 不另列語義證書 | `bridge/certificates.mbt`、[BRIDGE](BRIDGE.md) |

## 發佈、歷史與儲存倉治理

| ID | 優先級／狀態 | 缺口與影響 | 證據／下一步與驗收 |
|---|---|---|---|
| REL-001 | P1／待外部 | `algorithm01`、`algorithm03` 尚未加入遷移告示，也未在 GitHub Archive；`algo`、`algo4` 亦未貼五系統遷移告示，使用者仍可能在來源倉取得過時入口 | 四倉告示草案已改指向目前五成員主線 [fiveinone](https://github.com/vv0101v01/fiveinone)；仍須管理員提交四倉告示，再決定是否封存。驗收是四倉首頁告示可見且連結正確；封存需額外確認為 read-only |
| REL-003 | P1／待實作 | 尚無版本 tag、GitHub Release、簽章、SBOM 或來源 attestation；module 仍是 `0.0.1` | 先定版號策略並發第一個 tag；Release 至少附 commit、工具鏈、測試數字與已知限制，簽章／SBOM 在有外部使用者後再升級 |
| REL-004 | P1／待外部 | workflow 已入倉，但 branch protection、required checks、Actions 權限、Dependabot 與私密漏洞通報均不在程式碼可控制範圍 | 管理員啟用 required checks 後，以一個故意失敗的 PR 驗證不能合併；未驗證前不得宣稱 CI 是強制閘門 |
| REL-005 | P2／待外部 | GitHub 倉庫 description、topics、homepage 與 social preview 未納入版本控制 | 在 Settings 設定五系統描述；把最終文字回填 STATUS，避免倉庫頁面與 README 分叉 |
| SEC-001 | P2／待實作 | 尚無 `SECURITY.md` 或漏洞披露流程；cubical 工件 checksum 只防意外損壞，不是密碼學簽章 | 決定私密通報渠道後新增 SECURITY；需要可信發行時再引入簽章金鑰管理，不得把一般 checksum 升級宣稱為簽章 |

## CI 與可重現性（不含測試執行）

| ID | 優先級／狀態 | 缺口與影響 | 證據／下一步與驗收 |
|---|---|---|---|
| ENG-003 | P2／部分完成 | 固定 CI 使用 `tools/install_moonbit.sh`，從 `.moon-toolchain` 固定 Moonc release，對 Linux x86_64 MoonBit 和 core archive 做 SHA-256 pin；compile gate 同時檢查 moon/moonc 完整版本。尚無 separate latest-canary job，且目前只有 Linux x86_64 pinned installer | Linux x86_64 下載完整性及重現版本已落地；如增加 runner 平台，需各自記錄 archive digest；可再加非阻斷 latest canary，但不得取代固定閘門 |
| ENG-007 | P2／已接受 | `arch_check.py` 是唯讀源碼近似推導，不是編譯器型別圖；`observer` 組件可合法星形依賴，不能用它證明任意新邊都合理 | 新 package／跨支柱邊仍須人工裁決；若 MoonBit 提供穩定依賴圖 API，再用編譯器輸出取代匯入掃描 |
| ENG-008 | P2／待實作 | `.mbti` 與逐符號附錄均入庫，雖有 drift 閘門，但沒有 PR 摘要自動列出公共 API 增刪，審查大型生成 diff 成本高 | 產出按 package／kind 分組的 API diff 摘要供 PR 使用；生成檔本身仍不得手改 |


## 公共 API、錯誤模型與相容性

| ID | 優先級／狀態 | 缺口與影響 | 證據／下一步與驗收 |
|---|---|---|---|
| API-001 | P1／待實作 | 以 `abort(` 文字計，生產碼約 287 處（finalg 131、symlib 98、semiring 25、bridge 23、catmath 9、cmd 1；`unwrap` 等其他 panic 邊未計）；外部呼叫者對形狀錯誤、上限與前提失敗拿不到結構化錯誤 | 先按「不可恢復不變量／使用者輸入／資源上限」分類，再為 bridge 與新 API 提供 `Result` 版本；不得一次機械改寫 6,610 個符號 |
| API-002 | P1／待實作 | 上限參數、回傳慣例混雜：`Int32 cap`、`Int64` 計數、Option、Bool 驗證器與 abort 並存；超限是否完整、是否部分結果要逐 API 查文檔 | 定義共用 budget／outcome 形狀和命名規則，優先套用到列舉 API；每個新 API 必須明寫完整、截斷或失敗語義。2026-10-27 新增 GU API 已先統一用 `Option` 或 `valid/supported` 報告並寫明窮舉上限，但全倉共用 budget 型別仍未定 |
| API-003 | P1／部分完成 | [API-STABILITY](API-STABILITY.md) 已定義 0.x/1.0.0 前相容原則、Stable/Experimental/Test-support 級別及變更要求；目前仍沒有逐符號 Stable allowlist，也未實際發出 tag/Release | 在首個穩定版前由維護者核准 allowlist 與棄用期限；每次公開符號變更更新 changelog 和生成介面。此政策不等於已發佈 1.0 或已承諾所有 6,610 個符號穩定 |
| API-004 | P2／已接受 | 兩個 `algebra`、兩個 `Graph`、`Rat`、`Mat` 等同名概念造成 alias 負擔 | 聯邦邊界刻意保留；所有跨套件範例必須用完整路徑或 `exact`、`searched`、`weighted` 等語義 alias，索引不可裸寫「algebra」 |
| API-005 | P2／部分完成 | `weighted_graph_report.canonical_encoding` 已改為完整加權有向圖鍵：以 source/target port 有色 incidence gadget 保留方向、邊存在、兩個精確權重通道及自環，並把 exact weight palette 加入序列化前綴；欄位名為相容性保留 | 算法與 relabel／方向／權重／自環回歸案例已加入並 compile-only 驗證；尚待 runtime 差分驗收。Incidence graph 每條邊增三頂點，而目前 canonicalizer 使用近似平方記憶體的簡單圖表示；需另定 size/budget 後才可宣稱適合大圖。`canonical_colors` 仍是 support-search 診斷色列，不等同完整圖鍵 |
| SEC-002 | P1／部分完成 | `semiring/par_host` 已改用 `@fs.tmpdir` 原子建立 per-call 私有目錄、`CreateNew` 建立權限 `0600` 檔案、傳播 I/O 失敗並以 defer 清理；不再使用固定 `/tmp` 名稱或忽略寫入結果。compile-only 已覆蓋程式碼與 wbtest 編譯，但因目前停跑 runtime 尚未實際做雙程序併行驗收 | 下次獲准運行 native I/O 驗收時確認兩程序互不覆寫、失敗路徑清理及 Windows 支援；在 runtime 證據前維持「部分完成」 |

## cubical 根套件與精確 `algebra/`

以下不是漏測，而是可執行語義模型的明文理論邊界；詳細理由以
[SPEC §4「誠實邊界」](../SPEC.md) 為準。

| ID | 優先級／狀態 | 缺口與影響 | 下一步／驗收方向 |
|---|---|---|---|
| CUB-001 | P3／研究級 | inductive schema 的正性仍是受信不透明欄位，受驗 lambda 只是較小函子片斷；同時歸納—遞歸兩條路線與惰性 union 路線不完備 | 需把正性檢查、嚴格函子與 kernel 規則做成可判定證書；在完成前只能稱「受信 schema＋已驗證片斷」 |
| CUB-002 | P2／已接受 | DSystem 相關支撐、最大相容完成與 Bool 差異切分仍可指數增長；最大完成本質是最大團，budget 耗盡時只回 incumbent 與 `exact=false`，不列舉其他最大元；Nat 無對應切分，Circle／Torus 方塊 comp 只在候選座標可逐分支面驗證時計算，任意宿主／端點相合盒可停在形式 `DNComp` | 每個入口保留 budget／exact 狀態；效能工作先做共享／記憶化，不得把未完成搜尋包裝成反例或完備合成 |
| CUB-003 | P2／待實作 | 持久化工件沒有跨格式共享圖、增量 delta、作業系統檔案同步、多寫者或密碼學簽章；舊版工件有 bootstrap 信任 | 若要作外部交換格式，先定版本、原子寫入與簽章威脅模型；現階段定位是程序內證書與文字工件 |
| CUB-004 | P2／已接受 | 一般因式分解在無合適證書時，最壞成本仍由 Kronecker 列舉與 BigInt 位長支配，現有證書只判不可約性而不加速一般分解輸出；多二次擴張以四個獨立生成元為上限，第五生成元、未處理的被開方形狀與一般代數數根在支援外回 `None` | 新增算法必須與直算差分對拍；支援外維持 Option，不得回近似冒充精確值 |
| CUB-005 | P2／已接受 | 精確 BDD 變量序 DP 硬上限 `n≤16` 且成本仍約 `O(n·2^n)`；CDCL 證明是 DRUP 而不是 DRAT，完整 replay 也有成本；宿主立方 Tier D 是有限探針，高 arity 會回 `complete=false`；自適應 Jacobi 需以特徵多項式／Sturm 作精確後援，高重數與極小分離的成本不變 | 擴展前先定共享／證書檢查與成本模型；所有上限、未達標與 incomplete 狀態保留在回傳值和規格行中 |
| CUB-006 | P3／研究級 | 球面已覆蓋代表元、3-胞與閉環路式正規化，但仍缺任意中性環路的分類引理、完整內部 `π₁(S¹)≃ℤ`、一般同倫群、Eckmann–Hilton／pentagon 相干、內部 Hopf 映射與不變量 | 這是類型論研究工作；現有結果只能按已命名的代表元片斷引用 |
| CUB-007 | P3／已接受 | HOU 殘差求解一般只給 specific unifier，沒有完備 CSU 或非 pattern 形狀保證的 MGU，預算耗盡不表示無解；版本協商與 artifact 尚無身份簽章、遠端傳送或未宣告未來格式支援 | 保持「部分策略＋預算」定位，任何完備性主張必須先限定可判定片段；傳輸層需另定身份與相容政策 |
| CUB-008 | P3／研究級 | univalence 是可執行語義證書與填充公式，不是證明助理中的封閉形式證明，也不是完整生產 kernel | 若要升級，需要把核心規則移植到可獨立檢查的最小 kernel，並逐條卸除受信欄位 |

## `symlib/`

詳細限制在 [symlib 長文 §7](../symlib/README.md)；這裏登記工程後果。

| ID | 優先級／狀態 | 缺口與影響 | 下一步／驗收方向 |
|---|---|---|---|
| SYM-001 | P2／已接受 | 圖同構全域搜尋本質可指數爆炸；完全圖／空圖等高度規則大圖在 `n≥16` 可變得不可行，文件中的 E16 全搜尋明確不可行 | 已用連通分量與補圖分解繞過常見病態；進一步需要 partition refinement／canonical augmentation 的新搜尋核心 |
| SYM-002 | P1／待實作 | colored search 只支援固定語義的頂點顏色，不允許顏色全域重命名；原生 `Graph` 仍不表示有向邊、邊色、多重邊、自環或超邊 | 先決定在 symlib 增原生有向／邊色圖，還是把完整加權搜尋留在 bridge；驗收須含同 support、異方向／異權重的反例 |
| SYM-003 | P2／已接受 | `perm_key64` 上限 `n≤12`；子群、共軛類與置換列舉均有 caps；刪生元動態剪枝未完全實現 | API 狀態必須區分完備與截斷；換任意精度或 bitset 前先做 E8／E16 規模回歸 |
| SYM-004 | P2／待實作 | 群階與計數多用 `Int64`，大群可溢位；canonical encoding 保證同構不變但不是字典序最小標準標籤 | 為階數提供 overflow 狀態或 BigInt 變體；若要宣稱 canonical labeling，必須以暴力最小標籤差分測試 |
| SYM-005 | P2／待實作 | 部分子群分類只在已生成子群上完備，隨機 Schreier 類入口若截斷，生元可能不完整 | 高階入口回傳 completeness 旗標；登記在 SYM-003 的共用 outcome 改造中一併處理 |

## `semiring/*`

詳細限制在 [semiring README §7](../semiring/README.md) 與
[DESIGN §19](../semiring/DESIGN.md)。

| ID | 優先級／狀態 | 缺口與影響 | 下一步／驗收方向 |
|---|---|---|---|
| SEM-001 | P2／待實作 | 稀疏 Kleene 每輪走通用乘加與多次陣列重建，沒有 reserved／allocation-free merge、NUMA 或線上 autotune | 先量測分配熱點，再加容量保留；結果必須與現有稠密／稀疏差分 oracle 全等 |
| SEM-002 | P2／待實作 | 沒有真正 CPU 多執行緒；`async` host 是單執行緒分工，native-only，且要先 `moon update` 取依賴 | MoonBit 執行緒模型成熟前不可宣稱 CPU 並行；host 可攜性缺口另見 SEC-002 |
| SEM-003 | P2／已接受 | belief propagation 只在樹上精確，有環圖不保證收斂或等於 brute force；無 junction tree、GBP、連續／高斯訊息 | 擴展時每個新推理器要與小圖 brute-force 對拍；loopy BP 繼續明標近似 |
| SEM-004 | P2／已接受 | 熱帶子分割只有二變數、一般複雜度 `O(m^4)` 檢查；無高維、增量凸包、穩定交、重數或退化面原語；主係數多為 `Int32` | 高維化是獨立算法期；先確保現有二變數退化例有覆蓋，不得把二變數繪圖拓樸升級宣稱一般熱帶幾何 |
| SEM-005 | P2／已接受 | NFA 正規形只判定 Kleene／自由冪等片段，且最小化走 Moore 而非 Hopcroft；一般半環等價有共同模式錯誤 | 需要更強公理完備片段或外部 oracle 時，明寫可判定範圍與反例，不以多數決冒充證明 |
| SEM-006 | P2／待實作 | 稠密矩陣只有 row-major 形狀；稠密 bitset closure 大圖記憶體成本高；形狀錯誤多以 abort 處理 | 先定形狀錯誤 API（API-001），再評估 blocked／sparse 表示；不得為加速破壞現有代數 oracle |
| SEM-007 | P2／待實作 | `REPORT.md` 不記錄 CPU、OS、commit 與完整 toolchain 欄案，數字不可跨機器嚴格重現 | 報告產生器加環境欄案與命令；CI artifact 保存原始輸出，入庫快照仍經人工審查 |

## `finalg/`

詳細 package 圖與 proof 資產見 [FINALG](FINALG.md)。

| ID | 優先級／狀態 | 缺口與影響 | 下一步／驗收方向 |
|---|---|---|---|
| FIN-002 | P2／已接受 | finalg 核心是 `Int32` 模數、指數與小矩陣正規形；Gröbner、有限枚舉與 SNF/HNF 的實用邊界遠小於任意精度 CAS，多處前提以 abort 表達 | 保持有限小規模定位；若要擴展，先為模數／係數引入 BigInt 路徑並逐算法做差分 oracle，不得只放大型別而沿用未審的複雜度假設 |
| FIN-003 | P2／已接受 | `finalg/cat` 的閉包 Category 不能一般地枚舉回有限表；finite scheme/HoTT 也只是有限呈現模型，不是一般概形論或完整 HoTT kernel | 轉接只定義表格→閉包方向；新增一般理論主張前必須給出有限化前提或獨立語義證明 |
| FIN-004 | P2／待實作 | `finalg/testutil` 是公開 package 並進入符號附錄，但定位只是 test fixture；若被生產碼長期依賴，會把確定性測試產生器誤升成穩定 API | 在 API 穩定分級中標為 test-support；`architecture.json`／`moon.pkg` 繼續只允許 test-scope 匯入 |
| FIN-005 | P2／已接受 | `finalg/port` 的接口移植是簽名字串／記錄模型，不是 MoonBit 編譯器 AST 級遷移器；不能證明語義、trait 解析或生成介面相容 | 只作盤點與報告；真正遷移仍須編譯器、`.mbti` 與測試輸出三重核對 |

## `catmath/`

詳細內容分域與拆分事件見 [CATMATH](CATMATH.md)。

| ID | 優先級／狀態 | 缺口與影響 | 下一步／驗收方向 |
|---|---|---|---|
| CAT-001 | P1／部分完成 | 已新增 `tools/catmath_scc.py`；啟發式掃描 22 個 production `.mbt` 得 44 條檔案依賴邊、22 個 singleton SCC、0 cyclic SCC。這不是 MoonBit compiler 依賴圖，method dispatch／動態名稱仍可能漏邊 | `python3 tools/catmath_scc.py --list-edges` 可重現量測並列出 witness；每個拆包候選仍需人工核對真實型別／method 邊。實際拆包受 `AGENTS.md` 的 runtime evidence 要求與目前 runtime 暫停所阻，不得以此近似圖宣稱可安全拆分 |
| CAT-002 | P2／已接受 | 眾多 `verify_*` 是有限／抽樣可執行檢查，不是形式證明；公理窮舉的成本可達三次方或更高，函數名本身不記錄樣本域與完備性 | 與 DOC-009 一起在附錄外補逐函數域、複雜度與完備性元資料；引用時必須說清有限範圍 |
| CAT-003 | P2／待實作 | catmath `snf_int` 會就地改寫入參 `IntMat.data`；不熟悉此慣例的呼叫者可能在求 SNF 後誤用原矩陣（bridge 已以深拷貝構造避開） | 增加不變入參的 `*_copy`／report 變體或在型別／命名上標示 in-place；舊 API 的破壞性語義在相容政策前不得靜默改變 |
| CAT-004 | P2／部分完成 | `canonical_index`／`derived_index` 仍是手寫數學敘事，不能由治理腳本證明內容正確 | 已新增 `tools/catmath_index_check.py` 並掛入 compile-only gate：核對 production topic file/module 覆蓋、derived source labels 與 canonical entries/明示 aliases、derived theorem 名稱重複；深層宣告／測試語義仍須人工維護 |
| CAT-005 | P2／已接受 | 部分 catmath 群 API 實質假設單位元索引 `e=0`，`FinTop` 建構也會把關係自反化及傳遞閉包；bridge 只在明示小片段使用，原始 API 名稱本身不攜帶這些前提 | 增加 checked wrapper 或把前提進型別／命名，並為非零單位元與非閉包輸入加反例；在此之前 bridge 報告不得把片段結果推廣到任意標號 |

## 直接聯邦擴展（沿用原 UNI 編號）

| ID | 優先級／狀態 | 缺口與影響 | 下一步／驗收方向 |
|---|---|---|---|
| UNI-002 | P2／已併入 | 與 BRG-007 是同一 certificate envelope 工程債，不再重複維護 | 以 BRG-007 為正本 |
| UNI-003 | P2／已接受 | 直接橋已覆蓋有限範疇／群／G-集、單變量多項式、整數矩陣、布林函數、有限拓撲／Spec、功能圖、有限同調、S¹ 與窄 STLC；多變量 Q→finalg、一般 finalg scheme/module→catmath derived 等尚無共同資料模型 | 逐項以可逆性、反例、成本與來源判定器設計；不得為了覆蓋率在成員間共用私有表示 |
| UNI-004 | P2／待實作 | 群列舉、範疇表轉換與律檢查具平方／三次方成本，現以 `cap`／Option／Bool 分散表達，沒有共用 budget 或部分結果形狀 | 納入 API-002 的共用 outcome 設計；新轉接器先明寫大小上限與超限結果 |

## `bridge/` 與展示層

詳細語義與反例在 [BRIDGE](BRIDGE.md)。

| ID | 優先級／狀態 | 缺口與影響 | 下一步／驗收方向 |
|---|---|---|---|
| BRG-001 | P1／部分完成 | 候選群仍以 support graph＋精確無雜湊 one-hop 顏色（out/in 有序權重對多重集）搜尋，再逐邊精確驗證；顏色 key 不會因 hash collision 合併不同局部簽名，但仍可能留下大候選群 | 已完成精確顏色鍵；加入人造舊雜湊碰撞案例與大型候選 budget／性能處理，須待 runtime 測試重新授權後驗收；不可把候選縮小誤稱為完整邊色搜尋 |
| BRG-002 | P2／已接受 | 熱帶最優指派與完整對稱群需要列舉置換，具有 `n!` 本質成本與 cap；只接受有限橋接範圍的 `Int64` | 大規模入口應改回傳 generating set 或單一最優解；完整群 API 保留小 `n` 誠實版 |
| BRG-003 | P2／待實作 | 任意實／複浮點矩陣對稱只作 `eps` 近似檢查，沒有區間或譜誤差證書；projector 也繼承列舉上限 | 為可精確化的 0／1、置換與有理矩陣增加精確路徑；浮點路徑在名稱／回傳中保留 tolerance |
| BRG-004 | P2／已接受 | 自由範疇橋只接受 DAG，轉換會枚舉全部路徑並物化合成表；有環圖的自由範疇一般有無限多態射 | 有環版本只能採生成元＋關係或截斷長度表示，不能塞入現有 `FinCat` 全表 |
| BRG-005 | P2／已併入 | 一般有理賦值、多變數熱帶化與 Newton／根賦值 oracle 已由 GU-001 統一追蹤，不再重複維護 | 以 GU-001 為正本 |
| BRG-006 | P2／待實作 | Face 半環 star 在有限布爾格上恆為 top，尚無胞腔傳播應用；正方形胞腔只是固定展示，沒有一般定向、邊界符號或參數化胞腔複形 | 下一期橋接應先定 cell complex 資料型別與邊界算子，不再增加只含固定例子的符號 |
| BRG-007 | P2／已關閉 | bridge 證書現有 v1 envelope：canonical length-prefixed 序列化、雙 FNV-1a 摘要、逐項與全 registry 重驗 API（吸收原 UNI-002） | `BridgeCertificateEnvelope`、`bridge_certificate_envelopes_report`；摘要只作完整性 checksum，不是密碼學簽章，來源完整證據仍留在各支柱 |
| BRG-008 | P2／部分完成 | `weighted_graph_report` 已在單次報告內共用 candidate group、精確對稱過濾結果與 projector，並於昂貴 APSP 前先檢查 cap；但同時仍會做 incidence canonicalization、距離閉包與特徵多項式，沒有分段 budget 或部分報告 | 已消除報告路徑上的候選群重複計算；剩餘工作是可組合階段／共用 budget/outcome，並明寫每欄位成本和超限行為 |
| BRG-009 | P2／已接受 | cubical STLC 的 `quote_eta` 會把任何 `LUnit` 項塌縮為單位值，catmath `eta_long` 不對 `SOne` 中性項作同一塌縮；兩邊 raw normal form 因此不是同一相等 | bridge 報告同時保存 raw equality 與顯式 unit-η completion；若要 raw 相等，必須改 catmath 範形定義或引入型別化商，不可在橋中靜默抹除差異 |
| BRG-010 | P2／已接受 | 第二波交叉檢查多為小有限窮舉：assignments、子集、Hom、群元素與矩陣形狀在尺寸增大時成本急升，部分 API 只以 `Bool`/Option 匯總失敗原因 | 新報告先加成本欄位與分段 outcome；大規模版本必須換符號或增量算法並與窮舉 oracle 差分對拍 |

## 大一統後續理論軸（GU）

| ID | 優先／狀態 | 目前證據與缺口 | 完成標準 |
|---|---|---|---|
| GU-001 | P1／有限核心已實作；完整算法研究級 | 精確多變量 `Poly` 已有固定 p-進賦值與整數權重的 initial/residue forms、單項式判定、principal 精確有界分類、多生成元 sound exclusion／candidate，及單變量根與雙變量 BPoly/Newton oracles；尚無一般 Chan–Maclagan valued Gröbner、任意 initial ideal 完備判定或多面體 tropical variety（吸收原 BRG-005） | 下一步在同一精確表示上做 homogeneous valued Buchberger，並以 principal 分類為差分 oracle；不得把 lex GB 改名 |
| GU-002 | P2／有限核心已實作；概形化研究級 | 有限交換乘法么半群＋成對加法關係、formal-sum normalizer 與小和同餘／合流報告已落地，並有自由么半群、`F_p`、finalg 有限代數／distributive 理想格、Bool／有界 tropical 與 FinTop/Spec opens 實例 | 一般 blueprint／band 仍需態射、局部化、Spec、覆蓋與黏合；在有這些定理前只稱有限 presentation |
| GU-003 | P1／有限核心已實作；一般化待實作 | representable 上的 sieves 已窮舉 Heyting 運算、伴隨與 pullback，並與 opposite-thin Alexandrov opens 局部退化互校；任意 presheaf 子物件、一般 STLC 子型別與 coercion 相干性未實作 | 先擴到任意有限 presheaf 的逐點子物件與自然性；型別層子型別另立規格，不把 refinement 包含直接等同語法子型別 |
| GU-004 | P2／有限核心已實作 | Boolean 關係與有界非負 tropical 矩陣均有左右 residuals、伴隨窮舉（在明示小域）、star 固定點，並與 semiring 原生乘法／閉包及 Boolean support 可達性互校 | 無界、任意符號或一般 quantale 需另定完備格與飽和算術規格；現行報告的 `exhaustive_supported` 不得省略 |
| GU-005 | P2／有限核心已實作；一般理論研究級 | 已有有限 theory presentations、`monoid→group` 與 `bounded-lattice→heyting` morphisms、模型限制／同載體反射及非單位元／`M3` 反例；mode 註冊只作治理索引 | 一般 Lawvere／多類／dependent theory、operad／monad 與 cubical modes 仍需可執行語法與模型定理，不得以註冊欄位冒充 |
## 文檔、雙語與生成物

| ID | 優先級／狀態 | 缺口與影響 | 下一步／驗收方向 |
|---|---|---|---|
| DOC-006 | P2／待實作 | 雙語覆蓋不均：根 `GUIDE.en.md` 是較短的英文版，各成員 README、`semiring/DESIGN.md`、`catmath/MATH.md` 與中央 `BRIDGE.md`、`FINALG.md`、`CATMATH.md` 長文以中文為正本；英文規格靠 SPEC §1.17 與生成附錄維持結構 | 不追求逐字全譯；先為中央長文補英文摘要與限制章節，標明中文詳細版是正本 |
| DOC-007 | P2／待實作 | 多數使用範例已由 `cmd/*` 與 tests 編譯，但 Markdown 內的短 import／命令示例尚無逐段 doctest | `doc_check.py` 下一步抽取標記為可執行示例核對；不可執行的歷史片段要明標 pseudo-code |
| DOC-008 | P2／已接受 | 早期 GUIDE 期數敘事與已濃縮的研究決策有歷史價值，但篇幅大，容易被搜尋引擎或新讀者誤作現況 | 已由中央索引與 MIGRATION 決策史分流；不得改寫歷史量測來追平現值，現值只更新 STATUS |
| DOC-009 | P2／待實作 | 附錄只列符號、套件、類別和規格族，不含逐符號範例、前提、複雜度與穩定等級 | 與 API-003 一起設計元資料來源；不可手改生成附錄來補欄位 |
| DOC-010 | P3／待實作 | 尚無文件站、搜尋、術語表或跨文件概念圖；大型 Markdown 只能靠索引導航 | 在有外部讀者需求後再建站；目前先維持可由 GitHub 直接閱讀與機器檢查連結的純 Markdown |

## 建議執行順序

1. 先處理公共 API 與安全實施債：`API-001`、`API-002`、
   `API-003` 與 `SEC-002`。
2. 完成 bridge 精確有向邊色鍵及 canonical form
   （`BRG-001`、`API-005`），並以靜態 SCC 量測推進
   catmath 拆包（`CAT-001`）。
3. 發佈與外部治理（`REL-001`、`REL-003`、`REL-004`）
   只在負責人或管理員需要對外發佈時處理，不與代碼工程
   缺口混排。
4. GU 有限核心之後，理論界限按 [GRAND-UNIFICATION](GRAND-UNIFICATION.md)
   的 valued Gröbner、多面體、一般 presheaf、blueprint/band
   幾何與一般 theory/mode 次序逐項開期；沒有新證明或新
   算法前，保持「已接受／研究級」。
5. 其餘項目按上方分域表的 P1／P2 推進；文末已暫停項目
   不加入本順序。

## 已暫停／非現行優先（由重要事項移出）

負責人已決定暫停所有測試、smoke、benchmark、slow report、
proof、coverage 與 runtime workflow。下列項目只保留事實
紀錄與日後若重新授權時的入口，不排期、不占現行工程優先
次序，也不應在每輪重提。

| ID | 狀態 | 暫停前記錄 | 現行處理 |
|---|---|---|---|
| ENG-001 | 已暫停／非現行優先（原 P1） | `.github/workflows/ci.yml` 的 compile-only job 尚需在 GitHub 主機實跑；本機通過不等於 hosted runner、網路依賴與 timeout 設定已證實；runtime/slow workflow 目前只登記為 manual | 只保留事實紀錄；若負責人日後另行要求，再保存 hosted workflow 結果。 |
| ENG-002 | 已暫停／非現行優先（原 P1） | 沒有覆蓋率基線或分套件門檻；舊樹 336／340 只表示舊測試全過，五系統新套件尚無運行覆蓋證據，不表示公共 API 或錯誤分支覆蓋充分 | 暫停；不建立 coverage 基線或門檻。 |
| ENG-004 | 已暫停／非現行優先（原 P2） | 只有 Linux 實跑證據；macOS、Windows native、不同 CPU 的浮點／路徑／async 檔案行為未驗證 | 暫停；不安排跨平台實際運行。 |
| ENG-005 | 已暫停／非現行優先（原 P2） | 全套件耗時長且無分片、flaky 測試清單或時間預算；本機參考約為 wasm-gc 3.5 分鐘、native 8.4 分鐘、`cmd/main` 另約 3.8 分鐘 | 暫停；不做測試耗時分片、flaky 清單或時間預算。 |
| ENG-006 | 已暫停／非現行優先（原 P2） | 定律抽樣與差分 oracle 很強，但尚無 fuzz、property-based 生成基建、mutation testing 或 benchmark 趨勢資料庫 | 暫停；不新增 fuzz、mutation 或 benchmark 執行基建。 |
| ENG-009 | 已暫停／非現行優先（原 P0） | 目前五系統樹按負責人指示只做 compile-only：全部 test/wbtest 已保留並可編譯，但**尚未執行任何單元測試、bridge 證書、cmd smoke 或慢報告**；因此不能對五系統作運行正確性宣稱 | 依負責人決定不執行全倉測試；本項只記錄現行樹未實跑的事實，不作現行施工排序條件。 |
| FIN-001 | 已暫停／非現行優先（原 P1） | `finalg/verify` 只完成普通型別／合約編譯；八個 proof goals 未在本環境以 `moon prove`、Why3、Z3、cvc5 重證；上游 Why3 config 還記錄特定 prover 版本與原 `/home/user` 前綴（已由 prove script 在臨時副本重基） | 暫停；不執行 `moon prove`／Why3 proof pipeline。 |
| UNI-001 | 已暫停／非現行優先（原 P1） | 現行 21 項跨成員語義 bridge 證書已寫成可執行函數，但本階段與 ENG-009 一樣未運行；目前只能宣稱轉換器成功編譯，不能宣稱往返與互校在五成員樹上已通過 | 暫停；不實跑 bridge wbtest、showcase 或全倉。 |
