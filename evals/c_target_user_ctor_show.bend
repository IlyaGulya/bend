# SHOW regression for the C target: a user datatype's own Nil, Con and Tuple
# are qualified constructor keys from an imported module, not Base's List and
# Sigma arms. The reference decides an arm's bracket from the whole key, so all
# three print as `module.Name{...}` data: Con is not the list cons and Tuple is
# not the pair. The main is pure, so the run goes through the emitted SHOW
# descriptor and its arm names rather than an explicit IO.print.
import Base
import ./c_target_q_ctors.bend as Q

def main() -> Q.T:
  Q.T.Tuple{Q.T.Con{1, Q.T.Nil{}}, 2}

#|c_target_q_ctors.T.Tuple{c_target_q_ctors.T.Con{1, c_target_q_ctors.T.Nil{}}, 2}
