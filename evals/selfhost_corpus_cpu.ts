#!/usr/bin/env bun
/** Offline physical-code coverage only. Never imports an image or starts a process.
 * Usage: bun evals/selfhost_corpus_cpu.ts PLAN.json FRESH-REPORT.json
 * All evidence paths are explicit; plan paths are relative to the plan file.
 * Samples retain summarize_cpu_profile.mjs's identity and timeDeltas weighting.
 */
import {readFileSync, realpathSync, writeFileSync} from 'node:fs';
import {basename, dirname, isAbsolute, relative, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';

type Row = Record<string, any>;
type Ref = {path:string; sha256:string};
type JsonEvidence = {path:string; sha256:string; value:Row};
type Side = {
  image:Ref; profile:Ref; report:Ref; request:Ref; sourceManifest:Ref;
  run:Ref|null; phaseSummary:Ref|null;
  // Explicit archived copies may replace unavailable/mutated historical tool pins.
  pinFiles?:Record<string, Ref>;
};
export interface CpuPlan {schemaVersion:1; ruleSet:'g56-physical-v1'; full:Side; screen:Side; fragmentProvenance?:Ref}
type Family = 'scheduler-cps-dispatch'|'checker-body-helper'|'normalized-helper'|'arena'|'base-map-scope'|'gc'|'runtime-helper'|'unclassified';
const families:Family[] = ['scheduler-cps-dispatch','checker-body-helper','normalized-helper','arena','base-map-scope','gc','runtime-helper','unclassified'];
const G50 = '273b0022813e17908020c0ee58fd4e02da4f3dc756ce58e3389093440863c3fe';
const ABI = ['parsed_module','parse_with_fuel','expand_modules_start','template_step','check_expanded_start','inspect_checked_start','checker_step','emit_modules_start','emit_library_start','emitter_step','emit_c_modules_start','emit_c_library_start','c_emitter_step'];
const limits = {memoryMiB:8192,rssMiB:8192,pollMs:10,timeoutMs:600000};
const workerPolicy = {stackMiB:256,oldGenerationMiB:6144,youngGenerationMiB:128};
const flags = ['--experimental-strip-types','--max-old-space-size=6144','--max-semi-space-size=128'];
const toolPins:Record<string,string[]> = {
  'selfhost_throughput.mjs':['4b9b735630421c00f666a956f7adaaf40c0f57908d420ec2a1155e68c81ffd8e','1a806befee02216a9499f6b4dcde7e2326e01f0a5b96bbd36b75295344c50317'],
  'selfhost_cpu_profile.mjs':['5d5fc8d329a3b600522c58eeac59c49c515109bc7f48845d8177cb520129a1c0'],
  'checker_core_step_runtime.mjs':['00cd400ac0452a3681bf6491db08be51f9ae3a33ff2baf88654a9763eb5073ed'],
  'native_seed_runtime.mjs':['7f81a9b9013853355910b93bf59586b2acbcda4de7bcaa08d7942ebf45c0147a'],
  'heavy_gate.ts':['e72f2b81970be76734df918e35b1a4289d0fb194039e5ca20e9785e5ac0ee015'],
};
const object = (x:any):x is Row => x !== null && typeof x === 'object' && !Array.isArray(x);
const digest = (x:any):x is string => typeof x === 'string' && /^[a-f0-9]{64}$/.test(x);
const hash = (x:string|Buffer) => createHash('sha256').update(x).digest('hex');
function need(ok:any, message:string):asserts ok {if (!ok) throw Error(message);}
function canonical(x:any):string {
  if (Array.isArray(x)) return '['+x.map(canonical).join(',')+']';
  if (object(x)) return '{'+Object.keys(x).sort().map(k=>JSON.stringify(k)+':'+canonical(x[k])).join(',')+'}';
  return JSON.stringify(x);
}
const same = (a:any,b:any) => canonical(a) === canonical(b);
function pathAt(base:string, value:any):string {need(typeof value==='string' && value.length>0,'Missing explicit path');return resolve(base,value);}
function pathEqual(a:string,b:string):boolean {return realpathSync(a)===realpathSync(b);}
function relativeFile(root:string,file:string):string {
  const name=relative(root,file);
  need(name!=='' && !isAbsolute(name) && name!=='..' && !name.startsWith('../'),'File outside declared source directory: '+file);
  return name;
}
function readRef(base:string, ref:Ref) {
  need(object(ref) && digest(ref.sha256),'Explicit path and SHA-256 required');
  const path=realpathSync(pathAt(base,ref.path)), bytes=readFileSync(path);
  need(hash(bytes)===ref.sha256,'Evidence hash mismatch: '+path);
  return {path,sha256:ref.sha256,bytes};
}
function jsonRef(base:string,ref:Ref) {
  const {bytes,...identity}=readRef(base,ref), value=JSON.parse(bytes.toString('utf8'));
  need(object(value),'Expected JSON object: '+identity.path);
  return {...identity,value};
}

// Ordered, immutable rules. These identify physical emitted code, NOT semantic
// costs. In particular match_N cannot be relabelled inference/equality work.
const aliasRules:{family:Family; pattern:RegExp; evidence:string}[] = [
  {family:'normalized-helper',pattern:/(?:^|[._])match_[0-9]+(?:$|[._])/,evidence:'generated match_N spelling; logical pre-CPS owner unavailable'},
  {family:'scheduler-cps-dispatch',pattern:/^checker_core_steps_v1\.checker_(?:step(?:_one|_group_[0-9]+)?|pop|advance|chunk)$/,evidence:'explicit checker scheduler public alias'},
  {family:'arena',pattern:/^\.\.\/bend2\/selfhost\/checker_arena\./,evidence:'physical checker_arena module alias'},
  {family:'base-map-scope',pattern:/^(?:Map\.|\.\.\/bend2\/selfhost\/(?:scope_lookup|index_lookup)\.)/,evidence:'physical Base Map or scope/index lookup module alias'},
  {family:'checker-body-helper',pattern:/^(?:checker_core_steps_v1\.|\.\.\/bend2\/selfhost\/(?:core|checker_ir)\.)/,evidence:'physical checker/core/helper module alias; no semantic subdivision'},
];
const schedulerName = /^(?:\$(?:split(?:m|1|_enter|_done|_abort)?|frame|run|curried)|run_(?:loop|call1|base|force|many|tail|clo|named[0-9]+)|tail_(?:many|unary|named|dispatch))$/;
const runtimeName = /^(?:\$p_[A-Za-z0-9_]+|nat_[A-Za-z0-9_]+|char_[A-Za-z0-9_]+|str_(?:in|out)|cmp_new)$/;

interface Declaration {name:string; lineNumber:number; columnNumber:number; lineSha256:string; code:string|null}
interface Alias {name:string; body:string; lineNumber:number; lineSha256:string}
export interface ImageMap {
  declarations:Map<string,Declaration>; aliases:Map<string,Alias[]>;
  byLine:Map<number,string>; exportLines:Map<number,Alias>;
  incoming:Map<string,Set<string>>; omissions:Row[];
}
/** Mask quoted text before token matching. This is intentionally not a JS parser:
 * generated one-line bodies support JSON/single-quoted strings, not templates,
 * comments or regex literals. Unsupported bodies retain no inferred ownership.
 */
function generatedCode(line:string):string|null {
  let out='', quote='', escaped=false;
  for(let i=0;i<line.length;i++) {
    const c=line[i]!;
    if(quote) {
      out+=' ';
      if(escaped) escaped=false; else if(c==='\\') escaped=true; else if(c===quote) quote='';
    } else if(c==='"' || c==="'") {quote=c;out+=' ';}
    else if(c==='`' || c==='/') return null;
    else out+=c;
  }
  if(quote) return null;
  const stack:string[]=[];
  for(const c of out) {
    if('({['.includes(c)) stack.push(c);
    else if(')}]'.includes(c) && stack.pop()!=='({['[')}]'.indexOf(c)]) return null;
  }
  return stack.length===0?out:null;
}
export function mapImage(text:string):ImageMap {
  const lines=text.split('\n'), declarations=new Map<string,Declaration>(), aliases=new Map<string,Alias[]>();
  const byLine=new Map<number,string>(), exportLines=new Map<number,Alias>(), incoming=new Map<string,Set<string>>();
  const omissions:Row[]=[];
  for(let i=0;i<lines.length;i++) {
    const line=lines[i]!, decl=/^function ([A-Za-z_$][A-Za-z0-9_$]*)\(/.exec(line);
    if(decl) {
      const name=decl[1]!;
      need(!declarations.has(name),'Duplicate emitted declaration: '+name);
      const code=generatedCode(line);
      declarations.set(name,{name,lineNumber:i,columnNumber:line.indexOf('('),lineSha256:hash(line),code});
      // Only complete single-line bodies own blank-name callbacks on that line.
      if(code && line.endsWith('}')) byLine.set(i,name);
      if(/^\$[bk][0-9]+$/.test(name) && !code) omissions.push({lineNumber:i,name,reason:'unsupported one-line body syntax; no ownership inferred'});
      continue;
    }
    const exported=/^\$D\[("(?:[^"\\]|\\.)*")\]=(run_clo\(.*);$/.exec(line);
    if(!exported) continue;
    const code=generatedCode(exported[2]!);
    if(!code) {omissions.push({lineNumber:i,reason:'unsupported public alias body'});continue;}
    const calls=[...code.matchAll(/\$b[0-9]+(?=\()/g)].map(m=>m[0]);
    const refs=new Set([...code.matchAll(/\$b[0-9]+\b/g)].map(m=>m[0]));
    if(new Set(calls).size!==1 || refs.size!==1) {omissions.push({lineNumber:i,reason:'public wrapper does not name one direct body'});continue;}
    const body=calls[0]!, name=JSON.parse(exported[1]!);
    const row={name,body,lineNumber:i,lineSha256:hash(line)};
    const previous=aliases.get(body)??[]; previous.push(row);aliases.set(body,previous);exportLines.set(i,row);
  }
  for(const [name,decl] of declarations) {
    if(!/^\$[bk][0-9]+$/.test(name)) continue;
    // Direct body references only. Never infer ownership from adjacency or a
    // callee's $b references. A continuation referenced by a continuation is
    // deliberately unresolved instead of acquiring a transitive semantic owner.
    // Raw references in unsupported bodies only veto an ownership claim; they
    // never establish one. This preserves possible competing owners.
    const code=decl.code??lines[decl.lineNumber]!;
    const body=code.slice(code.indexOf('{')+1);
    for(const match of body.matchAll(/\$k[0-9]+\b/g)) {
      const owners=incoming.get(match[0])??new Set<string>();owners.add(name);incoming.set(match[0],owners);
    }
  }
  for(const [body, rows] of aliases) if(!declarations.has(body)) omissions.push({body,aliases:rows,reason:'public body declaration absent'});
  const anchors:Record<string,string>={'$b6848':'checker_core_steps_v1.checker_step_one','$b6849':'checker_core_steps_v1.checker_pop','$b6850':'checker_core_steps_v1.checker_advance','$b6851':'checker_core_steps_v1.checker_chunk'};
  for(const [body,name] of Object.entries(anchors)) need(aliases.get(body)?.some(x=>x.name===name),'Authentic G50 scheduler export missing: '+body+' = '+name);
  return {declarations,aliases,byLine,exportLines,incoming,omissions};
}
function attribution(frame:Row, image:string, map:ImageMap):Row {
  const none=(reason:string, evidence:Row={})=>({family:'unclassified',reason,aliases:[],...evidence});
  if(frame.functionName==='(garbage collector)') return {family:'gc',reason:'canonical V8 GC leaf frame',aliases:[]};
  let urlPath:string;
  try {
    const url=new URL(frame.url);
    if(url.protocol!=='file:' || url.search || url.hash) return none('No exact authenticated image URL');
    urlPath=fileURLToPath(url);
    if(!pathEqual(urlPath,image)) return none('Frame is outside authenticated image');
  } catch {return none('No resolvable authenticated image URL');}
  const name=frame.functionName as string;
  let owner=name, route='named declaration at exact source line';
  let wrapper:Alias|undefined;
  if(name==='') {
    wrapper=map.exportLines.get(frame.lineNumber);
    owner=wrapper?.body??map.byLine.get(frame.lineNumber)??'';
    route=wrapper?'blank callback on exact public alias line':'blank callback on exact complete emitted-body line';
    if(!owner) return none('Blank callback has no exact source-line owner');
  } else {
    const decl=map.declarations.get(name);
    if(!decl || decl.lineNumber!==frame.lineNumber) return none('No matching named declaration at exact source line');
  }
  const declaration=map.declarations.get(owner);
  if(!declaration) return none('Owner declaration absent');
  const evidence:Row={route,emittedName:owner,declaration:{name:owner,lineNumber:declaration.lineNumber,lineSha256:declaration.lineSha256}};
  if(wrapper) evidence.wrapper=wrapper;
  if(schedulerName.test(owner)) return {family:'scheduler-cps-dispatch',reason:'preregistered emitted scheduler name',aliases:[],...evidence};
  if(runtimeName.test(owner)) return {family:'runtime-helper',reason:'preregistered emitted runtime helper name',aliases:[],...evidence};
  if(/^\$k[0-9]+$/.test(owner)) {
    const owners=[...(map.incoming.get(owner)??[])].sort();evidence.directOwners=owners.map(name=>({name,lineNumber:map.declarations.get(name)?.lineNumber,lineSha256:map.declarations.get(name)?.lineSha256}));
    if(owners.length!==1 || !/^\$b[0-9]+$/.test(owners[0]!) || !map.declarations.get(owners[0]!)?.code) return none('Continuation lacks one direct supported emitted $b owner; ambiguity preserved',evidence);
    owner=owners[0]!;
  }
  const publicAliases=map.aliases.get(owner)??[];
  evidence.aliases=publicAliases;
  if(!publicAliases.length) return none('No authentic public alias for emitted body',evidence);
  const classifications=publicAliases.map(x=>({alias:x.name,rule:aliasRules.find(rule=>rule.pattern.test(x.name))}));
  const distinct=new Set(classifications.map(x=>x.rule?.family??'unclassified'));
  if(distinct.size!==1 || distinct.has('unclassified')) return none('Public aliases have missing or conflicting physical-family rules',evidence);
  return {family:classifications[0]!.rule!.family,reason:'public emitted alias matches preregistered physical family',...evidence,
    rules:classifications.map(x=>({alias:x.alias,pattern:x.rule!.pattern.source,evidence:x.rule!.evidence}))};
}

export function summarizeProfile(profile:Row,image:string,map:ImageMap) {
  need(Array.isArray(profile.nodes)&&Array.isArray(profile.samples)&&Array.isArray(profile.timeDeltas)&&profile.samples.length===profile.timeDeltas.length,'Profile requires nodes and equal-length samples/timeDeltas arrays');
  need(Number.isFinite(profile.startTime)&&Number.isFinite(profile.endTime)&&profile.endTime>=profile.startTime,'Invalid profile startTime/endTime');
  const nodes=new Map<number,string>(), parents=new Map<number,number>(), rows=new Map<string,Row>();
  for(const node of profile.nodes) {
    const f=node.callFrame;
    need(Number.isSafeInteger(node.id)&&!nodes.has(node.id)&&object(f)&&typeof f.functionName==='string'&&typeof f.url==='string'&&Number.isInteger(f.lineNumber)&&Number.isInteger(f.columnNumber),'Invalid or duplicate node/callFrame');
    const key=JSON.stringify([f.functionName,f.url,f.lineNumber,f.columnNumber]);nodes.set(node.id,key);
    if(!rows.has(key)) rows.set(key,{identity:key,functionName:f.functionName,url:f.url,lineNumber:f.lineNumber,columnNumber:f.columnNumber,
      classification:attribution(f,image,map),selfMicroseconds:0,selfSamples:0});
    need(node.children===undefined||Array.isArray(node.children),'Invalid node children');
    for(const child of node.children??[]) {need(Number.isSafeInteger(child)&&!parents.has(child),'Invalid or multiply-parented child');parents.set(child,node.id);}
  }
  for(const [child,parent] of parents) need(nodes.has(child)&&nodes.has(parent),'Missing parent/child node');
  // Validate all ancestry once, not once per sample. There is no inclusive cost.
  const done=new Set<number>(), path=new Set<number>();
  for(const start of nodes.keys()) {
    path.clear();let id:number|undefined=start;
    while(id!==undefined&&!done.has(id)) {need(!path.has(id),'Cyclic profile stack');path.add(id);id=parents.get(id);}
    for(const item of path) done.add(item);
  }
  let total=0;
  for(let i=0;i<profile.samples.length;i++) {
    const key=nodes.get(profile.samples[i]), duration=profile.timeDeltas[i];
    need(key!==undefined&&Number.isFinite(duration)&&duration>=0,'Invalid sample/timeDelta at '+i);
    const row=rows.get(key)!;row.selfMicroseconds+=duration;row.selfSamples++;total+=duration;
  }
  need(Number.isFinite(total),'Sampled duration overflow');
  const totals=new Map<Family,Row>(families.map(f=>[f,{family:f,selfSamples:0,selfMicroseconds:0,functionIdentities:[]}]));
  const functions=[...rows.values()].filter(row=>row.selfSamples>0).sort((a,b)=>b.selfMicroseconds-a.selfMicroseconds||a.identity.localeCompare(b.identity));
  for(const row of functions) {
    row.selfSampledMs=row.selfMicroseconds/1000;row.selfShare=total?row.selfMicroseconds/total:null;
    const bucket=totals.get(row.classification.family)!;bucket.selfSamples+=row.selfSamples;bucket.selfMicroseconds+=row.selfMicroseconds;bucket.functionIdentities.push(row.identity);
  }
  const result=[...totals.values()].map(row=>({...row,selfSampledMs:row.selfMicroseconds/1000,selfShare:total?row.selfMicroseconds/total:null}));
  return {samples:profile.samples.length,sampledMs:total/1000,profileDurationMs:(profile.endTime-profile.startTime)/1000,
    unattributedDurationMs:(profile.endTime-profile.startTime-total)/1000,excludedSamples:0,
    zeroSelfSampleFunctionCount:rows.size-functions.length,families:result,functions};
}

function authenticate(base:string,side:Side,label:string,omissions:string[]) {
  need(object(side),'Missing '+label+' evidence');
  const image=readRef(base,side.image), report=jsonRef(base,side.report), request=jsonRef(base,side.request), profile=jsonRef(base,side.profile), manifest=jsonRef(base,side.sourceManifest);
  need(image.sha256===G50,'Only exact native-produced G50 image is supported');
  const r=report.value, q=request.value, m=manifest.value;
  need(q.schemaVersion===1&&r.schemaVersion===1&&m.schemaVersion===1,'Unsupported evidence schema');
  need(r.status==='PASS'&&r.mode==='js'&&r.diagnosticOnly===true&&r.acceptanceEvidence===false,'Report is not a successful native-image diagnostic');
  need(r.checksExcluded===0&&r.outputPatches===0,'Report excludes checks or patches output');
  need(r.requestSha256===request.sha256&&pathEqual(r.request,request.path),'Report/request identity mismatch');
  need(pathEqual(q.image,image.path),'Request/image path mismatch');
  need(pathEqual(r.source,q.root),'Report/request source root mismatch');
  need(same(q.exports,ABI)&&same(r.exports,ABI)&&same(m.exports,ABI),'Original public ABI drift');
  need(same(q.limits,limits)&&same(r.limits,limits)&&same(r.workerPolicy,workerPolicy),'Original limits/worker policy drift');
  need(['check','compile'].includes(q.stopAfter??'compile')&&(r.stopAfter??'compile')===(q.stopAfter??'compile'),'Request/report stopAfter mismatch');
  need(same(r.runtime?.execArgv,flags)&&r.runtime?.versions?.node==='23.11.0'&&r.runtime?.versions?.v8==='12.9.202.28-node.14','Original Node/V8 runtime drift');
  need(pathEqual(r.runtime.execPath,q.node),'Request/report runtime path mismatch');
  const g=r.guardian;
  need(object(g)&&g.status==='PASS'&&g.reportPhase==='complete'&&g.ownedTreeStopped===true&&g.exitCode===0&&g.supervisorExitCode===0&&g.commandExitCode===0&&g.commandSignal===0,'Guardian did not complete successfully');
  need(g.memoryLimitBytes===8192*1048576&&g.rssLimitBytes===8192*1048576&&g.timeoutMs===600000,'Guardian original limits drift');
  need(Number.isFinite(g.peakRssBytes)&&g.peakRssBytes>0&&g.peakRssBytes<=g.rssLimitBytes&&Number.isFinite(g.peakFootprintBytes)&&g.peakFootprintBytes>0&&g.peakFootprintBytes<=g.memoryLimitBytes&&Number.isFinite(g.elapsedMs)&&g.elapsedMs>0&&g.elapsedMs<=g.timeoutMs,'Guardian resources exceed original limits or are absent');
  need(Array.isArray(g.command),'Guardian command absent');
  const workerIndex=g.command.indexOf('--worker');
  need(workerIndex>0&&g.command[workerIndex+1]==='js'&&pathEqual(g.command[workerIndex+2],request.path)&&g.command[workerIndex+3]===request.sha256&&pathEqual(g.command[workerIndex+4],report.path),'Guardian request/report binding mismatch');
  need(object(q.pins)&&object(q.inputs)&&Object.keys(q.inputs).length>0,'Request lacks pins/inputs');
  const pinned:Row[]=[];
  for(const [original,expected] of Object.entries(q.pins)) {
    need(isAbsolute(original)&&digest(expected),'Invalid request pin');
    const replacement=side.pinFiles?.[original];
    if(replacement) need(replacement.sha256===expected,'Archived pin digest differs from request');
    const read=readRef(base,replacement??{path:original,sha256:expected});
    pinned.push({original,path:read.path,sha256:read.sha256});
  }
  for(const original of Object.keys(side.pinFiles??{})) need(Object.hasOwn(q.pins,original),'Unused archived pin: '+original);
  for(const [name,hashes] of Object.entries(toolPins)) {
    const found=pinned.filter(x=>basename(x.original)===name);
    need(found.length===1&&hashes.includes(found[0]!.sha256),'Missing or unrecognized original driver pin: '+name);
  }
  need(pinned.some(x=>x.sha256===G50&&pathEqual(x.original,image.path)),'Image not pinned by request');
  need(pinned.some(x=>basename(x.original)==='local2039g50-combined-native-v2.json'&&x.sha256==='255477ed64fc5c3040b64b0e8bd6cd6128ffb1ad147725b3ffe2d1dd9f8453bc'),'Native-producing receipt pin missing');
  need(pinned.some(x=>resolve(x.original)===resolve(g.command[workerIndex-1])),'Guardian driver not pinned');
  const sourceDirectory=realpathSync(pathAt(dirname(manifest.path),m.directory));
  need(Array.isArray(m.files)&&m.files.length>0,'Source manifest files missing');
  const requestDirectory=realpathSync(q.repository), requestInputs=new Map<string,string>();
  for(const [file,sha256] of Object.entries(q.inputs)) {
    need(isAbsolute(file)&&digest(sha256),'Invalid request input');
    const name=relativeFile(requestDirectory,resolve(file));
    need(!requestInputs.has(name),'Duplicate request source path');requestInputs.set(name,sha256);
  }
  const sources:Row[]=[], names=new Set<string>();
  for(const entry of m.files) {
    need(object(entry)&&typeof entry.path==='string'&&!isAbsolute(entry.path)&&digest(entry.sha256),'Invalid manifest source entry');
    const file=pathAt(sourceDirectory,entry.path), name=relativeFile(sourceDirectory,file);
    need(name===entry.path&&!names.has(name),'Duplicate/noncanonical manifest source path');names.add(name);
    const real=realpathSync(file);relativeFile(sourceDirectory,real);
    need(requestInputs.get(name)===entry.sha256,'Manifest/request source identity mismatch: '+name);
    need(hash(readFileSync(real))===entry.sha256,'Frozen source bytes mismatch: '+name);
    sources.push({path:name,sha256:entry.sha256,external:entry.external===true});
  }
  need(names.size===requestInputs.size,'Manifest/request input set differs (including foreign files)');
  if(label==='full') need(names.size===53,'Full G50 request must contain exactly all 53 input files');
  need(typeof m.root==='string'&&m.root===relativeFile(requestDirectory,resolve(q.root))&&names.has(m.root),'Manifest/request root mismatch');
  need(r.sourceSha256===requestInputs.get(m.root),'Report source hash mismatch');
  const checks=r.phases?.filter((x:Row)=>x.phase==='check');
  need(checks?.length===1&&Number.isFinite(checks[0].elapsedMs)&&checks[0].elapsedMs>0,'Report lacks one successful checker phase');
  const diagnostic:Row={identityAvailable:false};
  need(side.run===null||object(side.run),'run must be an explicit reference or null');
  need(side.phaseSummary===null||object(side.phaseSummary),'phaseSummary must be an explicit reference or null');
  if(side.run===null||side.phaseSummary===null) omissions.push(label+': diagnostic run/phase identity is absent; profile hash alone cannot bind a check interval');
  else {
    const run=jsonRef(base,side.run), summary=jsonRef(base,side.phaseSummary), a=run.value, s=summary.value;
    need(a.schemaVersion===1&&a.kind==='selfhost-worker-cpu-profile'&&a.acceptanceEvidence===false&&a.samplingIntervalUs===1000,'Unexpected diagnostic run protocol');
    need(s.schemaVersion===1&&s.kind==='selfhost-worker-phase'&&s.phase==='check'&&s.status==='completed'&&s.sequence===4,'Not the recorded completed checker interval');
    need(Number.isSafeInteger(a.pid)&&a.pid>0&&Number.isSafeInteger(a.threadId)&&a.threadId>0&&a.isMainThread===false,'Invalid worker identity');
    need(s.pid===a.pid&&s.threadId===a.threadId&&s.isMainThread===a.isMainThread,'Run/phase worker identity mismatch');
    need(pathEqual(s.profilePath,profile.path)&&pathEqual(a.runDirectory,dirname(profile.path))&&pathEqual(s.runDirectory,a.runDirectory)&&pathEqual(dirname(run.path),a.runDirectory)&&pathEqual(dirname(summary.path),a.runDirectory),'Profile/run/phase directory identity mismatch');
    need(a.execution?.mode==='js'&&a.execution.requestSha256===request.sha256&&pathEqual(a.execution.request,request.path)&&pathEqual(a.execution.root,q.root)&&pathEqual(a.execution.image,image.path),'Diagnostic execution/request identity mismatch');
    need(s.details?.mode==='js'&&pathEqual(s.details.root,q.root),'Diagnostic phase source root mismatch');
    need(same(a.runtime?.versions,r.runtime.versions)&&same(a.runtime?.execArgv,r.runtime.execArgv)&&pathEqual(a.runtime.execPath,q.node),'Diagnostic/report runtime mismatch');
    need(Number.isFinite(Date.parse(a.startedAt))&&Number.isFinite(Date.parse(s.startedAt))&&Number.isFinite(Date.parse(s.endedAt))&&Date.parse(a.startedAt)<=Date.parse(s.startedAt)&&Date.parse(s.startedAt)<=Date.parse(s.endedAt),'Invalid diagnostic dates');
    if(r.profilePath!==undefined) need(pathEqual(r.profilePath,profile.path),'Report profile path mismatch');
    if(r.profileSha256!==undefined) need(r.profileSha256===profile.sha256,'Report profile digest mismatch');
    Object.assign(diagnostic,{identityAvailable:true,run:{path:run.path,sha256:run.sha256},phaseSummary:{path:summary.path,sha256:summary.sha256},pid:a.pid,threadId:a.threadId,startedAt:s.startedAt,endedAt:s.endedAt,
      binding:'Hashed retained run.execution joins hashed request; hashed phase summary joins exact profile path and worker identity. Legacy metadata does not embed the profile digest.',profileScope:a.profileScope,cpuScope:a.cpuScope});
  }
  return {image,profile:profile.value,request:q,identity:{image:{path:image.path,sha256:image.sha256},profile:{path:profile.path,sha256:profile.sha256},report:{path:report.path,sha256:report.sha256},request:{path:request.path,sha256:request.sha256},
    sourceManifest:{path:manifest.path,sha256:manifest.sha256},sourceDirectory,root:m.root,sourceSha256:r.sourceSha256,sources,pins:pinned,limits,workerPolicy,exports:ABI,diagnostic,
    reportCheckPhase:{elapsedMs:checks[0].elapsedMs,userCpuMs:checks[0].userCpuMs,systemCpuMs:checks[0].systemCpuMs,scope:r.phaseCpuScope},runtime:r.runtime}};
}

/** Compact provenance v2 uses half-open BYTE spans, never UTF-16 offsets.
 * declarations: [key,kind,originalBegin,originalEnd,originalSHA256,
 *   prefixBegin,prefixEnd,emittedBegin,emittedEnd,emittedSHA256,prefixSHA256].
 * header/suffix: {original:Span,emitted:Span}; omittedImports add original:Span.
 * Span = {beginByte,endByte,sliceSHA256}. This proves copied bytes, not syntax,
 * dependency closure, import-deletion semantics or native acceptance.
 */
function authenticateFragment(module:Row, original:Buffer, emitted:Buffer, root:boolean):Row {
  const span=(bytes:Buffer,value:any,label:string):Buffer=>{
    need(object(value)&&Number.isSafeInteger(value.beginByte)&&Number.isSafeInteger(value.endByte)&&
      value.beginByte>=0&&value.endByte>=value.beginByte&&value.endByte<=bytes.length&&digest(value.sliceSHA256),'Invalid fragment '+label+' span');
    const slice=bytes.subarray(value.beginByte,value.endByte);
    need(hash(slice)===value.sliceSHA256,'Fragment '+label+' slice hash mismatch');
    return slice;
  };
  const tupleSpan=(beginByte:any,endByte:any,sliceSHA256:any)=>({beginByte,endByte,sliceSHA256});
  need(object(module.header)&&object(module.suffix)&&Array.isArray(module.declarations)&&module.declarations.length>0&&
    Array.isArray(module.omittedImports)&&module.omittedImports.length<=1,'Fragment header/suffix/declarations/import proof missing');
  const header=module.header, suffix=module.suffix;
  span(original,header.original,'original header');span(emitted,header.emitted,'emitted header');
  need(header.original.beginByte===0&&header.emitted.beginByte===0,'Fragment header must start at byte zero');
  let cursor=0;
  const reconstructed=createHash('sha256');
  const copy=(slice:Buffer)=>{
    need(cursor+slice.length<=emitted.length&&slice.equals(emitted.subarray(cursor,cursor+slice.length)),'Fragment copied content differs at emitted byte '+cursor);
    reconstructed.update(slice);cursor+=slice.length;
  };
  let headerCursor=0;
  for(const omitted of module.omittedImports) {
    need(object(omitted)&&root&&omitted.alias==='CheckerCore'&&omitted.path==='./checker_core_steps_v1.bend'&&
      omitted.proof==='no-selected-reference-to-module-and-all-external-owners-retained','Only the root CheckerCore import deletion is permitted');
    const deleted=span(original,omitted.original,'deleted import'), start=omitted.original.beginByte, end=omitted.original.endByte;
    need(start>=headerCursor&&end<=header.original.endByte&&
      deleted.equals(Buffer.from('import ./checker_core_steps_v1.bend as CheckerCore'))&&
      (start===0||original[start-1]===10)&&(end===original.length||original[end]===10||original[end]===13),
      'Deleted span is not the exact complete original CheckerCore import');
    copy(original.subarray(headerCursor,start));headerCursor=end;
  }
  copy(original.subarray(headerCursor,header.original.endByte));
  need(cursor===header.emitted.endByte,'Fragment emitted header range differs from copied header');
  let previousOriginalEnd=header.original.endByte;
  const keys=new Set<string>();
  for(let index=0;index<module.declarations.length;index++) {
    const d=module.declarations[index];
    need(Array.isArray(d)&&d.length===11&&typeof d[0]==='string'&&d[0].length>0&&!keys.has(d[0])&&
      typeof d[1]==='string'&&d[1].length>0,'Invalid/duplicate fragment declaration');
    keys.add(d[0]);
    const body=span(original,tupleSpan(d[2],d[3],d[4]),'original '+d[0]);
    const prefix=span(original,tupleSpan(d[5],d[6],d[10]),'prefix '+d[0]);
    span(emitted,tupleSpan(d[7],d[8],d[9]),'emitted '+d[0]);
    need(body.length>0&&d[6]===d[2]&&d[5]>=previousOriginalEnd&&
      (index!==0||d[5]===header.original.endByte)&&d[7]===cursor,
      'Fragment declaration/prefix order, overlap or emitted gap: '+d[0]);
    copy(prefix);copy(body);
    need(cursor===d[8],'Fragment emitted declaration range differs from prefix + original: '+d[0]);
    previousOriginalEnd=d[3];
  }
  const trailing=span(original,suffix.original,'original suffix');
  span(emitted,suffix.emitted,'emitted suffix');
  need(suffix.original.beginByte>=previousOriginalEnd&&suffix.original.endByte===original.length&&
    /^[\t\n\r ]*$/.test(trailing.toString('utf8'))&&suffix.emitted.beginByte===cursor,
    'Fragment suffix must preserve the declared original trailing trivia through EOF');
  copy(trailing);
  need(cursor===suffix.emitted.endByte&&cursor===emitted.length&&reconstructed.digest('hex')===module.outputSha256,
    'Fragment reconstruction does not cover the entire output');
  return {id:module.id,originalRelativePath:module.originalRelativePath,originalSha256:module.originalSha256,
    outputSha256:module.outputSha256,declarations:keys.size,outputBytes:cursor,omittedImports:module.omittedImports};
}

function authenticateSourceMembership(base:string,ref:Ref|undefined,full:Row,screen:Row):Row {
  const fullSources=new Map<string,Row>(full.sources.map((source:Row)=>[source.path,source]));
  // Without fragment evidence, retain the legacy generated-root exception.
  // With evidence supplied, the root is subject to the same byte proof as any
  // other changed source. Foreign files can never use the fragment exception.
  let provenance:JsonEvidence|undefined;
  if(ref!==undefined) {
    try {provenance=jsonRef(base,ref);}
    catch(error) {throw Error('Fragment provenance unavailable or invalid: '+String(error));}
    need(provenance.value.schemaVersion===2&&digest(provenance.value.sourceGenerationReportSha256)&&
      Array.isArray(provenance.value.modules),'Expected complete fragment provenance schemaVersion 2');
    need(provenance.value.modules.every((module:any)=>object(module)&&typeof module.originalRelativePath==='string'&&
      module.source===module.originalRelativePath&&digest(module.originalSha256)&&digest(module.outputSha256)),
      'Invalid fragment provenance module identities');
  }
  const whole:string[]=[], fragments:Row[]=[];
  for(const source of screen.sources) {
    const original=fullSources.get(source.path);
    if(!provenance&&source.path===screen.root) continue;
    need(original,'Screen source is not a full-source member: '+source.path);
    if(original.sha256===source.sha256) {whole.push(source.path);continue;}
    need(provenance&&source.path.endsWith('.bend')&&!source.external&&!original.external,
      'Changed screen source requires authenticated Bend fragment lineage: '+source.path);
    const modules=provenance.value.modules.filter((module:Row)=>module.originalRelativePath===source.path&&module.outputSha256===source.sha256);
    need(modules.length>0,'No matching fragment provenance for screen source: '+source.path);
    const originalBytes=readRef(full.sourceDirectory,{path:source.path,sha256:original.sha256}).bytes;
    const emittedBytes=readRef(screen.sourceDirectory,{path:source.path,sha256:source.sha256}).bytes;
    // Equivalent min/complete entries may share an output; validate every match,
    // rather than letting a valid first entry conceal a conflicting proof.
    for(const module of modules) {
      need(module.originalSha256===original.sha256,'Fragment original differs from full manifest: '+source.path);
      fragments.push(authenticateFragment(module,originalBytes,emittedBytes,source.path===screen.root&&source.path===full.root));
    }
  }
  return {mode:provenance?'authenticated-source-fragments':'whole-members-with-generated-root-exception',
    provenance:provenance?{path:provenance.path,sha256:provenance.sha256}:null,wholeMembers:whole,fragments,
    authority:'Byte lineage only; source semantic closure and native acceptance are separate authority.'};
}

export function analyzeCpuCoverage(planPath:string):Row {
  const output:Row={schemaVersion:1,status:'INCONCLUSIVE',diagnosticOnly:true,acceptanceEvidence:false,
    scope:'Structural physical self-sampled elapsed-time coverage of one G50 full/screen checker interval; not performance speedup or full semantic-family coverage.',
    attribution:'samples[i] receives timeDeltas[i] microseconds; no rescaling, hitCount estimates, inclusive attribution, exclusions or inferred inlined work',
    functionIdentity:'functionName + url + zero-based lineNumber + zero-based columnNumber; scriptId excluded',
    ruleSet:'g56-physical-v1',thresholds:{maximumTV:0.20,minimumFullShareRequiringPresence:0.05,minimumSamplesPerProfile:1000,maximumUnclassifiedShare:0.20},
    rules:{aliases:aliasRules.map(x=>({family:x.family,pattern:x.pattern.source,evidence:x.evidence})),schedulerName:schedulerName.source,runtimeName:runtimeName.source},
    errors:[],omissions:[],limitations:[
      'V8 samples measure worker-isolate sampled elapsed time, not process CPU; process-wide CPU figures are retained separately and never used as weights.',
      'Only physical emitted source families are screened. CPS, normalization and inlining destroy semantic ownership; no inference/equality-family completeness claim is made.',
      'match_N helpers have normalized-helper identity only, not inferred logical pre-CPS ownership.',
      'Continuation ownership requires exactly one direct $b body reference; chained, ambiguous or unmapped continuations remain unclassified.',
      'Blank-name callbacks inherit only an exact complete emitted-body line or authenticated public alias line. No nearest-line/name fallback exists.',
      'GC means the canonical V8 garbage-collector leaf here; unlike an inclusive GC stack diagnostic it receives only self samples.',
      'Profile/metadata hashes pin retained evidence, not a cryptographic proof that the process produced it; legacy metadata binds profile paths, not profile digests.',
      'A single retained profile pair supplies no uncertainty interval, stationarity test or causal performance comparison.',
      'Observed-vector source TV (including HOAS signature omissions) is a separate bound, not a complete native-checker-AST or semantic CPU coverage bound.',
      'Fragment provenance proves ordered original-byte copying and complete output reconstruction only; declaration boundaries, dependency closure and import-deletion safety require separate source/native authority.',
    ]};
  try {
    const file=realpathSync(planPath), bytes=readFileSync(file), plan=JSON.parse(bytes.toString('utf8')) as CpuPlan, base=dirname(file);
    output.plan={path:file,sha256:hash(bytes)};
    need(plan.schemaVersion===1&&plan.ruleSet==='g56-physical-v1','Expected schemaVersion 1 and fixed g56-physical-v1 rule set');
    const full=authenticate(base,plan.full,'full',output.omissions), screen=authenticate(base,plan.screen,'screen',output.omissions);
    need(full.image.sha256===screen.image.sha256&&pathEqual(full.image.path,screen.image.path),'Full/screen image identity mismatch');
    need(full.identity.profile.sha256!==screen.identity.profile.sha256&&!pathEqual(full.identity.profile.path,screen.identity.profile.path),'Full/screen reuse the same profile');
    need(full.identity.request.sha256!==screen.identity.request.sha256,'Full/screen reuse the same request');
    need(same(full.identity.runtime,screen.identity.runtime),'Full/screen runtime identity differs');
    output.sourceMembership=authenticateSourceMembership(base,plan.fragmentProvenance,full.identity,screen.identity);
    const a=full.identity.diagnostic,b=screen.identity.diagnostic;
    if(a.identityAvailable&&b.identityAvailable) need(!(a.pid===b.pid&&a.threadId===b.threadId&&a.startedAt===b.startedAt),'Reused diagnostic process interval');
    const map=mapImage(full.image.bytes.toString('utf8'));
    output.mapping={imageSha256:G50,publicBodyCount:map.aliases.size,declarationCount:map.declarations.size,omissions:map.omissions};
    const f=summarizeProfile(full.profile,full.image.path,map), s=summarizeProfile(screen.profile,screen.image.path,map);
    output.full={evidence:full.identity,...f};output.screen={evidence:screen.identity,...s};
    const tv=f.sampledMs>0&&s.sampledMs>0?f.families.reduce((sum,row,i)=>sum+Math.abs(row.selfShare-s.families[i]!.selfShare),0)/2:null;
    const absent=f.families.filter((row,i)=>row.selfShare!==null&&row.selfShare>=0.05&&s.families[i]!.selfSamples===0).map(row=>row.family);
    const adequate=f.samples>=1000&&s.samples>=1000&&f.sampledMs>0&&s.sampledMs>0;
    const unclassified={full:f.families.find(x=>x.family==='unclassified')!.selfShare,screen:s.families.find(x=>x.family==='unclassified')!.selfShare};
    output.comparison={totalVariation:tv,absentFullFamiliesAtLeastFivePercent:absent,unclassified,
      gates:{sampleCounts:adequate?'PASS':'INCONCLUSIVE',totalVariation:tv===null?'INCONCLUSIVE':tv<=0.20?'PASS':'FAIL',familyPresence:absent.length?'FAIL':'PASS',unclassified:unclassified.full===null||unclassified.screen===null?'INCONCLUSIVE':Math.max(unclassified.full,unclassified.screen)<=0.20?'PASS':'INCONCLUSIVE',evidenceBinding:output.omissions.length?'INCONCLUSIVE':'PASS'}};
    // Evidence/sample insufficiency takes priority over potentially unstable TV.
    output.status=!adequate||output.omissions.length||unclassified.full===null||unclassified.screen===null||Math.max(unclassified.full,unclassified.screen)>0.20?'INCONCLUSIVE':tv!==null&&tv<=0.20&&!absent.length?'PASS':'FAIL';
  } catch(error) {
    output.status=(error as NodeJS.ErrnoException).code==='ENOENT'?'INCONCLUSIVE':'FAIL';
    output.errors.push(String(error));
  }
  return output;
}

if(import.meta.main) {
  const args=process.argv.slice(2);
  if(args.length!==2) throw Error('Usage: bun evals/selfhost_corpus_cpu.ts PLAN.json FRESH-REPORT.json');
  const report=analyzeCpuCoverage(args[0]!);
  // wx intentionally refuses existing reports, including a symlink destination.
  writeFileSync(resolve(args[1]!),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
  console.log(JSON.stringify({status:report.status,report:resolve(args[1]!)}));
  process.exitCode=report.status==='PASS'?0:report.status==='FAIL'?1:2;
}
