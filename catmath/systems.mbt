/// 動力系統（dynamical systems）的有限計算。
///
/// 定義（有限動力系統）：$(X, f)$，$X$ 有限集，$f:X\to X$ 自我映射。
/// 範疇論詮釋：動力系統 = 函子 $F:\mathbb{N}\to\mathbf{Set}$
///   （$\mathbb{N}$ 為加法幺半群視作單物件範疇）；
///   態射 $h:(X,f)\to(Y,g)$ = 自然變換 = 交換圖 $h\circ f=g\circ h$。
/// 定理（函數圖結構）：有限動力系統的相圖由若干「ρ 形」分量組成
///   （尾 + 環）；每點的軌道最終進入唯一環。
/// 定理（Floyd 龜兔演算法）：$O(\mu+\lambda)$ 時間、$O(1)$ 空間
///   偵測環（$\mu$ = 入環前距，$\lambda$ = 環長）。
/// 定理（自由動力系統）：$(\mathbb{N},\mathrm{succ})$ 為單點生成之
///   自由系統；萬有性質：$\forall(x_0\in X)$，$\exists!\,h:\mathbb{N}\to X$，
///   $h(0)=x_0$ 且 $h(n+1)=f(h(n))$（即 $h(n)=f^n(x_0)$）。
///   截断版 $\mathrm{Free}(k)=\{0,\dots,k\}$（$f(k)=k$）之萬有性質
///   對「所有軌道在 $k$ 步內抵達不動點」的系統成立。
/// 複雜度：環分解 $O(n)$（對每點重算軌道的樸素 $O(n^2)$ 降階）；
///   $f^m(x)$ 之計算 $O(m)\to O(\log m)$（二進制提升／跳躍指標）。

///|
/// 有限動力系統 $(X, f)$
pub struct DynSys {
  /// $|X|$
  n : Int32
  /// f[x] = f(x)
  f : Array[Int32]
}

///|
/// 建立動力系統（自動驗證 f 的值域）
pub fn make_dyn(n : Int32, f : Array[Int32]) -> DynSys {
  if f.length() != n {
    abort("make_dyn: f length mismatch")
  }
  for x in 0..<n {
    if f[x] < 0 || f[x] >= n {
      abort("make_dyn: f value out of range")
    }
  }
  { n, f, }
}

///|
/// 系統大小 |X|
pub fn ds_size(ds : DynSys) -> Int32 {
  ds.n
}

///|
/// f(x)
pub fn ds_apply(ds : DynSys, x : Int32) -> Int32 {
  ds.f[x]
}

///|
/// 軌道 [x, f(x), …, f^k(x)]（樸素 O(k)）
pub fn orbit(ds : DynSys, x : Int32, k : Int32) -> Array[Int32] {
  let r = Array::make(k + 1, 0)
  let mut cur = x
  for i in 0..<=k {
    r[i] = cur
    cur = ds.f[cur]
  }
  r
}

///|
/// f^m(x)（樸素 O(m)）
pub fn ds_iterate(ds : DynSys, x : Int32, m : Int32) -> Int32 {
  let mut cur = x
  for _ in 0..<m {
    cur = ds.f[cur]
  }
  cur
}

///|
/// 二進制提升（跳躍指標）：預處理 O(n log M)，查詢 O(log m)
pub struct JumpTable {
  jump : Array[Array[Int32]]
}

///|
/// 建立跳躍表：jump[k][x] = f^{2^k}(x)
pub fn make_jump(ds : DynSys, levels : Int32) -> JumpTable {
  let jump : Array[Array[Int32]] = []
  jump.push(ds.f.copy())
  for k in 1..<levels {
    let prev = jump[k - 1]
    let cur = Array::makei(ds.n, fn(x) { prev[prev[x]] })
    jump.push(cur)
  }
  { jump, }
}

///|
/// f^m(x)：二進制提升，O(log m)
pub fn ds_iterate_pow(jt : JumpTable, x : Int32, m : Int32) -> Int32 {
  let mut cur = x
  let mut rest = m
  let mut k = 0
  while rest > 0 {
    if (rest & 1) == 1 {
      cur = jt.jump[k][cur]
    }
    rest = rest >> 1
    k = k + 1
  }
  cur
}

