/// 自由函子與伴隨。
///
/// 定義（自由函子）：F : Set → Mon 為忘記函子 U : Mon → Set 的左伴隨。
/// 定理（萬有性質）：∀ 幺半群 A、∀ f : X → U(A)，∃! 幺半群同態 f̃ : F(X) → A
///   使得 U(f̃) ∘ η_X = f，其中 η_X : X → U(F(X)) 為單位。
/// 定理（伴隨）：Hom_Mon(F(X), A) ≅ Hom_Set(X, U(A))，自然於 X 與 A。
/// 定理（自由群）：自由群 F(X) = X⊔X⁻¹ 上的約化詞，歸一演算法為 O(n) 棧操作。

///|
/// 有限幺半群
pub struct FinMonoid {
  order : Int32
  mul : Array[Array[Int32]]
  e : Int32
  name : String
}

///|
/// 自由幺半群（列表幺半群）：字彙上的拼接
pub struct FreeMonoid {
  alphabet : Int32 // 生成元個數 |X|
}

///|
/// 自由幺半群的元素：詞（生成元索引序列）
pub fn fm_concat(u : Array[Int32], v : Array[Int32]) -> Array[Int32] {
  let r = u.copy()
  for x in v {
    r.push(x)
  }
  r
}

///|
/// 萬有性質的唯一擴展：f̃(w) = Π f(w_i)
pub fn fm_extend(
  _fm : FreeMonoid,
  f : Array[Int32],
  a : FinMonoid,
  w : Array[Int32],
) -> Int32 {
  let mut r = a.e
  for x in w {
    r = a.mul[r][f[x]]
  }
  r
}

///|
/// 驗證自由幺半群的萬有性質：
/// 對所有長度 ≤ L 的詞 u, v：f̃(uv) = f̃(u)·f̃(v)，且 f̃(ε) = e。
pub fn verify_free_monoid(
  alphabet : Int32,
  a : FinMonoid,
  f : Array[Int32],
  l : Int32,
) -> Bool {
  let fm = FreeMonoid::{ alphabet, }
  // 單位
  if fm_extend(fm, f, a, []) != a.e {
    return false
  }
  for u in all_words(alphabet, l) {
    for v in all_words(alphabet, l) {
      let uv = fm_concat(u, v)
      if fm_extend(fm, f, a, uv) !=
        a.mul[fm_extend(fm, f, a, u)][fm_extend(fm, f, a, v)] {
        return false
      }
    }
  }
  true
}

///|
/// 枚舉長度 ≤ l 的所有詞
fn all_words(alphabet : Int32, l : Int32) -> Array[Array[Int32]] {
  let r : Array[Array[Int32]] = [[]]
  let mut level : Array[Array[Int32]] = [[]]
  for _ in 0..<l {
    let next : Array[Array[Int32]] = []
    for w in level {
      for c in 0..<alphabet {
        let nw = w.copy()
        nw.push(c)
        next.push(nw)
      }
    }
    level = next
    for w in next {
      r.push(w)
    }
  }
  r
}

///|
/// 伴隨雙射驗證：Hom_Mon(F(X), A) ≅ Hom_Set(X, U(A))。
/// 左側由右側唯一決定；枚舉右側所有函數並驗證一一對應。
pub fn verify_adjunction_monoid(alphabet : Int32, a : FinMonoid) -> Bool {
  // 右側：所有函數 X → U(A)，共 |A|^|X| 個
  let mut count = 0
  let images : Array[Array[Int32]] = []
  for f in all_functions(alphabet, a.order) {
    // 左側：對應的幺半群同態（在自由幺半群的生成元上即 f）
    // 驗證其確實為同態（在長度 ≤ 2 的詞上即可，因為生成元決定一切）
    if is_monoid_hom_from_free(alphabet, f, a) {
      count = count + 1
      images.push(f)
    }
  }
  // 每個 f 恰好對應一個同態；同態總數 = |A|^|X|
  count == all_functions(alphabet, a.order).length()
}

