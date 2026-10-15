import Base
import ../../bend2/selfhost/checker_arena.bend as Arena
import ../../bend2/selfhost/ast.bend as Ast

def read(result: Arena.Arena & Bool) -> U32:
  match result:
    case Tuple{_, True{}}: 1
    case Tuple{_, False{}}: 0

def node(result: Arena.Arena & U32) -> U32:
  match result:
    case Tuple{arena, id}: read(Arena.node_is_closed(arena, id))

def lambda(result: Arena.Arena & U32) -> U32:
  match result:
    case Tuple{arena, id}: node(Arena.put_node(arena, Arena.TermLam{Some{Ast.QOne{}}, 0, 0n, id, Arena.empty_span()}))

def closed(index: Nat) -> U32:
  lambda(Arena.put_node(Arena.empty(), Arena.TermVar{0, index, Arena.empty_span()}))

def binder_node(arena: Arena.Arena, domain: U32, body: U32, substitute: Bool) -> U32:
  match substitute:
    case False{}: node(Arena.put_node(arena, Arena.TermAll{Ast.QOne{}, 0, 0n, domain, body, Arena.empty_span()}))
    case True{}: node(Arena.put_node(arena, Arena.TermSub{0n, domain, body, Arena.empty_span()}))

def binder_body(domain: U32, substitute: Bool, result: Arena.Arena & U32) -> U32:
  match result:
    case Tuple{arena, body}: binder_node(arena, domain, body, substitute)

def binder_domain(index: Nat, substitute: Bool, result: Arena.Arena & U32) -> U32:
  match result:
    case Tuple{arena, domain}: binder_body(domain, substitute, Arena.put_node(arena, Arena.TermVar{0, index, Arena.empty_span()}))

def binder(index: Nat, substitute: Bool) -> U32:
  binder_domain(index, substitute, Arena.put_node(Arena.empty(), Arena.TermRef{0, Arena.empty_span()}))

def main() -> U32:
  U32.add(closed(0n), U32.add(U32.mul(closed(1n), 10), U32.add(U32.mul(binder(0n, False{}), 100), U32.add(U32.mul(binder(1n, False{}), 1000), U32.add(U32.mul(binder(0n, True{}), 10000), U32.mul(binder(1n, True{}), 100000))))))

#|10101
