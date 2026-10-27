# 舊倉遷移提示與封存清單（待遠端憑證）

本文件預先備妥 T6 的本地材料。它**不表示**舊倉已經推送、加告示或在 GitHub
封存：那些遠端動作必須等主倉取得有效推送憑證並實際驗證後才能宣稱完成。

## algorithm01 README 頂部告示（待貼上）

> ## 已遷移／封存提示
>
> 本專案已併入 MoonBit 三支柱聯邦 **cubical-hermitian**。後續開發請至
> <https://github.com/vv0101v01/golden> 的 `semiring/` 與
> `cmd/semiringreport/`。import 對照見該倉的 `docs/MIGRATION.md`：
> `arena/semiring-lab/<pkg>` →
> `vv0101v01/cubical-hermitian/semiring/<pkg>`。
> 本舊倉只保留既有 commit／tag 作歷史出處，不再接新功能。

## algorithm03 README.mbt.md 頂部告示（待貼上）

> ## 已遷移／封存提示
>
> 本專案已併入 MoonBit 三支柱聯邦 **cubical-hermitian**。後續開發請至
> <https://github.com/vv0101v01/algorithms02> 的 `symlib/`、`cmd/symdemo/`
> 與 `cmd/symbench/`。新套件路徑為
> `vv0101v01/cubical-hermitian/symlib`，完整對照見該倉的
> `docs/MIGRATION.md`。本舊倉只保留既有 commit／tag 作歷史出處，
> 不再接新功能。

## 有憑證後的操作順序

1. 先把主倉 `main` 推到目標 GitHub 倉，確認遠端檔案、
   `docs/MIGRATION.md` 連結與 CI/閘門證據可見；令牌只在單次命令 URL 使用，
   不寫入檔案或 git config。
2. 在 algorithm01 與 algorithm03 各作一個只加上述 README 告示的提交並推送；
   不改寫既有歷史、不移動或刪除既有 tag。
3. 確認兩個舊倉 README 在 GitHub 首頁正確顯示新路徑後，再於 GitHub
   Settings 將兩倉 Archive。
4. 把實際遠端 commit、封存日期與連結回填 `MERGE-IMPLEMENTATION.md`；
   在此之前，T6 狀態只能寫「本地材料完成、遠端未執行」。