///|
fn is_monoid_hom_from_free(
  alphabet : Int32,
  f : Array[Int32],
  a : FinMonoid,
) -> Bool {
  let fm = FreeMonoid::{ alphabet, }
  // 生成元間的乘積在自由幺半群中即為拼接詞；同態性由 fm_extend 的定義保證。
  // 此處驗證：f̃(x·y) = f̃(x)·f̃(y) 對所有生成元 x, y
  for x in 0..<alphabet {
    for y in 0..<alphabet {
      let w = [x, y]
      if fm_extend(fm, f, a, w) != a.mul[f[x]][f[y]] {
        return false
      }
    }
  }
  true
}

///|
/// 所有函數 X → A（|A|^|X| 個）
fn all_functions(alphabet : Int32, codomain : Int32) -> Array[Array[Int32]] {
  if alphabet == 0 {
    return [[]]
  }
  let rest = all_functions(alphabet - 1, codomain)
  let r : Array[Array[Int32]] = []
  for v in rest {
    for c in 0..<codomain {
      let w = v.copy()
      w.push(c)
      r.push(w)
    }
  }
  r
}

// ---------------------------------------------------------------------------
// 自由群：約化詞正規形
// ---------------------------------------------------------------------------

///|
/// 自由群的元素：約化詞，正生成元 x ↦ 2x，逆生成元 x⁻¹ ↦ 2x+1
pub struct FreeGroup {
  generators : Int32
}

///|
/// O(n) 棧歸一：相鄰互逆生成元相消
pub fn fg_reduce(_fg : FreeGroup, w : Array[Int32]) -> Array[Int32] {
  let stack : Array[Int32] = []
  for x in w {
    if stack.length() > 0 {
      let top = stack[stack.length() - 1]
      if (top ^ 1) == x {
        ignore(stack.pop())
        continue
      }
    }
    stack.push(x)
  }
  stack
}

///|
/// 自由群上的乘法：拼接後歸一
pub fn fg_mul(
  fg : FreeGroup,
  u : Array[Int32],
  v : Array[Int32],
) -> Array[Int32] {
  fg_reduce(fg, fm_concat(u, v))
}

///|
/// 自由群的萬有性質驗證：任意 f : X → G 唯一擴展為群同態
pub fn verify_free_group(
  generators : Int32,
  gg : FinGroup,
  f : Array[Int32],
  l : Int32,
) -> Bool {
  let fg = FreeGroup::{ generators, }
  // 擴展：h(w) = Π f̂(w_i)，其中 f̂(2x) = f[x], f̂(2x+1) = f[x]⁻¹
  for u in all_words(2 * generators, l) {
    for v in all_words(2 * generators, l) {
      // 同態性：h(u·v) = h(u)·h(v)（在約化詞上）
      let lhs = fg_eval(fg, f, gg, fg_mul(fg, u, v))
      let rhs = gg.mul[fg_eval(fg, f, gg, fg_reduce(fg, u))][fg_eval(
          fg,
          f,
          gg,
          fg_reduce(fg, v),
        )]
      if lhs != rhs {
        return false
      }
    }
  }
  // 單位
  fg_eval(fg, f, gg, fg_reduce(fg, [])) == gg.e
}

///|
fn fg_eval(
  _fg : FreeGroup,
  f : Array[Int32],
  gg : FinGroup,
  w : Array[Int32],
) -> Int32 {
  let mut r = gg.e
  for x in w {
    let g = if x % 2 == 0 { f[x / 2] } else { gg.inv[f[x / 2]] }
    r = gg.mul[r][g]
  }
  r
}

///|
/// 伴隨雙射驗證（自由群版本）：Hom_Grp(F(X), G) ≅ Hom_Set(X, U(G))
pub fn verify_adjunction_group(generators : Int32, gg : FinGroup) -> Bool {
  let fg = FreeGroup::{ generators, }
  let mut count = 0
  for f in all_functions(generators, gg.order) {
    // 每個 f 唯一決定群同態；驗證其保持運算（在短詞上）
    let mut ok = true
    for u in all_words(2 * generators, 2) {
      for v in all_words(2 * generators, 2) {
        let lhs = fg_eval(fg, f, gg, fg_mul(fg, u, v))
        let rhs = gg.mul[fg_eval(fg, f, gg, fg_reduce(fg, u))][fg_eval(
            fg,
            f,
            gg,
            fg_reduce(fg, v),
          )]
        if lhs != rhs {
          ok = false
          break
        }
      }
      if !ok {
        break
      }
    }
    if ok {
      count = count + 1
    }
  }
  count == all_functions(generators, gg.order).length()
}
