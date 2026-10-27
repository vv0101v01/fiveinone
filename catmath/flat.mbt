/// 平坦函子：保持有限極限的函子 F : C → Set。
///
/// 定義（平坦函子）：F 保持終對象與拉回（有限極限）。
/// 定理（Grothendieck）：F : C → Set 平坦 ⟺ 其元素範疇 ∫F 餘濾過。
///   ∫F：物件為 (x, a)，a ∈ F(x)；箭號 (x,a)→(y,b) 為 C 中滿足 F(h)(a) = b 的 h : x → y。
/// 定理（模論版本）：M 平坦 ⟺ M ⊗ − 保持正合 ⟺ Tor₁(M, −) = 0。
///   域上所有模皆平坦（因為自由），見 derived.mbt 的 Tor 計算。
/// 複雜度：有限範疇上極限保持的暴力檢驗為 O(|Ob|³·|Mor|)，
///   餘濾過判準為 O(|∫F|²·|Mor|)，兩者等價可交叉驗證。

///|
/// 在有限範疇 C 中計算 cospan f : x→z, g : y→z 的拉回
pub fn find_pullback(
  cc : Category,
  f : Int32,
  g : Int32,
) -> (Int32, Int32, Int32)? {
  // 拉回：物件 p 配 a : p→x, b : p→y 使 f∘a = g∘b，且具萬有性
  for p in 0..<cc.n_obj {
    for a in hom(cc, p, cc.arrows[f].from) {
      for b in hom(cc, p, cc.arrows[g].from) {
        match (compose(cc, a, f), compose(cc, b, g)) {
          (Some(l), Some(r)) =>
            if l == r && is_pullback(cc, f, g, p, a, b) {
              return Some((p, a, b))
            }
          _ => ()
        }
      }
    }
  }
  None
}

///|
fn is_pullback(
  cc : Category,
  f : Int32,
  g : Int32,
  p : Int32,
  a : Int32,
  b : Int32,
) -> Bool {
  // 萬有性：對任意 q 配 a' : q→x, b' : q→y 使 f∘a' = g∘b'，
  // 存在唯一 u : q→p 使 a∘u = a' 且 b∘u = b'
  let z = cc.arrows[f].to
  for q in 0..<cc.n_obj {
    for ap in hom(cc, q, cc.arrows[f].from) {
      for bp in hom(cc, q, cc.arrows[g].from) {
        match (compose(cc, ap, f), compose(cc, bp, g)) {
          (Some(l), Some(r)) =>
            if l == r {
              // 找 u
              let mut found = 0
              for u in hom(cc, q, p) {
                match (compose(cc, u, a), compose(cc, u, b)) {
                  (Some(ua), Some(ub)) =>
                    if ua == ap && ub == bp {
                      found = found + 1
                    }
                  _ => ()
                }
              }
              if found != 1 {
                return false
              }
            }
          _ => ()
        }
      }
    }
  }
  // p 自身與 (a, b) 構成的錐必須相容（f∘a = g∘b 已在呼叫處檢查）
  let _ = z
  true
}

///|
/// 終對象（若存在）
pub fn terminal_object(cc : Category) -> Int32? {
  for t in 0..<cc.n_obj {
    let mut ok = true
    for x in 0..<cc.n_obj {
      let hs = hom(cc, x, t)
      if hs.length() != 1 {
        ok = false
        break
      }
    }
    if ok {
      return Some(t)
    }
  }
  None
}

///|
/// 平坦函子檢驗：保持終對象與拉回
pub fn is_flat(ff : SetFunctor) -> Bool {
  let cc = ff.dom
  // 終對象
  match terminal_object(cc) {
    Some(t) => if ff.objects[t].length() != 1 { return false }
    None => ()
  }
  // 拉回：枚舉所有 cospan
  for f in 0..<cc.arrows.length() {
    for g in 0..<cc.arrows.length() {
      if cc.arrows[f].to == cc.arrows[g].to {
        match find_pullback(cc, f, g) {
          Some((p, a, b)) =>
            if !preserves_pullback(ff, f, g, p, a, b) {
              return false
            }
          None => ()
        }
      }
    }
  }
  true
}

