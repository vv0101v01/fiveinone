// 規範形式與衍生定理之測試（白箱）。

///|
///\
/// 分類完整性
test "taxonomy covers every module" {
  assert_true(verify_taxonomy_complete())
  assert_true(canonical_index().length() >= 20)
  assert_true(derived_index().length() >= 15)
}

///|
///\
/// I. Smith 範形
test "snf basic" {
  let a = IntMat::{ rows: 2, cols: 2, data: [[2, 0], [0, 4]], }
  assert_true(array_eq_int(snf_invariant_factors(a), [2, 4]))
  let b = IntMat::{ rows: 2, cols: 2, data: [[6, 0], [0, 10]], }
  assert_true(array_eq_int(snf_invariant_factors(b), [2, 30]))
  let c = IntMat::{ rows: 2, cols: 2, data: [[2, 4], [6, 8]], }
  assert_true(array_eq_int(snf_invariant_factors(c), [2, 4]))
  assert_eq(snf_rank(a), 2)
  assert_eq(snf_rank(IntMat::{ rows: 2, cols: 2, data: [[0, 0], [0, 0]], }), 0)
}

///|
test "snf invariance under row/col swap" {
  assert_true(verify_snf_invariance())
}

///|
///\
/// I. 有限交換群結構定理
test "abelian structure theorem round trip" {
  assert_true(verify_structure_theorem_abelian())
  assert_true(verify_abelian_distinguishing())
  assert_true(array_eq_int(abelian_invariant_factors(cyclic_group(8)), [8]))
  let g222 = direct_product_abelian(
    cyclic_group(2),
    direct_product_abelian(cyclic_group(2), cyclic_group(2)),
  )
  assert_true(array_eq_int(abelian_invariant_factors(g222), [2, 2, 2]))
}

///|
///\
/// I. βη-長範式
test "beta-eta long normal form" {
  assert_true(verify_beta_eta_canonical())
}

///|
///\
/// I. 自由群字問題
test "free group word problem" {
  assert_true(verify_free_word_problem())
}

///|
///\
/// I. 證明網歸約核
test "proof net reduct" {
  assert_true(verify_net_reduct())
}

///|
///\
/// II. F_p 上 RREF
test "rref over f_p" {
  let m = [[1, 2], [2, 4]]
  let rr = rref_f_p(m, 5)
  assert_eq(rr[0][0], 1)
  assert_eq(rr[0][1], 2)
  assert_eq(rr[1][0], 0)
  assert_eq(rr[1][1], 0)
  assert_eq(rank_f_p(m, 5), 1)
  assert_eq(rank_f_p([[1, 0], [0, 1]], 5), 2)
}

///|
test "rank nullity cross check" {
  assert_true(verify_rank_nullity_cross())
}

///|
///\
/// II. 整係數同調（SNF 法）
test "integral homology" {
  assert_true(verify_integral_homology())
}

///|
///\
/// III. 範疇骨架與等價
test "skeleton and thin equivalence" {
  assert_true(verify_skeleton_equivalence())
}

///|
///\
/// III. 群胚骨架與基數
test "groupoid skeleton and cardinality" {
  assert_true(verify_groupoid_cardinality())
  let gg = cyclic_group(3)
  let skel = groupoid_skeleton(group_as_category(gg))
  assert_eq(skel.length(), 1)
  assert_eq(skel[0].order, 3)
}

///|
///\
/// III. 極小複形
test "minimal complex" {
  assert_true(verify_minimal_model())
}

///|
///\
/// III. 元素範疇與平坦性
test "elements category cofiltered" {
  assert_true(verify_elements_cofiltered())
}

///|
///\
/// III. 極小 A∞-模型
test "minimal a-infinity model" {
  assert_true(verify_minimal_a_infinity())
}

///|
///\
/// IV. 函數圖規範形
test "dynsys canonical form" {
  assert_true(verify_dynsys_canonical())
  let a = make_dyn(5, [1, 2, 0, 4, 3])
  let b = make_dyn(5, [2, 0, 1, 4, 3])
  assert_eq(are_conjugate(a, b), are_conjugate_canonical(a, b))
  assert_true(are_conjugate_canonical(a, b))
}

///|
///\
/// IV. 有限空間 core
test "finite space core" {
  assert_true(verify_core_theorem())
}

///|
///\
/// IV. 有限空間同胚判定
test "finite space homeomorphism" {
  assert_true(verify_finitop_homeomorphism())
}

///|
///\
/// IV. Read 樹規範化
test "read tree canonization" {
  assert_true(verify_tree_canonization())
}

///|
///\
/// V. 子群共軛類
test "subgroup conjugacy classes" {
  assert_true(verify_conjugacy_classes())
  let classes = subgroup_conjugacy_classes(cyclic_group(4))
  assert_eq(classes.length(), all_subgroups(cyclic_group(4)).length())
}

///|
///\
/// V. 特徵標分解
test "character decomposition" {
  assert_true(verify_character_decomposition())
  let chars = cyclic_characters(3, 7)
  assert_eq(chars.length(), 3)
  assert_eq(chars[0].length(), 3)
  assert_eq(chars[0][0], 1)
  assert_eq(chars[0][1], 1)
  assert_eq(chars[1][1], 2)
  assert_eq(chars[1][2], 4)
}

///|
///\
/// V. 複雜度 Θ-範形
test "complexity theta form" {
  assert_true(verify_complexity_theta())
}

///|
///\
/// 衍生定理總驗證
test "all derived theorems" {
  assert_true(verify_all_derived())
}