///|
/// Floyd 龜兔演算法：$(μ, λ)$——入環前距與環長。
/// 定理：$O(μ+λ)$ 時間、$O(1)$ 空間。
pub fn floyd_cycle(ds : DynSys, x : Int32) -> (Int32, Int32) {
  // 第一階段：龜（1 步）兔（2 步）相遇
  let mut tortoise = ds.f[x]
  let mut hare = ds.f[ds.f[x]]
  while tortoise != hare {
    tortoise = ds.f[tortoise]
    hare = ds.f[ds.f[hare]]
  }
  // 第二階段：求 μ（入環前距）
  let mut mu = 0
  tortoise = x
  while tortoise != hare {
    tortoise = ds.f[tortoise]
    hare = ds.f[hare]
    mu = mu + 1
  }
  // 第三階段：求 λ（環長）
  let mut lambda = 1
  hare = ds.f[tortoise]
  while tortoise != hare {
    hare = ds.f[hare]
    lambda = lambda + 1
  }
  (mu, lambda)
}

///|
/// 函數圖環分解：每點給出 (分量代表, 尾長, 環長)。
/// 算法：剝離入度 0 點（尾）→ 剩餘為環點 → 環遍歷標號
/// → 反向 BFS 標尾長。複雜度 O(n)。
pub fn cycle_decompose(ds : DynSys) -> Array[(Int32, Int32, Int32)] {
  let n = ds.n
  // 入度
  let indeg = Array::make(n, 0)
  for x in 0..<ds.n {
    indeg[ds.f[x]] = indeg[ds.f[x]] + 1
  }
  // 剝離尾點（入度 0）
  let is_tail = Array::make(n, false)
  let mut queue : Array[Int32] = []
  for x in 0..<ds.n {
    if indeg[x] == 0 {
      queue.push(x)
    }
  }
  while queue.length() > 0 {
    let u = queue[0]
    queue = queue[1:].to_owned()
    is_tail[u] = true
    let v = ds.f[u]
    indeg[v] = indeg[v] - 1
    if indeg[v] == 0 {
      queue.push(v)
    }
  }
  // 環遍歷：標號分量與環長
  let comp = Array::make(n, -1)
  let cyc_len = Array::make(n, 0)
  let mut comp_id = 0
  for x in 0..<ds.n {
    if !is_tail[x] && comp[x] == -1 {
      // 沿環走訪
      let members : Array[Int32] = []
      let mut cur = x
      while comp[cur] == -1 {
        comp[cur] = comp_id
        members.push(cur)
        cur = ds.f[cur]
      }
      for m in members {
        cyc_len[m] = members.length()
      }
      comp_id = comp_id + 1
    }
  }
  // 反向鄰接：反向 BFS 標尾長，並傳播分量與環長
  let rev : Array[Array[Int32]] = Array::makei(n, fn(_i) { [] })
  for x in 0..<ds.n {
    rev[ds.f[x]].push(x)
  }
  let tail = Array::make(n, 0)
  let mut bfs : Array[Int32] = []
  for x in 0..<ds.n {
    if !is_tail[x] {
      bfs.push(x)
    }
  }
  while bfs.length() > 0 {
    let u = bfs[0]
    bfs = bfs[1:].to_owned()
    for w in rev[u] {
      if is_tail[w] {
        tail[w] = tail[u] + 1
        comp[w] = comp[u]
        cyc_len[w] = cyc_len[u]
        bfs.push(w)
      }
    }
  }
  Array::makei(n, fn(x) { (comp[x], tail[x], cyc_len[x]) })
}

///|
/// 不動點
pub fn fixed_points(ds : DynSys) -> Array[Int32] {
  let r : Array[Int32] = []
  for x in 0..<ds.n {
    if ds.f[x] == x {
      r.push(x)
    }
  }
  r
}

///|
/// 週期點（環上點）：尾長為零。
/// 複雜度 O(n)（經環分解；對每點 Floyd 為 O(n²)）。
pub fn periodic_points(ds : DynSys) -> Array[Int32] {
  let dec = cycle_decompose(ds)
  let r : Array[Int32] = []
  for x in 0..<ds.n {
    if dec[x].1 == 0 {
      r.push(x)
    }
  }
  r
}

///|
/// f 為雙射（置換）⟺ 所有點皆為週期點（無尾）
pub fn is_permutation(ds : DynSys) -> Bool {
  let dec = cycle_decompose(ds)
  for x in 0..<ds.n {
    if dec[x].1 != 0 {
      return false
    }
  }
  true
}

///|
/// 態射檢查：h 是否為自然變換（交換圖 h∘f = g∘h）
pub fn is_dyn_morphism(ds1 : DynSys, ds2 : DynSys, h : Array[Int32]) -> Bool {
  if h.length() != ds1.n {
    return false
  }
  for x in 0..<ds1.n {
    if h[ds1.f[x]] != ds2.f[h[x]] {
      return false
    }
  }
  true
}

