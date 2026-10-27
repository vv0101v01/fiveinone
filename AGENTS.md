# Repository Guide for Agents and Maintainers

This is the public `golden` repository
(<https://github.com/vv0101v01/golden>). Its MoonBit module deliberately
remains `vv0101v01/cubical-hermitian`; do not rename imports to match the
GitHub repository name.

## Read first

1. `docs/STATUS.md` — authoritative current state and verified counts.
2. `docs/ENGINEERING-GAPS.md` — every registered limitation and pending job.
3. `docs/README.md` — documentation map and update classification.
4. `ARCHITECTURE.md` and `architecture.json` — dependency governance.
5. `CONTRIBUTING.md` — build, generated-file and gate rules.

The old standalone merge-research snapshots have been distilled into
`docs/MIGRATION.md`; do not recreate parallel decision documents.
Pre-federation member facts live in the one `README.md` at each member
root. Post-federation facts go to the central documents and must not be
written back into those member histories.

## Package map and boundaries

- Root package: cubical/Hermitian executable semantics, certificates and
  bounded decision procedures. It is not a complete production cubical
  type-theory kernel.
- `algebra/`: exact BigInt/rational algebra. Its full import path is
  `vv0101v01/cubical-hermitian/algebra`.
- `symlib/`: exact finite symmetry, graph search and finite categories.
  Its native `Graph` is a simple undirected graph.
- `semiring/*`: portable semiring algorithms. Its trait package is
  `vv0101v01/cubical-hermitian/semiring/algebra`, a different package from
  the exact `algebra/` above. Only native-only `semiring/par_host` may
  import `moonbitlang/async`; `cmd/semiringreport` is also native-only.
- `finalg/` plus `finalg/*`: the imported `algo`/`moon-algebra`
  finite-field pillar. Preserve its internal package DAG; only tests
  may import `finalg/testutil`, and `finalg/verify` proof execution is
  separate from ordinary compilation.
- `catmath/`: the imported `algo4` library, deliberately still one
  large MoonBit package. Its former same-package executable is
  `cmd/catmath`; do not split it without runtime evidence and an SCC
  measurement (CAT-001).
- `bridge/`: the only five-member federation core. It retains the
  original three-pillar files and adds direct `federation_*` adapters,
  reports and certificates for finalg/catmath. Do not create a second
  overlay integration package. Members must not import one another
  sideways merely to share a helper. Application packages under `cmd/`
  may observe the relevant public APIs.
- Root `Ty`, `Dim` and `Face` remain readonly across packages. Use their
  narrow public constructors; do not widen them to `pub(all)`.
- Terminology is stable: monoid = 么半群； monad = 單子／單子函子. Never
  call a monoid a 單子.

Every `.mbt` file belongs to exactly one component in `architecture.json`.
The observer components may inspect several lower components; that is not a
licence to add production cross-pillar edges elsewhere.

## Generated artifacts

Never hand-edit:

- any `pkg.generated.mbti`;
- the marked generated regions of `SPEC-APPENDIX.md` and
  `SPEC-APPENDIX.en.md`;
- the generated body of `semiring/REPORT.md` without preserving its
  manual snapshot banner.

After changing a public interface, run `moon info`, classify new symbols in
the bilingual SPEC families, then run
`python3 tools/audit_spec.py --write`.

## Documentation discipline

- Current facts go to `docs/STATUS.md` and the root `README.md`.
- `AGENTS.md`, `SPEC.md` and `GUIDE.md` exist only at the federation
  leader/repository root; member directories keep their own `README.md`
  (plus genuinely distinct technical appendices), never another copy of
  those three central documents.
- New caps, approximations, trusted assumptions or incomplete routes go to
  `docs/ENGINEERING-GAPS.md` in the same change.
- Every new Markdown file must be classified in `docs/README.md`.
- User-visible changes go to `CHANGELOG.md`.
- Keep target-specific test totals separate. The earlier public
  three-system baseline is wasm-gc 336/336 and native 340/340; never
  add them together or present them as five-system runtime evidence.

## Gates

Use the narrowest honest gate and report exactly what ran:

```bash
python3 tools/doc_check.py          # docs-only minimum, plus arch/audit
sh tools/check_compile.sh           # current authorized gate
GOLDEN_RUN_TESTS=1 sh tools/check_full.sh
                                    # future runtime stage only
GOLDEN_RUN_SMOKE=1 sh tools/check_slow.sh > /tmp/REPORT.generated.md
```

The owner has explicitly paused all test and smoke execution; it is
non-priority work and must not be proposed as the next step.  For
docs-only rearrangements, do not spend a turn on Moon gates unless the
owner asks.  Preserve/import test sources
and compile them with `moon test --build-only`, but do not run
`moon test` without `--build-only`, `moon run`, benchmarks,
`moon prove`, or the slow report until a later runtime-stage
instruction.  Without the environment switches, `check_full.sh`
refuses before execution and `check_slow.sh` only builds the report.
Report compile-only evidence as compile-only, never as tests passing.

GitHub workflow files existing in the tree do not prove a hosted run is
green, and branch protection is an external repository setting. None of the four
migrated source repositories is archived in this change; notices and
Archive steps require external evidence, see
`docs/LEGACY-ARCHIVE.md` and REL-001.
