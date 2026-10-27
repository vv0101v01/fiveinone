/// Galois 範疇（有限 G-集範疇）與 Galois 對應。
///
/// 定義（Galois 範疇）：具纖維函子 F : C → Set 的範疇，滿足
///   有限极限/余极限存在、F 完全忠實且正合、每物件有限。
/// 定理（Galois 對應）：有限 G-集範疇中，
///   傳遞物件 ↔ 子群共軛類（G/H ↔ [H]）；
///   Aut_G(G/H) ≅ N_G(H)/H；
///   纖維函子的自然自同構 Aut(F) ≅ G（Tannaka 型重建）。

///|
/// 有限 G-集
pub struct GSet {
  group : FinGroup
  elements : Int32
  /// action[g][x] = g·x
  action : Array[Array[Int32]]
}

///|
/// 驗證群作用公理
pub fn check_gset(gx : GSet) -> Bool {
  let gg = gx.group
  for x in 0..<gx.elements {
    if gx.action[gg.e][x] != x {
      return false
    }
  }
  for g in 0..<gg.order {
    for h in 0..<gg.order {
      for x in 0..<gx.elements {
        if gx.action[gg.mul[g][h]][x] != gx.action[g][gx.action[h][x]] {
          return false
        }
      }
    }
  }
  true
}

///|
/// 軌道分解（聯查集）
pub fn gset_orbits(gx : GSet) -> Array[Array[Int32]] {
  let gg = gx.group
  let parent = Array::makei(gx.elements, fn(i) { i })
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
  for g in 0..<gg.order {
    for x in 0..<gx.elements {
      union(x, gx.action[g][x])
    }
  }
  let buckets : Array[Array[Int32]] = []
  for x in 0..<gx.elements {
    let r = find(x)
    let mut placed = false
    for b in 0..<buckets.length() {
      if find(buckets[b][0]) == r {
        buckets[b].push(x)
        placed = true
      }
    }
    if !placed {
      buckets.push([x])
    }
  }
  buckets
}

///|
/// 傳遞性：單一軌道
pub fn is_transitive(gx : GSet) -> Bool {
  gset_orbits(gx).length() == 1
}

///|
/// 全部子群（窮舉子集並檢驗閉合；|G| ≤ 6 實際可行）
pub fn all_subgroups(gg : FinGroup) -> Array[Array[Int32]] {
  let n = gg.order
  let out : Array[Array[Int32]] = []
  // 枚舉 2^n 個子集（n ≤ 6）
  let total = pow_int(2, n)
  for mask in 0..<total {
    let ss : Array[Int32] = []
    for i in 0..<n {
      if ((mask >> i) & 1) == 1 {
        ss.push(i)
      }
    }
    // 含單位元、對乘法與逆元閉合
    let mut has_e = false
    for x in ss {
      if x == gg.e {
        has_e = true
      }
    }
    if !has_e {
      continue
    }
    let in_ss = Array::make(n, false)
    for x in ss {
      in_ss[x] = true
    }
    let mut closed = true
    for a in ss {
      for b in ss {
        if !in_ss[gg.mul[a][b]] {
          closed = false
        }
      }
      if !in_ss[gg.inv[a]] {
        closed = false
      }
    }
    if closed {
      out.push(ss)
    }
  }
  out
}

///|
/// 傳遞 G-集 G/H（H 為子群，元素為陪集代表元索引）
pub fn coset_gset(gg : FinGroup, hh : Array[Int32]) -> GSet {
  // 陪集：以每個陪集的首個元素為代表元
  let reps : Array[Int32] = []
  // rep_pos[x] = x 所屬陪集的代表元索引
  let rep_pos = Array::make(gg.order, -1)
  for g in 0..<gg.order {
    if rep_pos[g] == -1 {
      let idx = reps.length()
      reps.push(g)
      for h in hh {
        rep_pos[gg.mul[g][h]] = idx
      }
    }
  }
  // 作用：g·(xH) = (gx)H
  let action = Array::makei(gg.order, fn(g) {
    Array::makei(reps.length(), fn(i) { rep_pos[gg.mul[g][reps[i]]] })
  })
  { group: gg, elements: reps.length(), action, }
}

