import * as B from '../bend2/bend.ts';
import {readParserGraph,type ParserCall} from './parser_full_graph.ts';
import {termChildren,LexicalTypes,type Binding} from './parser_full_type_env.ts';
import {lexicalBodyCaptures,captureQuantityPrefix} from './parser_full_lexical_body_capture.ts';
import {createHash} from 'node:crypto';
const sha=(s:string)=>createHash('sha256').update(s).digest('hex');
function argumentsAt(source:string,offset:number){
 let depth=0,quote='',escape=false;
 const open=source.indexOf('(',offset),ranges:{beg:number;end:number}[]=[];
 let start=open+1;
 const append=(end:number)=>{
  let beg=start;
  while(beg<end&&/\s/.test(source[beg]!))beg++;
  while(end>beg&&/\s/.test(source[end-1]!))end--;
  ranges.push({beg,end});
 };
 for(let i=start;i<source.length;i++){
  const c=source[i]!;
  if(quote){if(escape)escape=false;else if(c==='\\')escape=true;else if(c===quote)quote='';continue;}
  if(c==='"'||c==="'"){quote=c;continue;}
  if('({['.includes(c)){depth++;continue;}
  if(c===')'&&depth===0){append(i);return{ranges,end:i+1};}
  if(')}]'.includes(c)){depth--;continue;}
  if(c===','&&depth===0){append(i);start=i+1;}
 }
 throw Error('Call boundary missing');
}
export type PatternScanCursorPlan={cursor:Binding;file:Binding;depth:1|2;formal:string;remainingArguments:readonly B.LTerm[]};
export type RenderedPatternScanCursorCall={source:string;originalEnd:number;substitutedArguments:B.LTerm[];astEquivalent:true};
function tailDepth(pattern:B.Patt,id:number,depth=0):number|undefined{
 if(pattern.$==='PVar')return pattern.i===id?depth:undefined;
 if(pattern.k!=='Con'||pattern.x.length!==2)return undefined;
 return tailDepth(pattern.x[1]!,id,depth+1);
}
/** Only lexical token tails and the existing unrestricted file may cross this seam. */
export function planPatternScanCursorCall(call:ParserCall,lexical:LexicalTypes,tokenPattern:B.Patt,fileId:number):PatternScanCursorPlan{
 if(call.callee!=='pattern_scan'||call.args.length!==7)throw Error('Recursive scanner ABI drift');
 const [cursor,file]=call.args;
 if(cursor?.$!=='Var'||file?.$!=='Var'||file.i!==fileId)throw Error('Scanner cursor/file must be existing lexical variables');
 const environment=lexical.environmentAt(cursor),cursorBinding=environment.get(cursor.i),fileBinding=environment.get(file.i);
 if(!cursorBinding||!fileBinding||fileBinding.quantity.$!=='Many')throw Error('Scanner cursor/file binding unavailable or file restricted');
 const depth=tailDepth(tokenPattern,cursor.i);
 if(depth!==1&&depth!==2)throw Error('Scanner cursor is not a structural token tail');
 return{cursor:cursorBinding,file:fileBinding,depth,formal:'cursor_tail_'+depth,remainingArguments:call.args.slice(1)};
}
function renameArgument(term:B.LTerm,aliases:ReadonlyMap<number,string>):B.LTerm{
 if(term.$==='Var')return aliases.has(term.i)?{...term,k:aliases.get(term.i)!}:term;
 const children=termChildren(term),copy={...term} as unknown as Record<string,unknown>;
 for(const [key,value] of Object.entries(term)){
  if(key==='s')continue;
  if(Array.isArray(value))copy[key]=value.map(child=>children.includes(child)?renameArgument(child,aliases):child);
  else if(children.includes(value as B.LTerm))copy[key]=renameArgument(value as B.LTerm,aliases);
 }
 return copy as B.LTerm;
}
function astKey(value:unknown,ids:ReadonlyMap<number,number>=new Map()):string{
 return JSON.stringify(value,function(key,child){
  if(key==='s'||key==='k'&&this.$==='Var')return undefined;
  if(key==='i')return Array.isArray(child)?child.map(id=>ids.get(id)??id):ids.get(child)??child;
  return child;
 });
}
function renderArgument(source:string,term:B.LTerm,aliases:ReadonlyMap<number,string>,span:{beg:number;end:number}):string{
 const patches=new Map<number,{end:number;name:string}>();
 function visit(node:B.LTerm){
  if(node.$==='Var'&&aliases.has(node.i)){
   if(!node.s||node.s.beg<span.beg||node.s.end>span.end)throw Error('Alias occurrence lacks an enclosing source span');
   patches.set(node.s.beg,{end:node.s.end,name:aliases.get(node.i)!});
  }
  for(const child of termChildren(node))visit(child);
 }
 visit(term);let rendered=source.slice(span.beg,span.end);
 for(const [beg,patch] of [...patches].sort((a,b)=>b[0]-a[0]))rendered=rendered.slice(0,beg-span.beg)+patch.name+rendered.slice(patch.end-span.beg);
 return rendered;
}
/** The six trailing AST arguments are retained, including the original file. */
export function renderPatternScanCursorCall(source:string,call:ParserCall,plan:PatternScanCursorPlan,aliases:ReadonlyMap<number,string>=new Map()):RenderedPatternScanCursorCall{
 if(call.args[0]?.$!=='Var'||call.args[0].i!==plan.cursor.id||call.args[1]?.$!=='Var'||call.args[1].i!==plan.file.id||call.args.length!==7)throw Error('Cursor plan does not match call');
 const substitutions=new Map(aliases);substitutions.set(plan.cursor.id,plan.formal);
 const substitutedArguments=call.args.map(argument=>renameArgument(argument,substitutions));
 if(astKey(substitutedArguments)!==astKey(call.args))throw Error('Cursor substitution changed recursive argument AST');
 const lexical=argumentsAt(source,call.offset);
 if(lexical.ranges.length!==call.args.length)throw Error('Original recursive argument boundaries changed');
 // An Ann's native span can cover only its value. Lexical argument boundaries
 // retain the original parentheses/type annotation as well as the actual AST.
 return{source:'pattern_scan('+call.args.map((argument,index)=>renderArgument(source,argument,substitutions,lexical.ranges[index]!)).join(', ')+')',originalEnd:lexical.end,substitutedArguments,astEquivalent:true};
}
function visitBodyTerms(body:B.Body,visit:(term:B.LTerm)=>void){
 if(body.$==='Local'){body.v.forEach(visit);visitBodyTerms(body.f,visit);}
 else if(body.$==='Match'){body.e.forEach(visit);body.r.forEach(row=>visitBodyTerms(row.f,visit));}
 else visit(body);
}
export async function partitionPatternScanSource(source:string){
 const graph=await readParserGraph(source),m=graph.bodies.get('pattern_scan'),sig=graph.signatures.get('pattern_scan');if(m?.$!=='Match'||m.r.length!==20||sig?.parameters[0]?.[1]!=='tokens')throw Error('Frozen scanner shape drift');
 const lexical=new LexicalTypes(graph.parserBook,graph.signatures);lexical.indexBody(m,sig.parameters,sig.result);
 const rowHelpers:string[]=[];
 const contextIds=new Set(sig.parameters.filter((_,index)=>index!==2).map(parameter=>parameter[2]));
 const showType=(t:B.LTerm)=>B.term_show(t).replace(/\bast\./g,'Ast.').replace(/\blexer\./g,'Lexer.');
 const text=(p:B.Patt)=>source.slice(p.s!.beg,p.s!.end).trim();
 // Cursor slots are values; no synthetic function type or lambda is emitted.
 const calls=graph.calls.get('pattern_scan')!.filter(c=>c.callee==='pattern_scan');
 const groups={expect:[] as string[],completed:[] as string[],empty:[] as string[]};const audit:{row:number;mode:string;originalPatterns:string[];head:string;lookahead:string;bodyOriginalSha256:string;rewrittenBodySha256:string;originalRecursiveCalls:string[][];recursiveFirstTokenArgumentPreservedViaLexicalCursor:boolean}[]=[];
 const completedTextCases=new Map<string,string>();
 const expectSelectors:string[]=[],expectActions:string[]=[],expectRuns:string[]=[];
 const tailCaptures=new Map<string,{name:string;type:B.LTerm;quantity:B.Quant;depth:number}>();
 const rowFormalIds=new Map<number,number[]>();
 const recursiveAudit:{row:number;call:ParserCall;plan:PatternScanCursorPlan;rendered:RenderedPatternScanCursorCall}[]=[];
 function tailSlot(binding:Binding,depth:number,cursor=false){
  const key=depth+':'+binding.quantity.$,previous=tailCaptures.get(key);
  if(previous&&astKey(previous.type)!==astKey(binding.type))throw Error('Structural tail capture type differs between rows');
  const name=cursor?'cursor_tail_'+depth:previous?.name??'captured_tail_'+depth+'_'+binding.quantity.$.toLowerCase();
  if(previous&&previous.name!==name)throw Error('Cursor slot must be planned before ordinary captures');
  tailCaptures.set(key,{name,type:binding.type,quantity:binding.quantity,depth});return name;
 }
 // Plan cursor slots before ordinary captures can claim a slot of equal quantity.
 for(const call of calls){
  const tokenPattern=m.r.map(row=>row.p[0]!).find(pattern=>call.args[0]?.$==='Var'&&tailDepth(pattern,call.args[0].i)!==undefined);
  if(!tokenPattern)throw Error('Recursive scanner cursor has no structural row binding');
  const plan=planPatternScanCursorCall(call,lexical,tokenPattern,sig.parameters[1]![2]);tailSlot(plan.cursor,plan.depth,true);
 }
 for(let i=0;i<20;i++){
  const row=m.r[i]!,mode=row.p[1];if(mode?.$!=='PCtr')throw Error('Non-constructor scanner mode');
  const begin=source.indexOf('\n',source.indexOf(':',Math.max(...row.p.map(p=>p.s!.end))))+1;
  const end=i+1<20?source.lastIndexOf('\n',m.r[i+1]!.p[0]!.s!.beg)+1:source.indexOf('\ndef ',begin);
  const originalBody=source.slice(begin,end);let body=originalBody;
  const patches:{beg:number;end:number;after:string}[]=[];
  const rowCalls=calls.filter(c=>c.offset>=begin&&c.offset<end);
  const initial=mode.k==='PatternExpect'?mode.x[1]:undefined;
  const aliases=new Map<number,string>();
  if(initial?.$==='PVar'&&initial.k!=='_')aliases.set(initial.i,'initial_beg');
  const plans=rowCalls.map(call=>planPatternScanCursorCall(call,lexical,row.p[0]!,sig.parameters[1]![2]));
  for(const plan of plans){tailSlot(plan.cursor,plan.depth,true);aliases.set(plan.cursor.id,plan.formal);}
  function term(t:B.LTerm){
   if(t.$==='Var'&&aliases.has(t.i)&&t.s)patches.push({beg:t.s.beg-begin,end:t.s.end-begin,after:aliases.get(t.i)!});
   for(const child of termChildren(t))term(child);
  }
  visitBodyTerms(row.f,term);
  for(let j=0;j<rowCalls.length;j++){
   const call=rowCalls[j]!,plan=plans[j]!,rendered=renderPatternScanCursorCall(source,call,plan,aliases);
   patches.push({beg:call.offset-begin,end:rendered.originalEnd-begin,after:rendered.source});
   recursiveAudit.push({row:i,call,plan,rendered});
  }
  const outer=patches.filter(p=>!patches.some(q=>q!==p&&q.beg<=p.beg&&q.end>=p.end));
  for(const p of [...outer].sort((a,b)=>b.beg-a.beg))body=body.slice(0,p.beg)+p.after+body.slice(p.end);
  const token=row.p[0]!;let head='_',lookahead='_';
  if(token.$==='PCtr'){if(token.k!=='Con'||token.x.length!==2)throw Error('Unexpected token pattern');head=text(token.x[0]!);const tail=token.x[1]!;if(tail.$==='PCtr'){if(tail.k!=='Con')throw Error('Unexpected lookahead');lookahead='Some{'+text(tail.x[0]!)+ '}';}}
  let rowCallBody=body;
  if(mode.k==='PatternExpect'||mode.k==='PatternCompleted'){
   const providedIds=new Set([...contextIds,...plans.map(plan=>plan.cursor.id)]);
   const names=lexicalBodyCaptures(row.f,lexical,{providedIds}).map(binding=>({...binding,name:aliases.get(binding.id)??binding.name}));
   const cursors=[...new Map(plans.map(plan=>[plan.cursor.id,plan])).values()];
   const params=['ctx: PatternScanContext',...names.map(b=>captureQuantityPrefix(b.quantity)+b.name+': '+showType(b.type)),...cursors.map(plan=>captureQuantityPrefix(plan.cursor.quantity)+plan.formal+': '+showType(plan.cursor.type))];
   const actuals=['ctx',...names.map(binding=>{
    if(mode.k==='PatternCompleted'&&mode.x[0]?.$==='PVar'&&binding.id===mode.x[0].i)return 'pattern';
    const depth=tailDepth(row.p[0]!,binding.id);
    if(depth!==undefined&&depth>0){
     if(depth>2)throw Error('Scanner capture exceeds its structural lookahead');
     return tailSlot(binding,depth);
    }
    return binding.name;
   }),...cursors.map(plan=>plan.formal)];
   rowHelpers.push('def pattern_scan_row_'+i+'('+params.join(', ')+') -> PatternScanOutcome:\n  match ctx:\n    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:\n'+body.trimEnd());
   rowFormalIds.set(i,[...names.map(binding=>binding.id),...cursors.map(plan=>plan.cursor.id)]);
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
  else if(mode.k!=='PatternBadNat')throw Error('Unknown mode');
  if(token.$==='PVar')groups.empty.push('    case '+text(mode)+':\n'+originalBody.trimEnd());
  audit.push({row:i,mode:mode.k,originalPatterns:row.p.map(text),head,lookahead,bodyOriginalSha256:sha(originalBody),rewrittenBodySha256:sha(body),originalRecursiveCalls:rowCalls.map(c=>argumentsAt(source,c.offset).args),recursiveFirstTokenArgumentPreservedViaLexicalCursor:true});
 }
 const commonBase='+file: String, +tokens: List<&2, Lexer.Token>, frames: List<&2, PatternFrame>, +scope: List<&2, Scope>, +depth: Nat, goal: PatternScanGoal';
 const tails=[...tailCaptures].sort((a,b)=>a[1].depth-b[1].depth||a[0].localeCompare(b[0]));
 const tailParameters=tails.map(([,binding])=>', '+captureQuantityPrefix(binding.quantity)+binding.name+': '+showType(binding.type)).join('');
 const tailArguments=tails.map(([,binding])=>', '+binding.name).join('');
 const common=commonBase+tailParameters;
 const completedClasses=[...completedTextCases];
 const completedTests=completedClasses.map(([literal,tag],index)=>{
  const next=completedClasses[index+1];
  const fallback=next?'pattern_completed_text_test_'+(index+1)+'(String.eq(text, '+next[0]+'), text)':'PatternCompletedTextOther{}';
  return 'def pattern_completed_text_test_'+index+'(same: Bool, +text: String) -> PatternCompletedText:\n  match same:\n    case True{}:\n      '+tag+'{}\n    case False{}:\n      '+fallback;
 });
 const completedClassifier=completedClasses.length?'pattern_completed_text_test_0(String.eq(text, '+completedClasses[0]![0]+'), text)':'PatternCompletedTextOther{}';
 const expectTests=expectSelectors.map((selector,index)=>{
  const fallback=index+1<expectSelectors.length?'\n    case +next_token next_quantity next_lookahead:\n      pattern_expect_action_test_'+(index+1)+'(next_token, next_quantity, next_lookahead)':'';
  return 'def pattern_expect_action_test_'+index+'(+token: Lexer.Token, quantity: Ast.Quantity, lookahead: Maybe<&2, Lexer.Token>) -> PatternExpectAction:\n  match token quantity lookahead:\n'+selector+fallback;
 });
 const helpers=[
 'type PatternScanContext is Data:\n  PatternScanContext{file: String, tokens: List<&2, Lexer.Token>, frames: List<&2, PatternFrame>, scope: List<&2, Scope>, depth: Nat, goal: PatternScanGoal}',
 'type PatternExpectAction is Data:\n'+expectActions.join('\n'),
 'type PatternCompletedText is Data:\n'+[...completedTextCases.values(),'PatternCompletedTextOther'].map(tag=>'  '+tag+'{}').join('\n'),
 ...completedTests,
 'def pattern_completed_text(+text: String) -> PatternCompletedText:\n  '+completedClassifier,
 ...rowHelpers,
 ...expectTests,
 'def pattern_expect_action(+token: Lexer.Token, quantity: Ast.Quantity, lookahead: Maybe<&2, Lexer.Token>) -> PatternExpectAction:\n  pattern_expect_action_test_0(token, quantity, lookahead)',
 'def pattern_scan_expect_run(+token: Lexer.Token, action: PatternExpectAction, +initial_beg: Nat, ctx: PatternScanContext'+tailParameters+') -> PatternScanOutcome:\n  match token:\n    case Lexer.TokenInfo{kind, +text, +token_beg, +token_end, +token_line, +token_col}:\n      match action:\n'+expectRuns.join('\n'),
 'def pattern_scan_expect_step(+token: Lexer.Token, quantity: Ast.Quantity, lookahead: Maybe<&2, Lexer.Token>, +initial_beg: Nat, ctx: PatternScanContext'+tailParameters+') -> PatternScanOutcome:\n  pattern_scan_expect_run(token, pattern_expect_action(token, quantity, lookahead), initial_beg, ctx'+tailArguments+')',
 'def pattern_scan_completed_fields(choice: PatternCompletedText, kind: Lexer.TokenKind, lookahead: Maybe<&2, Lexer.Token>, +text: String, +token_beg: Nat, +token_end: Nat, pattern: Ast.SyntaxPattern, ctx: PatternScanContext'+tailParameters+') -> PatternScanOutcome:\n  match choice kind lookahead:\n'+groups.completed.join('\n'),
 'def pattern_scan_completed_step(+token: Lexer.Token, lookahead: Maybe<&2, Lexer.Token>, pattern: Ast.SyntaxPattern, ctx: PatternScanContext'+tailParameters+') -> PatternScanOutcome:\n  match token:\n    case Lexer.TokenInfo{kind, +text, +beg, +end, line, col}:\n      pattern_scan_completed_fields(pattern_completed_text(text), kind, lookahead, text, beg, end, pattern, ctx'+tailArguments+')',
 'def pattern_scan_token_step(mode: PatternScanMode, +token: Lexer.Token, lookahead: Maybe<&2, Lexer.Token>, '+common+') -> PatternScanOutcome:\n  match mode:\n    case PatternExpect{quantity, +initial_beg}:\n      pattern_scan_expect_step(token, quantity, lookahead, initial_beg, PatternScanContext{file, tokens, frames, scope, depth, goal}'+tailArguments+')\n    case PatternCompleted{pattern}:\n      pattern_scan_completed_step(token, lookahead, pattern, PatternScanContext{file, tokens, frames, scope, depth, goal}'+tailArguments+')\n    case PatternBadNat{beg, end}:\n      pattern_finish(goal, Ast.PatternVar{"", depth, Ast.QOne{}, span(file, beg, end)}, tokens, scope, depth, False{})',
 'def pattern_scan_empty_step(mode: PatternScanMode, '+commonBase+') -> PatternScanOutcome:\n  match mode:\n'+groups.empty.join('\n')];
 const header=source.indexOf('def pattern_scan('),bodyStart=source.indexOf('\n',header)+1,bodyEnd=source.indexOf('\ndef ',bodyStart);
 const stepCall=(next:string,open:string)=>'pattern_scan_token_step(mode, token, '+next+', file, tokens, frames, scope, depth, goal'+tails.map(([,binding])=>', '+(binding.depth===1?'rest':open)).join('')+')';
 const scanner='  match tokens:\n    case +token <> +rest:\n      match rest:\n        case +next <> +after_open:\n          '+stepCall('Some{next}','after_open')+'\n        case Nil{}:\n          '+stepCall('None{}','rest')+'\n    case Nil{}:\n      pattern_scan_empty_step(mode, file, tokens, frames, scope, depth, goal)\n';
 const changed=source.slice(0,header)+helpers.join('\n\n')+'\n\n'+source.slice(header,bodyStart)+scanner+source.slice(bodyEnd);
 const fresh=await readParserGraph(changed);if(fresh.signatures.get('pattern_scan')!.parameters.map(p=>p[1]).join()!==sig.parameters.map(p=>p[1]).join())throw Error('Original scanner ABI changed');
 const freshLexical=new LexicalTypes(fresh.parserBook,fresh.signatures);
 const selected=[...fresh.bodies.keys()].filter(name=>name==='pattern_scan'||name.startsWith('pattern_scan_row_')||['pattern_scan_expect_run','pattern_scan_expect_step','pattern_scan_completed_fields','pattern_scan_completed_step','pattern_scan_token_step','pattern_scan_empty_step'].includes(name));
 let patternScanReferencesUnderLambda=0;
 for(const name of selected){
  const body=fresh.bodies.get(name)!,signature=fresh.signatures.get(name)!;freshLexical.indexBody(body,signature.parameters,signature.result);
  function inspect(term:B.LTerm,underLambda=false){
   if(term.$==='Ref'&&term.k==='pattern_scan'&&underLambda)patternScanReferencesUnderLambda++;
   for(const child of termChildren(term))inspect(child,underLambda||term.$==='Lam');
  }
  visitBodyTerms(body,term=>inspect(term));
 }
 if(patternScanReferencesUnderLambda!==0)throw Error('Selected scanner reference remains under Lam');
 for(const row of m.r.keys()){
  const records=recursiveAudit.filter(record=>record.row===row),emitted=fresh.calls.get('pattern_scan_row_'+row)?.filter(call=>call.callee==='pattern_scan')??[];
  if(records.length!==emitted.length)throw Error('Recursive scanner call count changed in row '+row);
  if(records.length===0)continue;
  const helper='pattern_scan_row_'+row,helperSignature=fresh.signatures.get(helper)!,helperBody=fresh.bodies.get(helper)!,ids=new Map<number,number>();
  const formals=rowFormalIds.get(row)!;
  if(helperSignature.parameters.length!==formals.length+1||helperBody.$!=='Match'||helperBody.r.length!==1)throw Error('Row helper binder shape changed');
  formals.forEach((id,index)=>ids.set(id,helperSignature.parameters[index+1]![2]));
  const context=helperBody.r[0]!.p[0]!;
  if(context.$!=='PCtr'||context.k!=='PatternScanContext'||context.x.length!==6)throw Error('Row helper context shape changed');
  [1,0,3,4,5,6].forEach((parameter,index)=>{
   const field=context.x[index]!;
   if(field.$!=='PVar')throw Error('Context field is not a lexical binder');
   ids.set(sig.parameters[parameter]![2],field.i);
  });
  function mapPattern(original:B.Patt,emitted:B.Patt){
   if(original.$==='PVar'&&emitted.$==='PVar'){ids.set(original.i,emitted.i);return;}
   if(original.$!=='PCtr'||emitted.$!=='PCtr'||original.k!==emitted.k||original.x.length!==emitted.x.length)throw Error('Extracted pattern structure changed');
   original.x.forEach((child,index)=>mapPattern(child,emitted.x[index]!));
  }
  function mapBody(original:B.Body,emitted:B.Body){
   if(original.$!=='Local'&&original.$!=='Match'&&emitted.$!=='Local'&&emitted.$!=='Match')return;
   if(original.$==='Local'&&emitted.$==='Local'&&original.k.length===emitted.k.length){
    original.k.forEach((pattern,index)=>mapPattern(pattern,emitted.k[index]!));mapBody(original.f,emitted.f);return;
   }
   if(original.$==='Match'&&emitted.$==='Match'&&original.r.length===emitted.r.length){
    original.r.forEach((branch,index)=>{
     const emittedBranch=emitted.r[index]!;
     if(branch.p.length!==emittedBranch.p.length)throw Error('Extracted branch arity changed');
     branch.p.forEach((pattern,patternIndex)=>mapPattern(pattern,emittedBranch.p[patternIndex]!));mapBody(branch.f,emittedBranch.f);
    });return;
   }
   throw Error('Extracted body structure changed');
  }
  mapBody(m.r[row]!.f,helperBody.r[0]!.f);
  for(let index=0;index<records.length;index++){
   const record=records[index]!,actual=emitted[index]!,newEnvironment=freshLexical.environmentAt(actual.args[0]!);
   function requireMapped(term:B.LTerm){
    if(term.$==='Var'&&!ids.has(term.i))throw Error('Recursive argument binder lost during factoring: '+term.i);
    for(const child of termChildren(term))requireMapped(child);
   }
   record.rendered.substitutedArguments.forEach(requireMapped);
   if(astKey(record.rendered.substitutedArguments,ids)!==astKey(actual.args))throw Error('Rendered recursive argument AST changed in row '+row);
   const first=actual.args[0]!,cursor=first.$==='Var'?newEnvironment.get(first.i):undefined;
   if(!cursor||cursor.quantity.$!==record.plan.cursor.quantity.$||astKey(cursor.type)!==astKey(record.plan.cursor.type))throw Error('Cursor lexical type or quantity changed');
  }
 }
 // Audit ASTs retain coordinates, not a full source copy at every syntax node.
 const snapshot=(value:unknown)=>JSON.parse(JSON.stringify(value,(key,child)=>key==='s'?{beg:child.beg,end:child.end}:child));
 return{source:changed,graph:fresh,audit:{question:'Can nonrecursive mode-specific scanner steps shrink checking while first-order lexical cursors preserve original token-first recursion and ownership?',onPass:'Actual complete ordinary load/check/codegen then artifact execution/corpus, no trusted-prefix acceptance',onFailure:'Report concrete source/toolchain boundary, no unsafe/checker/generator logic workaround',originalSha256:sha(source),transformedSha256:sha(changed),originalExternalScannerABIUnchanged:true,quantities:'Cursor and capture quantities are copied from lexical bindings without promotion',priority:'Original order preserved within disjoint mode constructors; no branch priority changed',rows:audit,recursiveCalls:recursiveAudit.map(({row,call,plan,rendered})=>({row,originalOffset:call.offset,firstArgument:snapshot(call.args[0]),cursorFormal:{name:plan.formal,binderId:plan.cursor.id,type:snapshot(plan.cursor.type),quantity:plan.cursor.quantity,structuralTailDepth:plan.depth},remainingSixArguments:snapshot(plan.remainingArguments),substitutedArguments:snapshot(rendered.substitutedArguments),astEquivalent:rendered.astEquivalent,renderedDirectCall:rendered.source})),patternScanReferencesUnderLambda,completedTextClassifier:{literals:[...completedTextCases],wildcardComplement:'PatternCompletedTextOther',stateFree:true,originalOrderedCompletedRows:audit.flatMap(row=>row.mode==='PatternCompleted'?[row.row]:[])},helperGroups:{expect:groups.expect.length,completed:groups.completed.length,empty:groups.empty.length},sourceSpecificGeneratorExceptions:0}};
}
