/// 範疇論核心：小範疇、函子（忠實／滿／等價）、自然變換與 Yoneda 引理。
///
/// 定義（小範疇）：C = (Ob, Mor, ∘, id)，∘ 滿足結合律，id 滿足單位律。
/// 定義（函子）：F : C → D 保持恆等與合成：F(id_X) = id_{FX}，F(g∘f) = F(g)∘F(f)。
/// 定義（忠實函子）：F_{X,Y} : hom_C(X,Y) → hom_D(FX,FY) 為單射。
/// 定義（滿函子）：F_{X,Y} 為滿射。
/// 定理（等價判準）：F 為範疇等價 ⟺ F 忠實 + 滿 + 本質滿射。
///   有限範疇上此判準是建構性的：可顯式造出擬逆函子 G 與自然同構 η : 1_C ≅ GF，ε : FG ≅ 1_D。
/// 定理（Yoneda 引理）：Nat(h^X, F) ≅ F(X)，自然同構。

///|
/// 箭號（以 Int 編號）
pub struct Arrow {
  from : Int32
  to : Int32
}

///|
/// 小範疇的有限表示：物件 0..n_obj-1，箭號表 arrows，合成表 comp，恆等表 id_of_obj
pub struct Category {
  n_obj : Int32
  arrows : Array[Arrow]
  /// comp[a][b] = Some(c) ⟺ c = b ∘ a（僅當 arrows[a].to == arrows[b].from 時有定義）
  comp : Array[Array[Int32?]]
  /// id_of_obj[x]：物件 x 的恆等箭號編號
  id_of_obj : Array[Int32]
}

///|
/// 建立範疇（不驗證公理，請用 check_laws 驗證）
pub fn make_category(
  n_obj : Int32,
  arrows : Array[Arrow],
  comp : Array[Array[Int32?]],
  id_of_obj : Array[Int32],
) -> Category {
  { n_obj, arrows, comp, id_of_obj, }
}

///|
/// 同態集 hom_C(x, y)（回傳箭號編號陣列）
pub fn hom(cc : Category, x : Int32, y : Int32) -> Array[Int32] {
  let r : Array[Int32] = []
  for i in 0..<cc.arrows.length() {
    let a = cc.arrows[i]
    if a.from == x && a.to == y {
      r.push(i)
    }
  }
  r
}

///|
/// 合成 b ∘ a
pub fn compose(cc : Category, a : Int32, b : Int32) -> Int32? {
  cc.comp[a][b]
}

///|
/// 驗證範疇公理：合成表良定義、恆等律、結合律。複雜度 O(|Mor|³)。
pub fn check_laws(cc : Category) -> Bool {
  let m = cc.arrows.length()
  for a in 0..<m {
    for b in 0..<m {
      let defined = cc.arrows[a].to == cc.arrows[b].from
      match cc.comp[a][b] {
        Some(_) => if !defined { return false }
        None => if defined { return false }
      }
    }
    let ax = cc.arrows[a].from
    let ay = cc.arrows[a].to
    match cc.comp[cc.id_of_obj[ax]][a] {
      Some(c) => if c != a { return false }
      None => return false
    }
    match cc.comp[a][cc.id_of_obj[ay]] {
      Some(c) => if c != a { return false }
      None => return false
    }
  }
  for a in 0..<m {
    for b in 0..<m {
      for c in 0..<m {
        if cc.arrows[a].to == cc.arrows[b].from &&
          cc.arrows[b].to == cc.arrows[c].from {
          match (cc.comp[a][b], cc.comp[b][c]) {
            (Some(ab), Some(bc)) =>
              match (cc.comp[ab][c], cc.comp[a][bc]) {
                (Some(l), Some(r)) => if l != r { return false }
                _ => return false
              }
            _ => return false
          }
        }
      }
    }
  }
  true
}

///|
/// 求箭號 a 的逆箭號（若 a 為同構）
pub fn inverse_arrow(cc : Category, a : Int32) -> Int32? {
  let x = cc.arrows[a].from
  let y = cc.arrows[a].to
  for b in hom(cc, y, x) {
    match (cc.comp[a][b], cc.comp[b][a]) {
      (Some(c1), Some(c2)) =>
        // c1 = b ∘ a = id_x，c2 = a ∘ b = id_y
        if c1 == cc.id_of_obj[x] && c2 == cc.id_of_obj[y] {
          return Some(b)
        }
      _ => ()
    }
  }
  None
}

///|
/// 箭號是否為同構
pub fn is_iso(cc : Category, a : Int32) -> Bool {
  match inverse_arrow(cc, a) {
    Some(_) => true
    None => false
  }
}

