import Base
import ./backend_ir.bend as BIR

# Prefix codes, not hashes. Each constructor has a distinct tag; strings have
# an exact character length, naturals a terminator, and lists explicit cons/nil.
# Writers prepend chunks to a caller-supplied suffix. Only finish concatenates,
# so a deep descriptor never repeatedly copies its already-encoded children.
def finish(chunks: List<&2, String>) -> String:
  String.concat("K1;" <> chunks)

def string_chunks(+value: String, tail: List<&2, String>) -> List<&2, String>:
  Nat.show(String.length(value)) <> ":" <> value <> tail

def nat_chunks(value: Nat, tail: List<&2, String>) -> List<&2, String>:
  Nat.show(value) <> ";" <> tail

def bool_chunks(value: Bool, tail: List<&2, String>) -> List<&2, String>:
  match value:
    case False{}: "0" <> tail
    case True{}: "1" <> tail

def quantity_chunks(value: BIR.Quantity, tail: List<&2, String>) -> List<&2, String>:
  match value:
    case BIR.Erased{}: "e" <> tail
    case BIR.Once{}: "o" <> tail
    case BIR.Unrestricted{}: "u" <> tail

def maybe_quantity_chunks(value: Maybe<&2, BIR.Quantity>, tail: List<&2, String>) -> List<&2, String>:
  match value:
    case None{}: "z" <> tail
    case Some{quantity}: "s" <> quantity_chunks(quantity, tail)

def maybe_string_chunks(value: Maybe<&2, String>, tail: List<&2, String>) -> List<&2, String>:
  match value:
    case None{}: "z" <> tail
    case Some{text}: "s" <> string_chunks(text, tail)

def strings_chunks(values: List<&2, String>, tail: List<&2, String>) -> List<&2, String>:
  match values:
    case Nil{}: "z" <> tail
    case value <> rest: "c" <> string_chunks(value, strings_chunks(rest, tail))

def pattern_chunks(value: BIR.DescriptorPattern, tail: List<&2, String>) -> List<&2, String>:
  match value:
    case BIR.DescriptorBinder{quantity}:
      "p0;" <> quantity_chunks(quantity, tail)
    case BIR.DescriptorConstructorPattern{key, fields}:
      "p1;" <> string_chunks(key, patterns_chunks(fields, tail))

def patterns_chunks(values: List<&2, BIR.DescriptorPattern>, tail: List<&2, String>) -> List<&2, String>:
  match values:
    case Nil{}: "z" <> tail
    case value <> rest: "c" <> pattern_chunks(value, patterns_chunks(rest, tail))

def descriptor_chunks(value: BIR.Descriptor, tail: List<&2, String>) -> List<&2, String>:
  match value:
    case BIR.DescriptorNull{}:
      "d0;" <> tail
    case BIR.DescriptorRef{key, args}:
      "d1;" <> string_chunks(key, descriptors_chunks(args, tail))
    case BIR.DescriptorParameter{index}:
      "d2;" <> nat_chunks(index, tail)
    case BIR.DescriptorQuantityKind{}:
      "d3;" <> tail
    case BIR.DescriptorQuantity{quantity}:
      "d4;" <> quantity_chunks(quantity, tail)
    case BIR.DescriptorKind{quantity}:
      "d5;" <> descriptor_chunks(quantity, tail)
    case BIR.DescriptorMinimum{left, right}:
      "d6;" <> descriptor_chunks(left, descriptor_chunks(right, tail))
    case BIR.DescriptorArrow{quantity, domain, body}:
      "d7;" <> quantity_chunks(quantity, descriptor_chunks(domain, descriptor_chunks(body, tail)))
    case BIR.DescriptorLambda{quantity, body}:
      "d8;" <> maybe_quantity_chunks(quantity, descriptor_chunks(body, tail))
    case BIR.DescriptorConstructor{key, args}:
      "d9;" <> string_chunks(key, descriptors_chunks(args, tail))
    case BIR.DescriptorApplication{fn, arg}:
      "d10;" <> descriptor_chunks(fn, descriptor_chunks(arg, tail))
    case BIR.DescriptorSubstitution{index, value, body}:
      "d11;" <> nat_chunks(index, descriptor_chunks(value, descriptor_chunks(body, tail)))
    case BIR.DescriptorLet{values, body}:
      "d12;" <> descriptors_chunks(values, descriptor_chunks(body, tail))
    case BIR.DescriptorLocal{patterns, values, body}:
      "d13;" <> patterns_chunks(patterns, descriptors_chunks(values, descriptor_chunks(body, tail)))
    case BIR.DescriptorMatch{values, cases}:
      "d14;" <> descriptors_chunks(values, descriptors_chunks(cases, tail))
    case BIR.DescriptorCase{patterns, body}:
      "d15;" <> patterns_chunks(patterns, descriptor_chunks(body, tail))
    case BIR.DescriptorBind{value, body}:
      "d16;" <> descriptor_chunks(value, descriptor_chunks(body, tail))
    case BIR.DescriptorEquality{left, right, ty}:
      "d17;" <> descriptor_chunks(left, descriptor_chunks(right, descriptor_chunks(ty, tail)))
    case BIR.DescriptorReflexivity{}:
      "d18;" <> tail
    case BIR.DescriptorFailure{message}:
      "d19;" <> string_chunks(message, tail)
    case BIR.DescriptorFill{head, args}:
      "d20;" <> descriptor_chunks(head, descriptors_chunks(args, tail))
    case BIR.DescriptorPlus{head, args}:
      "d21;" <> descriptor_chunks(head, descriptors_chunks(args, tail))
    case BIR.DescriptorNamedFill{key, head, args}:
      "d22;" <> string_chunks(key, descriptor_chunks(head, descriptors_chunks(args, tail)))
    case BIR.DescriptorNamedPlus{key, head, args}:
      "d23;" <> string_chunks(key, descriptor_chunks(head, descriptors_chunks(args, tail)))

