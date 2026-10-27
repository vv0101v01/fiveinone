/// 乘性線性邏輯（MLL）證明網。
///
/// 定義（證明結構）：鏈（link）有向圖——
///   公理鏈（axiom, kind=0）：無前提，兩個結論（對偶原子對）；
///   張量鏈（⊗, kind=1）：兩前提一結論；
///   並鏈（⅋, kind=2）：兩前提一結論；
///   切鏈（cut, kind=3）：兩前提零結論。
/// 每個內部文字出現恰為一個鏈的結論與另一鏈的前提（資源線性）。
///
/// 定理（Danos–Regnier 1989，switching 準則）：切網正確 ⟺
///   對每個 ⅋ 鏈選取其兩前提邊之一刪去（switching），
///   所得圖均為連通無環（樹）。檢查需遍歷 2^p 種 switching，
///   複雜度 O(2^p · n)（p = ⅋ 鏈數）——指數級。
///
/// 定理（GMM 1993 圖解析／收縮準則；與 DR 等價，Straßburger 2006）：
///   切網正確 ⟺ 可反覆收縮至單一鏈。收縮規則：
///   規則鏈 L 可收縮 ⟺ 其每個前提文字由「可用」鏈結出
///   （可用 = 尚未併入任何群的公理鏈，或已收縮群的 head 鏈），
///   且各前提所屬群兩兩相異；收縮 L 時將其與各前提群合併，
///   L 成為新群的 head（其結論成為新群的輸出文字）。
///   複雜度 O(n²)（Guerrini 1999 改进至 O(n)）——多項式級。
///   本模組採用此收縮準則，將正確性檢查由指數級降至多項式級。
///
/// 定理（切消除）：MLL 證明網的切歸約保持正確性並終止，
///   歸約至無切正規形；網正確 ⟺ 其切消除正規形正確。
/// 複複雜度：證明網上的切消除為多項式；相對地，
///   MLL 序列演算的證明搜尋為 NP 完全（Kanovich 1991）。

///|
/// 證明網節點（鏈）
pub struct NetNode {
  /// 0 = 公理，1 = 張量，2 = 並，3 = 切
  kind : Int32
  /// 前提鏈索引（公理鏈為空；−1 表示懸空，不應出現於完好網）
  prem : Array[Int32]
  /// 此鏈的結論文字是否已被切消除（僅收縮歸約產生的鏈為真）
  dead : Bool
}

///|
pub struct ProofNet {
  nodes : Array[NetNode]
}

///|
/// 公理鏈
pub fn mk_axiom() -> NetNode {
  { kind: 0, prem: [], dead: false, }
}

///|
/// 張量鏈 ⊗(n₁, n₂)
pub fn mk_tensor(n1 : Int32, n2 : Int32) -> NetNode {
  { kind: 1, prem: [n1, n2], dead: false, }
}

///|
/// 並鏈 ⅋(n₁, n₂)
pub fn mk_par(n1 : Int32, n2 : Int32) -> NetNode {
  { kind: 2, prem: [n1, n2], dead: false, }
}

///|
/// 切鏈 cut(n₁, n₂)
pub fn mk_cut(n1 : Int32, n2 : Int32) -> NetNode {
  { kind: 3, prem: [n1, n2], dead: false, }
}

///|
/// 節點數
pub fn net_size(nn : ProofNet) -> Int32 {
  nn.nodes.length()
}

///|
/// 並鏈數量
pub fn par_count(nn : ProofNet) -> Int32 {
  let mut n = 0
  for node in nn.nodes {
    if node.kind == 2 {
      n = n + 1
    }
  }
  n
}

///|
/// 切鏈數量
pub fn cut_count(nn : ProofNet) -> Int32 {
  let mut n = 0
  for node in nn.nodes {
    if node.kind == 3 {
      n = n + 1
    }
  }
  n
}

///|
/// 正確性檢查（GMM 收縮準則，多項式時間）。
/// 含切網先做切消除，再檢查其無切正規形（標準做法：
/// 網正確 ⟺ 切消除正規形正確）。
pub fn net_is_correct(nn : ProofNet) -> Bool {
  gmm_contractible(cut_eliminate(nn))
}

