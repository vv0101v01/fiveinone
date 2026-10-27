/// 群胚（groupoid）與嚴格 2-群（交叉模）。
///
/// 定義（群胚）：所有箭號均可逆的範疇。
/// 定理：連通群胚 ≃ 其頂點群（一個物件群胚）；
///   一般群胚 ≃ 諸頂點群之積（骨架分解）。
/// 定義（交叉模）：∂ : H → G 配 G 在 H 上的作用，滿足
///   Peiffer 恆等式：
///   （一）∂(α_g(h)) = g·∂(h)·g⁻¹；
///   （二）α_{∂(h)}(h') = h·h'·h⁻¹。
/// 定理（交叉模 ↔ 嚴格 2-群）：嚴格 2-群範疇 ≅ 交叉模範疇。
///   π₀ = coker ∂ = G/im(∂)，π₁ = ker ∂。

///|
/// 檢查範疇是否為群胚：所有箭號可逆
pub fn is_groupoid(cc : Category) -> Bool {
  for a in 0..<cc.arrows.length() {
    if !is_iso(cc, a) {
      return false
    }
  }
  true
}

///|
/// 群胚的連通分量（物件上的聯查集，x ~ y ⟺ ∃ 箭號 x → y）
pub fn groupoid_components(cc : Category) -> Array[Int32] {
  let parent = Array::makei(cc.n_obj, fn(i) { i })
  fn find(x : Int32) -> Int32 {
    let mut r = x
    while parent[r] != r {
      r = parent[r]
    }
    let mut c = x
    while parent[c] != c {
      let nxt = parent[c]
      parent[c] = r
      c = nxt
    }
    r
  }
  fn union(x : Int32, y : Int32) -> Unit {
    let rx = find(x)
    let ry = find(y)
    if rx != ry {
      parent[rx] = ry
    }
  }
  for a in 0..<cc.arrows.length() {
    union(cc.arrows[a].from, cc.arrows[a].to)
  }
  Array::makei(cc.n_obj, fn(x) { find(x) })
}

///|
/// 連通群胚的頂點群 π₁(C, x)：x 處迴圈在合成下成的群
pub fn vertex_group(cc : Category, x : Int32) -> FinGroup {
  let loops : Array[Int32] = []
  for a in 0..<cc.arrows.length() {
    if cc.arrows[a].from == x && cc.arrows[a].to == x {
      loops.push(a)
    }
  }
  let n = loops.length()
  let pos = Array::make(cc.arrows.length(), -1)
  for i in 0..<n {
    pos[loops[i]] = i
  }
  let mul = Array::makei(n, fn(i) {
    Array::makei(n, fn(j) {
      match compose(cc, loops[i], loops[j]) {
        Some(c) => pos[c]
        None => -1
      }
    })
  })
  {
    order: n,
    e: pos[cc.id_of_obj[x]],
    mul,
    inv: Array::makei(n, fn(i) { pos[inverse_arrow(cc, loops[i]).unwrap()] }),
    name: "pi1_" + x.to_string(),
  }
}

