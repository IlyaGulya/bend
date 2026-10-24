import Base
import ../bend2/selfhost/loaded_module.bend as Loader
import ../bend2/selfhost/backend_ir.bend as BIR
import ../bend2/selfhost/c_backend_layout.bend as CLay
import ../bend2/selfhost/c_backend_physical.bend as Phys

# Phys SHOW smoke: the descriptor printed by Phys.show_build, which the host
# replaces into the official C's SHOW_DESC and executes in the real runtime.

type PhysSmoke is Data:
  PhysSmoke{desc: String, names: String}

def fld(+ty: BIR.Descriptor) -> BIR.DescriptorField:
  BIR.DescriptorField{None{}, BIR.Unrestricted{}, ty}

def arm(+key: String, +fields: List<&2, BIR.DescriptorField>) -> BIR.DescriptorArm:
  BIR.DescriptorArm{key, fields}

def fam(+key: String, +native: Maybe<&2, String>, +arity: Nat, +arms: List<&2, BIR.DescriptorArm>) -> BIR.Family:
  BIR.Family{key, key, native, 0n, arity, arms}

def ref(+key: String, +args: List<&2, BIR.Descriptor>) -> BIR.Descriptor:
  BIR.DescriptorRef{key, args}

def fam_u32() -> BIR.Family:
  fam("U32", Some{"U32"}, 0n, Nil{})

def fam_pt() -> BIR.Family:
  fam("Pt", None{}, 0n, [arm("Pt", [fld(ref("U32", Nil{})), fld(ref("U32", Nil{}))])])

def fam_fl() -> BIR.Family:
  fam("Fl", None{}, 0n, [arm("Fl", [fld(ref("U32", Nil{}))])])

def fam_seg() -> BIR.Family:
  fam("Seg", None{}, 0n, [arm("Seg", [fld(ref("Pt", Nil{})), fld(ref("Pt", Nil{})), fld(ref("Fl", Nil{}))])])

def families() -> List<&2, BIR.Family>:
  [fam_u32(), fam_pt(), fam_fl(), fam_seg()]

def constructors() -> List<&2, BIR.ConstructorLayout>:
  [BIR.ConstructorLayout{16, "Seg", None{}, Nil{}},
   BIR.ConstructorLayout{17, "Pt", None{}, Nil{}},
   BIR.ConstructorLayout{18, "Fl", None{}, Nil{}}]

def program() -> BIR.Program:
  BIR.Program{Nil{}, Nil{}, Nil{}, families(), Nil{}, BIR.Library{Nil{}}}

def chain_key(+pn: Nat) -> String:
  String.append("F", Nat.show(pn))

def next_key(+pn: Nat) -> String:
  match pn:
    case 0n: chain_key(0n)
    case 1n+p: chain_key(p)

def fam_chain(+pn: Nat) -> List<&2, BIR.Family>:
  match pn:
    case 0n: [BIR.Family{chain_key(0n), chain_key(0n), None{}, 0n, 0n, [BIR.DescriptorArm{chain_key(0n), [BIR.DescriptorField{None{}, BIR.Unrestricted{}, ref("U32", Nil{})}]}]},
               BIR.Family{"U32", "U32", Some{"U32"}, 0n, 0n, Nil{}}]
    case 1n+p: BIR.Family{chain_key(p), chain_key(p), None{}, 0n, 0n, [BIR.DescriptorArm{chain_key(p), [BIR.DescriptorField{None{}, BIR.Unrestricted{}, ref(next_key(p), Nil{})}]}]} <> fam_chain(p)

def ctor_chain(+pn: Nat) -> List<&2, BIR.ConstructorLayout>:
  match pn:
    case 0n: Nil{}
    case 1n+p: BIR.ConstructorLayout{0, chain_key(p), None{}, Nil{}} <> ctor_chain(p)

def deep_program() -> BIR.Program:
  BIR.Program{Nil{}, Nil{}, Nil{}, fam_chain(400n), Nil{}, BIR.Library{Nil{}}}

def summarize(+pout: Phys.ShowOut) -> String:
  match pout:
    case Phys.ShowOk{desc, names}: String.append(Nat.show(List.length(&2, String, String.split(desc, ','))), String.append("/", Nat.show(List.length(&2, String, String.split(names, ',')))))
    case Phys.ShowFail{message}: message

def deep_text(+pout: Phys.ShowOut) -> String:
  match pout:
    case Phys.ShowOk{desc, names}: String.append(String.append("D", desc), String.append("|N", names))
    case Phys.ShowFail{message}: String.append("D!", message)

def deep_summary() -> String:
  deep_text(Phys.show_build(CLay.context(deep_program()), ref("F399", Nil{}), ctor_chain(400n), fam_chain(400n)))

