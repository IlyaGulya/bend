# SHOW must keep each applied family's own semantic arguments across all arms.
# The same recursive sum is reached through a captured type alias at two
# representations; the second generic field must retain its shifted scope.
# Base List still prints as data, including both constructor arms and brackets.
import Base

type ShowChoice<-A: Data> is Data:
  ShowEmpty{}
  ShowOne{value: A}
  ShowTwo{left: A, right: A}
  ShowAgain{next: ShowChoice<A>}

def apply_type(F: Data -> Data) -> Data:
  F(Unit)

def ShowAlias(A: Data) -> Data:
  apply_type(Ignored => ShowChoice<A>)

type ShowPair<-A: Data> is Data:
  ShowPair{first: A, rest: List<&2, A>}

type ShowReport is Data:
  ShowReport{list: List<&2, U32>, words: ShowAlias(U32), nested: ShowAlias(List<&2, U32>), empty: ShowAlias(U32), pair: ShowPair<U32>}

def main() -> ShowReport:
  ShowReport{[1, 2], ShowTwo{3, 4}, ShowAgain{ShowOne{[5, 6]}}, ShowEmpty{}, ShowPair{7, [8, 9]}}

#|ShowReport{[1, 2], ShowTwo{3, 4}, ShowAgain{ShowOne{[5, 6]}}, ShowEmpty{}, ShowPair{7, [8, 9]}}
