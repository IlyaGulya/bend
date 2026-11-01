import Base

def byte(n: Nat) -> U32:
  U32.from_nat(Nat.mod(n, 256n))

def utf8_char_class_3(+n: Nat, less65536: Bool, acc: List<&2, U32>) -> List<&2, U32>:
  match less65536:
    case True{}: byte((128n + Nat.mod(n, 64n) : Nat)) <> (byte((128n + Nat.mod(Nat.div(n, 64n), 64n) : Nat)) <> (byte((224n + Nat.div(n, 4096n) : Nat)) <> acc))
    case False{}: byte((128n + Nat.mod(n, 64n) : Nat)) <> (byte((128n + Nat.mod(Nat.div(n, 64n), 64n) : Nat)) <> (byte((128n + Nat.mod(Nat.div(n, 4096n), 64n) : Nat)) <> (byte((240n + Nat.div(n, 262144n) : Nat)) <> acc)))

def utf8_char_class_wide(+n: Nat, less2048: Bool, less65536: Bool, acc: List<&2, U32>) -> List<&2, U32>:
  match less2048:
    case True{}: byte((128n + Nat.mod(n, 64n) : Nat)) <> (byte((192n + Nat.div(n, 64n) : Nat)) <> acc)
    case False{}: utf8_char_class_3(n, less65536, acc)

def utf8_char_class(+n: Nat, less128: Bool, less2048: Bool, less65536: Bool, acc: List<&2, U32>) -> List<&2, U32>:
  match less128:
    case True{}: byte(n) <> acc
    case False{}: utf8_char_class_wide(n, less2048, less65536, acc)

def utf8_char(c: Char, acc: List<&2, U32>) -> List<&2, U32>:
  +n = U32.to_nat(Char.to_u32(c))
  utf8_char_class(n, Nat.is_lt(n, 128n), Nat.is_lt(n, 2048n), Nat.is_lt(n, 65536n), acc)

def utf8_chars(chars: List<&2, Char>, acc: List<&2, U32>) -> List<&2, U32>:
  match chars:
    case Nil{}: acc
    case +c <> rest: utf8_chars(rest, utf8_char(c, acc))

def word_bytes(+value: U32) -> List<&2, U32>:
  [U32.and(U32.shrn(value, 24n), 255), U32.and(U32.shrn(value, 16n), 255), U32.and(U32.shrn(value, 8n), 255), U32.and(value, 255)]

def pad(+bytes: List<&2, U32>, +bit_length: Nat) -> List<&2, U32>:
  +rem = Nat.mod(List.length(&2, U32, bytes), 64n)
  zeros = Nat.mod(((56n + 64n : Nat) - Nat.mod((rem + 1n : Nat), 64n) : Nat), 64n)
  padded = List.append(&2, U32, bytes, List.append(&2, U32, [U32.from_nat(128n)], List.replicate(U32, zeros, U32.from_nat(0n))))
  +radix = (4294967295n + 1n : Nat)
  hi = U32.from_nat(Nat.div(bit_length, radix))
  lo = U32.from_nat(Nat.mod(bit_length, radix))
  List.append(&2, U32, padded, List.append(&2, U32, word_bytes(hi), word_bytes(lo)))

def choose(+x: U32, y: U32, z: U32) -> U32:
  U32.xor(U32.and(x, y), U32.and(U32.not(x), z))

def majority(+x: U32, +y: U32, +z: U32) -> U32:
  U32.xor(U32.xor(U32.and(x, y), U32.and(x, z)), U32.and(y, z))

def big0(+x: U32) -> U32:
  U32.xor(U32.xor(U32.or(U32.shrn(x, 2n), U32.shln(x, 30n)), U32.or(U32.shrn(x, 13n), U32.shln(x, 19n))), U32.or(U32.shrn(x, 22n), U32.shln(x, 10n)))

def big1(+x: U32) -> U32:
  U32.xor(U32.xor(U32.or(U32.shrn(x, 6n), U32.shln(x, 26n)), U32.or(U32.shrn(x, 11n), U32.shln(x, 21n))), U32.or(U32.shrn(x, 25n), U32.shln(x, 7n)))

def small0(+x: U32) -> U32:
  U32.xor(U32.xor(U32.or(U32.shrn(x, 7n), U32.shln(x, 25n)), U32.or(U32.shrn(x, 18n), U32.shln(x, 14n))), U32.shrn(x, 3n))

def small1(+x: U32) -> U32:
  U32.xor(U32.xor(U32.or(U32.shrn(x, 17n), U32.shln(x, 15n)), U32.or(U32.shrn(x, 19n), U32.shln(x, 13n))), U32.shrn(x, 10n))

def at_result(result: Maybe<&2, U32>) -> U32:
  match result:
    case Some{value}: value
    case None{}: 0

def at(xs: List<&2, U32>, n: Nat) -> U32:
  at_result(List.get(&2, U32, xs, n))

def words(bytes: List<&2, U32>, acc: List<&2, U32>) -> List<&2, U32>:
  match bytes:
    case +a <> +b <> +c <> +d <> rest:
      w = U32.or(U32.or(U32.shln(a, 24n), U32.shln(b, 16n)), U32.or(U32.shln(c, 8n), d))
      words(rest, w <> acc)
    case _: List.reverse(&2, U32, acc)

