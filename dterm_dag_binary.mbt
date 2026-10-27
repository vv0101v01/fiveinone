///|
// Persistent binary form of the in-process `DTerm` intern DAG.
//
// Format (all integers little-endian, one byte 0--255 per
// `Array[Int32]` element):
//
//   bytes  0..8   magic `CHDAGBIN`
//          8..10  format version (u16; version 1)
//         10..12  reserved, must be 0
//         12..16  payload length (i32)
//         16..20  DJB2-xor checksum of the payload
//         20..    payload: node count; for each node its local
//                 shell in the bare (back-reference-free) term
//                 codec, then the child count and child node
//                 ids; finally the root count and root ids.
//
// The payload is a serialization of `DTermDagSnapshot` itself:
// sharing is represented by the same child-id edges used by
// `DTermInternTable`, not by a second byte-level sharing scheme.
// Importing decoded bytes into an intern table therefore reuses
// the destination table's existing nodes whenever the shell and
// destination child ids already occur there.

///|
pub struct DTermDagBinaryLoad {
  status : ModuleBinaryStatus
  snapshot : DTermDagSnapshot?
} derive(Debug, Eq)

///|
pub extend DTermDagBinaryLoad with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend DTermDagBinaryLoad with Eq::{not_equal, equal}

///|
/// The `CHDAGBIN` layout version written by this build.
pub fn dterm_dag_binary_format_version() -> Int32 {
  1
}

///|
/// All `CHDAGBIN` layout versions this loader can read.
pub fn dterm_dag_binary_supported_versions() -> Array[Int32] {
  [1]
}

///|
pub fn dterm_dag_binary_version_policy() -> BinaryVersionPolicy {
  BinaryVersionPolicy::{
    current: dterm_dag_binary_format_version(),
    supported: dterm_dag_binary_supported_versions(),
    oldest_writable: 1,
  }
}

///|
fn dterm_dag_binary_magic() -> Array[Int32] {
  [67, 72, 68, 65, 71, 66, 73, 78]
}

///|
/// The layout version declared by a blob's header, or -1 when the
/// header is too short or its magic disagrees.
pub fn dterm_dag_binary_version_of(bytes : Array[Int32]) -> Int32 {
  if bytes.length() < 10 {
    return -1
  }
  let magic = dterm_dag_binary_magic()
  for i in 0..<8 {
    if bytes[i] != magic[i] {
      return -1
    }
  }
  module_binary_u16_at(bytes, 8)
}

///|
fn bw_dterm_dag_payload(
  w : ModuleBinWriter,
  snapshot : DTermDagSnapshot,
) -> Unit {
  bw_i32(w, snapshot.nodes.length())
  for i in 0..<snapshot.nodes.length() {
    let node = snapshot.nodes[i]
    bw_term(w, node.shell)
    bw_i32(w, node.children.length())
    for j in 0..<node.children.length() {
      bw_i32(w, node.children[j])
    }
  }
  bw_i32(w, snapshot.roots.length())
  for i in 0..<snapshot.roots.length() {
    bw_i32(w, snapshot.roots[i])
  }
}

///|
/// Serialize a DAG snapshot, or `None` when the snapshot is
/// structurally invalid (`dterm_dag_snapshot_validate`).
pub fn dterm_dag_snapshot_to_binary(
  snapshot : DTermDagSnapshot,
) -> Array[Int32]? {
  if !dterm_dag_snapshot_validate(snapshot) {
    return None
  }
  let payload_writer = module_bin_writer_new_bare()
  bw_dterm_dag_payload(payload_writer, snapshot)
  let payload = payload_writer.bytes
  let writer = module_bin_writer_new()
  let magic = dterm_dag_binary_magic()
  for i in 0..<magic.length() {
    bw_u8(writer, magic[i])
  }
  let version = dterm_dag_binary_format_version()
  bw_u8(writer, version)
  bw_u8(writer, version >> 8)
  bw_u8(writer, 0)
  bw_u8(writer, 0)
  bw_i32(writer, payload.length())
  bw_i32(writer, module_binary_checksum(payload))
  for i in 0..<payload.length() {
    bw_u8(writer, payload[i])
  }
  Some(writer.bytes)
}

///|
fn dterm_dag_binary_failure(status : ModuleBinaryStatus) -> DTermDagBinaryLoad {
  { status, snapshot: None, }
}

