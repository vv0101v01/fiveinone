/// Top：有限拓撲空間。
///
/// 定理（Alexandrov 對應）：有限拓撲空間 ≅ 有限預序集。
///   專化預序：x ≤ y ⟺ x ∈ cl({y})；開集 = 上集，閉集 = 下集。
/// 定理：有限空間間的映射連續 ⟺ 單調（保預序）。
/// 定理：同胚 ⟺ 預序同構。
/// 複雜度優化：閉包/內部由預序可達性計算 O(n²)，
///   連續性檢驗由 O(|τ_X|·n) 降至 O(n²)（單調性檢查）。

///|
/// 有限拓撲空間（Alexandrov 預序表示）
pub struct FinTop {
  n : Int32
  /// le[x][y] ⟺ x ≤ y（專化預序：x ∈ cl({y})）
  le : Array[Array[Bool]]
}

///|
/// 由預序建立有限拓撲空間（自動取傳遞閉包）
pub fn make_top(n : Int32, le : Array[Array[Bool]]) -> FinTop {
  // 自反化
  let r = Array::makei(n, fn(i) {
    Array::makei(n, fn(j) { le[i][j] || i == j })
  })
  // Warshall 傳遞閉包 O(n³)
  for k in 0..<n {
    for i in 0..<n {
      for j in 0..<n {
        if r[i][k] && r[k][j] {
          r[i][j] = true
        }
      }
    }
  }
  { n, le: r, }
}

///|
/// 驗證預序公理（自反、傳遞）
pub fn check_preorder(tt : FinTop) -> Bool {
  for i in 0..<tt.n {
    if !tt.le[i][i] {
      return false
    }
  }
  for i in 0..<tt.n {
    for j in 0..<tt.n {
      for k in 0..<tt.n {
        if tt.le[i][j] && tt.le[j][k] && !tt.le[i][k] {
          return false
        }
      }
    }
  }
  true
}

///|
/// 閉包 cl(S) = {x : ∃ s∈S, x ≤ s}（下集）
pub fn closure(tt : FinTop, s : Array[Bool]) -> Array[Bool] {
  Array::makei(tt.n, fn(x) {
    let mut hit = false
    for y in 0..<tt.n {
      if s[y] && tt.le[x][y] {
        hit = true
        break
      }
    }
    hit
  })
}

///|
/// 內部 int(S) = 補集的閉包之補集（上集）
pub fn interior(tt : FinTop, s : Array[Bool]) -> Array[Bool] {
  let comp = Array::makei(tt.n, fn(x) { !s[x] })
  let cl = closure(tt, comp)
  Array::makei(tt.n, fn(x) { !cl[x] })
}

///|
/// 開集判定（上集）
pub fn is_open(tt : FinTop, u : Array[Bool]) -> Bool {
  for x in 0..<tt.n {
    if u[x] {
      for y in 0..<tt.n {
        if tt.le[x][y] && !u[y] {
          return false
        }
      }
    }
  }
  true
}

///|
/// 閉集判定（下集）
pub fn is_closed(tt : FinTop, c : Array[Bool]) -> Bool {
  for y in 0..<tt.n {
    if c[y] {
      for x in 0..<tt.n {
        if tt.le[x][y] && !c[x] {
          return false
        }
      }
    }
  }
  true
}

///|
/// 枚舉所有開集（冪集篩選，O(2ⁿ·n²)）
pub fn open_sets(tt : FinTop) -> Array[Array[Bool]] {
  let r : Array[Array[Bool]] = []
  let total = 1 << tt.n
  for mask in 0..<total {
    let u = Array::makei(tt.n, fn(x) { ((mask >> x) & 1) == 1 })
    if is_open(tt, u) {
      r.push(u)
    }
  }
  r
}