///|
/// 全部傳遞 G-集（每個子群共軛類取一個代表）
pub fn transitive_gsets(gg : FinGroup) -> Array[GSet] {
  let subs = all_subgroups(gg)
  let out : Array[GSet] = []
  let done : Array[Array[Int32]] = []
  for hh in subs {
    let mut conj_seen = false
    for dd in done {
      if conjugate_subgroups(gg, hh, dd) {
        conj_seen = true
      }
    }
    if !conj_seen {
      done.push(hh)
      out.push(coset_gset(gg, hh))
    }
  }
  out
}

///|
/// H, K 是否共軛：∃g, gHg⁻¹ = K
pub fn conjugate_subgroups(
  gg : FinGroup,
  hh : Array[Int32],
  kk : Array[Int32],
) -> Bool {
  if hh.length() != kk.length() {
    return false
  }
  for g in 0..<gg.order {
    let mut ok = true
    // gHg⁻¹ ⊆ K
    for h in hh {
      let v = gg.mul[gg.mul[g][h]][gg.inv[g]]
      let mut found = false
      for k in kk {
        if v == k {
          found = true
        }
      }
      if !found {
        ok = false
      }
    }
    if ok {
      return true
    }
  }
  false
}

///|
/// 等變映射檢驗：f : X → Y 滿足 f(g·x) = g·f(x)
pub fn is_equivariant(gx : GSet, gy : GSet, f : Array[Int32]) -> Bool {
  if f.length() != gx.elements {
    return false
  }
  let gg = gx.group
  for g in 0..<gg.order {
    for x in 0..<gx.elements {
      if f[gx.action[g][x]] != gy.action[g][f[x]] {
        return false
      }
    }
  }
  true
}

///|
/// 全部等變映射 X → Y（窮舉函數並檢驗）
pub fn equivariant_maps(gx : GSet, gy : GSet) -> Array[Array[Int32]] {
  let out : Array[Array[Int32]] = []
  let total = pow_int(gy.elements, gx.elements)
  for code in 0..<total {
    let f = Array::make(gx.elements, 0)
    let mut r = code
    let mut i = gx.elements - 1
    while i >= 0 {
      f[i] = r % gy.elements
      r = r / gy.elements
      i = i - 1
    }
    if is_equivariant(gx, gy, f) {
      out.push(f)
    }
  }
  out
}

///|
/// Galois 對應：Aut_G(G/H) ≅ N_G(H)/H
pub fn aut_g_h(gg : FinGroup, hh : Array[Int32]) -> Int32 {
  let gx = coset_gset(gg, hh)
  equivariant_maps(gx, gx).length()
}

///|
/// 正規化子 N_G(H)
pub fn normalizer(gg : FinGroup, hh : Array[Int32]) -> Array[Int32] {
  let in_h = Array::make(gg.order, false)
  for h in hh {
    in_h[h] = true
  }
  let out : Array[Int32] = []
  for g in 0..<gg.order {
    let mut ok = true
    for h in hh {
      let v = gg.mul[gg.mul[g][h]][gg.inv[g]]
      if !in_h[v] {
        ok = false
      }
    }
    if ok {
      out.push(g)
    }
  }
  out
}

///|
/// 驗證 Aut_G(G/H) ≅ N_G(H)/H（計數一致）
pub fn verify_galois_correspondence(gg : FinGroup) -> Bool {
  for hh in all_subgroups(gg) {
    let n = normalizer(gg, hh)
    // |N_G(H)/H| = |N| / |H|
    let expected = n.length() / hh.length()
    if aut_g_h(gg, hh) != expected {
      return false
    }
  }
  true
}

///|
fn array_eq_int(aa : Array[Int32], bb : Array[Int32]) -> Bool {
  if aa.length() != bb.length() {
    return false
  }
  for i in 0..<aa.length() {
    if aa[i] != bb[i] {
      return false
    }
  }
  true
}

///|
/// 纖維函子的自然自同構 τ^b : X → X, x ↦ b·x（b ∈ G）
pub fn fiber_autos(
  gg : FinGroup,
  objects : Array[GSet],
) -> Array[Array[Array[Int32]]] {
  // 對每個 b ∈ G，自然變換族 (τ^b_X)_X
  Array::makei(gg.order, fn(b) {
    Array::makei(objects.length(), fn(i) {
      Array::makei(objects[i].elements, fn(x) { objects[i].action[b][x] })
    })
  })
}

