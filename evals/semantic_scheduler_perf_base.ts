import {createHash} from 'node:crypto';
import {mkdirSync,readFileSync,realpathSync,writeFileSync} from 'node:fs';
import {basename,dirname,relative,resolve} from 'node:path';
import {sourceOracle,type RawDeclaration} from './bootstrap_source_oracle.ts';

/** Exact source-declaration closure, not replacement implementations or checked AST replay.
 * FFI paths are relocated to the same original files; retained declarations otherwise stay byte-exact.
 * Canonical full-Base C/stdout and native reduced-Base runs are separate evidence.
 */
export async function sliceSemanticSchedulerBase(sourcePath:string,basePath:string,outPath:string){
 const source=realpathSync(resolve(sourcePath)),base=realpathSync(resolve(basePath));
 // lower_catalog.base_source authenticates native scalar/IO markers by this module identity.
 if(!resolve(outPath).split('\\').join('/').endsWith('/bend2/base.bend'))throw Error('Preserve the canonical /bend2/base.bend module suffix for native builtin markers');
 mkdirSync(dirname(resolve(outPath)),{recursive:true});
 const out=resolve(realpathSync(dirname(resolve(outPath))),basename(outPath));
 const text=readFileSync(base,'utf8'),root=await sourceOracle(source,readFileSync(source,'utf8'),{recordInputs:true});
 const prelude=await sourceOracle(base,text,{recordInputs:true});
 if(!root.accepted||!prelude.accepted)throw Error('Canonical parser did not accept slice inputs');
 if(prelude.imports.length)throw Error('Prelude module imports need explicit closure handling');
 const hash=(value:string|Uint8Array)=>createHash('sha256').update(value).digest('hex');
 const declarations=new Map<string,RawDeclaration[]>(),constructors=new Map<string,string>();
 for(const d of prelude.declarations){const rows=declarations.get(d.key)??[];rows.push(d);declarations.set(d.key,rows);
  for(const c of d.constructors??[])constructors.set(c.key,d.key);}
 function refs(d:RawDeclaration,visit?:(node:any)=>void){
  const result=new Set<string>(),seen=new WeakSet<object>();
  function walk(value:any):void{
   if(!value||typeof value!=='object'||seen.has(value))return;seen.add(value);
   if(Array.isArray(value)){for(const child of value)walk(child);return;}
   visit?.(value);
   if(['Ref','ADT','Ctr','Mat','PCtr'].includes(value.$)&&typeof value.k==='string')result.add(value.k);
   if(value.$==='Var'){if(value.v!==undefined)walk(value.v);return;}
   for(const[key,child]of Object.entries(value))if(key!=='s')walk(child);
  }
  for(const p of d.parameters??[])walk(p[3]);walk(d.kindTerm);
  for(const c of d.constructors??[])for(const p of c.fields)walk(p[3]);
  for(const p of d.signature?.parameters??[])walk(p[3]);walk(d.signature?.result);walk(d.body);
  for(const c of d.clauses??[])walk(c[4]);walk(d.lawBody);walk(d.lawType);
  return result;
 }
 // The C runtime names constructors even when source expressions do not.
 // Derive these implicit roots from the real backend AST, not a second ABI list.
 const runtimeSource=resolve(dirname(base),'selfhost/c_backend.bend'),runtimeText=readFileSync(runtimeSource,'utf8');
 const runtimeOracle=await sourceOracle(runtimeSource,runtimeText,{recordInputs:true});
 const runtimeDeclaration=runtimeOracle.declarations.find(d=>d.kind==='def'&&d.key==='runtime_cid_aliases');
 if(!runtimeOracle.accepted||!runtimeDeclaration)throw Error('Missing authoritative C runtime constructor roots');
 const runtimeConstructors=new Set<string>();
 refs(runtimeDeclaration,node=>{
  if(node.$!=='App')return;const args:any[]=[];let head=node;
  while(head.$==='App'){args.unshift(head.x);head=head.f;}
  if(head.$==='Var'&&head.v?.$==='Ref')head=head.v;
  if(head.$==='Ref'&&head.k==='runtime_cid_alias'&&args.length===3&&args[1].$==='Lit'&&args[1].k==='String')runtimeConstructors.add(args[1].v);
 });
 if(!runtimeConstructors.size||[...runtimeConstructors].some(key=>!constructors.has(key)))throw Error('Runtime ABI roots do not resolve to original Base constructors');
 const runtimeABI={source:runtimeSource,sourceSha256:hash(runtimeText),declaration:runtimeDeclaration.key,
  declarationSha256:hash(runtimeText.slice(runtimeDeclaration.beg,runtimeDeclaration.end)),constructors:[...runtimeConstructors]};
 const retained=new Set<string>(),pending=[...root.declarations.flatMap(d=>[...refs(d)]),...runtimeConstructors];
 while(pending.length){const ref=pending.pop()!,key=constructors.get(ref)??ref;
  if(retained.has(key)||!declarations.has(key))continue;retained.add(key);
  for(const d of declarations.get(key)!)for(const dependency of refs(d))pending.push(dependency);
 }
 const selected=prelude.declarations.filter(d=>retained.has(d.key));
 if(!selected.length)throw Error('Empty prelude closure');
 const foreign:Record<string,string>={},rows:any[]=[];
 const chunks=selected.map(d=>{
  const original=text.slice(d.beg,d.end);let output=original;
  for(const spec of d.nativeImports??[]){
   const target=resolve(dirname(base),spec),moved=relative(dirname(out),target).split('\\').join('/');
   const replacement=moved.startsWith('.')?moved:'./'+moved;
   const originalRelative=relative(dirname(base),target).split('\\').join('/');
   const originalSpec=originalRelative.startsWith('.')?originalRelative:'./'+originalRelative;
   const quoted=JSON.stringify(originalSpec),at=output.indexOf(quoted);
   if(at<0||output.indexOf(quoted,at+quoted.length)>=0)throw Error('Ambiguous native import '+d.key+' '+spec);
   output=output.slice(0,at)+JSON.stringify(replacement)+output.slice(at+quoted.length);
   foreign[target]=hash(readFileSync(target));
  }
  rows.push({key:d.key,kind:d.kind,begin:d.beg,end:d.end,sourceSha256:hash(original),emittedSha256:hash(output),nativeImports:d.nativeImports??[]});
  return output.trimEnd();
 });
 const emitted='# Exact used declaration closure of bend2/base.bend; generated by semantic_scheduler_perf_base.ts.\n'+chunks.join('\n\n')+'\n';
 const receipt={schemaVersion:1,acceptanceEvidence:false,kind:'exact-performance-prelude-source-closure',source,sourceSha256:hash(readFileSync(source)),base,baseSha256:hash(text),out,outputSha256:hash(emitted),bytes:Buffer.byteLength(emitted),originalDeclarations:prelude.declarations.length,retainedDeclarations:selected.length,retainedNames:retained.size,rows,foreign,runtimeABI,
  limitations:['Unused declarations intentionally absent: development fixture only, not original qualification.','Raw parsed declarations drive reference closure; canonical and native source checks must still accept the result.','Only FFI path spelling is relocated; implementation bodies are original bytes.']};
 writeFileSync(out,emitted,{flag:'wx'});return receipt;
}
if(import.meta.main){
 const options=new Map<string,string>();for(const arg of process.argv.slice(2)){const at=arg.indexOf('='),key=arg.slice(0,at),value=arg.slice(at+1);
  if(at<0||!['--source','--base','--out','--receipt'].includes(key)||!value||options.has(key))throw Error('Expected unique --source= --base= --out= --receipt=');options.set(key,value);}
 for(const key of ['--source','--base','--out','--receipt'])if(!options.has(key))throw Error('Missing '+key);
 const receipt=await sliceSemanticSchedulerBase(options.get('--source')!,options.get('--base')!,options.get('--out')!);
 writeFileSync(resolve(options.get('--receipt')!),JSON.stringify(receipt,null,2)+'\n',{flag:'wx'});
 console.log(JSON.stringify({out:receipt.out,retainedDeclarations:receipt.retainedDeclarations,originalDeclarations:receipt.originalDeclarations,bytes:receipt.bytes,outputSha256:receipt.outputSha256}));
}