def schedule_steps(remaining: Nat, +ws: List<&2, U32>) -> List<&2, U32>:
  match remaining:
    case 0n: ws
    case 1n+rest:
      +n = List.length(&2, U32, ws)
      a = at(ws, (n - 15n : Nat))
      b = at(ws, (n - 2n : Nat))
      next = U32.add(U32.add(U32.add(small1(b), at(ws, (n - 7n : Nat))), small0(a)), at(ws, (n - 16n : Nat)))
      schedule_steps(rest, List.append(&2, U32, ws, [next]))

def schedule(+ws: List<&2, U32>) -> List<&2, U32>:
  schedule_steps((64n - List.length(&2, U32, ws) : Nat), ws)

def constants() -> List<&2, U32>:
  [
    1116352408, 1899447441, 3049323471, 3921009573, 961987163, 1508970993, 2453635748, 2870763221,
    3624381080, 310598401, 607225278, 1426881987, 1925078388, 2162078206, 2614888103, 3248222580,
    3835390401, 4022224774, 264347078, 604807628, 770255983, 1249150122, 1555081692, 1996064986,
    2554220882, 2821834349, 2952996808, 3210313671, 3336571891, 3584528711, 113926993, 338241895,
    666307205, 773529912, 1294757372, 1396182291, 1695183700, 1986661051, 2177026350, 2456956037,
    2730485921, 2820302411, 3259730800, 3345764771, 3516065817, 3600352804, 4094571909, 275423344,
    430227734, 506948616, 659060556, 883997877, 958139571, 1322822218, 1537002063, 1747873779,
    1955562222, 2024104815, 2227730452, 2361852424, 2428436474, 2756734187, 3204031479, 3329325298
  ]

def rounds_steps(remaining: Nat, +i: Nat, +ws: List<&2, U32>, +ks: List<&2, U32>, +state: List<&2, U32>) -> List<&2, U32>:
  match remaining:
    case 0n: state
    case 1n+rest:
      +a = at(state, 0n)
      +b = at(state, 1n)
      +c = at(state, 2n)
      d = at(state, 3n)
      +e = at(state, 4n)
      +f = at(state, 5n)
      +g = at(state, 6n)
      +h = at(state, 7n)
      +t1 = U32.add(U32.add(U32.add(U32.add(h, big1(e)), choose(e, f, g)), at(ks, i)), at(ws, i))
      t2 = U32.add(big0(a), majority(a, b, c))
      rounds_steps(rest, (i + 1n : Nat), ws, ks, [U32.add(t1, t2), a, b, c, U32.add(d, t1), e, f, g])

def sum_state_steps(remaining: Nat, +old: List<&2, U32>, +next: List<&2, U32>, +i: Nat, acc: List<&2, U32>) -> List<&2, U32>:
  match remaining:
    case 0n: List.reverse(&2, U32, acc)
    case 1n+rest: sum_state_steps(rest, old, next, (i + 1n : Nat), U32.add(at(old, i), at(next, i)) <> acc)

def compress_block(block: List<&2, U32>, +state: List<&2, U32>) -> List<&2, U32>:
  ws = schedule(words(block, Nil{}))
  next = rounds_steps(64n, 0n, ws, constants(), state)
  sum_state_steps(8n, state, next, 0n, Nil{})

def compress_bytes(bytes: List<&2, U32>, +state: List<&2, U32>, count: Nat, +block: List<&2, U32>, boundary: Bool) -> List<&2, U32>:
  match bytes boundary:
    case Nil{} _: state
    case +byte_value <> +rest False{}:
      +next_block = List.append(&2, U32, [byte_value], block)
      +next_count = (count + 1n : Nat)
      compress_bytes(rest, state, next_count, next_block, Nat.is_eq(next_count, 63n))
    case +byte_value <> +rest True{}:
      next_block = List.append(&2, U32, [byte_value], block)
      next_state = compress_block(List.reverse(&2, U32, next_block), state)
      compress_bytes(rest, next_state, 0n, Nil{}, False{})

def compress(bytes: List<&2, U32>, state: List<&2, U32>) -> List<&2, U32>:
  compress_bytes(bytes, state, 0n, Nil{}, False{})

def nibble_if(small: Bool, +n: Nat) -> Char:
  match small:
    case True{}: Char.from_u32(U32.from_nat((48n + n : Nat)))
    case False{}: Char.from_u32(U32.from_nat((87n + n : Nat)))

def nibble(+n: Nat) -> Char:
  nibble_if(Nat.is_lt(n, 10n), n)

def hex_word_steps(remaining: Nat, +x: U32, +i: Nat, acc: List<&2, Char>) -> List<&2, Char>:
  match remaining:
    case 0n: acc
    case 1n+rest:
      n = Nat.mod(U32.to_nat(U32.shrn(x, (4n * ((7n - i : Nat)) : Nat))), 16n)
      hex_word_steps(rest, x, (i + 1n : Nat), nibble(n) <> acc)

def hex_word(x: U32) -> List<&2, Char>:
  hex_word_steps(8n, x, 0n, Nil{})

def hex_state(state: List<&2, U32>, acc: List<&2, Char>) -> List<&2, Char>:
  match state:
    case Nil{}: List.reverse(&2, Char, acc)
    case +word <> rest: hex_state(rest, List.append(&2, Char, hex_word(word), acc))

def hash(text: String) -> String:
  +bytes = List.reverse(&2, U32, utf8_chars(String.to_list(text), Nil{}))
  bit_length = (8n * List.length(&2, U32, bytes) : Nat)
  state = {[1779033703, 3144134277, 1013904242, 2773480762, 1359893119, 2600822924, 528734635, 1541459225] : List<&2, U32>}
  final_state = compress(pad(bytes, bit_length), state)
  String.from_list(hex_state(final_state, Nil{}))