def descriptors_chunks(values: List<&2, BIR.Descriptor>, tail: List<&2, String>) -> List<&2, String>:
  match values:
    case Nil{}: "z" <> tail
    case value <> rest: "c" <> descriptor_chunks(value, descriptors_chunks(rest, tail))

def field_chunks(value: BIR.DescriptorField, tail: List<&2, String>) -> List<&2, String>:
  match value:
    case BIR.DescriptorField{key, quantity, ty}:
      "f;" <> maybe_string_chunks(key, quantity_chunks(quantity, descriptor_chunks(ty, tail)))

def fields_chunks(values: List<&2, BIR.DescriptorField>, tail: List<&2, String>) -> List<&2, String>:
  match values:
    case Nil{}: "z" <> tail
    case value <> rest: "c" <> field_chunks(value, fields_chunks(rest, tail))

def arm_chunks(value: BIR.DescriptorArm, tail: List<&2, String>) -> List<&2, String>:
  match value:
    case BIR.DescriptorArm{key, fields}:
      "a;" <> string_chunks(key, fields_chunks(fields, tail))

def arms_chunks(values: List<&2, BIR.DescriptorArm>, tail: List<&2, String>) -> List<&2, String>:
  match values:
    case Nil{}: "z" <> tail
    case value <> rest: "c" <> arm_chunks(value, arms_chunks(rest, tail))

def family_chunks(value: BIR.Family, tail: List<&2, String>) -> List<&2, String>:
  match value:
    case BIR.Family{key, name, native, quantity_prefix, arity, arms}:
      "F;" <> string_chunks(key, string_chunks(name, maybe_string_chunks(native, nat_chunks(quantity_prefix, nat_chunks(arity, arms_chunks(arms, tail))))))

def families_chunks(values: List<&2, BIR.Family>, tail: List<&2, String>) -> List<&2, String>:
  match values:
    case Nil{}: "z" <> tail
    case value <> rest: "c" <> family_chunks(value, families_chunks(rest, tail))

def function_chunks(value: BIR.TypeFunction, tail: List<&2, String>) -> List<&2, String>:
  match value:
    case BIR.TypeFunction{key, native, quantity_prefix, arity, body}:
      "T;" <> string_chunks(key, maybe_string_chunks(native, nat_chunks(quantity_prefix, nat_chunks(arity, descriptor_chunks(body, tail)))))

def functions_chunks(values: List<&2, BIR.TypeFunction>, tail: List<&2, String>) -> List<&2, String>:
  match values:
    case Nil{}: "z" <> tail
    case value <> rest: "c" <> function_chunks(value, functions_chunks(rest, tail))

def descriptor_key(descriptor: BIR.Descriptor) -> String:
  finish(descriptor_chunks(descriptor, Nil{}))

def context_key(families: List<&2, BIR.Family>, type_functions: List<&2, BIR.TypeFunction>) -> String:
  finish("N;" <> families_chunks(families, functions_chunks(type_functions, Nil{})))
