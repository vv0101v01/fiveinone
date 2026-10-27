/// 零成本抽象與編譯期計算示範。
///
/// 定理（零成本抽象，Stroustrup）：抽象機制不應課予
///   執行期成本——使用抽象者與手寫特化版本效能相同。
///
/// 機制（一）單態化（monomorphization）：
///   泛型函數 fn[T : Addable] 在編譯期為每個具體類型 T
///   生成特化副本——trait 約束在編譯期解析，
///   呼叫靜態綁定，無執行期查表（無虛函數表）。
///
/// 機制（二）#inline：小函數在編譯期展開，呼叫開銷為零。
///
/// 機制（三）編譯期常量摺疊：純函數作用於字面量的
///   表達式由編譯器在編譯期求值。
///
/// 驗證：generic_sum 與 int_sum 在所有輸入上結果相同，
///   且（見 bench_wbtest.mbt）效能相同——抽象成本為零。

///|
/// 可加性抽象（typeclass / concept 風格）
pub trait Addable {
  fn add(Self, Self) -> Self
  fn zero() -> Self
}

///|
impl Addable for Int32 with fn add(xx : Int32, yy : Int32) -> Int32 {
  xx + yy
}

///|
impl Addable for Int32 with fn zero() -> Int32 {
  0
}

///|
impl Addable for Int64 with fn add(xx : Int64, yy : Int64) -> Int64 {
  xx + yy
}

///|
impl Addable for Int64 with fn zero() -> Int64 {
  0L
}

///|
/// 泛型求和：編譯期單態化為 Int / Int64 兩個特化副本
pub fn[T : Addable] generic_sum(xs : Array[T]) -> T {
  let mut r : T = Addable::zero()
  for x in xs {
    r = Addable::add(r, x)
  }
  r
}

///|
/// 手寫特化版本（對照組）
pub fn int_sum(xs : Array[Int32]) -> Int32 {
  let mut r = 0
  for x in xs {
    r = r + x
  }
  r
}

///|
/// 手寫特化版本（Int64，對照組）
pub fn int64_sum(xs : Array[Int64]) -> Int64 {
  let mut r = 0L
  for x in xs {
    r = r + x
  }
  r
}

///|
/// #inline 小函數：編譯期展開，呼叫開銷為零
#inline
pub fn inline_double(x : Int32) -> Int32 {
  x + x
}

///|
#inline
pub fn inline_triple(x : Int32) -> Int32 {
  x + x + x
}

///|
/// 內聯鏈：inline_double ∘ inline_triple
#inline
pub fn inline_sextuple(x : Int32) -> Int32 {
  inline_double(inline_triple(x))
}

///|
/// 編譯期常量摺疊示範：純函數作用於字面量
#inline
pub fn compile_time_square(x : Int32) -> Int32 {
  x * x
}

///|
pub fn zero_cost_demo() -> Int32 {
  // 以下表達式在編譯期摺疊為常量 36
  compile_time_square(6)
}

///|
/// 單態化正確性：泛型版本與特化版本結果一致
pub fn verify_monomorphization() -> Bool {
  let xs = [1, 2, 3, 4, 5]
  let mut ok = generic_sum(xs) == int_sum(xs)
  let xs64 = [1L, 2L, 3L, 4L, 5L]
  ok = ok && generic_sum(xs64) == int64_sum(xs64)
  // 空陣列：單位元
  let empty_int : Array[Int32] = []
  let empty_int64 : Array[Int64] = []
  ok = ok && generic_sum(empty_int) == 0
  ok = ok && generic_sum(empty_int64) == 0L
  ok
}

///|
/// #inline 正確性：內聯函數與原始表達式一致
pub fn verify_inline() -> Bool {
  inline_double(21) == 42 &&
  inline_triple(14) == 42 &&
  inline_sextuple(7) == 42 &&
  zero_cost_demo() == 36
}
