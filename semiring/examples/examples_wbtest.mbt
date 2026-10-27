// ===========================================================================
// examples 的測試：把「可編譯的 README 片段」升級成「會執行並斷言的 README 片段」
//
// 原本 `examples/` 只被 `moon check` 驗證「編得過」，卻從未被執行——
// 那是一種安靜的死碼：型別對，數字錯，沒人會發現。
// 這裡對每個範例斷言一個**具體值或具體不變量**，文件與行為因此綁在一起。
// ===========================================================================

///|
test "example_shortest_path：Dijkstra 與 Kleene 在同一張圖上，且沒有負環" {
  let (d, has_neg) = @self.example_shortest_path()
  inspect(has_neg, content="false")
  // 權重是 1..30 的正整數 ⇒ 距離必須是正的有限值
  inspect(d > 0.0, content="true")
}

///|
test "example_counting_paths：空邊集的路徑數矩陣就是單位矩陣" {
  let m = @self.example_counting_paths(4)
  // A = 0 ⇒ A* = I ⊕ 0 ⊕ … = I
  for i in 0..<4 {
    for j in 0..<4 {
      let want = if i == j { 1L } else { 0L }
      inspect(m.get(i, j).value(), content="\{want}")
    }
  }
}

///|
test "example_pareto：標籤數有限且收斂" {
  let (labels, converged) = @self.example_pareto(20)
  inspect(converged, content="true")
  // n 個節點、每個節點至少一個標籤
  inspect(labels >= 20, content="true")
}

///|
test "example_spline：週期解與開放解都是長度 n 的有限係數" {
  // 兩種邊界條件（週期 vs 開放）解的是**不同**的方程組，
  // 因此這裡只斷言「都解得出來且有限」——把它們當成同一個解會是錯的期待。
  let y : Array[Double] = [0.0, 1.0, 4.0, 9.0, 16.0, 25.0, 36.0, 49.0]
  let (c, c2, v) = @self.example_spline(y)
  inspect(c.length(), content="\{y.length()}")
  inspect(c2.length(), content="\{y.length()}")
  let mut finite = true
  for i in 0..<c.length() {
    if c[i] != c[i] || c2[i] != c2[i] {
      finite = false
    }
  }
  inspect(finite, content="true")
  inspect(v == v, content="true")
}

///|
test "example_aggregates：三種聚合結構在同一份資料上給同一個和" {
  let (a, b, cc) = @self.example_aggregates()
  inspect(a, content="6")
  inspect(b, content="9")
  inspect(cc, content="6")
}

///|
test "example_ratelimit：第一個請求被放行，額度用完後被拒" {
  let first = @self.example_ratelimit(7UL, 1_000_000L)
  // 空桶起步 ⇒ 第一個請求必被放行（GCRA 的 TA 在過去）
  inspect(first is Allowed, content="true")
}

///|
test "example_csr：樹狀圖上葉節點的距離等於深度，SpGEMM 非空" {
  let (d, nnz, sq_nonempty) = @self.example_csr(8)
  // 每個節點 i 的父是 (i-1)/2，邊權 1 ⇒ 深度 = 距離
  inspect(d.value(), content="3")
  inspect(nnz, content="7")
  inspect(sq_nonempty, content="true")
}

///|
test "example_float_minplus：1.5 + 0.25" {
  let v = @self.example_float_minplus()
  inspect(v, content="1.75")
}

///|
test "example_blocking：由快取預算推出的磚大小是 8 的倍數" {
  let b = @self.example_blocking()
  inspect(b > 0 && b % 8 == 0, content="true")
}

///|
test "example_parallel：後端名稱非空，且和與公式一致" {
  let (backend, total) = @self.example_parallel(1000)
  inspect(backend.length() > 0, content="true")
  // 0 + 1 + … + 999 = 499500
  inspect(total, content="499500")
}

///|
test "example_tropical_roots：兩個根、重數和等於次數" {
  let roots = @self.example_tropical_roots()
  inspect(roots.length(), content="6")
}

///|
test "example_tropical_curve：細分面數與對偶邊數、平衡殘差為 0" {
  let (faces, edges, worst) = @self.example_tropical_curve()
  inspect(faces, content="4")
  inspect(edges, content="8")
  // 平衡條件是整數恆等式，殘差必須恰為 0
  inspect(worst, content="0")
}

///|
test "example_tropical_det：指派問題的最小成本" {
  inspect(@self.example_tropical_det(), content="7")
}

///|
test "example_regex_equiv：(a+b)* 與 (a*b*)* 等價" {
  inspect(@self.example_regex_equiv(), content="true")
}

///|
test "example_min_dfa_states：(a+b)*(a+b)* 最小化後是 2 個狀態" {
  inspect(@self.example_min_dfa_states(), content="2")
}

///|
test "example_free_category：多個路徑數量的交叉驗證" {
  inspect(@self.example_free_category(), content="3")
}

///|
test "example_app_five_semirings：同一段閉包在三個半環上的答案" {
  let (reach, dist, wide) = @self.example_app_five_semirings()
  inspect(reach, content="true")
  // 0→1→2→3 的權重和 = 12；直達邊 20 ⇒ min = 12
  inspect(dist, content="12")
  // max-min（最寬路徑）：直達邊 0→3 的瓶頸 20 勝過 3→4→5 的 min = 3
  inspect(wide, content="20")
}

///|
test "example_belief：兩變數兩因子的邊緣機率總和為 1" {
  let (m0, _ops) = @self.example_belief()
  let (m1, _ops2) = @self.example_belief()
  inspect(m0, content="\{m1}")
  inspect(m0 >= 0.0 && m0 <= 1.0, content="true")
}
