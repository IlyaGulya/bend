import Base
import ../bend2/selfhost/lexer.bend as Lexer

type SymbolCombineMode is Data:
  SymbolCombineScan{}
  SymbolCombineMerged{merged: Lexer.Token, consumed: Nat}
  SymbolCombineUnmerged{token: Lexer.Token}
  SymbolCombineSkip{merged: Lexer.Token}

type SymbolPairClass is Data:
  SymbolPairMerged{pair: String}
  SymbolPairUnmerged{left: String}

type SymbolTripleClass is Data:
  SymbolTripleMerged{three: String}
  SymbolTripleUnmerged{left: String, right: String}

def multi_symbol_3(text: String) -> SymbolTripleClass:
  match text:
    case "<&>": SymbolTripleMerged{"<&>"}
    case ".|.": SymbolTripleMerged{".|."}
    case ".^.": SymbolTripleMerged{".^."}
    case ".&.": SymbolTripleMerged{".&."}
    case SCon{first, SCon{second, _}}: SymbolTripleUnmerged{String.from_list([first]), String.from_list([second])}
    case SCon{first, SNil{}}: SymbolTripleUnmerged{String.from_list([first]), SNil{}}
    case SNil{}: SymbolTripleUnmerged{SNil{}, SNil{}}

def multi_symbol_2(text: String) -> SymbolPairClass:
  match text:
    case "=>": SymbolPairMerged{"=>"}
    case "->": SymbolPairMerged{"->"}
    case "<-": SymbolPairMerged{"<-"}
    case "==": SymbolPairMerged{"=="}
    case "!=": SymbolPairMerged{"!="}
    case "<=": SymbolPairMerged{"<="}
    case ">=": SymbolPairMerged{">="}
    case "<>": SymbolPairMerged{"<>"}
    case "++": SymbolPairMerged{"++"}
    case "<<": SymbolPairMerged{"<<"}
    case ">>": SymbolPairMerged{">>"}
    case "||": SymbolPairMerged{"||"}
    case "&&": SymbolPairMerged{"&&"}
    case SCon{first, _}: SymbolPairUnmerged{String.from_list([first])}
    case SNil{}: SymbolPairUnmerged{SNil{}}

def merge_symbol_pair_result(result: SymbolPairClass, beg: Nat, end: Nat, line: Nat, col: Nat, middle_end: Nat) -> SymbolCombineMode:
  match result:
    case SymbolPairMerged{pair}:
      SymbolCombineMerged{Lexer.TokenInfo{Lexer.SymbolToken{}, pair, beg, middle_end, line, col}, 1n}
    case SymbolPairUnmerged{left}:
      SymbolCombineUnmerged{Lexer.TokenInfo{Lexer.SymbolToken{}, left, beg, end, line, col}}

def merge_symbol_pair(is_adjacent: Bool, left: String, right: String, beg: Nat, end: Nat, line: Nat, col: Nat, middle_end: Nat) -> SymbolCombineMode:
  match is_adjacent:
    case True{}:
      merge_symbol_pair_result(multi_symbol_2(String.append(left, right)), beg, end, line, col, middle_end)
    case False{}:
      SymbolCombineUnmerged{Lexer.TokenInfo{Lexer.SymbolToken{}, left, beg, end, line, col}}

def merge_symbol_2(left: String, right: String, beg: Nat, +end: Nat, line: Nat, col: Nat, tokens: List<&2, Lexer.Token>) -> SymbolCombineMode:
  match tokens:
    case +middle <> rest:
      match middle:
        case Lexer.TokenInfo{ Lexer.SymbolToken{}, _, middle_beg, middle_end, _, _}:
          merge_symbol_pair(Nat.is_eq(end, middle_beg), left, right, beg, end, line, col, middle_end)
        case _:
          SymbolCombineUnmerged{Lexer.TokenInfo{Lexer.SymbolToken{}, left, beg, end, line, col}}
    case Nil{}:
      SymbolCombineUnmerged{Lexer.TokenInfo{Lexer.SymbolToken{}, left, beg, end, line, col}}

def merge_symbol_three_result(result: SymbolTripleClass, beg: Nat, end: Nat, line: Nat, col: Nat, last_end: Nat, middle: Lexer.Token, rest: List<&2, Lexer.Token>) -> SymbolCombineMode:
  match result:
    case SymbolTripleMerged{three}:
      SymbolCombineMerged{Lexer.TokenInfo{Lexer.SymbolToken{}, three, beg, last_end, line, col}, 2n}
    case SymbolTripleUnmerged{left, right}:
      merge_symbol_2(left, right, beg, end, line, col, middle <> rest)

