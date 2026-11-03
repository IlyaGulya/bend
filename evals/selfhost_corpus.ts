/** Static-only whole-module corpus inventory. Usage:
 * bun evals/selfhost_corpus.ts PLAN.json FRESH-OUT.json
 * Paths in PLAN are relative to PLAN, except universe file paths (relative to
 * sourceUniverse.directory). Workload roots must be in cwd or that universe.
 * Output references fresh sibling ordinary corpus manifests; no AST is emitted.
 */
import {readFileSync, realpathSync, writeFileSync, lstatSync} from 'node:fs';
import {basename, dirname, isAbsolute, relative, resolve, sep} from 'node:path';
import {createHash} from 'node:crypto';
import {corpusFor, hashPath, workloadRows} from './native_seed_runtime.mjs';
import {sourceOracle, type RawDeclaration, type Parameter} from './bootstrap_source_oracle.ts';

type Counts = Record<string, number>;
type UniverseFile = {path:string; sha256:string; namespace?:string; external?:boolean};
type Candidate = {id:string; root:string; role:string};
type Plan = {schemaVersion:1; sourceUniverse:{directory:string; officialCommit:string; files:UniverseFile[]}; candidates:Candidate[]; fullRoot?:string; wrappers?:string[]; observerStage0?:{file:string;sha256:string}};
type SourceRow = {file:string; path:string; sha256:string; namespace:string};
type ExternalRow = {file:string; path:string; sha256:string};
type Rows = {directory:string; root:string; sources:SourceRow[]; externals:ExternalRow[]};
const digest = (bytes:Uint8Array|string) => createHash('sha256').update(bytes).digest('hex');
const increment = (counts:Counts, key:string|number, amount=1) => { counts[key] = (counts[key] ?? 0) + amount; };
const emptyCounts = ():Counts => Object.create(null);
function fail(message:string):never { throw Error(message); }
function text(value:unknown, label:string):asserts value is string {
  if(typeof value !== 'string' || !value.length) fail('Expected nonempty '+label);
}
function within(directory:string, file:string):boolean {
  const path = relative(directory,file);
  return path !== '' && path !== '..' && !path.startsWith('..'+sep) && !isAbsolute(path);
}
function fresh(file:string):void {
  try { lstatSync(file); } catch(error) {
    if((error as NodeJS.ErrnoException).code === 'ENOENT') return;
    throw error;
  }
  fail('Output must be fresh (including symlinks): '+file);
}
function sourceText(file:string):string {
  const bytes = readFileSync(file), source = bytes.toString('utf8');
  if(!Buffer.from(source,'utf8').equals(bytes)) fail('Source is not lossless UTF-8: '+file);
  return source;
}
function validatePlan(value:any):asserts value is Plan {
  if(!value || value.schemaVersion !== 1 || !value.sourceUniverse || !Array.isArray(value.sourceUniverse.files)
    || !Array.isArray(value.candidates) || value.candidates.length === 0) fail('Expected schemaVersion 1, sourceUniverse.files and nonempty candidates');
  text(value.sourceUniverse.directory,'sourceUniverse.directory');
  text(value.sourceUniverse.officialCommit,'sourceUniverse.officialCommit');
  const ids = new Set<string>();
  for(const candidate of value.candidates) {
    if(!candidate || typeof candidate !== 'object') fail('Invalid candidate');
    text(candidate.id,'candidate id'); text(candidate.root,'candidate root'); text(candidate.role,'candidate role');
    if(!/^[A-Za-z0-9][A-Za-z0-9_-]*$/.test(candidate.id) || candidate.id === 'full') fail('Candidate id must be filename-safe and not reserved full: '+candidate.id);
    if(ids.has(candidate.id)) fail('Duplicate candidate id: '+candidate.id);
    ids.add(candidate.id);
  }
  if(value.fullRoot !== undefined) text(value.fullRoot,'fullRoot');
  if(value.wrappers !== undefined && !Array.isArray(value.wrappers)) fail('Expected optional wrappers array');
  if(value.observerStage0 !== undefined) {
    text(value.observerStage0.file,'observerStage0.file');
    if(!/^[a-f0-9]{64}$/.test(value.observerStage0.sha256)) fail('Expected observerStage0 SHA-256');
  }
  for(const row of value.sourceUniverse.files) {
    if(!row || typeof row !== 'object') fail('Invalid universe row');
    text(row.path,'universe path'); text(row.sha256,'universe sha256');
    if(!/^[a-f0-9]{64}$/.test(row.sha256)) fail('Expected lowercase SHA-256 for '+row.path);
    if(row.namespace !== undefined && typeof row.namespace !== 'string') fail('Invalid namespace: '+row.path);
    if(row.external !== undefined && typeof row.external !== 'boolean') fail('Invalid external marker: '+row.path);
  }
}
const moduleImport = /^import\s+(\S+)(?:\s+as\s+[A-Za-z_]\w*)?\s*(?:#.*)?$/;
const foreignImport = /^\s*import\s+"([^"]+\.(?:js|c))"\s*$/;
function wrapperOnly(source:string):boolean {
  let imports=0;
  for(const line of source.split('\n')) {
    if(!line.trim() || line.trimStart().startsWith('#')) continue;
    const match=moduleImport.exec(line);
    if(!match || (match[1] !== 'Base' && !match[1]!.endsWith('.bend')) || match[1]!.startsWith('"')) return false;
    imports++;
  }
  return imports > 0;
}
function family(path:string, wrapper:boolean, external=false):string {
  if(wrapper) return 'wrapper';
  if(external) return 'foreign-js';
  const name=basename(path);
  if(/checker|checked_frontend|scope_lookup|index_lookup/.test(name)) return 'checker-arena-ir';
  if(/parser|lexer|compiler-root/.test(name)) return 'parser-lexer';
  if(/template/.test(name)) return 'template';
  if(/backend|emitter|emit|descriptor|lower|layout|cps|region/.test(name)) return 'bir-lowering-emitter';
  if(/^(base|ast|core|path|sha256|loaded_module)\.bend$/.test(name)) return 'foundation';
  return 'other';
}
function distribution(values:number[]) {
  const histogram=emptyCounts();
  for(const value of values) increment(histogram,value === 0 ? '0' : '2^'+Math.floor(Math.log2(value)));
  const sorted=values.slice().sort((a,b)=>a-b);
  const percentile=(fraction:number)=>sorted.length ? sorted[Math.ceil(fraction*sorted.length)-1]! : null;
  return {count:values.length, histogram, p50:percentile(.5), p90:percentile(.9), p99:percentile(.99), max:sorted.at(-1) ?? null};
}
const syntaxTags=new Set(['Var','Ref','Sub','Let','Typ','Qnt','Qua','Min','All','Lam','App','ADT','Ctr','Lit','Mat','Efq','Eql','Rfl','Rwt','Hol','Ann','PVar','PCtr','Match','Local','None','Lone','Many']);
const quantityTags=new Set(['None','Lone','Many']);
/** Object-identity inventory of authentic observed syntax, never HOAS execution.
 * Span objects and derived constructor HTerms are not source syntax. Nested raw
 * blocks and their parser-flattened term representations are both observations:
 * counts are explicitly an observation-graph vector, not lexical token counts.
 */