///|
/// 連通群胚 → 頂點群群胚的等價函子（骨架化）。
/// 選定基點 x₀ 與每個物件的標準箭號 p_x : x₀ → x（BFS），
/// F(a : x → y) = p_y⁻¹ ∘ a ∘ p_x ∈ π₁(C, x₀)。
pub fn skeleton_functor(cc : Category, x0 : Int32) -> Functor {
  let n = cc.n_obj
  let p : Array[Int32] = Array::make(n, -1)
  p[x0] = cc.id_of_obj[x0]
  let mut frontier = [x0]
  while frontier.length() > 0 {
    let next_front : Array[Int32] = []
    for u in frontier {
      for a in 0..<cc.arrows.length() {
        if cc.arrows[a].from == u && p[cc.arrows[a].to] == -1 {
          match compose(cc, p[u], a) {
            Some(w) => {
              p[cc.arrows[a].to] = w
              next_front.push(cc.arrows[a].to)
            }
            None => ()
          }
        }
      }
    }
    frontier = next_front
  }
  // π₁(C, x₀) 的元素（按迴圈收集順序）↔ 箭號
  let loops : Array[Int32] = []
  for a in 0..<cc.arrows.length() {
    if cc.arrows[a].from == x0 && cc.arrows[a].to == x0 {
      loops.push(a)
    }
  }
  let loop_pos = Array::make(cc.arrows.length(), -1)
  for i in 0..<loops.length() {
    loop_pos[loops[i]] = i
  }
  // F(a : x → y) = p_y⁻¹ ∘ a ∘ p_x
  let mor_map = Array::makei(cc.arrows.length(), fn(a) {
    let x = cc.arrows[a].from
    let y = cc.arrows[a].to
    let py_inv = inverse_arrow(cc, p[y]).unwrap()
    match compose(cc, p[x], a) {
      Some(t1) =>
        match compose(cc, t1, py_inv) {
          Some(lp) => loop_pos[lp]
          None => 0
        }
      None => 0
    }
  })
  { obj_map: Array::makei(n, fn(_) { 0 }), mor_map, }
}

///|
/// 交叉模（嚴格 2-群）
pub struct CrossedModule {
  /// ∂ : H → G（h_index → g_index）
  hh : FinGroup
  gg : FinGroup
  d : Array[Int32]
  /// action[g][h]：g 在 H 上的作用
  action : Array[Array[Int32]]
}

///|
/// 驗證交叉模的 Peiffer 公理
pub fn check_crossed_module(cm : CrossedModule) -> Bool {
  let hh = cm.hh
  let gg = cm.gg
  // ∂ 為同態
  for a in 0..<hh.order {
    for b in 0..<hh.order {
      if cm.d[hh.mul[a][b]] != gg.mul[cm.d[a]][cm.d[b]] {
        return false
      }
    }
  }
  // 作用為同態作用：α_g 為 H 的自同構
  for g in 0..<gg.order {
    for a in 0..<hh.order {
      for b in 0..<hh.order {
        if cm.action[g][hh.mul[a][b]] !=
          hh.mul[cm.action[g][a]][cm.action[g][b]] {
          return false
        }
      }
    }
  }
  // α_{gk} = α_g ∘ α_k
  for g in 0..<gg.order {
    for k in 0..<gg.order {
      for a in 0..<hh.order {
        if cm.action[gg.mul[g][k]][a] != cm.action[g][cm.action[k][a]] {
          return false
        }
      }
    }
  }
  // Peiffer（一）：∂(α_g(h)) = g·∂(h)·g⁻¹
  for g in 0..<gg.order {
    for a in 0..<hh.order {
      let lhs = cm.d[cm.action[g][a]]
      let gd = gg.mul[g][cm.d[a]]
      let rhs = gg.mul[gd][gg.inv[g]]
      if lhs != rhs {
        return false
      }
    }
  }
  // Peiffer（二）：α_{∂(h)}(h') = h·h'·h⁻¹
  for a in 0..<hh.order {
    for b in 0..<hh.order {
      let lhs = cm.action[cm.d[a]][b]
      let hab = hh.mul[a][b]
      let rhs = hh.mul[hab][hh.inv[a]]
      if lhs != rhs {
        return false
      }
    }
  }
  true
}

///|
/// 內自同構交叉模 Inn(G) : G → Aut(G)，∂(g) = conj_g，α_φ(h) = φ(h)。
/// aut_of[i][x] = 第 i 個自同構在 x 上的值。
/// 定理：π₀(Inn(G)) = Out(G)，π₁(Inn(G)) = Z(G)。
pub fn inner_crossed_module(
  gg : FinGroup,
  aut : FinGroup,
  aut_of : Array[Array[Int32]],
) -> CrossedModule {
  // ∂(g) = conj_g 對應的 Aut 元素編號
  let d = Array::makei(gg.order, fn(g) {
    let mut found = 0
    for i in 0..<aut.order {
      let mut ok = true
      for x in 0..<gg.order {
        if aut_of[i][x] != gg.mul[gg.mul[g][x]][gg.inv[g]] {
          ok = false
        }
      }
      if ok {
        found = i
      }
    }
    found
  })
  // 作用：α_φ(h) = φ(h)
  let action = Array::makei(aut.order, fn(i) {
    Array::makei(gg.order, fn(h) { aut_of[i][h] })
  })
  { hh: gg, gg: aut, d, action, }
}