///|
/// 連續性：有限空間中 f 連續 ⟺ 單調。複雜度 O(n²)。
pub fn is_continuous(tt : FinTop, uu : FinTop, f : Array[Int32]) -> Bool {
  if f.length() != tt.n || uu.n != tt.n {
    return false
  }
  for x in 0..<tt.n {
    for y in 0..<tt.n {
      if tt.le[x][y] && !uu.le[f[x]][f[y]] {
        return false
      }
    }
  }
  true
}

///|
/// 雙射
fn is_bijection(f : Array[Int32], n : Int32) -> Bool {
  let seen = Array::make(n, false)
  for i in 0..<n {
    if f[i] < 0 || f[i] >= n || seen[f[i]] {
      return false
    }
    seen[f[i]] = true
  }
  true
}

///|
/// 同胚 ⟺ 雙射且雙向單調（預序同構）
pub fn is_homeomorphism(tt : FinTop, uu : FinTop, f : Array[Int32]) -> Bool {
  is_bijection(f, tt.n) &&
  is_continuous(tt, uu, f) &&
  is_continuous(uu, tt, inverse_map(f, tt.n))
}

///|
fn inverse_map(f : Array[Int32], n : Int32) -> Array[Int32] {
  let g = Array::make(n, 0)
  for i in 0..<n {
    g[f[i]] = i
  }
  g
}

///|
/// T0 分離公理 ⟺ 預序反對稱
pub fn is_t0(tt : FinTop) -> Bool {
  for x in 0..<tt.n {
    for y in 0..<tt.n {
      if x != y && tt.le[x][y] && tt.le[y][x] {
        return false
      }
    }
  }
  true
}

///|
/// T0 化（商掉拓撲不可區別點）：複雜度 O(n²)
pub fn t0_quotient(tt : FinTop) -> FinTop {
  let cls = Array::makei(tt.n, fn(i) { i })
  // x ∼ y ⟺ x ≤ y ≤ x
  let repr : Array[Int32] = []
  let used = Array::make(tt.n, false)
  for x in 0..<tt.n {
    if !used[x] {
      used[x] = true
      repr.push(x)
      for y in (x + 1)..<tt.n {
        if !used[y] && tt.le[x][y] && tt.le[y][x] {
          used[y] = true
          cls[y] = x
        }
      }
    }
  }
  let m = repr.length()
  let le = Array::makei(m, fn(i) {
    Array::makei(m, fn(j) { tt.le[repr[i]][repr[j]] })
  })
  { n: m, le, }
}

///|
/// 連通分支（預序的無向可達性，union-find）
pub fn connected_components(tt : FinTop) -> Array[Int32] {
  let parent = Array::makei(tt.n, fn(i) { i })
  for x in 0..<tt.n {
    for y in 0..<tt.n {
      if tt.le[x][y] || tt.le[y][x] {
        let rx = find_uf_top(parent, x)
        let ry = find_uf_top(parent, y)
        if rx != ry {
          parent[rx] = ry
        }
      }
    }
  }
  Array::makei(tt.n, fn(i) { find_uf_top(parent, i) })
}

///|
fn find_uf_top(parent : Array[Int32], x : Int32) -> Int32 {
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
/// 同胚檢驗（暴力排列，O(n!·n²)；小 n 可行）。
/// 複雜度註記：可先用度數簽名剪枝，將常數項降低。
pub fn are_homeomorphic(tt : FinTop, uu : FinTop) -> Bool {
  if tt.n != uu.n {
    return false
  }
  perm_homeo(tt, uu, Array::make(tt.n, -1), Array::make(tt.n, false), 0)
}

///|
fn perm_homeo(
  tt : FinTop,
  uu : FinTop,
  f : Array[Int32],
  used : Array[Bool],
  pos : Int32,
) -> Bool {
  if pos == tt.n {
    return is_homeomorphism(tt, uu, f)
  }
  for v in 0..<tt.n {
    if !used[v] {
      used[v] = true
      f[pos] = v
      if perm_homeo(tt, uu, f, used, pos + 1) {
        return true
      }
      used[v] = false
    }
  }
  false
}
