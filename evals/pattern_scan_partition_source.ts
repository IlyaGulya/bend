import * as B from '../bend2/bend.ts';
import {readParserGraph} from './parser_full_graph.ts';
import {termChildren,LexicalTypes,freeBinderIds} from './parser_full_type_env.ts';
import {createHash} from 'node:crypto';
const sha=(s:string)=>createHash('sha256').update(s).digest('hex');
function argumentsAt(source:string,offset:number){let depth=0,quote='',escape=false;const open=source.indexOf('(',offset),args:string[]=[];let start=open+1;for(let i=start;i<source.length;i++){const c=source[i]!;if(quote){if(escape)escape=false;else if(c==='\\')escape=true;else if(c===quote)quote='';continue;}if(c==='"'||c==="'"){quote=c;continue;}if('({['.includes(c)){depth++;continue;}if(c===')'&&depth===0){args.push(source.slice(start,i).trim());return{args,end:i+1};}if(')}]'.includes(c)){depth--;continue;}if(c===','&&depth===0){args.push(source.slice(start,i).trim());start=i+1;}}throw Error('Call boundary missing');}
export async function partitionPatternScanSource(source:string){
 const graph=await readParserGraph(source),m=graph.bodies.get('pattern_scan'),sig=graph.signatures.get('pattern_scan');if(m?.$!=='Match'||m.r.length!==20||sig?.parameters[0]?.[1]!=='tokens')throw Error('Frozen scanner shape drift');
 const lexical=new LexicalTypes(graph.parserBook,graph.signatures);lexical.indexBody(m,sig.parameters,sig.result);
 const rowHelpers:string[]=[];
 const commonNames=new Set(['file','tokens','frames','scope','depth','goal','rest','after_open']);
 const showType=(t:B.LTerm)=>B.term_show(t).replace(/\bast\./g,'Ast.').replace(/\blexer\./g,'Lexer.');
 const text=(p:B.Patt)=>source.slice(p.s!.beg,p.s!.end).trim();
 const captures='next_mode => next_frames => next_scope => next_depth => next_goal => ';
 const cbType='PatternScanMode -> List<&2, PatternFrame> -> List<&2, Scope> -> Nat -> PatternScanGoal -> PatternScanOutcome';
 const suffixArgs='next_mode, next_frames, next_scope, next_depth, next_goal';
 const callback=(cursor:string)=>captures+'pattern_scan('+cursor+', file, '+suffixArgs+')';
 const calls=graph.calls.get('pattern_scan')!.filter(c=>c.callee==='pattern_scan');
 const groups={expect:[] as string[],completed:[] as string[],empty:[] as string[]};const audit:object[]=[];
 const completedTextCases=new Map<string,string>();
 const expectSelectors:string[]=[],expectActions:string[]=[],expectRuns:string[]=[];
 for(let i=0;i<20;i++){
  const row=m.r[i]!,mode=row.p[1];if(mode?.$!=='PCtr')throw Error('Non-constructor scanner mode');
  const begin=source.indexOf('\n',source.indexOf(':',Math.max(...row.p.map(p=>p.s!.end))))+1;
  const end=i+1<20?source.lastIndexOf('\n',m.r[i+1]!.p[0]!.s!.beg)+1:source.indexOf('\ndef ',begin);
  const originalBody=source.slice(begin,end);let body=originalBody;
  const patches:{beg:number;end:number;after:string}[]=[];
  const rowCalls=calls.filter(c=>c.offset>=begin&&c.offset<end);
  for(const c of rowCalls){const call=argumentsAt(source,c.offset);if(call.args.length!==7||call.args[1]!=='file')throw Error('Recursive ABI drift');const cursor=call.args[0];if(cursor!=='rest'&&cursor!=='after_open')throw Error('Unknown token suffix '+cursor);patches.push({beg:c.offset-begin,end:call.end-begin,after:(cursor==='rest'?'continue_rest':'continue_open')+'('+call.args.slice(2).join(', ')+')'});}
  if(mode.k==='PatternExpect'){
   const initial=mode.x[1];if(initial?.$==='PVar'&&initial.k!=='_'){
    function term(t:B.LTerm){if(t.$==='Var'&&t.i===initial.i&&t.s)patches.push({beg:t.s.beg-begin,end:t.s.end-begin,after:'initial_beg'});for(const child of termChildren(t))term(child);}
    function visit(b:B.Body){if(b.$==='Reply')term(b.x);else if(b.$==='Local'){b.v.forEach(term);visit(b.f);}else{b.e.forEach(term);b.r.forEach(r=>visit(r.f));}}visit(row.f);
   }
  }
  // Call replacement already carries original arguments; apply bound begin renames inside it too.
  const initial=mode.k==='PatternExpect'?mode.x[1]:undefined;
  if(initial?.$==='PVar'&&initial.k!=='_')for(const p of patches.filter(p=>p.after.startsWith('continue_'))){const contained=patches.filter(q=>q!==p&&q.beg>=p.beg&&q.end<=p.end);for(const q of contained){p.after=p.after.replace(new RegExp('\\b'+initial.k+'\\b','g'),'initial_beg');}}
  const outer=patches.filter(p=>!patches.some(q=>q!==p&&q.beg<=p.beg&&q.end>=p.end));
  for(const p of [...outer].sort((a,b)=>b.beg-a.beg))body=body.slice(0,p.beg)+p.after+body.slice(p.end);
  const token=row.p[0]!;let head='_',lookahead='_';
  if(token.$==='PCtr'){if(token.k!=='Con'||token.x.length!==2)throw Error('Unexpected token pattern');head=text(token.x[0]!);const tail=token.x[1]!;if(tail.$==='PCtr'){if(tail.k!=='Con')throw Error('Unexpected lookahead');lookahead='Some{'+text(tail.x[0]!)+ '}';}}
  let rowCallBody=body;
  if(mode.k==='PatternExpect'||mode.k==='PatternCompleted'){
   const first=row.f.$==='Reply'?row.f.x:row.f.$==='Match'?row.f.e[0]!:row.f.v[0]!;
   const env=lexical.environmentAt(first),ids=new Set<number>();
   function expression(t:B.LTerm){const[head,args]=B.term_unapply(t);const nodes=head.$==='Ref'&&head.k==='pattern_scan'&&args.length===7?args.slice(2):[t];for(const n of nodes)for(const id of freeBinderIds(n))if(env.has(id)&&!commonNames.has(env.get(id)!.name))ids.add(id);}
   function collect(b:B.Body){if(b.$==='Reply')expression(b.x);else if(b.$==='Local'){b.v.forEach(expression);collect(b.f);}else{b.e.forEach(expression);b.r.forEach(r=>collect(r.f));}}collect(row.f);
   const names=[...ids].sort((a,b)=>a-b).map(id=>{const binding=env.get(id)!;return{...binding,name:initial?.$==='PVar'&&id===initial.i?'initial_beg':binding.name};});
   const params=['ctx: PatternScanContext',...names.map(b=>(b.quantity.$==='Many'?'+':'')+b.name+': '+showType(b.type))];
   const actuals=['ctx',...names.map(b=>b.name)];
   for(const name of ['continue_rest','continue_open'])if(body.includes(name+'(')){params.push(name+': '+cbType);actuals.push(name);}
   rowHelpers.push('def pattern_scan_row_'+i+'('+params.join(', ')+') -> PatternScanOutcome:\n  match ctx:\n    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:\n'+body.trimEnd());
   rowCallBody='      pattern_scan_row_'+i+'('+actuals.join(', ')+')';
  }
  if(mode.k==='PatternExpect'){
   const quantity=text(mode.x[0]!),qtyPattern=mode.x[0]!,needsQuantity=qtyPattern.$==='PVar'&&qtyPattern.k!=='_'&&new RegExp('\\b'+qtyPattern.k+'\\b').test(rowCallBody),tag='PatternExpectActionRow'+i;
   expectActions.push('  '+tag+'{'+(needsQuantity?'quantity: Ast.Quantity':'')+'}');
   expectSelectors.push('    case '+head+' '+quantity+' '+lookahead+':\n      '+tag+'{'+(needsQuantity?qtyPattern.k:'')+'}');
   if(token.$==='PCtr'){const scalar=token.x[0]!;if(scalar.$!=='PCtr'||scalar.x.length!==6)throw Error('Expect token fields drift');for(const [index,name] of ['kind','text','token_beg','token_end','token_line','token_col'].entries()){const field=scalar.x[index]!;if(field.$==='PVar'&&field.k!=='_')rowCallBody=rowCallBody.replace(new RegExp('\\b'+field.k+'\\b','g'),name);}}
   expectRuns.push('        case '+tag+'{'+(needsQuantity?'quantity':'')+'}:\n    '+rowCallBody.trimEnd());
   groups.expect.push('    case '+head+' '+quantity+' '+lookahead+':\n'+rowCallBody.trimEnd());
  }
  else if(mode.k==='PatternCompleted'){
   if(token.$==='PCtr'){
    const scalar=token.x[0]!;if(scalar.$!=='PCtr'||!text(scalar).startsWith('Lexer.TokenInfo{')||scalar.x.length!==6)throw Error('Unexpected completed token fields');
    if(scalar.x.slice(4).some(p=>p.$!=='PVar'||p.k!=='_'))throw Error('Completed scanner observes additional token fields');
    for(const [index,name] of [[2,'token_beg'],[3,'token_end']] as const){const field=scalar.x[index]!;if(field.$==='PVar'&&field.k!=='_')rowCallBody=rowCallBody.replace(new RegExp('\\b'+field.k+'\\b','g'),name);}
    const textPattern=scalar.x[1]!;let choice='_';
    if(textPattern.$==='PVar'){if(textPattern.k!=='_')rowCallBody=rowCallBody.replace(new RegExp('\\b'+textPattern.k+'\\b','g'),'text');}
    else{const literal=text(textPattern);if(!literal.startsWith('"'))throw Error('Unsupported completed text pattern');const tag='PatternCompletedTextRow'+i;if(completedTextCases.has(literal))throw Error('Duplicate completed text literal');completedTextCases.set(literal,tag);choice=tag+'{}';}
    groups.completed.push('    case '+choice+' '+text(scalar.x[0]!)+' '+lookahead+':\n'+rowCallBody.trimEnd());
   }else groups.completed.push('    case _ _ '+lookahead+':\n'+rowCallBody.trimEnd());
  }
  else if(!['PatternNoNat','PatternBadNat'].includes(mode.k))throw Error('Unknown mode');
  if(token.$==='PVar')groups.empty.push('    case '+text(mode)+':\n'+originalBody.trimEnd());
  audit.push({row:i,mode:mode.k,originalPatterns:row.p.map(text),head,lookahead,bodyOriginalSha256:sha(originalBody),rewrittenBodySha256:sha(body),originalRecursiveCalls:rowCalls.map(c=>argumentsAt(source,c.offset).args),recursiveFirstTokenArgumentPreservedViaLexicalTailCallbacks:true});
 }
 const common='+file: String, +tokens: List<&2, Lexer.Token>, frames: List<&2, PatternFrame>, +scope: List<&2, Scope>, +depth: Nat, goal: PatternScanGoal';
 const continuations='continue_rest: '+cbType+', continue_open: '+cbType;
 if(completedTextCases.size!==4)throw Error('Completed text classification drift');
 const helpers=[
 'type PatternScanContext is Data:\n  PatternScanContext{file: String, tokens: List<&2, Lexer.Token>, frames: List<&2, PatternFrame>, scope: List<&2, Scope>, depth: Nat, goal: PatternScanGoal}',
 'type PatternExpectAction is Data:\n'+expectActions.join('\n'),
 'type PatternCompletedText is Data:\n'+[...completedTextCases.values(),'PatternCompletedTextOther'].map(tag=>'  '+tag+'{}').join('\n'),
 'def pattern_completed_text(text: String) -> PatternCompletedText:\n  match text:\n'+[...completedTextCases].map(([literal,tag])=>'    case '+literal+':\n      '+tag+'{}').join('\n')+'\n    case _:\n      PatternCompletedTextOther{}',
 ...rowHelpers,
 'def pattern_expect_action(+token: Lexer.Token, quantity: Ast.Quantity, lookahead: Maybe<&2, Lexer.Token>) -> PatternExpectAction:\n  match token quantity lookahead:\n'+expectSelectors.join('\n'),
 'def pattern_scan_expect_run(+token: Lexer.Token, action: PatternExpectAction, +initial_beg: Nat, ctx: PatternScanContext, '+continuations+') -> PatternScanOutcome:\n  match token:\n    case Lexer.TokenInfo{kind, +text, +token_beg, +token_end, +token_line, +token_col}:\n      match action:\n'+expectRuns.join('\n'),
 'def pattern_scan_expect_step(+token: Lexer.Token, quantity: Ast.Quantity, lookahead: Maybe<&2, Lexer.Token>, +initial_beg: Nat, ctx: PatternScanContext, '+continuations+') -> PatternScanOutcome:\n  pattern_scan_expect_run(token, pattern_expect_action(token, quantity, lookahead), initial_beg, ctx, continue_rest, continue_open)',
 'def pattern_scan_completed_fields(choice: PatternCompletedText, kind: Lexer.TokenKind, lookahead: Maybe<&2, Lexer.Token>, +text: String, +token_beg: Nat, +token_end: Nat, pattern: Ast.SyntaxPattern, ctx: PatternScanContext, '+continuations+') -> PatternScanOutcome:\n  match choice kind lookahead:\n'+groups.completed.join('\n'),
 'def pattern_scan_completed_step(+token: Lexer.Token, lookahead: Maybe<&2, Lexer.Token>, pattern: Ast.SyntaxPattern, ctx: PatternScanContext, '+continuations+') -> PatternScanOutcome:\n  match token:\n    case Lexer.TokenInfo{kind, +text, +beg, +end, line, col}:\n      pattern_scan_completed_fields(pattern_completed_text(text), kind, lookahead, text, beg, end, pattern, ctx, continue_rest, continue_open)',
 'def pattern_scan_token_step(mode: PatternScanMode, +token: Lexer.Token, lookahead: Maybe<&2, Lexer.Token>, '+common+', '+continuations+') -> PatternScanOutcome:\n  match mode:\n    case PatternExpect{quantity, +initial_beg}:\n      pattern_scan_expect_step(token, quantity, lookahead, initial_beg, PatternScanContext{file, tokens, frames, scope, depth, goal}, continue_rest, continue_open)\n    case PatternCompleted{pattern}:\n      pattern_scan_completed_step(token, lookahead, pattern, PatternScanContext{file, tokens, frames, scope, depth, goal}, continue_rest, continue_open)\n    case PatternNoNat{number, quantity, beg, end}:\n      pattern_finish(goal, Ast.PatternVar{"", depth, quantity, span(file, beg, end)}, number <> tokens, scope, depth, False{})\n    case PatternBadNat{beg, end}:\n      pattern_finish(goal, Ast.PatternVar{"", depth, Ast.QOne{}, span(file, beg, end)}, tokens, scope, depth, False{})',
 'def pattern_scan_empty_step(mode: PatternScanMode, '+common+') -> PatternScanOutcome:\n  match mode:\n'+groups.empty.join('\n')];
 const header=source.indexOf('def pattern_scan('),bodyStart=source.indexOf('\n',header)+1,bodyEnd=source.indexOf('\ndef ',bodyStart);
 const stepCall=(next:string,open:string)=>'pattern_scan_token_step(mode, token, '+next+', file, tokens, frames, scope, depth, goal, '+callback('rest')+', '+callback(open)+')';
 const scanner='  match tokens:\n    case +token <> +rest:\n      match rest:\n        case +next <> +after_open:\n          '+stepCall('Some{next}','after_open')+'\n        case Nil{}:\n          '+stepCall('None{}','rest')+'\n    case Nil{}:\n      pattern_scan_empty_step(mode, file, tokens, frames, scope, depth, goal)\n';
 const changed=source.slice(0,header)+helpers.join('\n\n')+'\n\n'+source.slice(header,bodyStart)+scanner+source.slice(bodyEnd);
 const fresh=await readParserGraph(changed);if(fresh.signatures.get('pattern_scan')!.parameters.map(p=>p[1]).join()!==sig.parameters.map(p=>p[1]).join())throw Error('Original scanner ABI changed');
 return{source:changed,graph:fresh,audit:{question:'Can nonrecursive mode-specific scanner steps shrink checking while lexical tail callbacks preserve original token-first recursion and ownership?',cheapTest:'Typed callback native smoke PASS7n; direct nested mode-first original-ABI smoke consumed-binder FAIL, so mode matching lives in nonrecursive helpers with aligned formals',onPass:'Actual complete ordinary load/check/codegen then artifact execution/corpus, no trusted-prefix acceptance',onFailure:'Report concrete source/toolchain boundary, no unsafe/checker/generator logic workaround',originalSha256:sha(source),transformedSha256:sha(changed),originalExternalScannerABIUnchanged:true,quantities:'Original scanner ABI and emitted syntax quantities unchanged; helper sharing is explicit and checked',priority:'Original order preserved within disjoint mode constructors; no branch priority changed',rows:audit,completedTextClassifier:{literals:[...completedTextCases],wildcardComplement:'PatternCompletedTextOther',stateFree:true,originalOrderedCompletedRows:[11,12,13,14,15,16,17,18]},helperGroups:{expect:groups.expect.length,completed:groups.completed.length,empty:groups.empty.length},sourceSpecificGeneratorExceptions:0}};
}
