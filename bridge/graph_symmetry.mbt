///|
/// Forget direction and weights, retaining the simple undirected support.
pub fn semiring_graph_support(g : @sgraph.Graph) -> @sym.Graph {
  let edges : Array[(Int32, Int32)] = []
  for u in 0..<g.n {
    for e in g.offsets[u]..<g.offsets[u + 1] {
      let v = g.to[e]
      if u != v {
        edges.push((u, v))
      }
    }
  }
  @sym.Graph::from_edges(g.n, edges)
}

///|
/// Dense reconstruction of the two CSR weight channels.  Repeated edges
/// follow `Graph::to_trop_mat`: the last triplet wins.
fn semiring_graph_dense(
  g : @sgraph.Graph,
) -> (Array[Bool], Array[Int32], Array[Int32]) {
  let n = g.n
  let present = Array::make(n * n, false)
  let first = Array::make(n * n, 0)
  let second = Array::make(n * n, 0)
  for u in 0..<n {
    for e in g.offsets[u]..<g.offsets[u + 1] {
      let k = u * n + g.to[e]
      present[k] = true
      first[k] = g.w[e]
      second[k] = g.w2[e]
    }
  }
  (present, first, second)
}

///|
fn compare_int_arrays(a : Array[Int32], b : Array[Int32]) -> Int32 {
  let limit = a.length().min(b.length())
  for i in 0..<limit {
    let cmp = a[i].compare(b[i])
    if cmp != 0 {
      return cmp
    }
  }
  a.length().compare(b.length())
}

///|
/// Exact, CSR-order-independent one-hop colors. Each signature stores the
/// sorted outgoing and incoming (w, w2) multisets, with explicit lengths;
/// no modular hash can merge distinct signatures. These are pruning colors,
/// not a complete encoding, and exact preservation remains the final check.
pub fn semiring_graph_vertex_colors(g : @sgraph.Graph) -> Array[Int32] {
  let (present, first, second) = semiring_graph_dense(g)
  let n = g.n
  let signatures : Array[Array[Int32]] = []
  for v in 0..<n {
    let outgoing : Array[(Int32, Int32)] = []
    let incoming : Array[(Int32, Int32)] = []
    for u in 0..<n {
      let out_index = v * n + u
      if present[out_index] {
        outgoing.push((first[out_index], second[out_index]))
      }
      let in_index = u * n + v
      if present[in_index] {
        incoming.push((first[in_index], second[in_index]))
      }
    }
    outgoing.sort_by(fn(a : (Int32, Int32), b : (Int32, Int32)) -> Int32 {
      let first_cmp = a.0.compare(b.0)
      if first_cmp != 0 {
        first_cmp
      } else {
        a.1.compare(b.1)
      }
    })
    incoming.sort_by(fn(a : (Int32, Int32), b : (Int32, Int32)) -> Int32 {
      let first_cmp = a.0.compare(b.0)
      if first_cmp != 0 {
        first_cmp
      } else {
        a.1.compare(b.1)
      }
    })
    let signature : Array[Int32] = [outgoing.length()]
    for pair in outgoing {
      signature.push(pair.0)
      signature.push(pair.1)
    }
    signature.push(incoming.length())
    for pair in incoming {
      signature.push(pair.0)
      signature.push(pair.1)
    }
    signatures.push(signature)
  }
  let order : Array[Int32] = []
  for i in 0..<n {
    order.push(i)
  }
  order.sort_by(fn(a : Int32, b : Int32) -> Int32 {
    compare_int_arrays(signatures[a], signatures[b])
  })
  let colors = Array::make(n, 0)
  let mut color = -1
  let mut previous = -1
  for vertex in order {
    if previous < 0 ||
      compare_int_arrays(signatures[previous], signatures[vertex]) != 0 {
      color = color + 1
    }
    colors[vertex] = color
    previous = vertex
  }
  colors
}

///|
/// Exact preservation of edge presence and both weight channels.
pub fn perm_preserves_semiring_graph(g : @sgraph.Graph, p : @sym.Perm) -> Bool {
  guard p.size() == g.n else { return false }
  let (present, first, second) = semiring_graph_dense(g)
  let n = g.n
  for i in 0..<n {
    for j in 0..<n {
      let a = i * n + j
      let b = p.apply(i) * n + p.apply(j)
      if present[a] != present[b] ||
        (present[a] && (first[a] != first[b] || second[a] != second[b])) {
        return false
      }
    }
  }
  true
}

