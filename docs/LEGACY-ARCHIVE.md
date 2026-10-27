# 舊倉遷移提示與封存清單（五成員主倉為現行入口；來源倉待辦）

<https://github.com/vv0101v01/golden> 的首次公開三系統提交為
`9452cb94a441ffe17b082c09cd8ee351c4c96c89`；本文件隨直接
3＋2 五成員樹維護。`algorithm01`、`algorithm03`、`algo` 與
`algo4` 四個來源倉的告示提交與 GitHub Archive **尚未執行**，所以
不得把任何一倉寫成已封存。此項登記為
[ENGINEERING-GAPS 的 REL-001](ENGINEERING-GAPS.md)。

## algorithm01 README 頂部告示（待貼上）

> ## 已遷移提示
>
> 本專案已併入 MoonBit 聯邦體 **cubical-hermitian**。後續開發請至
> <https://github.com/vv0101v01/golden> 的 `semiring/` 與
> `cmd/semiringreport/`。import 對照見該倉的 `docs/MIGRATION.md`：
> `arena/semiring-lab/<pkg>` →
> `vv0101v01/cubical-hermitian/semiring/<pkg>`。
> 本舊倉只保留既有 commit／tag 作歷史出處，不再接新功能。

## algorithm03 README.mbt.md 頂部告示（待貼上）

> ## 已遷移提示
>
> 本專案已併入 MoonBit 聯邦體 **cubical-hermitian**。後續開發請至
> <https://github.com/vv0101v01/golden> 的 `symlib/`、`cmd/symdemo/`
> 與 `cmd/symbench/`。新套件路徑為
> `vv0101v01/cubical-hermitian/symlib`，完整對照見該倉的
> `docs/MIGRATION.md`。本舊倉只保留既有 commit／tag 作歷史出處，
> 不再接新功能。

## algo README.mbt.md 頂部告示（五系統發布後待貼上）

> ## 已遷移提示
>
> 本專案（MoonBit module `moon-algebra`）已併入
> <https://github.com/vv0101v01/golden>，成為 `finalg/` 支柱。import
> 主前綴改為 `vv0101v01/cubical-hermitian/finalg`，子套件只作
> `moon-algebra/<pkg>` → `vv0101v01/cubical-hermitian/finalg/<pkg>` 的
> 前綴替換；完整對照見該倉 `docs/MIGRATION.md`，proof 資產位於
> `finalg/verify/`、`finalg/prelude/` 與 `finalg/prove.sh`。本舊倉只
> 保留歷史出處，不再接新功能。

## algo4 README.mbt.md 頂部告示（五系統發布後待貼上）

> ## 已遷移提示
>
> 本專案（catmath）已併入 <https://github.com/vv0101v01/golden>，成為
> `catmath/` 函式庫與 `cmd/catmath/` 執行入口。新 import 路徑為
> `vv0101v01/cubical-hermitian/catmath`，完整對照見該倉
> `docs/MIGRATION.md`。本舊倉只保留歷史出處，不再接新功能。

## 尚待執行的操作順序

1. 先確認五成員樹已推送並保存 hosted compile-only 證據；運行期測試是
   ENG-009 的另一發布門檻。
2. 在四個來源倉各作一個只加上述 README 告示的提交並推送；不改寫
   既有歷史、不移動或刪除既有 tag。憑證只供單次推送使用，不寫入
   檔案或 git config。
3. 開啟四個來源倉 GitHub 首頁，確認告示正確顯示且連結指向 `golden`。
4. 儲存倉管理員再按決定於 GitHub Settings Archive；這一步不能由
   普通 `git push` 代替。
5. 把實際告示 commit、Archive 日期與可見證據回填本文與缺口登記，
   並把 REL-001 改為已關閉。在此之前，狀態只能寫「舊倉告示／封存
   未執行」。
