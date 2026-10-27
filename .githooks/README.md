# Git hooks

此目錄只提供可選的本地 `pre-commit` hook。啟用方式：

```bash
chmod +x .githooks/pre-commit
git config core.hooksPath .githooks
```

hook 實際只做非執行式快速防線：

- `moon fmt --check`
- `python3 tools/doc_check.py`
- `python3 tools/arch_check.py`
- `python3 tools/audit_spec.py --check`

它不執行 `moon info`、不改檔案、不跑任何 test block 或 smoke
程式，也不取代完整的 `sh tools/check_compile.sh` 與 hosted CI。
介面變動仍須按 [CONTRIBUTING](../CONTRIBUTING.md) 先重生
`.mbti` 與雙語規格附錄。