///|
fn semiring_graph_candidate_group(g : @sgraph.Graph) -> @sym.PermGroup {
  @sym.automorphism_group_colored(
    semiring_graph_support(g),
    semiring_graph_vertex_colors(g),
  )
}

///|
fn semiring_graph_filter_symmetries(
  g : @sgraph.Graph,
  group : @sym.PermGroup,
  cap : Int32,
) -> Array[@sym.Perm] {
  let out : Array[@sym.Perm] = []
  for p in group.elements(cap) {
    if perm_preserves_semiring_graph(g, p) {
      out.push(p)
    }
  }
  out
}

///|
/// Enumerate weighted directed symmetries. symlib's colored search proposes
/// support automorphisms preserving the exact one-hop signature colors;
/// exact two-channel weights are then filtered entry by entry. Enumeration
/// is explicitly capped by `cap` candidate group elements.
pub fn semiring_graph_symmetries(
  g : @sgraph.Graph,
  cap : Int32,
) -> Array[@sym.Perm] {
  semiring_graph_filter_symmetries(g, semiring_graph_candidate_group(g), cap)
}

///|
/// Candidate colored-support group order. The exact weighted symmetry
/// group is a subgroup of this group.
pub fn semiring_graph_candidate_order(g : @sgraph.Graph) -> Int64 {
  semiring_graph_candidate_group(g).order()
}

///|
/// Complete canonical encoding for the dense directed two-channel graph
/// semantics used by `semiring_graph_dense`. Each directed edge is replaced
/// by a three-node gadget with separately colored source and target ports;
/// the central node color records the exact weight pair. This reduces the
/// weighted directed graph to a vertex-colored simple undirected graph,
/// whose canonical key is complete. The sorted exact weight palette is
/// prefixed so distinct numeric weights cannot collapse to the same color
/// ranks. Repeated CSR entries retain the documented last-entry-wins rule.
fn semiring_graph_canonical_encoding(g : @sgraph.Graph) -> Array[Int32] {
  let (present, first, second) = semiring_graph_dense(g)
  let n = g.n
  let palette : Array[(Int32, Int32)] = []
  let mut edge_count = 0
  for index in 0..<(n * n) {
    if present[index] {
      edge_count = edge_count + 1
      let w = first[index]
      let w2 = second[index]
      let mut found = false
      for pair in palette {
        if pair.0 == w && pair.1 == w2 {
          found = true
        }
      }
      if !found {
        palette.push((w, w2))
      }
    }
  }
  palette.sort_by(fn(a : (Int32, Int32), b : (Int32, Int32)) -> Int32 {
    let first_cmp = a.0.compare(b.0)
    if first_cmp != 0 {
      first_cmp
    } else {
      a.1.compare(b.1)
    }
  })

  let node_count = n + 3 * edge_count
  let colors = Array::make(node_count, 0)
  let edges : Array[(Int32, Int32)] = []
  let mut edge_index = 0
  for u in 0..<n {
    for v in 0..<n {
      let matrix_index = u * n + v
      if present[matrix_index] {
        let center = n + 3 * edge_index
        let source_port = center + 1
        let target_port = center + 2
        colors[source_port] = 1
        colors[target_port] = 2
        let mut rank = 0
        for pair in palette {
          if pair.0 == first[matrix_index] && pair.1 == second[matrix_index] {
            break
          }
          rank = rank + 1
        }
        colors[center] = 3 + rank
        edges.push((center, source_port))
        edges.push((source_port, u))
        edges.push((center, target_port))
        edges.push((target_port, v))
        edge_index = edge_index + 1
      }
    }
  }
  let incidence = @sym.Graph::from_edges(node_count, edges)
  let (canonical_colors, graph_encoding) = @sym.colored_canonical_key(
    incidence, colors,
  )
  let out : Array[Int32] = [1, n, edge_count, palette.length()]
  for pair in palette {
    out.push(pair.0)
    out.push(pair.1)
  }
  out.push(canonical_colors.length())
  for color in canonical_colors {
    out.push(color)
  }
  out.push(graph_encoding.length())
  for bit in graph_encoding {
    out.push(bit)
  }
  out
}

