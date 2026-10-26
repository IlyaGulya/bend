# Fixture module for evals/c_target_user_ctor_show.bend.
#
# Its constructors deliberately carry the three names Base gives the List and
# Sigma arms. The module namespace is what keeps them distinct, so a printer
# must compare the whole constructor key and never the last segment: these are
# ordinary module data constructors, not Base's list and tuple sugar.
import Base

type T is Data:
  T.Nil{}
  T.Con{head: U32, tail: T}
  T.Tuple{fst: T, snd: U32}