function syntaxInventory(declaration:RawDeclaration) {
  const roots:unknown[]=[], issues:string[]=[];
  const parameters=(rows:Parameter[]|undefined) => {
    for(const row of rows ?? []) roots.push(row[0],row[3]);
  };
  parameters(declaration.signature?.parameters); parameters(declaration.parameters);
  roots.push(declaration.signature?.result,declaration.kindTerm,declaration.body,declaration.lawType);
  for(const row of declaration.clauses ?? []) roots.push(row[1],row[4]);
  for(const constructor of declaration.constructors ?? []) parameters(constructor.fields);
  roots.push(...declaration.blocks);
  if(declaration.signature?.declaredType && !declaration.signature.parameters)
    issues.push('Law-completion signature is HOAS-only; not replayed');
  const tags=emptyCounts(), quantities=emptyCounts(), constructorArities=emptyCounts();
  const depths=new Map<object,number>(), active=new Set<object>();
  let functions=0, localBindings=0, matchRows=0, references=0, qualifiedReferences=0;
  const children=(value:object):unknown[] => Array.isArray(value) ? value : Object.entries(value).filter(([key])=>key !== 's').map(([,child])=>child);
  for(const root of roots) {
    if(!root || typeof root !== 'object' || depths.has(root)) continue;
    const stack:{value:object; exit:boolean}[]=[{value:root,exit:false}];
    while(stack.length) {
      const {value,exit}=stack.pop()!;
      if(depths.has(value)) continue;
      const node=value as Record<string,any>;
      if(exit) {
        let depth=0;
        for(const child of children(value)) if(child && typeof child === 'object') depth=Math.max(depth,depths.get(child) ?? 0);
        const tag=typeof node.$ === 'string' ? node.$ : undefined;
        depths.set(value,depth+(tag && !quantityTags.has(tag) ? 1 : 0)); active.delete(value);
        continue;
      }
      if(active.has(value)) { issues.push('Cyclic observation graph'); continue; }
      active.add(value); stack.push({value,exit:true});
      if(typeof node.$ === 'string') {
        increment(tags,node.$);
        if(!syntaxTags.has(node.$)) issues.push('Unknown syntax constructor: '+node.$);
        if(quantityTags.has(node.$)) increment(quantities,node.$);
        if(node.$ === 'Local') localBindings+=node.k.length;
        if(node.$ === 'Match') matchRows+=node.r.length;
        if(node.$ === 'Ctr' || node.$ === 'PCtr') increment(constructorArities,node.x.length);
        if(node.$ === 'Var' || node.$ === 'Ref') {
          references++;
          if(typeof node.k === 'string' && /[/.]/.test(node.k)) qualifiedReferences++;
        }
      }
      for(const child of children(value)) {
        if(typeof child === 'function') functions++;
        else if(child && typeof child === 'object' && !depths.has(child)) stack.push({value:child,exit:false});
      }
    }
  }
  if(functions) issues.push('Unobserved callable syntax fields: '+functions);
  let depth=0;
  for(const root of roots) if(root && typeof root === 'object') depth=Math.max(depth,depths.get(root) ?? 0);
  return {tags,quantities,constructorArities,depth,localBindings,matchRows,references,qualifiedReferences,issues:[...new Set(issues)]};
}
function diagnostic(error:unknown):string {
  if(error instanceof Error) return error.message;
  if(error && typeof error === 'object') {
    const value=error as Record<string,unknown>;
    return JSON.stringify({tag:value.$,expected:value.exp,detected:value.got});
  }
  return String(error);
}