def shadow_fams() -> List<&2, BIR.Family>:
  [fam("U32", Some{"U32"}, 0n, Nil{}),
   fam("F32", None{}, 0n, [arm("F32", [fld(ref("U32", Nil{}))])]),
   fam("Nat", None{}, 0n, [arm("Nat", [fld(ref("U32", Nil{}))])]),
   fam("Array", None{}, 0n, [arm("Array", [fld(ref("U32", Nil{}))])]),
   fam("IO.OP", None{}, 0n, [arm("IO.OP", [fld(ref("U32", Nil{}))])])]

def shadow_ctors() -> List<&2, BIR.ConstructorLayout>:
  [BIR.ConstructorLayout{30, "F32", None{}, Nil{}}, BIR.ConstructorLayout{31, "Nat", None{}, Nil{}}, BIR.ConstructorLayout{32, "Array", None{}, Nil{}}, BIR.ConstructorLayout{33, "IO.OP", None{}, Nil{}}]

def shadow_program() -> BIR.Program:
  BIR.Program{Nil{}, Nil{}, Nil{}, shadow_fams(), Nil{}, BIR.Library{Nil{}}}

def shadow_one(+pkey: String, +pctx: CLay.Context) -> String:
  match Phys.show_build(pctx, ref(pkey, Nil{}), shadow_ctors(), shadow_fams()):
    case Phys.ShowOk{desc, names}: String.append(String.append(pkey, "="), String.append(desc, String.append("@", names)))
    case Phys.ShowFail{message}: String.append(String.append(pkey, "!"), message)

def shadow_summary() -> String:
  ctx = CLay.context(shadow_program())
  String.append(shadow_one("F32", ctx), String.append(";", String.append(shadow_one("Nat", ctx), String.append(";", String.append(shadow_one("Array", ctx), String.append(";", shadow_one("IO.OP", ctx)))))))

def key_pair(+pa: BIR.Descriptor, +pb: BIR.Descriptor) -> String:
  match Phys.show_descriptor_key(pa), Phys.show_descriptor_key(pb):
    case Some{ka}, Some{kb}: Bool.pick(String, String.eq(ka, kb), "SAME", "SEP")
    case _, _: "FAIL"

def deep_key_probe() -> String:
  match Phys.show_descriptor_key(ref("U32", Nil{})), Phys.show_descriptor_key(ref("F0", Nil{})):
    case Some{ka}, Some{kb}: Bool.pick(String, String.eq(ka, kb), "K-SAME", "K-DIFF")
    case _, _: "K-FAIL"

def key_checks() -> String:
  String.append(key_pair(BIR.DescriptorRef{"@T", Nil{}}, BIR.DescriptorConstructor{"T", Nil{}}),
    String.append(key_pair(BIR.DescriptorParameter{1n}, BIR.DescriptorRef{"1", Nil{}}),
      String.append(key_pair(BIR.DescriptorQuantity{BIR.Once{}}, BIR.DescriptorKind{BIR.DescriptorNull{}}),
        String.append(key_pair(BIR.DescriptorRef{"x", Nil{}}, BIR.DescriptorConstructor{"x", Nil{}}), deep_key_probe()))))

def multi_fams() -> List<&2, BIR.Family>:
  [fam("U32", Some{"U32"}, 0n, Nil{}),
   fam("Choice", None{}, 0n, [arm("ChA", [fld(ref("U32", Nil{}))]), arm("ChB", [fld(ref("U32", Nil{}))]), arm("ChC", [fld(ref("U32", Nil{}))])])]

def multi_ctors() -> List<&2, BIR.ConstructorLayout>:
  [BIR.ConstructorLayout{40, "ChA", None{}, Nil{}}, BIR.ConstructorLayout{41, "ChB", None{}, Nil{}}, BIR.ConstructorLayout{42, "ChC", None{}, Nil{}}]

def multi_program() -> BIR.Program:
  BIR.Program{Nil{}, Nil{}, Nil{}, multi_fams(), Nil{}, BIR.Library{Nil{}}}

def multi_text(+pout: Phys.ShowOut) -> String:
  match pout:
    case Phys.ShowOk{desc, names}: String.append(String.append("C", desc), String.append("|M", names))
    case Phys.ShowFail{message}: String.append("C!", message)

def multi_summary() -> String:
  multi_text(Phys.show_build(CLay.context(multi_program()), ref("Choice", Nil{}), multi_ctors(), multi_fams()))

def main(modules: List<&2, Loader.LoadedModule>) -> PhysSmoke:
  ctx = CLay.context(program())
  unwrap(Phys.show_build(ctx, ref("Seg", Nil{}), constructors(), families()), String.append(deep_summary(), String.append("|", String.append(shadow_summary(), String.append("|K:", String.append(key_checks(), String.append("|", multi_summary())))))))

def unwrap(+out: Phys.ShowOut, +pdeep: String) -> PhysSmoke:
  match out:
    case Phys.ShowOk{desc, names}: PhysSmoke{desc, String.append(names, String.append("|", pdeep))}
    case Phys.ShowFail{message}: PhysSmoke{message, pdeep}
