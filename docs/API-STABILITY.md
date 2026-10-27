# 公開 API 穩定度與相容政策

**適用版本：** `vv0101v01/cubical-hermitian` `0.0.1`。  
**狀態：** 初始政策；尚未發布 1.0.0。

## 版本號與相容性

本 module 遵循 Semantic Versioning 的版本格式，但在 `1.0.0` 前不對全部公開符號承諾穩定性。當前 `0.0.1` 的每個公開符號都視為 **experimental**，除非未來政策明確將其列入穩定 API 清單。公開介面可能因算法、表示或型別邊界而作破壞性調整；應在 `CHANGELOG.md` 記錄使用者可見變化，並更新遷移文件與生成介面。

第一個 `1.0.0` Release 前，必須先建立版本控制的穩定 API allowlist、處理不適合成為穩定面之入口，並在 Release notes 清楚列出 API 邊界。之後按 SemVer：

- patch：向後相容的修正，不改公開語義或型別契約；
- minor：向後相容功能新增；已棄用 API 在本系列仍可用；
- major：移除/改變穩定 API、型別或保證。

若實際 MoonBit module 發佈規則與此處 SemVer 描述有衝突，發佈前須記錄差異，不能讓 tag、`moon.mod` 與 Release notes 各自使用不同版號。

## 穩定級別

| 級別 | 判定 | 相容承諾 |
|---|---|---|
| **Stable** | 只限正式版本化 allowlist 明列的符號；目前尚未建立 allowlist，故目前沒有可宣稱的 Stable symbol | 遵守已發布的相容/棄用政策 |
| **Experimental** | `pkg.generated.mbti` 中其餘所有公開符號（包含 bridge、constructor、report、有限域/有限模型接口） | 可在 `0.x` 內作破壞性調整；需記錄於 CHANGELOG，且須保留語義邊界文件 |
| **Test-support** | 明確供測試 fixture 使用的 API，例如 `finalg/testutil` | 不作一般應用 API；禁止 production package 依賴，架構檢查維持 test-only import |
| **Internal** | 非公開符號及私有表示 | 不提供外部相容保證；仍受倉內架構規則約束 |

「公開」只表示編譯器暴露，不表示數學完備、執行期驗證充分、API 已穩定或適合生產用途。有限窮舉、cap、浮點近似、`abort` 前提及未完成模型等限制，仍以 [ENGINEERING-GAPS](ENGINEERING-GAPS.md) 與各成員文件為準。

## 每次公開 API 變更的要求

1. 更新來源程式與生成的 `pkg.generated.mbti`；不手改生成檔。
2. 依符號規格分類更新雙語 SPEC 附錄。
3. 更新使用者可見 `CHANGELOG.md`；若改變行為或命名，提供遷移說明。
4. 新增／變更的 cap、錯誤、部分結果、精度或受信假設，記入 `docs/ENGINEERING-GAPS.md`。
5. 本階段只執行 `sh tools/check_compile.sh`：它編譯測試源碼但不執行 test block。沒有運行測試不等於新 API 已有 runtime 正確性證據。

**政策維護者：** 由本倉維護者在下一次發布前核准 Stable allowlist 與 `1.0.0` 發布範圍。此文件不自行將任何現有符號升格為 Stable。