def merge_symbol_three(is_adjacent: Bool, text: String, middle: Lexer.Token, rest: List<&2, Lexer.Token>, middle_text: String, last_text: String, last_end: Nat, beg: Nat, end: Nat, line: Nat, col: Nat) -> SymbolCombineMode:
  match is_adjacent:
    case True{}:
      merge_symbol_three_result(multi_symbol_3(String.append(String.append(text, middle_text), last_text)), beg, end, line, col, last_end, middle, rest)
    case False{}:
      merge_symbol_2(text, middle_text, beg, end, line, col, middle <> rest)

def merge_symbol_middle(is_adjacent: Bool, text: String, middle: Lexer.Token, rest: List<&2, Lexer.Token>, middle_text: String, middle_beg: Nat, middle_end: Nat, beg: Nat, end: Nat, line: Nat, col: Nat) -> SymbolCombineMode:
  match is_adjacent rest:
    case True{} +last <> _:
      match last:
        case Lexer.TokenInfo{ Lexer.SymbolToken{}, last_text, last_beg, last_end, _, _}:
          merge_symbol_three(Nat.is_eq(middle_end, last_beg), text, middle, rest, middle_text, last_text, last_end, beg, end, line, col)
        case _:
          merge_symbol_2(text, middle_text, beg, end, line, col, middle <> rest)
    case True{} Nil{}:
      merge_symbol_2(text, middle_text, beg, end, line, col, [middle])
    case False{} _:
      SymbolCombineUnmerged{Lexer.TokenInfo{Lexer.SymbolToken{}, text, beg, end, line, col}}

def merge_symbol(text: String, beg: Nat, +end: Nat, line: Nat, col: Nat, tokens: List<&2, Lexer.Token>) -> SymbolCombineMode:
  match tokens:
    case +middle <> rest:
      match middle:
        case Lexer.TokenInfo{ Lexer.SymbolToken{}, middle_text, middle_beg, middle_end, _, _}:
          merge_symbol_middle(Nat.is_eq(end, middle_beg), text, middle, rest, middle_text, middle_beg, middle_end, beg, end, line, col)
        case _:
          SymbolCombineUnmerged{Lexer.TokenInfo{Lexer.SymbolToken{}, text, beg, end, line, col}}
    case Nil{}:
      SymbolCombineUnmerged{Lexer.TokenInfo{Lexer.SymbolToken{}, text, beg, end, line, col}}

def scan_symbol_mode(token: Lexer.Token, rest: List<&2, Lexer.Token>) -> SymbolCombineMode:
  match token:
    case Lexer.TokenInfo{Lexer.SymbolToken{}, text, beg, end, line, col}:
      merge_symbol(text, beg, end, line, col, rest)
    case _:
      SymbolCombineUnmerged{token}

def combine_symbols(tokens: List<&2, Lexer.Token>, mode: SymbolCombineMode) -> List<&2, Lexer.Token>:
  match tokens mode:
    case +token <> +rest SymbolCombineScan{}:
      combine_symbols(rest, scan_symbol_mode(token, rest))
    case Nil{} SymbolCombineScan{}:
      Nil{}
    case +_ <> rest SymbolCombineMerged{merged, 1n}:
      merged <> combine_symbols(rest, SymbolCombineScan{})
    case +_ <> rest SymbolCombineMerged{merged, 2n}:
      combine_symbols(rest, SymbolCombineSkip{merged})
    case +_ <> rest SymbolCombineMerged{merged, _}:
      merged <> combine_symbols(rest, SymbolCombineScan{})
    case Nil{} SymbolCombineMerged{merged, _}:
      merged <> Nil{}
    case +next <> +rest SymbolCombineUnmerged{token}:
      token <> combine_symbols(rest, scan_symbol_mode(next, rest))
    case Nil{} SymbolCombineUnmerged{token}:
      token <> Nil{}
    case +_ <> rest SymbolCombineSkip{merged}:
      merged <> combine_symbols(rest, SymbolCombineScan{})
    case Nil{} SymbolCombineSkip{merged}:
      merged <> Nil{}


def tokens(source: String) -> List<&2, Lexer.Token>:
  combine_symbols(Lexer.tokens(source), SymbolCombineScan{})
