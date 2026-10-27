/// 偽函子（pseudofunctor）與雙範疇相干性。
///
/// 定義（偽函子）：雙範疇 B → C 之間保持合成與單元至多同構：
///   φ_{g,f} : F(g) ∘ F(f) ≅ F(g ∘ f)，φ_x : id_{F(x)} ≅ F(id_x)，
///   滿足結合律（五邊形）與單位律（三角形）相干公理。
/// 定理（Mac Lane 相干性）：每個偽函子都相干地等價於嚴格 2-函子
///   （strictification）。
/// 實作：BG（一個 0-胞的雙範疇，G 為有限群）→ Cat 的偽函子
///   = G 對有限範疇 D 的作用（至多相干同構）。
///   結合公理在 D 為交換群時即 2-上循環條件：
///   c(h, gk) + c(g, k) = c(hg, k) + c(h, g)。

///|
/// 函子間的自然同構（箭號編號族）
pub struct NatIso {
  /// components[x]：F(x) → G(x) 的同構箭號
  components : Array[Int32]
}

///|
/// 驗證自然同構：分量為同構且自然
pub fn check_nat_iso(
  ni : NatIso,
  ff : Functor,
  gg : Functor,
  cc : Category,
) -> Bool {
  for x in 0..<cc.n_obj {
    if !is_iso(cc, ni.components[x]) {
      return false
    }
    if cc.arrows[ni.components[x]].from != ff.obj_map[x] {
      return false
    }
    if cc.arrows[ni.components[x]].to != gg.obj_map[x] {
      return false
    }
  }
  for f in 0..<cc.arrows.length() {
    let x = cc.arrows[f].from
    let y = cc.arrows[f].to
    // G(f) ∘ η_x = η_y ∘ F(f)
    match
      (
        compose(cc, ni.components[x], gg.mor_map[f]),
        compose(cc, ff.mor_map[f], ni.components[y]),
      ) {
      (Some(l), Some(r)) => if l != r { return false }
      _ => return false
    }
  }
  true
}

///|
/// 恆等自然同構
pub fn nat_iso_id(cc : Category) -> NatIso {
  NatIso::{ components: Array::makei(cc.n_obj, fn(x) { cc.id_of_obj[x] }), }
}

///|
/// G 對範疇 D 的偽函子作用（BG → Cat）
pub struct GroupActionPseudo {
  gg : FinGroup
  dom : Category
  /// alpha[g]：D → D 的函子（g ∈ G）
  alpha : Array[Functor]
  /// phi[g][h]：α_g ∘ α_h ≅ α_{gh} 的自然同構
  phi : Array[Array[NatIso]]
}

///|
/// 函子相等（嚴格）：物件與箭號映射逐點相等
pub fn functor_eq(ff : Functor, gg : Functor) -> Bool {
  if ff.obj_map.length() != gg.obj_map.length() {
    return false
  }
  for x in 0..<ff.obj_map.length() {
    if ff.obj_map[x] != gg.obj_map[x] {
      return false
    }
  }
  if ff.mor_map.length() != gg.mor_map.length() {
    return false
  }
  for a in 0..<ff.mor_map.length() {
    if ff.mor_map[a] != gg.mor_map[a] {
      return false
    }
  }
  true
}