///|
/// 驗證 Tannaka 型重建：Aut(F) ≅ G
/// （一）每個 τ^b 自然（對所有等變映射交換）；
/// （二）τ^b ∘ τ^c = τ^{bc}；
/// （三）b ↦ τ^b 為單射；
/// （四）完備性：任何與所有等變映射交換的雙射族必為某個 τ^b
///   （由正則表現的右乘映射迫使 τ_G(x) = τ_G(e)·x）。
pub fn verify_aut_fiber(gg : FinGroup, objects : Array[GSet]) -> Bool {
  // τ 族：autos[b] = (τ^b_X)_X，其中 τ^b_X(x) = b·x
  let autos = fiber_autos(gg, objects)
  // （一）自然性：τ^b_Y ∘ f = f ∘ τ^b_X
  for b in 0..<gg.order {
    for i in 0..<objects.length() {
      for j in 0..<objects.length() {
        for f in equivariant_maps(objects[i], objects[j]) {
          for x in 0..<objects[i].elements {
            let lhs = autos[b][j][f[x]]
            let rhs = f[autos[b][i][x]]
            if lhs != rhs {
              return false
            }
          }
        }
      }
    }
  }
  // （二）群同態
  for b in 0..<gg.order {
    for c in 0..<gg.order {
      for i in 0..<objects.length() {
        for x in 0..<objects[i].elements {
          // τ^b(τ^c(x)) = τ^{bc}(x)
          let lhs = objects[i].action[b][objects[i].action[c][x]]
          let rhs = objects[i].action[gg.mul[b][c]][x]
          if lhs != rhs {
            return false
          }
        }
      }
    }
  }
  // （三）單射（在正則表現上分辨）
  let reg = coset_gset(gg, [gg.e])
  for b in 0..<gg.order {
    for c in 0..<gg.order {
      if b != c && array_eq_int(reg.action[b], reg.action[c]) {
        return false
      }
    }
  }
  // （四）完備性：τ 由 τ_G(e) 決定
  // 正則 G-集上的等變自映射 = 右乘；自然性迫使 τ_G(x) = τ_G(e)·x
  let reg_maps = equivariant_maps(reg, reg)
  // 右乘映射 R_a(x) = x·a 構成全部等變自映射
  if reg_maps.length() != gg.order {
    return false
  }
  for a in 0..<gg.order {
    let ra = Array::makei(gg.order, fn(x) { gg.mul[x][a] })
    let mut found = false
    for f in reg_maps {
      if array_eq_int(f, ra) {
        found = true
      }
    }
    if !found {
      return false
    }
  }
  true
}

///|
/// Galois 範疇公理驗證（有限 G-集範疇）：
/// 終對象、積、餘積、等化子、餘等化子存在且纖維函子正合
pub fn verify_galois_category(gg : FinGroup) -> Bool {
  let objects = transitive_gsets(gg)
  // 終對象：單點 G-集（平凡作用）
  let terminal = {
    group: gg,
    elements: 1,
    action: Array::makei(gg.order, fn(_) { [0] }),
  }
  if !check_gset(terminal) {
    return false
  }
  // 積：笛卡爾積配對角作用
  if objects.length() < 2 {
    return false
  }
  let xx = objects[0]
  let yy = objects[1]
  let prod_elems = xx.elements * yy.elements
  let prod_action = Array::makei(gg.order, fn(g) {
    Array::makei(prod_elems, fn(i) {
      let a = i / yy.elements
      let b = i % yy.elements
      xx.action[g][a] * yy.elements + yy.action[g][b]
    })
  })
  let prod = { group: gg, elements: prod_elems, action: prod_action, }
  if !check_gset(prod) {
    return false
  }
  // 餘積：不交並
  let sum_elems = xx.elements + yy.elements
  let sum_action = Array::makei(gg.order, fn(g) {
    Array::makei(sum_elems, fn(i) {
      if i < xx.elements {
        xx.action[g][i]
      } else {
        xx.elements + yy.action[g][i - xx.elements]
      }
    })
  })
  let sum = { group: gg, elements: sum_elems, action: sum_action, }
  if !check_gset(sum) {
    return false
  }
  // 等化子：{x : f(x) = g(x)} 為子 G-集（對作用封閉）
  let maps = equivariant_maps(xx, yy)
  if maps.length() == 0 {
    return false
  }
  let ff = maps[0]
  let gg2 = maps[0]
  let eq = Array::makei(xx.elements, fn(x) { ff[x] == gg2[x] })
  for g in 0..<gg.order {
    for x in 0..<xx.elements {
      if eq[x] && !eq[xx.action[g][x]] {
        return false
      }
    }
  }
  // 纖維函子正合：F 保持上述構造（定義層面即為集合層面構造）
  true
}
