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
    case 0n: "U32"
    case 1n+p: chain_key(p)

def fam_chain(+pn: Nat) -> List<&2, BIR.Family>:
  match pn:
    case 0n: [BIR.Family{"U32", "U32", Some{"U32"}, 0n, 0n, Nil{}}]
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

def deep_summary() -> String:
  summarize(Phys.show_build(CLay.context(deep_program()), ref("F399", Nil{}), ctor_chain(400n), fam_chain(400n)))

def shadow_fams() -> List<&2, BIR.Family>:
  [fam("U32", Some{"U32"}, 0n, Nil{}),
   fam("F32", None{}, 0n, [arm("F32", [fld(ref("U32", Nil{}))])]),
   fam("Nat", None{}, 0n, [arm("Nat", [fld(ref("U32", Nil{}))])]),
   fam("Array", None{}, 0n, [arm("Array", [fld(ref("U32", Nil{}))])])]

def shadow_ctors() -> List<&2, BIR.ConstructorLayout>:
  [BIR.ConstructorLayout{30, "F32", None{}, Nil{}}, BIR.ConstructorLayout{31, "Nat", None{}, Nil{}}, BIR.ConstructorLayout{32, "Array", None{}, Nil{}}]

def shadow_program() -> BIR.Program:
  BIR.Program{Nil{}, Nil{}, Nil{}, shadow_fams(), Nil{}, BIR.Library{Nil{}}}

def shadow_one(+pkey: String, +pctx: CLay.Context) -> String:
  match Phys.show_build(pctx, ref(pkey, Nil{}), shadow_ctors(), shadow_fams()):
    case Phys.ShowOk{desc, names}: String.append(String.append(pkey, "="), String.append(desc, String.append("@", names)))
    case Phys.ShowFail{message}: String.append(String.append(pkey, "!"), message)

def shadow_summary() -> String:
  ctx = CLay.context(shadow_program())
  String.append(shadow_one("F32", ctx), String.append(";", String.append(shadow_one("Nat", ctx), String.append(";", shadow_one("Array", ctx)))))

def main(modules: List<&2, Loader.LoadedModule>) -> PhysSmoke:
  ctx = CLay.context(program())
  unwrap(Phys.show_build(ctx, ref("Seg", Nil{}), constructors(), families()), String.append(deep_summary(), String.append("|", shadow_summary())))

def unwrap(+out: Phys.ShowOut, +pdeep: String) -> PhysSmoke:
  match out:
    case Phys.ShowOk{desc, names}: PhysSmoke{desc, String.append(names, String.append("|", pdeep))}
    case Phys.ShowFail{message}: PhysSmoke{message, pdeep}