///|
/// F 是否保持拉回方塊
fn preserves_pullback(
  ff : SetFunctor,
  f : Int32,
  g : Int32,
  p : Int32,
  a : Int32,
  b : Int32,
) -> Bool {
  let x = ff.dom.arrows[f].from
  let y = ff.dom.arrows[g].from
  // Set 中的拉回：{(u, v) : F(f)(u) = F(g)(v)}
  // 萬有性：每個 (u, v) 有唯一 w ∈ F(p) 使 F(a)(w) = u, F(b)(w) = v
  for u in 0..<ff.objects[x].length() {
    for v in 0..<ff.objects[y].length() {
      if ff.arrows[f][u] == ff.arrows[g][v] {
        let mut count = 0
        for w in 0..<ff.objects[p].length() {
          if ff.arrows[a][w] == u && ff.arrows[b][w] == v {
            count = count + 1
          }
        }
        if count != 1 {
          return false
        }
      }
    }
  }
  true
}

///|
/// 元素範疇 ∫F 的箭號判定：h : x→y 滿足 F(h)(a) = b
fn elements_arrow(ff : SetFunctor, h : Int32, a : Int32, b : Int32) -> Bool {
  ff.arrows[h][a] == b
}

///|
/// 餘濾過判準：∫F 非空、任意兩物件有共同錐、任意平行箭號可被等化。
pub fn is_cofiltered(ff : SetFunctor) -> Bool {
  let cc = ff.dom
  // 列舉 ∫F 的物件
  let objs : Array[(Int32, Int32)] = []
  for x in 0..<cc.n_obj {
    for a in 0..<ff.objects[x].length() {
      objs.push((x, a))
    }
  }
  if objs.length() == 0 {
    return false
  }
  // (2) 任意兩物件有共同錐
  for o1 in objs {
    for o2 in objs {
      let mut ok = false
      for o in objs {
        // 找箭號 o → o1 與 o → o2
        let mut has1 = false
        let mut has2 = false
        for h in 0..<cc.arrows.length() {
          if cc.arrows[h].from == o.0 &&
            cc.arrows[h].to == o1.0 &&
            elements_arrow(ff, h, o.1, o1.1) {
            has1 = true
          }
          if cc.arrows[h].from == o.0 &&
            cc.arrows[h].to == o2.0 &&
            elements_arrow(ff, h, o.1, o2.1) {
            has2 = true
          }
        }
        if has1 && has2 {
          ok = true
          break
        }
      }
      if !ok {
        return false
      }
    }
  }
  // (3) 平行箭號等化
  for o1 in objs {
    for o2 in objs {
      let parallel : Array[Int32] = []
      for h in 0..<cc.arrows.length() {
        if cc.arrows[h].from == o1.0 &&
          cc.arrows[h].to == o2.0 &&
          elements_arrow(ff, h, o1.1, o2.1) {
          parallel.push(h)
        }
      }
      for i in 0..<parallel.length() {
        for j in (i + 1)..<parallel.length() {
          let h = parallel[i]
          let k = parallel[j]
          let mut ok = false
          for o in objs {
            for m in 0..<cc.arrows.length() {
              if cc.arrows[m].from == o.0 &&
                cc.arrows[m].to == o1.0 &&
                elements_arrow(ff, m, o.1, o1.1) {
                match (compose(cc, m, h), compose(cc, m, k)) {
                  (Some(mh), Some(mk)) =>
                    if mh == mk {
                      ok = true
                      break
                    }
                  _ => ()
                }
              }
              if ok {
                break
              }
            }
            if ok {
              break
            }
          }
          if !ok {
            return false
          }
        }
      }
    }
  }
  true
}

///|
/// 定理驗證：平坦 ⟺ 餘濾過（在有限範疇上交叉檢驗）
pub fn flat_iff_cofiltered(ff : SetFunctor) -> Bool {
  is_flat(ff) == is_cofiltered(ff)
}