///|
/// 物件 x, y 是否同構
pub fn isomorphic(cc : Category, x : Int32, y : Int32) -> Bool {
  for a in hom(cc, x, y) {
    if is_iso(cc, a) {
      return true
    }
  }
  false
}

///|
/// 物件在同構意義下的等價類（union-find，O(|Mor|·α(n))）
pub fn iso_classes(cc : Category) -> Array[Int32] {
  let parent = Array::makei(cc.n_obj, fn(i) { i })
  for a in 0..<cc.arrows.length() {
    if is_iso(cc, a) {
      let rx = find_uf(parent, cc.arrows[a].from)
      let ry = find_uf(parent, cc.arrows[a].to)
      if rx != ry {
        parent[rx] = ry
      }
    }
  }
  Array::makei(cc.n_obj, fn(i) { find_uf(parent, i) })
}

///|
fn find_uf(parent : Array[Int32], x : Int32) -> Int32 {
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

///|
/// 函子 F : C → D 的有限表示
pub struct Functor {
  obj_map : Array[Int32]
  mor_map : Array[Int32]
}

///|
/// 驗證函子公理：F(id) = id，F(g∘f) = F(g)∘F(f)，端點相容
pub fn check_functor(ff : Functor, cc : Category, dd : Category) -> Bool {
  if ff.obj_map.length() != cc.n_obj ||
    ff.mor_map.length() != cc.arrows.length() {
    return false
  }
  for x in 0..<cc.n_obj {
    if ff.mor_map[cc.id_of_obj[x]] != dd.id_of_obj[ff.obj_map[x]] {
      return false
    }
  }
  for a in 0..<cc.arrows.length() {
    if dd.arrows[ff.mor_map[a]].from != ff.obj_map[cc.arrows[a].from] {
      return false
    }
    if dd.arrows[ff.mor_map[a]].to != ff.obj_map[cc.arrows[a].to] {
      return false
    }
  }
  for a in 0..<cc.arrows.length() {
    for b in 0..<cc.arrows.length() {
      match cc.comp[a][b] {
        Some(ab) => {
          let fa = ff.mor_map[a]
          let fb = ff.mor_map[b]
          match dd.comp[fa][fb] {
            Some(fab) => if fab != ff.mor_map[ab] { return false }
            None => return false
          }
        }
        None => ()
      }
    }
  }
  true
}

///|
/// 忠實性：每個同態集上的映射為單射。複雜度 O(Σ|hom|²)。
pub fn is_faithful(ff : Functor, cc : Category, _dd : Category) -> Bool {
  for x in 0..<cc.n_obj {
    for y in 0..<cc.n_obj {
      let hs = hom(cc, x, y)
      for i in 0..<hs.length() {
        for j in 0..<i {
          if ff.mor_map[hs[i]] == ff.mor_map[hs[j]] {
            return false
          }
        }
      }
    }
  }
  true
}

///|
/// 滿性：每個同態集上的映射為滿射
pub fn is_full(ff : Functor, cc : Category, dd : Category) -> Bool {
  for x in 0..<cc.n_obj {
    for y in 0..<cc.n_obj {
      for d in hom(dd, ff.obj_map[x], ff.obj_map[y]) {
        let mut found = false
        for c in hom(cc, x, y) {
          if ff.mor_map[c] == d {
            found = true
            break
          }
        }
        if !found {
          return false
        }
      }
    }
  }
  true
}

///|
/// 本質滿射：每個 D 物件同構於某個 F(x)
pub fn is_essentially_surjective(
  ff : Functor,
  cc : Category,
  dd : Category,
) -> Bool {
  for d in 0..<dd.n_obj {
    let mut hit = false
    for x in 0..<cc.n_obj {
      if isomorphic(dd, ff.obj_map[x], d) {
        hit = true
        break
      }
    }
    if !hit {
      return false
    }
  }
  true
}

///|
/// 等價函子：忠實 + 滿 + 本質滿射
pub fn is_equivalence(ff : Functor, cc : Category, dd : Category) -> Bool {
  is_faithful(ff, cc, dd) &&
  is_full(ff, cc, dd) &&
  is_essentially_surjective(ff, cc, dd)
}

///|
/// 由等價函子 ff 建構擬逆函子 gg : D → C（有限範疇上的建構性證明）。
/// 演算法：
///   1. 對每個 d ∈ D 選取同構 e_d : ff(gg(d)) → d（本質滿射保證存在）
///   2. 對 g : d → d'，定義 gg(g) 為唯一滿足 ff(gg(g)) = e_{d'}⁻¹ ∘ g ∘ e_d 的箭號
///      （由完全忠實性，hom_C(gg d, gg d') → hom_D 為雙射）
///   3. ε_d = e_d 自然同構 ff∘gg ≅ 1_D；η_x 為 e_{ff x}⁻¹ 對應的箭號，自然同構 1_C ≅ gg∘ff
pub fn quasi_inverse(ff : Functor, cc : Category, dd : Category) -> Functor {
  let obj_map = Array::make(dd.n_obj, 0)
  let e = Array::make(dd.n_obj, 0) // e[d]：箭號編號，from = ff(gg(d))，to = d
  for d in 0..<dd.n_obj {
    for x in 0..<cc.n_obj {
      let mut chosen = false
      for a in hom(dd, ff.obj_map[x], d) {
        if is_iso(dd, a) {
          obj_map[d] = x
          e[d] = a
          chosen = true
          break
        }
      }
      if chosen {
        break
      }
    }
  }
  let mor_map = Array::make(dd.arrows.length(), 0)
  for g in 0..<dd.arrows.length() {
    let d = dd.arrows[g].from
    let d2 = dd.arrows[g].to
    let x = obj_map[d]
    let y = obj_map[d2]
    // 計算 e_{d'}⁻¹ ∘ g ∘ e_d : ff(x) → ff(y)
    let eg = compose3(dd, e[d], g, inverse_arrow(dd, e[d2]).unwrap()).unwrap()
    // 在 hom_C(x, y) 中找唯一 a 使 ff(a) = eg
    let mut a0 = -1
    for a in hom(cc, x, y) {
      if ff.mor_map[a] == eg {
        a0 = a
        break
      }
    }
    if a0 == -1 {
      abort("quasi_inverse: ff 非完全忠實，無法造擬逆")
    }
    mor_map[g] = a0
  }
  { obj_map, mor_map, }
}

///|
/// 合成三個箭號：(c ∘ b) ∘ a，要求相容
fn compose3(cc : Category, a : Int32, b : Int32, c : Int32) -> Int32? {
  match compose(cc, a, b) {
    Some(ab) => compose(cc, ab, c)
    None => None
  }
}

///|
/// e_d : ff(gg(d)) → d 的同構箭號（與 quasi_inverse 中相同的選取規則）
fn e_arrow(ff : Functor, gg : Functor, dd : Category, d : Int32) -> Int32 {
  for a in hom(dd, ff.obj_map[gg.obj_map[d]], d) {
    if is_iso(dd, a) {
      return a
    }
  }
  abort("e_arrow: 非本質滿射")
}

///|
/// η_x : x → gg(ff(x)) 的自然同構箭號
fn eta_arrow(
  ff : Functor,
  gg : Functor,
  cc : Category,
  dd : Category,
  x : Int32,
) -> Int32 {
  let target = inverse_arrow(dd, e_arrow(ff, gg, dd, ff.obj_map[x])).unwrap()
  for a in hom(cc, x, gg.obj_map[ff.obj_map[x]]) {
    if ff.mor_map[a] == target {
      return a
    }
  }
  abort("eta_arrow: 找不到自然同構分量")
}

///|
/// 驗證擬逆：ε : fg∘ff ≅ 1_D 與 η : 1_C ≅ gg∘ff 均為自然同構
pub fn verify_quasi_inverse(
  ff : Functor,
  gg : Functor,
  cc : Category,
  dd : Category,
) -> Bool {
  // ε_d = e_d 為同構，且自然：g ∘ ε_d = ε_{d'} ∘ fg(g)
  for d in 0..<dd.n_obj {
    if !is_iso(dd, e_arrow(ff, gg, dd, d)) {
      return false
    }
  }
  for g in 0..<dd.arrows.length() {
    let d = dd.arrows[g].from
    let d2 = dd.arrows[g].to
    let eg1 = e_arrow(ff, gg, dd, d)
    let eg2 = e_arrow(ff, gg, dd, d2)
    let fgg = ff.mor_map[gg.mor_map[g]]
    match (compose(dd, eg1, g), compose(dd, fgg, eg2)) {
      (Some(l), Some(r)) => if l != r { return false }
      _ => return false
    }
  }
  // η_x 為同構，且自然：gg(ff(f)) ∘ η_x = η_y ∘ f
  for x in 0..<cc.n_obj {
    if !is_iso(cc, eta_arrow(ff, gg, cc, dd, x)) {
      return false
    }
  }
  for f in 0..<cc.arrows.length() {
    let x = cc.arrows[f].from
    let y = cc.arrows[f].to
    let eta_x = eta_arrow(ff, gg, cc, dd, x)
    let eta_y = eta_arrow(ff, gg, cc, dd, y)
    match
      (compose(cc, eta_x, gg.mor_map[ff.mor_map[f]]), compose(cc, f, eta_y)) {
      (Some(l), Some(r)) => if l != r { return false }
      _ => return false
    }
  }
  true
}

///|
/// 函子合成（hh ∘ ff，先 ff 後 hh）
pub fn compose_functor(ff : Functor, hh : Functor) -> Functor {
  // 定義域物件數與箭號數由 ff 決定
  let n_obj = ff.obj_map.length()
  let n_mor = ff.mor_map.length()
  let obj_map = Array::makei(n_obj, fn(x) { hh.obj_map[ff.obj_map[x]] })
  let mor_map = Array::makei(n_mor, fn(a) { hh.mor_map[ff.mor_map[a]] })
  { obj_map, mor_map, }
}

///|
/// 恆等函子
pub fn identity_functor(cc : Category) -> Functor {
  {
    obj_map: Array::makei(cc.n_obj, fn(x) { x }),
    mor_map: Array::makei(cc.arrows.length(), fn(a) { a }),
  }
}

///|
/// 有限 Set 值函子 F : C → Set
pub struct SetFunctor {
  dom : Category
  /// objects[x]：F(x) 的元素（以 Int 編號）
  objects : Array[Array[Int32]]
  /// arrows[a][i]：F(a)(objects[from][i]) 在 objects[to] 中的索引
  arrows : Array[Array[Int32]]
}

///|
/// 驗證 Set 值函子的函子公理
pub fn check_set_functor(ff : SetFunctor) -> Bool {
  let cc = ff.dom
  for a in 0..<cc.arrows.length() {
    let src = cc.arrows[a].from
    if ff.arrows[a].length() != ff.objects[src].length() {
      return false
    }
  }
  for a in 0..<cc.arrows.length() {
    for b in 0..<cc.arrows.length() {
      match cc.comp[a][b] {
        Some(ab) => {
          let src = cc.arrows[a].from
          for i in 0..<ff.objects[src].length() {
            if ff.arrows[ab][i] != ff.arrows[b][ff.arrows[a][i]] {
              return false
            }
          }
        }
        None => ()
      }
    }
  }
  true
}

///|
/// 自然變換 τ : F ⇒ G（每個物件一個函數，以索引陣列表示）是否自然
pub fn is_natural(
  tau : Array[Array[Int32]],
  ff : SetFunctor,
  gg : SetFunctor,
) -> Bool {
  let cc = ff.dom
  for a in 0..<cc.arrows.length() {
    let src = cc.arrows[a].from
    let tgt = cc.arrows[a].to
    for i in 0..<ff.objects[src].length() {
      // G(a)(τ_src(i)) == τ_tgt(F(a)(i))
      if gg.arrows[a][tau[src][i]] != tau[tgt][ff.arrows[a][i]] {
        return false
      }
    }
  }
  true
}

///|
/// Yoneda 嵌入 h^X = hom(X, −) : C → Set
pub fn yoneda(cc : Category, xx : Int32) -> SetFunctor {
  let objects = Array::makei(cc.n_obj, fn(y) { hom(cc, xx, y) })
  let arrows = Array::makei(cc.arrows.length(), fn(a) {
    let src = cc.arrows[a].from
    let tgt = cc.arrows[a].to
    let hs = hom(cc, xx, src)
    let ht = objects[tgt]
    let r : Array[Int32] = []
    for f in hs {
      // h^X(a)(f) = a ∘ f
      let g = match compose(cc, f, a) {
        Some(g) => g
        None => 0
      }
      let mut idx = 0
      for j in 0..<ht.length() {
        if ht[j] == g {
          idx = j
          break
        }
      }
      r.push(idx)
    }
    r
  })
  { dom: cc, objects, arrows, }
}

///|
/// Yoneda 引理正向：Nat(h^X, F) ∋ τ ↦ τ_X(id_X) ∈ F(X)
pub fn yoneda_forward(
  ff : SetFunctor,
  xx : Int32,
  tau : Array[Array[Int32]],
) -> Int32 {
  let id_index = index_of(ff.dom.id_of_obj[xx], ff.objects[xx])
  tau[xx][id_index]
}

///|
/// Yoneda 引理反向：F(X) ∋ a ↦ τ^a，τ^a_Y(f) = F(f)(a)
pub fn yoneda_backward(
  ff : SetFunctor,
  xx : Int32,
  a : Int32,
) -> Array[Array[Int32]] {
  let cc = ff.dom
  Array::makei(cc.n_obj, fn(y) {
    let r : Array[Int32] = []
    for f in hom(cc, xx, y) {
      r.push(ff.arrows[f][a])
    }
    r
  })
}

///|
fn index_of(x : Int32, xs : Array[Int32]) -> Int32 {
  for i in 0..<xs.length() {
    if xs[i] == x {
      return i
    }
  }
  0
}