///|
/// GMM 圖解析（收縮）準則：反覆收縮可收縮規則鏈，
/// 正確 ⟺ 全部鏈收縮至同一群。複雜度 O(n²)。
fn gmm_contractible(nn : ProofNet) -> Bool {
  let n = nn.nodes.length()
  if n == 0 {
    return true
  }
  // 並查集：parent[i] = i 的群代表；head[g] = 群 g 的輸出鏈
  let parent = Array::makei(n, fn(i) { i })
  let head = Array::makei(n, fn(i) { i })
  // done[i] = 規則鏈 i 是否已收縮（公理鏈恆可用，視為獨立群）
  let done = Array::make(n, false)
  let mut progress = true
  while progress {
    progress = false
    for i in 0..<n {
      if nn.nodes[i].kind == 0 {
        continue
      }
      if done[i] {
        continue
      }
      let node = nn.nodes[i]
      let mut ok = true
      // 前提可用性：每個前提鏈須為獨立公理或已收縮群的 head
      for k in 0..<node.prem.length() {
        let m = node.prem[k]
        if m < 0 {
          ok = false
        } else if nn.nodes[m].kind == 0 {
          if parent[m] != m {
            ok = false
          }
        } else if !done[m] {
          ok = false
        } else if head[uf_find(parent, m)] != m {
          ok = false
        }
        if !ok {
          break
        }
      }
      // 前提所屬群兩兩相異（防止同一子證明被雙重使用）
      if ok {
        for a in 0..<node.prem.length() {
          for b in (a + 1)..<node.prem.length() {
            if uf_find(parent, node.prem[a]) == uf_find(parent, node.prem[b]) {
              ok = false
            }
          }
        }
      }
      if ok {
        done[i] = true
        for k in 0..<node.prem.length() {
          uf_union(parent, i, node.prem[k])
        }
        head[uf_find(parent, i)] = i
        progress = true
      }
    }
  }
  // 全部鏈收縮至同一群 ⟺ 正確
  let r0 = uf_find(parent, 0)
  for i in 1..<n {
    if uf_find(parent, i) != r0 {
      return false
    }
  }
  true
}

///|
/// 並查集：找代表（路徑壓縮）
fn uf_find(parent : Array[Int32], x : Int32) -> Int32 {
  let mut r = x
  while parent[r] != r {
    r = parent[r]
  }
  let mut c = x
  while parent[c] != c {
    let nx = parent[c]
    parent[c] = r
    c = nx
  }
  r
}

///|
/// 並查集：合併
fn uf_union(parent : Array[Int32], a : Int32, b : Int32) -> Unit {
  let ra = uf_find(parent, a)
  let rb = uf_find(parent, b)
  if ra != rb {
    parent[ra] = rb
  }
}

///|
/// 切消除（單步）：找第一個切鏈並歸約。
/// 規則（樹形證明網，前提依位置配對）：
///   cut(ax, ax) → 合併為單一公理鏈（原子切）；
///   cut(⊗(t₁, t₂), ⅋(p₁, p₂)) → ⊗(cut(t₁, p₁), cut(t₂, p₂))；
///   cut(⅋(p₁, p₂), ⊗(t₁, t₂)) → ⅋(cut(p₁, t₁), cut(p₂, t₂))。
pub fn cut_reduce_step(nn : ProofNet) -> ProofNet? {
  for i in 0..<nn.nodes.length() {
    if nn.nodes[i].kind != 3 {
      continue
    }
    let l = nn.nodes[i].prem[0]
    let r = nn.nodes[i].prem[1]
    let ln = nn.nodes[l]
    let rn = nn.nodes[r]
    // 原子切：兩前提皆為公理鏈 → 合併為單一公理鏈
    if ln.kind == 0 && rn.kind == 0 {
      return Some(atomic_cut_merge(nn, i, l, r))
    }
    // ⊗/⅋ 交換
    if ln.kind == 1 && rn.kind == 2 {
      return Some(
        exchange_reduce(
          nn,
          i,
          l,
          r,
          ln.prem[0],
          rn.prem[0],
          ln.prem[1],
          rn.prem[1],
          true,
        ),
      )
    }
    if ln.kind == 2 && rn.kind == 1 {
      return Some(
        exchange_reduce(
          nn,
          i,
          l,
          r,
          ln.prem[0],
          rn.prem[0],
          ln.prem[1],
          rn.prem[1],
          false,
        ),
      )
    }
  }
  None
}

///|
/// 原子切歸約：cut(a₁, a₂) → 單一公理鏈。
/// 刪除 a₁, a₂, cut，新增公理鏈；所有對 a₁/a₂/cut 的引用改指新鏈。
fn atomic_cut_merge(
  nn : ProofNet,
  cut : Int32,
  a1 : Int32,
  a2 : Int32,
) -> ProofNet {
  let drop = [a1, a2, cut]
  let is_dropped = Array::make(nn.nodes.length(), false)
  for d in drop {
    is_dropped[d] = true
  }
  // 新公理鏈排在末尾，其索引 = 保留節點數
  let keep = nn.nodes.length() - 3
  let remap = Array::make(nn.nodes.length(), -1)
  let mut next = 0
  for i in 0..<nn.nodes.length() {
    if !is_dropped[i] {
      remap[i] = next
      next = next + 1
    }
  }
  remap[a1] = keep
  remap[a2] = keep
  remap[cut] = keep
  let nodes = Array::makei(keep + 1, fn(i) {
    let _ = i
    mk_axiom()
  })
  let mut idx = 0
  for i in 0..<nn.nodes.length() {
    if is_dropped[i] {
      continue
    }
    let node = nn.nodes[i]
    let prem = Array::makei(node.prem.length(), fn(k) { remap[node.prem[k]] })
    nodes[idx] = { kind: node.kind, prem, dead: node.dead, }
    idx = idx + 1
  }
  { nodes, }
}

