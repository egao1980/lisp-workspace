---
name: quint-modeling
description: >-
  Quint (Informal Systems) specification language + CLI for cl-stack formal models: modes, sum types,
  nondet/any/all, invariants, runs, `quint run --mbt`, ITF traces, Apalache/TLC verify. Use when writing
  or validating `.qnt`, model-checking a protocol, choosing invariants, or debugging quint CLI output.
  For the Lisp DSL that emits Quint use spec-dsl; for trace replay use spec-mbt-conformance.
---

# Quint modeling

Quint = TLA+ semantics, typed programmer syntax. Docs: [quint.sh/docs/lang](https://quint.sh/docs/lang) · CLI [quint.sh/docs/quint](https://quint.sh/docs/quint) · cheatsheet [quint-cheatsheet.pdf](https://quint.sh/quint-cheatsheet.pdf) · ITF [ADR-015](https://apalache-mc.org/docs/adr/015adr-trace.html). Repo moved to `quint-co/quint`.

Lisp never writes `.qnt` by hand in first-party repos — `defspec` emits it (skill **spec-dsl**). Hand-written `.qnt` is for scratch validation under `/tmp` only.

## Install (never global)

```bash
mkdir -p /tmp/quint-tool && npm install --prefix /tmp/quint-tool @informalsystems/quint
export QUINT_BIN=/tmp/quint-tool/node_modules/.bin/quint
```

`spec-backend-quint` honours `QUINT_BIN`, else `quint` on PATH. Tests must `skip` when quint is absent; CI has no Node.

## Local model checkers (this box)

| Checker | Status | How |
|---------|--------|-----|
| **TLC** 2.19 | available | TLA+ Toolbox cask: `/Applications/TLA+ Toolbox.app/Contents/Eclipse/tla2tools.jar` + bundled x86_64 JRE `…/plugins/org.lamport.openjdk.macosx.x86_64_14.0.1.7/Contents/Home/bin/java` (Rosetta; first run ~2 min translating, warm 0.3 s) |
| **Apalache** (`quint verify` default) | not available | needs JDK ≥ 17; no system JDK installed. Do not `brew install` a JDK without asking |

```bash
export TLA_JAVA="/Applications/TLA+ Toolbox.app/Contents/Eclipse/plugins/org.lamport.openjdk.macosx.x86_64_14.0.1.7/Contents/Home/bin/java"
export TLA2TOOLS="/Applications/TLA+ Toolbox.app/Contents/Eclipse/tla2tools.jar"
PATH="$(dirname "$TLA_JAVA"):$PATH" quint verify spec.qnt --backend tlc --invariants inv    # quint drives TLC
"$TLA_JAVA" -cp "$TLA2TOOLS" tlc2.TLC -config Spec.cfg Spec.tla                             # direct, after `quint compile --target tlaplus`
```

`spec-backend-quint` reads `TLA_JAVA` / `TLA2TOOLS` (`verify … :checker :tlc`); Apalache path gated by `SPEC_QUINT_VERIFY=1`. TLC = finite state only — keep domains small (see Tractability). Prefer `verify :checker :tlc` locally, `run` (simulation) in CI.

## Language in one screen

```quint
module Bank {
  const Accounts: Set[str]                 // parameter; bind with `import Bank(Accounts = Set("a")) as b`
  type Status = Idle | Busy(int)           // sum type; labels PascalCase
  var balances: str -> int                 // state; every var/const is typed
  pure def canWithdraw(b: int, n: int): bool = b - n >= 0   // stateless
  val total = balances.keys().fold(0, (acc, k) => acc + balances.get(k))  // reads state
  action init = balances' = Accounts.mapBy(_ => 0)
  action withdraw(who, n) = all {
    canWithdraw(balances.get(who), n),     // guard: false ⇒ action disabled
    balances' = balances.set(who, balances.get(who) - n),
  }
  action step = {
    nondet who = Accounts.oneOf()
    nondet n = 1.to(5).oneOf()
    any { withdraw(who, n), deposit(who, n) }
  }
  val noNegatives = Accounts.forall(a => balances.get(a) >= 0)   // invariant = plain `val: bool`
  temporal liveness = eventually(total > 0)
  run happy = init.then(deposit("a", 3)).then(withdraw("a", 1)).expect(balances.get("a") == 2)
}
```

Modes (checked): `pure val`/`pure def` stateless · `val`/`def` read state · `action` primes (`x' = e`) · `temporal` · `run`. No recursion; iterate with `fold`, `reps`, `to`. An `action` returns false when a guard fails — `any {}` skips disabled branches, `all {}` fails whole.

## Invariants that pay

- Name after the source of truth: RFC section (`windowsBounded_6_9_1`), state-machine figure, or protocol docstring.
- Determinism / replay: `replay(journal) == state`.
- Terminality: terminal status ⇒ no further events.
- Uniqueness / monotonicity: ids strictly increasing, no duplicate keys.
- Resource balance: acquired − released ≥ 0 and ≤ bound.
- Add a deliberately broken variant to prove the invariant bites; keep the counterexample as a fixture.

## Tractability

Finite, small domains: 2–3 participants, values from `1.to(3)`, `--max-steps 10..20`. Prefer `Set`/`Map` over `List` unless order matters. `nondet` only inside actions, before assignments. Avoid `int` unbounded growth in verified specs (Apalache bounds are per-step, TLC needs finite state).

## CLI

| Command | Use |
|---------|-----|
| `quint typecheck f.qnt --out t.json` | static check; JSON `{stage, errors}` (ADR-002) |
| `quint run f.qnt --invariants a b --max-steps 15 --seed 1 --mbt --n-traces 3 --out-itf out/t_{seq}.itf.json` | random simulation; `--mbt` adds `mbt::actionTaken` / `mbt::nondetPicks` |
| `quint test f.qnt --match happy` | deterministic `run` definitions |
| `quint verify f.qnt --invariants a --max-steps 10` | bounded model checking (Apalache, JDK 17+); `--backend tlc` explicit-state via `tla2tools.jar` (`--tlc-config` JSON: `maxHeap`, `workers`) |
| `quint compile f.qnt --target tlaplus` | TLA+ text; `--target json` = IR |

`--invariant "not(prop)"` = witness a scenario. `--seed` from a failing run is the reproducer — record it in the test.

## ITF trace shape

```json
{ "#meta": {...}, "vars": ["x", "mbt::actionTaken", "mbt::nondetPicks"],
  "states": [{ "#meta": {"index": 0}, "x": {"#bigint": "1"}, "mbt::actionTaken": "init",
               "mbt::nondetPicks": {"n": {"tag": "None", "value": {"#tup": []}}} }] }
```

`#bigint` string int · `#set` · `#map` `[[k,v],…]` · `#tup` · `{tag, value}` variant · plain array = List · plain object = record. `vars` may duplicate mbt names — derive from state keys. Parser: `spec-protocol/itf`.

## Anti-patterns

- Unbounded `int` counters in verified specs
- Encoding the implementation instead of the spec (model the RFC / design, then test the code against it)
- `List` for unordered collections (blows up state space)
- Treating `quint run` OK as proof — it is sampling; `verify` for bounded proof
- Committing `node_modules` / global `npm i -g`
