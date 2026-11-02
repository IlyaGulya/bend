#!/usr/bin/env bun
/** Fast development oracle, NOT native bootstrap/fixedpoint/qualification.
 * Fresh canonical TS book loading + all-body validation + optional JS library.
 * No serialized ASTs, checked-program replay, body exclusions or output patches.
 * bun --smol evals/selfhost_fast.ts --repository=REPO --source=FILE.bend
 *   --out=FRESH_DIR [--exports=start,step --node=NODE] [--check-only]
 * Use --memory-mib=8192 --rss-mib=8192 --poll-ms=10 --timeout-ms=120000
 * for deep JS production. All-body checks stay on the current runtime.
 */
import {createHash} from 'node:crypto';
import {spawn} from 'node:child_process';
import {existsSync,mkdirSync,readFileSync,realpathSync,writeFileSync} from 'node:fs';
import {resolve,join} from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {isMainThread} from 'node:worker_threads';
import {guardHeavyGate} from './heavy_gate.ts';
import type * as Bend from '../bend2/bend.ts';
import type * as Comp from '../bend2/comp.ts';

await guardHeavyGate(fileURLToPath(import.meta.url),{label:'Selfhost fast TS source oracle, not qualification'});
const values=new Map<string,string>();let checkOnly=false;
for(const argument of process.argv.slice(2)){
 if(argument==='--check-only'){if(checkOnly)throw Error('duplicate --check-only');checkOnly=true;continue;}
 const at=argument.indexOf('='),key=argument.slice(0,at),value=argument.slice(at+1);
 if(at<0||!['--repository','--source','--out','--exports','--node'].includes(key)||!value||values.has(key))throw Error('Expected unique documented --option=value');
 values.set(key,value);
}
for(const key of ['--source','--out'])if(!values.has(key))throw Error('Missing '+key);
if(checkOnly&&values.has('--exports'))throw Error('--check-only does not emit exports');
const repository=realpathSync(resolve(values.get('--repository')??'.'));
const source=realpathSync(resolve(repository,values.get('--source')!));
const directory=resolve(values.get('--out')!);
if(existsSync(directory))throw Error('Use a fresh output directory: '+directory);
const exports_=values.has('--exports')?values.get('--exports')!.split(','):undefined;
if(exports_&&(!exports_.every(Boolean)||new Set(exports_).size!==exports_.length))throw Error('Exports must be nonempty and distinct');
// JS lowering has deep checked terms: reuse the existing bounded V8 worker,
// while plain all-body checks stay on the low-startup-cost Bun path.
if(!checkOnly&&isMainThread){
 const node=values.get('--node')??(process.versions.bun?undefined:process.execPath);
 if(!node)throw Error('JS oracle emission needs --node=PATH; --check-only uses the current runtime');
 const child=spawn(realpathSync(resolve(node)),['--experimental-strip-types',
  fileURLToPath(new URL('./candidate_consumer_worker.mjs',import.meta.url)),
  fileURLToPath(import.meta.url),...process.argv.slice(2)],{stdio:'inherit'});
 const code=await new Promise<number>((done,fail)=>{child.once('error',fail);child.once('close',(value,signal)=>signal?fail(Error('Oracle worker stopped: '+signal)):done(value??1));});
 process.exit(code);
}
mkdirSync(directory,{recursive:true});
const hash=(path:string)=>createHash('sha256').update(readFileSync(path)).digest('hex');
const save=(name:string,value:unknown)=>writeFileSync(join(directory,name),JSON.stringify(value,null,2)+'\n',{flag:'wx'});
const kernel=join(repository,'bend2/bend.ts'),compiler=join(repository,'bend2/comp.ts');
const timings:Record<string,number>={},inputs:Record<string,string>={[kernel]:hash(kernel),[compiler]:hash(compiler)};
const started=performance.now();let K:typeof Bend|undefined,checkedDefinitions=0,modules=0;
const base={schemaVersion:1,kind:'selfhost-fast-ts-oracle',acceptanceEvidence:false,nativeCompiler:false,
 byteFixedpointClaim:false,source,repository,checkOnly,exports:exports_??null,
 runtime:{versions:process.versions,executable:process.execPath,execArgv:process.execArgv},
 scope:'Fresh TS canonical source check and JS oracle; never substitutes native parsing/checking/emission or final consumer gates'};
try{
 let at=performance.now();K=await import(pathToFileURL(kernel).href) as typeof Bend;
 const C=checkOnly?undefined:await import(pathToFileURL(compiler).href) as typeof Comp;
 timings.importMs=performance.now()-at;
 const book=K.book_nil();
 class Inputs extends Map<string,string|null>{override set(path:string,namespace:string|null){if(namespace===null)inputs[path]=hash(path);return super.set(path,namespace);}}
 const seen=new Inputs();at=performance.now();await K.book_load(book,source,'',seen);
 timings.loadMs=performance.now()-at;modules=seen.size;at=performance.now();
 K.book_valid(book);
 if(book.hols)throw Error('Canonical source validation left holes');
 for(const definition of Object.values(book.tlds))if(definition.$==='Def'&&definition.v!==null){
  checkedDefinitions++;if(definition.e===undefined)throw Error('Missing canonical checked body');
 }
 timings.checkMs=performance.now()-at;
 let output:string|undefined,outputBytes:number|undefined,outputSha256:string|undefined;
 if(C){
  at=performance.now();const js=C.js_lib(book,true,exports_?{exports:exports_}:{});
  timings.emitJsMs=performance.now()-at;output=join(directory,'oracle.mjs');
  writeFileSync(output,js,{flag:'wx'});outputBytes=Buffer.byteLength(js);outputSha256=hash(output);
 }
 for(const [path,digest]of Object.entries(inputs))if(hash(path)!==digest)throw Error('Source input changed during fast oracle: '+path);
 const result={...base,status:'FAST_ORACLE_PASS',checkedDefinitions,modules,timings,wallMs:performance.now()-started,
  loadedInputs:inputs,output,outputBytes,outputSha256};
 save('receipt.json',result);console.log(JSON.stringify({status:result.status,acceptanceEvidence:false,checkedDefinitions,modules,timings,wallMs:result.wallMs,output,outputBytes}));
}catch(error){
 const message=K&&error&&typeof error==='object'&&'$'in error&&error.$==='Err'?K.err_show(error as Bend.Err):String(error);
 save('receipt.json',{...base,status:'FAST_ORACLE_FAIL',checkedDefinitions,modules,timings,wallMs:performance.now()-started,loadedInputs:inputs,error:message});
 console.error(message);process.exitCode=1;
}