///|
/// Group-average projector of all weighted symmetries.  It refuses an
/// incomplete enumeration instead of silently averaging a partial set.
pub fn semiring_graph_symmetry_projector(
  g : @sgraph.Graph,
  cap : Int32,
) -> @cub.CMat {
  let group = semiring_graph_candidate_group(g)
  guard group.order() <= cap.to_int64() else {
    abort("semiring_graph_symmetry_projector: enumeration cap exceeded")
  }
  average_permutation_matrices(semiring_graph_filter_symmetries(g, group, cap))
}

///|
/// Complex matrix support as a symlib graph (nonzero test uses cubical's
/// existing floating tolerance through comparison with `cx_zero`).
pub fn matrix_support_graph(m : @cub.CMat) -> @sym.Graph {
  let edges : Array[(Int32, Int32)] = []
  for i in 0..<m.n {
    for j in 0..<m.n {
      if i != j && !@cub.cx_approx_eq(@cub.mat_get(m, i, j), @cub.cx_zero()) {
        edges.push((i, j))
      }
    }
  }
  @sym.Graph::from_edges(m.n, edges)
}

///|
fn matrix_support_colors(m : @cub.CMat) -> Array[Int32] {
  let out : Array[Int32] = []
  for i in 0..<m.n {
    let mut row = 0
    let mut col = 0
    for j in 0..<m.n {
      if !@cub.cx_approx_eq(@cub.mat_get(m, i, j), @cub.cx_zero()) {
        row = row + 1
      }
      if !@cub.cx_approx_eq(@cub.mat_get(m, j, i), @cub.cx_zero()) {
        col = col + 1
      }
    }
    out.push(row * 4099 + col)
  }
  out
}

///|
/// Entrywise approximate preservation of a floating complex matrix.
pub fn perm_preserves_matrix(m : @cub.CMat, p : @sym.Perm) -> Bool {
  guard p.size() == m.n else { return false }
  for i in 0..<m.n {
    for j in 0..<m.n {
      if !@cub.cx_approx_eq(
          @cub.mat_get(m, p.apply(i), p.apply(j)),
          @cub.mat_get(m, i, j),
        ) {
        return false
      }
    }
  }
  true
}

///|
/// Enumerate permutation symmetries of a complex matrix, capped.
pub fn matrix_permutation_symmetries(
  m : @cub.CMat,
  cap : Int32,
) -> Array[@sym.Perm] {
  let group = @sym.automorphism_group_colored(
    matrix_support_graph(m),
    matrix_support_colors(m),
  )
  let out : Array[@sym.Perm] = []
  for p in group.elements(cap) {
    if perm_preserves_matrix(m, p) {
      out.push(p)
    }
  }
  out
}

///|
/// One-stop report for a weighted directed graph. It deliberately keeps
/// the answers separate: symlib support-graph candidate data, semiring
/// APSP data, and cubical matrix data. `canonical_colors` remains the
/// support-search color sequence; `canonical_encoding` is a complete key
/// for directed edge presence and both exact weight channels.
pub(all) struct WeightedGraphReport {
  n : Int32
  directed_edges : Int32
  canonical_colors : Array[Int32]
  canonical_encoding : Array[Int32]
  candidate_group_order : Int64
  weighted_symmetry_count : Int32
  symmetry_projector : @cub.CMat
  distance_matrix : @smat.Mat[@semialg.Trop]
  reachable_pairs : Int32
  finite_distance_sum : Int64
  support_characteristic_poly : @exactalg.QPoly
}