///|
/// 驗證偽函子的相干公理：
/// （一）每個 α_g 是函子；
/// （二）每個 φ_{g,h} 是自然同構 α_g α_h ⇒ α_{gh}；
/// （三）結合律：φ_{h,gk} ∘ (α_h ⋆ φ_{g,k}) = φ_{hg,k} ∘ (φ_{h,g} ⋆ α_k)；
/// （四）單位律：φ_{e,g}、φ_{g,e} 為恆等（當 α_e = id_D）。
pub fn check_pseudo(ap : GroupActionPseudo) -> Bool {
  let gg = ap.gg
  let dd = ap.dom
  // （一）
  for g in 0..<gg.order {
    if !check_functor(ap.alpha[g], dd, dd) {
      return false
    }
  }
  // （二）
  for g in 0..<gg.order {
    for h in 0..<gg.order {
      let comp = compose_functor(ap.alpha[h], ap.alpha[g])
      let target = ap.alpha[gg.mul[g][h]]
      if !check_nat_iso(ap.phi[g][h], comp, target, dd) {
        return false
      }
    }
  }
  // （三）結合律（在每個物件 x 上驗證）
  for g in 0..<gg.order {
    for h in 0..<gg.order {
      for k in 0..<gg.order {
        for x in 0..<dd.n_obj {
          let gf = gg.mul[g][k]
          let hg = gg.mul[h][g]
          let y = ap.alpha[h].obj_map[ap.alpha[g].obj_map[ap.alpha[k].obj_map[x]]]
          // LHS：φ_{h,gk}(x) ∘ α_h(φ_{g,k}(x))
          let lhs = match
            compose(
              dd,
              ap.alpha[h].mor_map[ap.phi[g][k].components[x]],
              ap.phi[h][gf].components[x],
            ) {
            Some(a) => a
            None => return false
          }
          let _ = y
          // RHS：φ_{hg,k}(x) ∘ φ_{h,g}(α_k(x))
          let rhs = match
            compose(
              dd,
              ap.phi[h][g].components[ap.alpha[k].obj_map[x]],
              ap.phi[hg][k].components[x],
            ) {
            Some(a) => a
            None => return false
          }
          if lhs != rhs {
            return false
          }
        }
      }
    }
  }
  // （四）單位律（α_e = id_D 時）
  let e = gg.e
  for g in 0..<gg.order {
    for x in 0..<dd.n_obj {
      if ap.phi[e][g].components[x] != dd.id_of_obj[ap.alpha[g].obj_map[x]] {
        return false
      }
      if ap.phi[g][e].components[x] != dd.id_of_obj[ap.alpha[g].obj_map[x]] {
        return false
      }
    }
  }
  true
}

///|
/// 2-上循環的余邊界：db(g,h) = b(g) + b(h) − b(gh)（交換群值，加法記號）。
/// 定理：上循環為余邊界 ⟺ 對應偽函子嚴格化為嚴格 2-函子。
pub fn is_coboundary(
  gg : FinGroup,
  c : Array[Array[Int32]],
  b : Array[Int32],
  p : Int32,
) -> Bool {
  for g in 0..<gg.order {
    for h in 0..<gg.order {
      // db(g,h) = b(g) + b(h) − b(gh) ≡ c(g,h) mod p
      let db = ((b[g] + b[h] - b[gg.mul[g][h]]) % p + p) % p
      if db != c[g][h] {
        return false
      }
    }
  }
  true
}

///|
/// 嚴格化：把相干同構 φ 換成 φ' = φ − db（db 為 b 的余邊界）。
/// 當 c = db 時 φ' ≡ 0，即嚴格作用。
pub fn strictify(
  ap : GroupActionPseudo,
  b : Array[Int32],
  c : Array[Array[Int32]],
  p : Int32,
) -> GroupActionPseudo {
  let gg = ap.gg
  let dd = ap.dom
  let phi = Array::makei(gg.order, fn(g) {
    Array::makei(gg.order, fn(h) {
      let db = b[g] + b[h] - b[gg.mul[g][h]]
      let d = ((c[g][h] - db) % p + p) % p
      NatIso::{ components: Array::makei(dd.n_obj, fn(_) { d }), }
    })
  })
  { gg, dom: dd, alpha: ap.alpha, phi, }
}

///|
/// 驗證原偽函子與嚴格化之間的等價：
/// 自然同構 β_g : α_g ≅ α'_g 由 b 給出（平凡作用下分量為 b(g)）。
pub fn strictification_equivalent(
  ap : GroupActionPseudo,
  ap_strict : GroupActionPseudo,
  b : Array[Int32],
) -> Bool {
  let gg = ap.gg
  let dd = ap.dom
  for g in 0..<gg.order {
    let beta = NatIso::{ components: Array::makei(dd.n_obj, fn(_) { b[g] }), }
    if !check_nat_iso(beta, ap.alpha[g], ap_strict.alpha[g], dd) {
      return false
    }
  }
  // 嚴格化後必為嚴格作用：α'_g ∘ α'_h = α'_{gh}（函子逐點相等）
  for g in 0..<gg.order {
    for h in 0..<gg.order {
      let comp = compose_functor(ap_strict.alpha[h], ap_strict.alpha[g])
      if !functor_eq(comp, ap_strict.alpha[gg.mul[g][h]]) {
        return false
      }
    }
  }
  true
}
