import * as B from '../bend2/bend.ts';
import * as Normal from '../bend2/comp.ts';
import * as Variant from '../bend2/.comp_js_storage_probe.ts';
import {replayKernel} from './load_replay_kernel.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {dlopen,FFIType,ptr} from 'bun:ffi';
import {mkdtempSync,writeFileSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {createHash} from 'node:crypto';
await guardHeavyGate(import.meta.path,{label:'Exact JS release-e fixtures and large-definition retention'});
const report='/Users/ilyagulya/Projects/My/bend/checkpoints/js-storage-release-e.json';
const lib=dlopen('/tmp/bend-artifact-phase-memory.dylib',{artifact_memory:{args:[FFIType.ptr],returns:FFIType.i32}});
function memory(){const m=new BigUint64Array(2);if(lib.symbols.artifact_memory(ptr(m)))throw Error('Memory sampler failed');return {footprintBytes:Number(m[0]),rssBytes:Number(m[1]),heapUsed:process.memoryUsage().heapUsed};}
const dir=mkdtempSync(join(tmpdir(),'bend-js-storage-fixtures-')),fixtures=[];
const sha=(s:string)=>createHash('sha256').update(s).digest('hex');
try{
  for(const [name,source,args,expected] of [
    ['constant','def main() -> Nat:\n  7n\n',[],7n],
    ['callee','def plus(x: Nat) -> Nat:\n  Succ{x}\ndef main(x: Nat) -> Nat:\n  plus(x)\n',[4n],5n],
    ['recursive','def count(x: Nat) -> Nat:\n  match x:\n    case Zero{}: 0n\n    case Succ{n}: Succ{count(n)}\ndef main(x: Nat) -> Nat:\n  count(x)\n',[6n],6n]
  ] as const){
    const file=join(dir,'main.bend');writeFileSync(file,'import Base\n\n'+source);
    const normal=B.book_nil(),variant=B.book_nil();for(const book of [normal,variant]){await B.book_load(book,file,'',new Map());B.book_valid(book);if(book.hols||book.open)throw Error('Incomplete fixture validation');}
    const original=Normal.js_lib(normal,['main'],['main']);Variant.js_storage_release_e(false);const a=Variant.js_storage_prepare(normal,'main');
    Variant.js_storage_release_e(true);const b=Variant.js_storage_prepare(variant,'main'),changed=Variant.js_lib(variant,['main'],['main']);
    if(a?.$!=='Def'||b?.$!=='Def'||!a.h||!b.h)throw Error('Missing prepared fixture h');
    const hEqual=B.term_show(B.term_lower(a.h))===B.term_show(B.term_lower(b.h));
    if(!hEqual||a.n!==b.n||original!==changed)throw Error('Fixture preparation/JS difference '+name);
    const js=join(dir,'normal-'+name+'.js'),js2=join(dir,'release-'+name+'.js');writeFileSync(js,original);writeFileSync(js2,changed);
    const child=Bun.spawn([process.execPath,'--eval',`const a=(await import(${JSON.stringify(js)})).default.main(${args.map(v=>v+'n').join(',')});const b=(await import(${JSON.stringify(js2)})).default.main(${args.map(v=>v+'n').join(',')});if(a!==${expected}n||b!==${expected}n)throw Error("Runtime mismatch");console.log(String(a));`],{stdout:'pipe',stderr:'pipe'});
    const actual=(await new Response(child.stdout).text()).trim(),stderr=await new Response(child.stderr).text();if(await child.exited)throw Error('Fixture runtime failed '+name+': '+stderr);
    fixtures.push({name,nativeValidation:'PASS both',preparedHEqual:hEqual,adjustedNEqual:a.n===b.n,jsBytesEqual:true,jsSha256:sha(original),runtime:actual,expected:String(expected)});
  }
  writeFileSync(report,JSON.stringify({fixtures},null,2)+'\n');
  const kernel=await replayKernel('direct',undefined,{retention:'retain'});
  try{
    const K=kernel.kernel,book=K.book_nil();await K.book_load(book,'bend2/selfhost/.parser_definition_body_shape_generated_fuel.bend','',new Map());const originalOrder=book.order;
    const retention=[];
    for(const name of ['step_parse_term_tail','step_parse_atom_name_dispatch']){
      const index=originalOrder.lastIndexOf(name);if(index<0)throw Error('Missing target');
      book.order=originalOrder.slice(0,index+1);K.book_valid(book,index);book.order=originalOrder;
      let weak:WeakRef<B.LTerm>;
      {const def=book.tlds[name];if(def?.$!=='Def'||!def.e)throw Error('Missing target checked e');let node=def.e;while(node.$==='Ann')node=node.x;weak=new WeakRef(node);}
      await Bun.sleep(0);Bun.gc(true);const before=memory();
      Variant.js_storage_release_e(false);Variant.js_storage_clear_memos();Variant.js_storage_prepare(book,name);const afterPrepare=memory();
      {const def=book.tlds[name];if(def?.$!=='Def')throw Error('Missing prepared target');delete def.e;}
      Variant.js_storage_clear_memos();await Bun.sleep(0);Bun.gc(true);const afterERelease=memory(),backingAliveWithH=weak.deref()!==undefined;
      {const def=book.tlds[name];if(def?.$==='Def')delete def.h;}
      Variant.js_storage_clear_memos();await Bun.sleep(0);Bun.gc(true);const afterHRelease=memory(),backingAliveWithoutH=weak.deref()!==undefined;
      retention.push({name,index,diagnostic:'Target-only native book_valid(done=index), not whole-book acceptance; whole1478 baseline proof separate',before,afterPrepare,afterERelease,backingAliveWithH,afterHRelease,backingAliveWithoutH});
      writeFileSync(report,JSON.stringify({fixtures,retention},null,2)+'\n');
    }
  }finally{kernel.close();}
}finally{rmSync(dir,{recursive:true,force:true});}
console.log(await Bun.file(report).text());