///|
/// π₀ = coker ∂ = G/im(∂)（im(∂) 正規由 Peiffer（一）保證）
pub fn pi0(cm : CrossedModule) -> FinGroup {
  let gg = cm.gg
  let img : Array[Int32] = []
  let seen = Array::make(gg.order, false)
  for h in 0..<cm.hh.order {
    let v = cm.d[h]
    if !seen[v] {
      seen[v] = true
      img.push(v)
    }
  }
  // 商群 G/N：陪集代表元
  let reps : Array[Int32] = []
  let coset = Array::make(gg.order, -1)
  for g in 0..<gg.order {
    if coset[g] == -1 {
      let idx = reps.length()
      reps.push(g)
      for nn in 0..<img.length() {
        coset[gg.mul[g][img[nn]]] = idx
      }
    }
  }
  let m = reps.length()
  let mul = Array::makei(m, fn(i) {
    Array::makei(m, fn(j) { coset[gg.mul[reps[i]][reps[j]]] })
  })
  {
    order: m,
    e: coset[gg.e],
    mul,
    inv: Array::makei(m, fn(i) { coset[gg.inv[reps[i]]] }),
    name: "pi0",
  }
}

///|
/// π₁ = ker ∂
pub fn pi1(cm : CrossedModule) -> FinGroup {
  let hh = cm.hh
  let ker : Array[Int32] = []
  for h in 0..<hh.order {
    if cm.d[h] == cm.gg.e {
      ker.push(h)
    }
  }
  let pos = Array::make(hh.order, -1)
  for i in 0..<ker.length() {
    pos[ker[i]] = i
  }
  let n = ker.length()
  let mul = Array::makei(n, fn(i) {
    Array::makei(n, fn(j) { pos[hh.mul[ker[i]][ker[j]]] })
  })
  {
    order: n,
    e: pos[hh.e],
    mul,
    inv: Array::makei(n, fn(i) { pos[hh.inv[ker[i]]] }),
    name: "pi1_ker",
  }
}

///|
/// 群的所有自同構（置換陣列形式，小群窮舉）
pub fn automorphism_perms(gg : FinGroup) -> Array[Array[Int32]] {
  let n = gg.order
  let sn = symmetric_group(n)
  let out : Array[Array[Int32]] = []
  for idx in 0..<sn.order {
    let p = symmetric_perm(n, idx)
    let mut ok = true
    for a in 0..<n {
      for b in 0..<n {
        if p[gg.mul[a][b]] != gg.mul[p[a]][p[b]] {
          ok = false
        }
      }
    }
    if ok {
      out.push(p)
    }
  }
  out
}

///|
/// 群的自同構群 Aut(G)（小群：在 S_n 中窮舉並檢驗）
pub fn automorphism_group(gg : FinGroup) -> FinGroup {
  let n = gg.order
  let perms = automorphism_perms(gg)
  let m = perms.length()
  let sn_order = symmetric_group(n).order
  let pos_map = Array::make(sn_order, -1)
  for i in 0..<m {
    pos_map[symmetric_index(perms[i])] = i
  }
  let mul = Array::makei(m, fn(i) {
    Array::makei(m, fn(j) {
      let comp = Array::makei(n, fn(x) { perms[i][perms[j][x]] })
      pos_map[symmetric_index(comp)]
    })
  })
  let inv = Array::makei(m, fn(i) {
    let rho = Array::make(n, 0)
    for x in 0..<n {
      rho[perms[i][x]] = x
    }
    pos_map[symmetric_index(rho)]
  })
  { order: m, e: 0, mul, inv, name: "Aut(" + gg.name + ")", }
}