export async function materialize(planPath:string, outputPath:string) {
  const planFile=realpathSync(planPath), planBytes=readFileSync(planFile), plan:unknown=JSON.parse(planBytes.toString('utf8'));
  validatePlan(plan);
  const output=resolve(outputPath), planDirectory=dirname(planFile), repository=realpathSync('.');
  fresh(output);
  const universeDirectory=realpathSync(resolve(planDirectory,plan.sourceUniverse.directory));
  const observerStage0=plan.observerStage0 ? realpathSync(resolve(planDirectory,plan.observerStage0.file)) : undefined;
  if(observerStage0 && (!within(universeDirectory,observerStage0) || hashPath(observerStage0) !== plan.observerStage0!.sha256))
    fail('Frozen observer source escaped universe or changed');
  const universe=new Map<string,UniverseFile & {file:string; bytes:number}>();
  const universeReal=new Set<string>();
  for(const row of plan.sourceUniverse.files) {
    if(isAbsolute(row.path) || row.path !== relative(universeDirectory,resolve(universeDirectory,row.path))) fail('Universe paths must be canonical repository-relative: '+row.path);
    const file=realpathSync(resolve(universeDirectory,row.path));
    if(!within(universeDirectory,file)) fail('Universe input escaped repository: '+file);
    if(universe.has(row.path) || universeReal.has(file)) fail('Duplicate universe source: '+row.path);
    const bytes=readFileSync(file);
    if(digest(bytes) !== row.sha256) fail('Stale declared universe hash: '+row.path);
    universe.set(row.path,{...row,file,bytes:bytes.length}); universeReal.add(file);
  }
  const specifications=[...plan.candidates.map(candidate=>({...candidate,kind:'screen' as const})),
    ...(plan.fullRoot ? [{id:'full',root:plan.fullRoot,role:'full-reference',kind:'full' as const}] : [])];
  const children=specifications.map(spec=>resolve(dirname(output),basename(output)+'.'+spec.id+'.corpus.json'));
  for(const child of children) fresh(child);
  const declaredWrappers=new Set((plan.wrappers ?? []).map(file=>{
    text(file,'wrapper path');
    return realpathSync(resolve(planDirectory,file));
  }));
  const prepared=specifications.map((spec,index)=>{
    const root=realpathSync(resolve(planDirectory,spec.root));
    const directory=within(repository,root) ? repository : within(universeDirectory,root) ? universeDirectory : fail('Root escaped both declared repositories: '+root);
    let rows:Rows;
    try { process.chdir(directory); rows=workloadRows(root,'js'); } finally { process.chdir(repository); }
    const namespaces=new Map<string,string>(), wrappers:{path:string;sha256:string;bytes:number;source:string}[]=[];
    const identities:any[]=[];
    for(const row of [...rows.sources,...rows.externals]) {
      const bytes=readFileSync(row.file), actual=digest(bytes), original=universe.get(row.path);
      if(actual !== row.sha256) fail('Workload bytes changed or were decoded lossily: '+row.path);
      if(original) {
        if(actual !== original.sha256) fail('Workload does not match authenticated universe: '+row.path);
        if(original.external !== undefined && original.external !== !('namespace' in row)) fail('Source/foreign role conflict: '+row.path);
        identities.push({path:row.path,file:row.file,original:original.file,sha256:actual,bytes:bytes.length,
          universeNamespace:original.namespace ?? null,namespace:'namespace' in row ? row.namespace : null});
      } else if(row.file !== root || !('namespace' in row) || !wrapperOnly(sourceText(row.file))) {
        fail('Missing universe authentication for non-wrapper source: '+row.path);
      }
      if(row.file === root && wrapperOnly(sourceText(row.file))) {
        wrappers.push({path:row.path,sha256:actual,bytes:bytes.length,source:sourceText(row.file)});
      } else if(declaredWrappers.has(row.file)) {
        fail('Declared wrapper must be an import-only workload root: '+row.file);
      }
      if('namespace' in row && row.namespace !== '') {
        const prior=namespaces.get(row.namespace);
        if(prior && prior !== row.file) fail('Namespace shared by distinct source files: '+row.namespace);
        namespaces.set(row.namespace,row.file);
      }
    }
    // Fail closed for syntax the canonical lexical workload walker would omit.
    // This is an import safety check, never syntax-fingerprint authority.
    for(const row of rows.sources) for(const line of sourceText(row.file).split('\n')) {
      if(!/^\s*import(?:\s|$)/.test(line)) continue;
      const foreign=foreignImport.exec(line);
      if(foreign) continue;
      const imported=moduleImport.exec(line);
      if(!imported || imported[1] !== 'Base' && !/^(?:\/|(?:\.\.?\/)*)(?:[A-Za-z_][\w-]*\/)*[A-Za-z_][\w-]*\.bend$/.test(imported[1]!))
        fail('Import unsupported by exact workload closure (no omission or Hub access): '+row.file+': '+line);
    }
    return {spec,rows,identities,wrappers,child:children[index]!};
  });
  for(const wrapper of declaredWrappers) if(!prepared.some(item=>item.rows.root === wrapper && item.wrappers.length > 0))
    fail('Declared wrapper is not a selected import-only root: '+wrapper);
  // sourceOracle only exposes root declarations; cache each real root once across
  // candidates. Dependencies still load through its unmodified authentic loader.
  const cache=new Map<string,any>();
  async function fingerprintModule(row:SourceRow, rows:Rows) {
    const cached=cache.get(row.file); if(cached) return cached;
    const source=sourceText(row.file), issues:string[]=[];
    const module:any={path:row.path,sha256:row.sha256,bytes:Buffer.byteLength(source),status:'INCONCLUSIVE',issues,
      declarations:[],imports:[],constructorTags:emptyCounts(),quantities:emptyCounts(),parameterArities:emptyCounts(),
      constructorFieldArities:emptyCounts(),constructorUseArities:emptyCounts(),declarationKinds:emptyCounts(),locals:0,matches:0,localBindings:0,matchRows:0,references:0,qualifiedReferences:0};
    try {
      const oracle=await sourceOracle(row.file,source,{recordInputs:true,stage0File:observerStage0});
      if(plan.observerStage0 && oracle.observation.stage0Sha256 !== plan.observerStage0.sha256)
        fail('Observed compiler source differs from frozen observer');
      module.observation=oracle.observation; module.exclusions=oracle.exclusions;
      module.loaderInputs=oracle.inputFiles; module.loadContexts=oracle.loadContexts;
      module.imports=oracle.imports;
      if(!oracle.accepted) { module.status='INVALID'; issues.push(diagnostic(oracle.error)); module.failure=oracle.failure; }
      // Base may come from the oracle's own checkout; authenticate its exact
      // relative source identity and bytes rather than silently trusting it.
      const closure=new Set(rows.sources.map(item=>item.path));
      for(const input of oracle.inputFiles) {
        const home=within(repository,input.file) ? repository : within(universeDirectory,input.file) ? universeDirectory : undefined;
        const path=home ? relative(home,input.file) : undefined;
        const declared=path ? universe.get(path) : undefined;
        if(input.file === row.file && input.sha256 === row.sha256) continue;
        if(!path || !closure.has(path) || !declared || declared.sha256 !== input.sha256 || input.sourceSha256 !== input.sha256)
          issues.push('Oracle loaded input outside authenticated workload: '+input.file);
      }
      const declaredJS=new Set<string>();
      for(const declaration of oracle.declarations) {
        const syntax=syntaxInventory(declaration);
        const arity=declaration.signature?.parameters?.length ?? declaration.parameters?.length ?? declaration.vars?.length ?? declaration.clauses?.filter(clause=>!clause[0]).length ?? 0;
        const bytes=Buffer.byteLength(source.slice(declaration.beg,declaration.end));
        module.declarations.push({key:declaration.key,kind:declaration.kind,beg:declaration.beg,end:declaration.end,bytes,arity,depth:syntax.depth,
          template:declaration.template ?? false,unsafe:declaration.unsafe ?? false,syntaxIssues:syntax.issues});
        increment(module.parameterArities,arity); increment(module.declarationKinds,declaration.kind);
        for(const [tag,count] of Object.entries(syntax.tags)) increment(module.constructorTags,tag,count);
        for(const [tag,count] of Object.entries(syntax.quantities)) increment(module.quantities,tag,count);
        for(const [arity,count] of Object.entries(syntax.constructorArities)) increment(module.constructorUseArities,arity,count);
        for(const constructor of declaration.constructors ?? []) increment(module.constructorFieldArities,constructor.fields.length);
        module.locals+=syntax.tags.Local ?? 0; module.matches+=syntax.tags.Match ?? 0;
        module.localBindings+=syntax.localBindings; module.matchRows+=syntax.matchRows;
        module.references+=syntax.references; module.qualifiedReferences+=syntax.qualifiedReferences;
        issues.push(...syntax.issues.map(issue=>declaration.key+': '+issue));
        for(const imported of declaration.nativeImports ?? []) if(imported.endsWith('.js')) declaredJS.add(realpathSync(resolve(dirname(row.file),imported)));
      }
      const externalFiles=new Set(rows.externals.map(item=>item.file));
      for(const file of declaredJS) if(!externalFiles.has(file)) issues.push('Authentic parser JS alternative absent from workload: '+file);
      module.foreignJSAlternatives=[...declaredJS].sort();
      for(const imported of oracle.imports) if(!imported.resolved) issues.push('Unresolved authentic import: '+imported.path);
      if(oracle.accepted) module.status=issues.length ? 'INCONCLUSIVE' : 'VALID';
    } catch(error) { module.status='INVALID'; issues.push(diagnostic(error)); }
    module.declarationBytes=distribution(module.declarations.map((item:any)=>item.bytes));
    module.declarationDepth=distribution(module.declarations.map((item:any)=>item.depth));
    cache.set(row.file,module); return module;
  }
  const corpora:any[]=[];
  for(const item of prepared) {
    const modules:any[]=[], families:Record<string,any>=Object.create(null), constructorTags=emptyCounts();
    for(const row of item.rows.sources) {
      const module=await fingerprintModule(row,item.rows), group=family(row.path,item.wrappers.some(wrapper=>wrapper.path === row.path));
      modules.push({...module,family:group,namespace:row.namespace});
      const stats=families[group] ??= {modules:0,bytes:0,declarations:0,declarationKinds:emptyCounts(),moduleByteHistogram:emptyCounts(),moduleDeclarationHistogram:emptyCounts()};
      stats.modules++; stats.bytes+=module.bytes; stats.declarations+=module.declarations.length;
      increment(stats.moduleByteHistogram,module.bytes); increment(stats.moduleDeclarationHistogram,module.declarations.length);
      for(const [kind,count] of Object.entries(module.declarationKinds)) increment(stats.declarationKinds,kind,count as number);
      for(const [tag,count] of Object.entries(module.constructorTags)) increment(constructorTags,tag,count as number);
    }
    const foreignFiles=item.rows.externals.map(row=>({...row,bytes:readFileSync(row.file).length,family:'foreign-js'}));
    const foreignBytes=foreignFiles.reduce((sum,row)=>sum+row.bytes,0), foreignByteHistogram=emptyCounts();
    for(const row of foreignFiles) increment(foreignByteHistogram,row.bytes);
    families['foreign-js']={files:foreignFiles.length,bytes:foreignBytes,fileByteHistogram:foreignByteHistogram,declarations:null};
    const status=modules.some(module=>module.status === 'INVALID') ? 'INVALID' : modules.some(module=>module.status !== 'VALID') ? 'INCONCLUSIVE' : 'VALID';
    const manifest={...corpusFor(item.rows),officialCommit:plan.sourceUniverse.officialCommit};
    const manifestText=JSON.stringify(manifest,null,2)+'\n';
    corpora.push({id:item.spec.id,kind:item.spec.kind,role:item.spec.role,manifest:basename(item.child),manifestSha256:digest(manifestText),
      provenance:{sourceUniverseDirectory:universeDirectory,officialCommit:plan.sourceUniverse.officialCommit,identities:item.identities,wrappers:item.wrappers},
      fingerprint:{status,structuralStatus:'INCONCLUSIVE',authority:'bootstrap_source_oracle.sourceOracle; authentic stage0 static observation only',
        counting:'Unique objects per declaration across observed signature/body/nested-block AST roots; includes parser-flattened nested term representations, not source-token frequencies. Depth counts non-quantity tagged objects along longest observation path.',
        limitations:['No checker, normalizationBook, target execution or timing AST reuse.','VALID means complete static observation only, not structural representativeness or native-parser acceptance.',
          'Source families are explicit filename categories, not inferred execution costs.','Declarations retain authentic UTF-16 boundaries; byte lengths include any parser-consumed trailing trivia.','Derived constructor HTerms excluded: original fields and datatype kind are observed instead.'],
        modules,families,constructorTags,bendModules:modules.length,declarations:modules.reduce((sum,module)=>sum+module.declarations.length,0),
        bendBytes:modules.reduce((sum,module)=>sum+module.bytes,0),foreignFiles,foreignBytes},_manifestText:manifestText});
  }
  // Reauthenticate after static loading, before publishing immutable outputs.
  for(const row of universe.values()) if(hashPath(row.file) !== row.sha256) fail('Universe changed while observing: '+row.file);
  if(observerStage0 && hashPath(observerStage0) !== plan.observerStage0!.sha256) fail('Frozen observer changed while observing');
  for(const item of prepared) for(const row of [...item.rows.sources,...item.rows.externals]) if(hashPath(row.file) !== row.sha256) fail('Workload changed while observing: '+row.file);
  for(let index=0;index<corpora.length;index++) {
    writeFileSync(children[index]!,corpora[index]._manifestText,{flag:'wx'}); delete corpora[index]._manifestText;
  }
  const result={schemaVersion:1,plan:{file:planFile,sha256:digest(planBytes)},sourceUniverse:{directory:universeDirectory,
    officialCommit:plan.sourceUniverse.officialCommit,files:plan.sourceUniverse.files},tool:{file:import.meta.path,sha256:hashPath(import.meta.path),
    oracleSha256:hashPath(resolve(import.meta.dir,'bootstrap_source_oracle.ts')),workloadRowsSha256:hashPath(resolve(import.meta.dir,'native_seed_runtime.mjs')),
    observerStage0:observerStage0 ? {file:observerStage0,sha256:hashPath(observerStage0)} : null},
    status:corpora.some(corpus=>corpus.fingerprint.status === 'INVALID') ? 'INVALID' : corpora.some(corpus=>corpus.fingerprint.status !== 'VALID') ? 'INCONCLUSIVE' : 'VALID',corpora};
  writeFileSync(output,JSON.stringify(result,null,2)+'\n',{flag:'wx'});
  return result;
}
if(import.meta.main) {
  try {
    const args=process.argv.slice(2);
    if(args.length !== 2) fail('Usage: bun evals/selfhost_corpus.ts PLAN.json FRESH-OUT.json');
    const result=await materialize(args[0]!,args[1]!);
    console.log(JSON.stringify({output:resolve(args[1]!),status:result.status,corpora:result.corpora.map(corpus=>({id:corpus.id,manifest:corpus.manifest,status:corpus.fingerprint.status}))}));
    if(result.status !== 'VALID') process.exitCode=2;
  } catch(error) { console.error('selfhost_corpus: '+diagnostic(error)); process.exitCode=1; }
}