///|
fn br_dterm_dag_payload(r : ModuleBinReader) -> DTermDagSnapshot? {
  let nodes : Array[DTermDagNode] = []
  let node_count = br_count(r)
  if !br_require_ok(r) {
    return None
  }
  for _ in 0..<node_count {
    let shell = match br_term(r, 0) {
      Some(value) => value
      None => return None
    }
    let child_count = br_count(r)
    if !br_require_ok(r) {
      return None
    }
    let children : Array[Int32] = []
    for _ in 0..<child_count {
      children.push(br_i32(r))
      if !br_require_ok(r) {
        return None
      }
    }
    nodes.push(DTermDagNode::{ shell, children, })
  }
  let roots : Array[Int32] = []
  let root_count = br_count(r)
  if !br_require_ok(r) {
    return None
  }
  for _ in 0..<root_count {
    roots.push(br_i32(r))
    if !br_require_ok(r) {
      return None
    }
  }
  Some({ nodes, roots, })
}

///|
/// Parse `CHDAGBIN` bytes, reporting a precise format status.
/// A payload that parses but is not a valid topologically
/// ordered snapshot is `ModuleBinaryMalformed`.
pub fn dterm_dag_snapshot_load_binary_report(
  bytes : Array[Int32],
) -> DTermDagBinaryLoad {
  for i in 0..<bytes.length() {
    if bytes[i] < 0 || bytes[i] > 255 {
      return dterm_dag_binary_failure(ModuleBinaryMalformed)
    }
  }
  if bytes.length() < 20 {
    return dterm_dag_binary_failure(ModuleBinaryTruncated)
  }
  let magic = dterm_dag_binary_magic()
  for i in 0..<magic.length() {
    if bytes[i] != magic[i] {
      return dterm_dag_binary_failure(ModuleBinaryBadMagic)
    }
  }
  let layout_version = module_binary_u16_at(bytes, 8)
  if !contains_int(dterm_dag_binary_supported_versions(), layout_version) ||
    module_binary_u16_at(bytes, 10) != 0 {
    return dterm_dag_binary_failure(ModuleBinaryUnsupportedVersion)
  }
  let payload_length = module_binary_i32_at(bytes, 12)
  if payload_length < 0 {
    return dterm_dag_binary_failure(ModuleBinaryMalformed)
  }
  if bytes.length() < 20 + payload_length {
    return dterm_dag_binary_failure(ModuleBinaryTruncated)
  }
  if bytes.length() > 20 + payload_length {
    return dterm_dag_binary_failure(ModuleBinaryTrailingBytes)
  }
  let payload : Array[Int32] = []
  for i in 20..<bytes.length() {
    payload.push(bytes[i])
  }
  if module_binary_checksum(payload) != module_binary_i32_at(bytes, 16) {
    return dterm_dag_binary_failure(ModuleBinaryChecksumMismatch)
  }
  let reader = module_bin_reader_new_bare(payload)
  let snapshot = match br_dterm_dag_payload(reader) {
    Some(value) => value
    None => return dterm_dag_binary_failure(reader.status)
  }
  if reader.pos != payload.length() {
    return dterm_dag_binary_failure(ModuleBinaryTrailingBytes)
  }
  if !dterm_dag_snapshot_validate(snapshot) {
    return dterm_dag_binary_failure(ModuleBinaryMalformed)
  }
  { status: ModuleBinaryOk, snapshot: Some(snapshot), }
}

///|
pub fn dterm_dag_snapshot_from_binary(
  bytes : Array[Int32],
) -> DTermDagSnapshot? {
  dterm_dag_snapshot_load_binary_report(bytes).snapshot
}

///|
/// Decode `CHDAGBIN` bytes and import the DAG into `table`,
/// reusing any nodes the table already contains.  This is the
/// point where the byte backend and the in-process interner meet:
/// the imported roots are nodes of `table` itself.
pub fn dterm_dag_import_binary(
  table : DTermInternTable,
  bytes : Array[Int32],
) -> DTermDagImportReport? {
  match dterm_dag_snapshot_from_binary(bytes) {
    Some(snapshot) => dterm_dag_import(table, snapshot)
    None => None
  }
}

///|
pub fn dterm_dag_binary_to_hex(bytes : Array[Int32]) -> String {
  compiled_module_binary_to_hex(bytes)
}

///|
pub fn dterm_dag_binary_from_hex(text : String) -> Array[Int32]? {
  compiled_module_binary_from_hex(text)
}