///|
/// ⊗/⅋ 交換歸約：cut(⊗(t₁,t₂), ⅋(p₁,p₂)) → ⊗(cut(t₁,p₁), cut(t₂,p₂))
/// （par_result = false）；切換角色時得 ⅋(cut(p₁,t₁), cut(p₂,t₂))。
/// 被刪去的切/張量/並鏈的結論文字即為被消除的切公式，
/// 無其他鏈引用它們，故只需重建成新鏈。
fn exchange_reduce(
  nn : ProofNet,
  cut : Int32,
  tt : Int32,
  pp : Int32,
  t1 : Int32,
  p1 : Int32,
  t2 : Int32,
  p2 : Int32,
  tensor_result : Bool,
) -> ProofNet {
  let drop = [cut, tt, pp]
  let is_dropped = Array::make(nn.nodes.length(), false)
  for d in drop {
    is_dropped[d] = true
  }
  let keep = nn.nodes.length() - 3
  let remap = Array::make(nn.nodes.length(), -1)
  let mut next = 0
  for i in 0..<nn.nodes.length() {
    if !is_dropped[i] {
      remap[i] = next
      next = next + 1
    }
  }
  let c1 = keep
  let c2 = keep + 1
  let res = keep + 2
  let nodes = Array::makei(keep + 3, fn(i) {
    let _ = i
    mk_axiom()
  })
  let mut idx = 0
  for i in 0..<nn.nodes.length() {
    if is_dropped[i] {
      continue
    }
    let node = nn.nodes[i]
    let prem = Array::makei(node.prem.length(), fn(k) { remap[node.prem[k]] })
    nodes[idx] = { kind: node.kind, prem, dead: node.dead, }
    idx = idx + 1
  }
  nodes[c1] = mk_cut(remap[t1], remap[p1])
  nodes[c2] = mk_cut(remap[t2], remap[p2])
  let res_node = if tensor_result { mk_tensor(c1, c2) } else { mk_par(c1, c2) }
  nodes[res] = { kind: res_node.kind, prem: res_node.prem, dead: true, }
  { nodes, }
}

///|
/// 剪除已死亡的鏈：收縮歸約產生的張量/並鏈，其結論文字為
/// 被消除的切公式；當其前提皆為公理鏈時，該鏈自身亦應消失。
fn prune_dead(nn : ProofNet) -> ProofNet {
  let mut changed = true
  let mut cur = nn
  while changed {
    changed = false
    let n = cur.nodes.length()
    let mut drop_count = 0
    let is_dropped = Array::make(n, false)
    for i in 0..<n {
      let node = cur.nodes[i]
      if node.kind == 0 || !node.dead {
        continue
      }
      let mut all_axiom = true
      for k in 0..<node.prem.length() {
        let m = node.prem[k]
        if m < 0 || cur.nodes[m].kind != 0 {
          all_axiom = false
        }
      }
      if all_axiom {
        is_dropped[i] = true
        drop_count = drop_count + 1
        changed = true
      }
    }
    if changed {
      let keep = n - drop_count
      let remap = Array::make(n, -1)
      let mut next = 0
      for i in 0..<n {
        if !is_dropped[i] {
          remap[i] = next
          next = next + 1
        }
      }
      let nodes = Array::makei(keep, fn(i) {
        let _ = i
        mk_axiom()
      })
      let mut idx = 0
      for i in 0..<n {
        if is_dropped[i] {
          continue
        }
        let node = cur.nodes[i]
        let prem = Array::makei(node.prem.length(), fn(k) {
          remap[node.prem[k]]
        })
        nodes[idx] = { kind: node.kind, prem, dead: node.dead, }
        idx = idx + 1
      }
      cur = { nodes, }
    }
  }
  cur
}

///|
/// 完全切消除：歸約至無切正規形（含死亡鏈修剪）
pub fn cut_eliminate(nn : ProofNet) -> ProofNet {
  let mut cur = prune_dead(nn)
  let mut go = true
  while go {
    match cut_reduce_step(cur) {
      Some(next) => cur = prune_dead(next)
      None => go = false
    }
  }
  cur
}

///|
/// 切步數（至正規形）
pub fn cut_steps(nn : ProofNet) -> Int32 {
  let mut cur = nn
  let mut steps = 0
  let mut go = true
  while go {
    match cut_reduce_step(cur) {
      Some(next) => {
        cur = prune_dead(next)
        steps = steps + 1
      }
      None => go = false
    }
  }
  steps
}
