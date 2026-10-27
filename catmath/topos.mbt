/// 拓撲斯（topos）：預層範疇 [C^op, Set] 與次對象分類器。
///
/// 定義（初等拓撲斯）：具有限极限、冪對象、次對象分類器 Ω 的範疇。
/// 定義（預層範疇）：[C^op, Set] 對小範疇 C 是拓撲斯；
///   極限與餘極限逐點計算。
/// 定義（子對象分類器）：Ω(c) = c 上的篩（sieve）——
///   C 中以 c 為終點的箭號集合，對前複合封閉：
///   f ∈ S 且 g 可合成 ⟹ f∘g ∈ S。
///   特徵態射 χ_S : F → Ω，χ_S(c)(x) = {f : c'→c | F(f)(x) ∈ S(c')}。
/// 定理：Sub(F) ≅ Nat(F, Ω)（單射 ↔ 特徵態射雙射）。

///|
/// 預層 F : C^op → Set（有限表示）
pub struct Presheaf {
  cc : Category
  /// sets[c] = F(c) 的大小
  sets : Array[Int32]
  /// maps[f]：F(f) : F(to(f)) → F(from(f))（反變作用，箭號 f : x→y）
  maps : Array[Array[Int32]]
}

///|
/// 驗證預層函子性：F(id) = id，F(f∘g) = F(g)∘F(f)
pub fn check_presheaf(ps : Presheaf) -> Bool {
  let cc = ps.cc
  for c in 0..<cc.n_obj {
    // F(id_c) = id
    if !array_eq_int(
        ps.maps[cc.id_of_obj[c]],
        Array::makei(ps.sets[c], fn(i) { i }),
      ) {
      return false
    }
  }
  for f in 0..<cc.arrows.length() {
    for g in 0..<cc.arrows.length() {
      match compose(cc, f, g) {
        Some(h) => {
          // F(h) = F(f) ∘ F(g)（反變：h = g∘f ⟹ F(h) = F(f)∘F(g)）
          let fg = compose_ps(ps, f, g)
          if !array_eq_int(fg, ps.maps[h]) {
            return false
          }
        }
        None => ()
      }
    }
  }
  true
}

///|
/// F(f) ∘ F(g)（反變複合）
fn compose_ps(ps : Presheaf, f : Int32, g : Int32) -> Array[Int32] {
  // F(f) : F(to f) → F(from f)；F(g) : F(to g) → F(from g)
  // h = g∘f，F(h) = F(f) ∘ F(g) : F(to g) → F(from f)
  let ff = ps.maps[f]
  let gg = ps.maps[g]
  Array::makei(gg.length(), fn(z) { ff[gg[z]] })
}

///|
/// c 上的篩：以 c 為終點的箭號集合，對前複合封閉
pub fn sieves_on(cc : Category, c : Int32) -> Array[Array[Int32]] {
  // 進入 c 的箭號
  let into_c : Array[Int32] = []
  for a in 0..<cc.arrows.length() {
    if cc.arrows[a].to == c {
      into_c.push(a)
    }
  }
  // 窮舉子集並檢驗封閉性
  let total = pow_int(2, into_c.length())
  let out : Array[Array[Int32]] = []
  for mask in 0..<total {
    let ss : Array[Int32] = []
    for i in 0..<into_c.length() {
      if ((mask >> i) & 1) == 1 {
        ss.push(into_c[i])
      }
    }
    // 封閉性：f ∈ S，g : d→c' 可合成（f 的源 = g 的終）⟹ f∘g ∈ S
    let mut closed = true
    for f in ss {
      for g in 0..<cc.arrows.length() {
        if cc.arrows[g].to == cc.arrows[f].from {
          // f ∘ g 存在
          let fg = compose(cc, g, f)
          match fg {
            Some(h) => {
              let mut in_s = false
              for t in ss {
                if t == h {
                  in_s = true
                }
              }
              if !in_s {
                closed = false
              }
            }
            None => ()
          }
        }
      }
    }
    if closed {
      out.push(ss)
    }
  }
  out
}

///|
/// 次對象分類器 Ω : C^op → Set，Ω(c) = c 上的篩
pub fn omega_presheaf(cc : Category) -> Presheaf {
  let sets = Array::makei(cc.n_obj, fn(c) { sieves_on(cc, c).length() })
  // Ω(f) : Ω(y) → Ω(x)（f : x → y）：篩 S ↦ {g : f∘g ∈ S}
  let maps = Array::makei(cc.arrows.length(), fn(f) {
    let x = cc.arrows[f].from
    let y = cc.arrows[f].to
    let sy = sieves_on(cc, y)
    let sx = sieves_on(cc, x)
    Array::makei(sy.length(), fn(i) {
      // S = sy[i]；拉回篩 {g : x'→x | f∘g ∈ S}
      let pulled : Array[Int32] = []
      for g in 0..<cc.arrows.length() {
        if cc.arrows[g].to == x {
          match compose(cc, g, f) {
            Some(h) => {
              let mut in_s = false
              for t in sy[i] {
                if t == h {
                  in_s = true
                }
              }
              if in_s {
                pulled.push(g)
              }
            }
            None => ()
          }
        }
      }
      // 找 pulled 在 sx 中的索引
      let mut idx = 0
      for j in 0..<sx.length() {
        if array_eq_int(sx[j], pulled) {
          idx = j
        }
      }
      idx
    })
  })
  { cc, sets, maps, }
}