///|
pub fn weighted_graph_report(
  g : @sgraph.Graph,
  cap : Int32,
) -> WeightedGraphReport {
  let support = semiring_graph_support(g)
  let colors = semiring_graph_vertex_colors(g)
  let (canonical_colors, _) = @sym.colored_canonical_key(support, colors)
  let canonical_encoding = semiring_graph_canonical_encoding(g)
  let candidate_group = semiring_graph_candidate_group(g)
  let candidate_order = candidate_group.order()
  guard candidate_order <= cap.to_int64() else {
    abort("weighted_graph_report: enumeration cap exceeded")
  }
  let symmetries = semiring_graph_filter_symmetries(g, candidate_group, cap)
  let projector = average_permutation_matrices(symmetries)
  let distances = @sgraph.apsp_dijkstra(g)
  let mut reachable = 0
  let mut distance_sum = 0L
  for i in 0..<g.n {
    for j in 0..<g.n {
      let d = distances.get(i, j)
      if !d.is_inf() {
        reachable = reachable + 1
        distance_sum = distance_sum + d.value().to_int64()
      }
    }
  }
  let rows : Array[Array[Int32]] = []
  for i in 0..<g.n {
    let row : Array[Int32] = []
    for j in 0..<g.n {
      row.push(if support.has_edge(i, j) { 1 } else { 0 })
    }
    rows.push(row)
  }
  {
    n: g.n,
    directed_edges: g.edges(),
    canonical_colors,
    canonical_encoding,
    candidate_group_order: candidate_order,
    weighted_symmetry_count: symmetries.length(),
    symmetry_projector: projector,
    distance_matrix: distances,
    reachable_pairs: reachable,
    finite_distance_sum: distance_sum,
    support_characteristic_poly: @exactalg.qmat_charpoly(
      @exactalg.qmat_from_int_rows(rows),
    ),
  }
}

///|
/// A 2-cell square as an incidence graph.  Vertices 0..3 are corners,
/// 4..7 are edge cells and 8 is the square; colors are cell dimensions.
pub fn square_cell_incidence() -> (@sym.Graph, Array[Int32]) {
  let edges = [
    (4, 0),
    (4, 1),
    (5, 1),
    (5, 2),
    (6, 2),
    (6, 3),
    (7, 3),
    (7, 0),
    (8, 4),
    (8, 5),
    (8, 6),
    (8, 7),
  ]
  (@sym.Graph::from_edges(9, edges), [0, 0, 0, 0, 1, 1, 1, 1, 2])
}

///|
/// The square's dimension-colored incidence symmetries are exactly D4:
/// the 2-cell is fixed, corners form one orbit and edge cells another.
pub fn check_square_cell_symmetry() -> Bool {
  let (g, colors) = square_cell_incidence()
  let group = @sym.automorphism_group_colored(g, colors)
  group.order() == 8L &&
  group.orbit(8).length() == 1 &&
  group.orbit(0).length() == 4 &&
  group.orbit(4).length() == 4
}

///|
/// Flagship checks: a directed weighted C4 has four rotations (its
/// reflections reverse the directed cycle), their average is a trace-1
/// projector, and a two-identical-block complex matrix has 8 symmetries.
pub fn check_graph_symmetry_bridges() -> Bool {
  let g = @sgraph.Graph::build(4, [0, 1, 2, 3], [1, 2, 3, 0], [1, 1, 1, 1])
  let report = weighted_graph_report(g, 32)
  if report.weighted_symmetry_count != 4 ||
    !@cub.is_projector(report.symmetry_projector) ||
    (@cub.mat_trace_re(report.symmetry_projector) - 1.0).abs() >= 0.000001 ||
    report.reachable_pairs != 16 ||
    report.finite_distance_sum != 24L {
    return false
  }
  // C4 adjacency characteristic polynomial is x^4 - 4x^2.
  let cp = report.support_characteristic_poly
  if !@exactalg.rat_eq(@exactalg.qpoly_coeff(cp, 4), @exactalg.rat_int(1)) ||
    !@exactalg.rat_eq(@exactalg.qpoly_coeff(cp, 2), @exactalg.rat_int(-4)) ||
    !@exactalg.rat_eq(@exactalg.qpoly_coeff(cp, 0), @exactalg.rat_zero()) {
    return false
  }
  let z = @cub.cx_zero()
  let one = @cub.cx_real(1.0)
  let half = @cub.cx_real(0.5)
  let blocks = @cub.mat_from_rows([
    [one, half, z, z],
    [half, one, z, z],
    [z, z, one, half],
    [z, z, half, one],
  ])
  matrix_permutation_symmetries(blocks, 32).length() == 8 &&
  check_square_cell_symmetry()
}