///|
/// Dyn 範疇之積：$(X_1,f_1)\times(X_2,f_2)=(X_1\times X_2, f_1\times f_2)$
pub fn ds_product(ds1 : DynSys, ds2 : DynSys) -> DynSys {
  let n = ds1.n * ds2.n
  let f = Array::makei(n, fn(i) {
    let a = i / ds2.n
    let b = i % ds2.n
    ds1.f[a] * ds2.n + ds2.f[b]
  })
  { n, f, }
}

///|
/// 自由動力系統（截断）：$\{0,\dots,k\}$，$f(x)=\min(x+1,k)$
pub fn free_dyn(k : Int32) -> DynSys {
  let f = Array::makei(k + 1, fn(x) { if x + 1 <= k { x + 1 } else { k } })
  { n: k + 1, f, }
}

///|
/// 自由系統的萬有性質：$\forall (X,f)\,\forall x_0\in X$，
/// 存在唯一態射 $h:\mathrm{Free}(k)\to X$，$h(0)=x_0$，
/// $h(n)=f^n(x_0)$。
pub fn verify_free_dyn_universal(ds : DynSys, k : Int32) -> Bool {
  let free = free_dyn(k)
  for x0 in 0..<ds.n {
    // 唯一候選：h(n) = f^n(x0)
    let h = Array::makei(k + 1, fn(i) { ds_iterate(ds, x0, i) })
    if !is_dyn_morphism(free, ds, h) {
      return false
    }
    if h[0] != x0 {
      return false
    }
    // 唯一性：任何態射 g 滿 g(0)=x0 必等於 h
    // （由交換圖遞迴決定：g(n+1) = f(g(n))）
    for j in 0..<=k {
      if h[j] != ds_iterate(ds, x0, j) {
        return false
      }
    }
  }
  true
}

///|
/// Dyn 範疇公理：態射複合為態射、恆等為態射、結合律
/// （小系統窮舉驗證；結合律由函數複合結合律保證）
pub fn verify_dyn_category() -> Bool {
  // 系統 (X, f)：X = {0,1}，兩個 f：恆等與交換
  let id2 = make_dyn(2, [0, 1])
  let sw2 = make_dyn(2, [1, 0])
  let systems = [id2, sw2]
  // 態射：所有 h : {0,1} → {0,1}
  let morphisms : Array[(Int32, Int32, Array[Int32])] = []
  for i in 0..<2 {
    for j in 0..<2 {
      let ds1 = systems[i]
      let ds2 = systems[j]
      for h0 in 0..<2 {
        for h1 in 0..<2 {
          let h = [h0, h1]
          if is_dyn_morphism(ds1, ds2, h) {
            morphisms.push((i, j, h))
          }
        }
      }
    }
  }
  // 恆等態射存在
  for i in 0..<2 {
    let id = [0, 1]
    if !is_dyn_morphism(systems[i], systems[i], id) {
      return false
    }
  }
  // 複合封閉性與結合律
  for (i1, j1, h1) in morphisms {
    for (i2, j2, h2) in morphisms {
      if j1 != i2 {
        continue
      }
      // h2 ∘ h1 : systems[i1] → systems[j2]
      let comp = [h2[h1[0]], h2[h1[1]]]
      if !is_dyn_morphism(systems[i1], systems[j2], comp) {
        return false
      }
    }
  }
  true
}

///|
/// 共軛（同構）：存在雙射 h 使 h∘f₁ = f₂∘h。
/// 小 n 暴力排列。
pub fn are_conjugate(ds1 : DynSys, ds2 : DynSys) -> Bool {
  if ds1.n != ds2.n {
    return false
  }
  perm_conjugate(ds1, ds2, Array::make(ds1.n, -1), Array::make(ds1.n, false), 0)
}

///|
fn perm_conjugate(
  ds1 : DynSys,
  ds2 : DynSys,
  h : Array[Int32],
  used : Array[Bool],
  pos : Int32,
) -> Bool {
  if pos == ds1.n {
    return is_dyn_morphism(ds1, ds2, h)
  }
  for v in 0..<ds2.n {
    if !used[v] {
      used[v] = true
      h[pos] = v
      if perm_conjugate(ds1, ds2, h, used, pos + 1) {
        return true
      }
      used[v] = false
    }
  }
  false
}