///|
/// 預層 F 的子預層（逐點子集，對作用封閉）
pub fn subpresheaves(ps : Presheaf) -> Array[Array[Array[Bool]]] {
  // 遞迴枚舉每個物件的子集（位元掩碼）並檢驗封閉性
  let out : Array[Array[Array[Bool]]] = []
  enum_subsets(ps, 0, Array::make(ps.cc.n_obj, 0), out)
  out
}

///|
/// 遞迴枚舉每個物件的子集掩碼並檢驗封閉性
fn enum_subsets(
  ps : Presheaf,
  c : Int32,
  current : Array[Int32],
  out : Array[Array[Array[Bool]]],
) -> Unit {
  if c == ps.cc.n_obj {
    // 檢驗封閉性：x ∈ S(to f) ⟹ F(f)(x) ∈ S(from f)
    let mut ok = true
    for f in 0..<ps.cc.arrows.length() {
      let x = ps.cc.arrows[f].from
      let y = ps.cc.arrows[f].to
      for i in 0..<ps.sets[y] {
        if bit_at(current[y], i) && !bit_at(current[x], ps.maps[f][i]) {
          ok = false
        }
      }
    }
    if ok {
      let ss = Array::makei(ps.cc.n_obj, fn(k) {
        Array::makei(ps.sets[k], fn(i) { bit_at(current[k], i) })
      })
      out.push(ss)
    }
  } else {
    let total = pow_int(2, ps.sets[c])
    for mask in 0..<total {
      let next = current.copy()
      next[c] = mask
      enum_subsets(ps, c + 1, next, out)
    }
  }
}

///|
fn bit_at(mask : Int32, i : Int32) -> Bool {
  ((mask >> i) & 1) == 1
}

///|
/// 特徵態射在物件 c 上的分量：F(c) → Ω(c)
pub fn classify_at(
  ps : Presheaf,
  ss : Array[Array[Bool]],
  c : Int32,
) -> Array[Int32] {
  let cc = ps.cc
  let sc = sieves_on(cc, c)
  Array::makei(ps.sets[c], fn(x) {
    // 篩 {f : c'→c | F(f)(x) ∈ S(c')}
    let sv : Array[Int32] = []
    for f in 0..<cc.arrows.length() {
      if cc.arrows[f].to == c {
        let xp = cc.arrows[f].from
        let img = ps.maps[f][x]
        if ss[xp][img] {
          sv.push(f)
        }
      }
    }
    // 找 sv 在篩列表中的索引
    let mut idx = 0
    for j in 0..<sc.length() {
      if array_eq_int(sc[j], sv) {
        idx = j
      }
    }
    idx
  })
}

///|
/// 驗證次對象分類器：Sub(F) ≅ Nat(F, Ω)（有限窮舉）
/// 對每個子預層 S，χ_S 是自然變換，且 S ↦ χ_S 為單射。
pub fn verify_subobject_classifier(ps : Presheaf) -> Bool {
  let cc = ps.cc
  let om = omega_presheaf(cc)
  let subs = subpresheaves(ps)
  let signatures : Array[Array[Array[Int32]]] = []
  for ss in subs {
    // χ_S 的全部點分量
    let chi = Array::makei(cc.n_obj, fn(c) { classify_at(ps, ss, c) })
    // 自然性檢查：對每個箭號 f : x→y，
    // Ω(f) ∘ χ_y = χ_x ∘ F(f)
    for f in 0..<cc.arrows.length() {
      let x = cc.arrows[f].from
      let y = cc.arrows[f].to
      for i in 0..<ps.sets[y] {
        // χ_y(F... 註：χ_y(i) 經 Ω(f) 作用
        let lhs = om.maps[f][chi[y][i]]
        let rhs = chi[x][ps.maps[f][i]]
        if lhs != rhs {
          return false
        }
      }
    }
    // 單射：不同子預層有不同 χ
    for other in signatures {
      if nat_eq(chi, other) {
        return false
      }
    }
    signatures.push(chi)
  }
  true
}

///|
fn nat_eq(aa : Array[Array[Int32]], bb : Array[Array[Int32]]) -> Bool {
  if aa.length() != bb.length() {
    return false
  }
  for i in 0..<aa.length() {
    if !array_eq_int(aa[i], bb[i]) {
      return false
    }
  }
  true
}

///|
/// 預層範疇的終對象（每點單點集）
pub fn terminal_presheaf(cc : Category) -> Presheaf {
  {
    cc,
    sets: Array::makei(cc.n_obj, fn(_) { 1 }),
    maps: Array::makei(cc.arrows.length(), fn(_) { [0] }),
  }
}

///|
/// 冪對象 P(X) = Ω^X 的大小（逐點：P(X)(c) = Ω(c)^{X(c)}）
pub fn power_object_size(ps : Presheaf) -> Array[Int32] {
  let om = omega_presheaf(ps.cc)
  Array::makei(ps.cc.n_obj, fn(c) { pow_int(om.sets[c], ps.sets[c]) })
}
