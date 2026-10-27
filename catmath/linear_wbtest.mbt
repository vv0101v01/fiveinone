// linear.mbt 的白盒測試：MLL 證明網之 GMM 收縮正確性準則與切消除。

// 測試 1：單公理網 ⊢ A, A⊥ —— 正確（基本案例）。

///|
test "linear_single_axiom_correct" {
  let a1 = mk_axiom()
  let net = ProofNet::{ nodes: [a1], }
  assert_eq(net_size(net), 1)
  assert_eq(net_is_correct(net), true)
}

// 測試 2：單並網 ⊢ A⅋B, A⊥, B⊥ —— 正確。
// 這是舊 switching 模型誤判的案例：任何刪邊都會斷開，
// 但收縮準則正確判定之（公理鏈 a₁,a₂ 可用，⅋ 鏈收縮）。

///|
test "linear_single_par_correct" {
  let a1 = mk_axiom()
  let a2 = mk_axiom()
  let p = mk_par(0, 1)
  let net = ProofNet::{ nodes: [a1, a2, p], }
  assert_eq(par_count(net), 1)
  assert_eq(net_is_correct(net), true)
}

// 測試 3：單張量網 ⊢ A⊗B, A⊥, B⊥ —— 正確。

///|
test "linear_single_tensor_correct" {
  let a1 = mk_axiom()
  let a2 = mk_axiom()
  let t = mk_tensor(0, 1)
  let net = ProofNet::{ nodes: [a1, a2, t], }
  assert_eq(net_is_correct(net), true)
}

// 測試 4：四公理網 ⊢ (A⊗B)⅋(A⊥⊗B⊥), A, B, A⊥, B⊥ —— 正確。
// 兩側各經張量鏈 T₁, T₂ 匯入並鏈 P；收縮次序：
// T₁ → T₂ → P，全部歸入同一群。

///|
test "linear_four_axiom_par_correct" {
  let a1 = mk_axiom()
  let a2 = mk_axiom()
  let a3 = mk_axiom()
  let a4 = mk_axiom()
  let t1 = mk_tensor(0, 1)
  let t2 = mk_tensor(2, 3)
  let p = mk_par(4, 5)
  let net = ProofNet::{ nodes: [a1, a2, a3, a4, t1, t2, p], }
  assert_eq(net_size(net), 7)
  assert_eq(net_is_correct(net), true)
}

// 測試 5：無效網 ⊢ A⅋B, A⊥⊗B⊥ 的證明結構 —— 不正確。
// P 先與 a₁,a₂ 收縮成群 G（head=P，輸出 A⅋B）；
// T 的前提 a₁,a₂ 已併入 G（非獨立公理）→ T 永不可收縮。

///|
test "linear_par_tensor_invalid" {
  let a1 = mk_axiom()
  let a2 = mk_axiom()
  let p = mk_par(0, 1)
  let t = mk_tensor(0, 1)
  let net = ProofNet::{ nodes: [a1, a2, p, t], }
  assert_eq(net_is_correct(net), false)
}

// 測試 6：雙重使用網 ⊢ A⊗A⊥ 的結構 —— 不正確。
// 張量鏈的兩前提同屬公理 a₁ 的群 → 群相異檢查失敗。

///|
test "linear_double_use_invalid" {
  let a1 = mk_axiom()
  let t = mk_tensor(0, 0)
  let net = ProofNet::{ nodes: [a1, t], }
  assert_eq(net_is_correct(net), false)
}

// 測試 7：兩條獨立公理 ⊢ A, A⊥, B, B⊥ —— 不正確（無 mix 規則）。
// 兩個公理鏈各自成群，無規則鏈可合併。

///|
test "linear_two_axioms_invalid" {
  let a1 = mk_axiom()
  let a2 = mk_axiom()
  let net = ProofNet::{ nodes: [a1, a2], }
  assert_eq(net_is_correct(net), false)
}

// 測試 8：原子切網 cut(a₁, a₂)，正規形為合併後的單一公理鏈。

///|
test "linear_atomic_cut_correct" {
  let a1 = mk_axiom()
  let a2 = mk_axiom()
  let cut = mk_cut(0, 1)
  let net = ProofNet::{ nodes: [a1, a2, cut], }
  assert_eq(cut_count(net), 1)
  assert_eq(net_is_correct(net), true)
  let nf = cut_eliminate(net)
  assert_eq(net_size(nf), 1)
  assert_eq(net_is_correct(nf), true)
  assert_eq(cut_steps(net), 1)
}

// 測試 9：切交換歸約 cut(⊗(a₁,a₂), ⅋(a₃,a₄))。
// 歸約：先交換得 ⊗(cut(a₁,a₃), cut(a₂,a₄))，
// 兩原子切各合併為公理鏈，死亡張量鏈被剪除，
// 正規形 = 兩條獨立公理（對應 ⊢ A⊥, B⊥, A, B 不可證）。

///|
test "linear_cut_exchange_reduce" {
  let a1 = mk_axiom()
  let a2 = mk_axiom()
  let a3 = mk_axiom()
  let a4 = mk_axiom()
  let tt = mk_tensor(0, 1)
  let pp = mk_par(2, 3)
  let cut = mk_cut(4, 5)
  let net = ProofNet::{ nodes: [a1, a2, a3, a4, tt, pp, cut], }
  // 原始含切網：其切消除正規形為兩條獨立公理 → 不正確
  assert_eq(net_is_correct(net), false)
  let nf = cut_eliminate(net)
  assert_eq(cut_count(nf), 0)
  assert_eq(net_size(nf), 2)
  assert_eq(net_is_correct(nf), false)
  assert_eq(cut_steps(net), 3)
}

// 測試 10：有效切網 —— 原子切直接歸約為單一公理。
// cut(a₁, a₂) 其中 a₁, a₂ 為公理：正確（含切網正確性
// 定義為其切消除正規形正確）。

///|
test "linear_valid_cut_net_correct" {
  let a1 = mk_axiom()
  let a2 = mk_axiom()
  let cut = mk_cut(0, 1)
  let net = ProofNet::{ nodes: [a1, a2, cut], }
  let nf = cut_eliminate(net)
  assert_eq(net_size(nf), 1)
  assert_eq(nf.nodes[0].kind, 0)
  assert_eq(net_is_correct(nf), true)
}

// 測試 11：GMM 收縮直接檢查（無切網）——
// 星形網 ⊢ (A⅋B)⊗(C⅋D), A⊥, B⊥, C⊥, D⊥ 正確。

///|
test "linear_star_net_correct" {
  let a1 = mk_axiom()
  let a2 = mk_axiom()
  let a3 = mk_axiom()
  let a4 = mk_axiom()
  let p1 = mk_par(0, 1)
  let p2 = mk_par(2, 3)
  let t = mk_tensor(4, 5)
  let net = ProofNet::{ nodes: [a1, a2, a3, a4, p1, p2, t], }
  assert_eq(par_count(net), 2)
  assert_eq(net_is_correct(net), true)
}

// 測試 12：空網（空序列）視為正確。

///|
test "linear_empty_net_correct" {
  let net = ProofNet::{ nodes: [], }
  assert_eq(net_size(net), 0)
  assert_eq(net_is_correct(net), true)
}
