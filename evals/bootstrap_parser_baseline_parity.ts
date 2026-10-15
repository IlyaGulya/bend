import {sourceOracle} from './bootstrap_source_oracle.ts';
import {canonicalCore,normalizeCoreBook,normalizeImports} from './parser_full_semantic_normalize.ts';
import type {Value} from './parser_full_semantic_normalize.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {createHash} from 'node:crypto';
import {writeFileSync} from 'node:fs';
await guardHeavyGate(import.meta.path,{label:'Bootstrap real-source accepted artifact normalized AST baseline'});
const manifest=await Bun.file('checkpoints/bootstrap-real-source-corpus.json').json();
function decode(x:any):Value{if(typeof x==='bigint'){const n=Number(x);if(!Number.isSafeInteger(n))throw Error('Unsafe AST Nat');return n;}if(typeof x!=='object'||x===null)return x;if(x.$==='Nil'||x.$==='Con'){const out:Value[]=[];while(x.$==='Con'){out.push(decode(x.head));x=x.tail;}if(x.$!=='Nil')throw Error('Invalid list');return out;}return {tag:x.$.split('.').at(-1),fields:Object.entries(x).filter(([k])=>k!=='$').map(([,v])=>decode(v))};}
function hash(value:unknown){return createHash('sha256').update(JSON.stringify(value)).digest('hex');}
function firstDiff(a:any,b:any,path='$'):any{if(a===b)return null;if(typeof a!==typeof b||a===null||b===null)return {path,expected:a,actual:b};if(typeof a!=='object')return {path,expected:a,actual:b};if(Array.isArray(a)!==Array.isArray(b))return {path,expected:a,actual:b};const ak=Object.keys(a),bk=Object.keys(b);if(ak.join()!==bk.join())return {path,expectedKeys:ak,actualKeys:bk};for(const k of ak){const d=firstDiff(a[k],b[k],path+'/'+k);if(d)return d;}return null;}
const rows=[];
for(const item of manifest.modules){
 const source=await Bun.file(item.snapshot).text(),oracle=await sourceOracle(item.file,source);const row:any={file:item.file,stage0Accepted:oracle.accepted,compiledAccepted:item.compiledBaselineAccepted,compiledFailure:item.compiledBaselineFailure};
 if(oracle.accepted&&item.compiledBaselineAccepted){
  try{
   const raw=JSON.parse(await Bun.file('checkpoints/bootstrap-real-source/'+String(item.id).padStart(2,'0')+'.compiled-ast.json').text(),(_,v)=>v?.$==='$NativeNat'?BigInt(v.value):v);
   const module=decode(raw.module) as any,importNodes=module.fields[1],imports=oracle.imports.map(i=>({path:i.path,alias:i.alias}));
   const adjusted={...module,fields:[module.fields[0],importNodes.map((v:any)=>{const actual=oracle.imports.find(i=>i.alias===v.fields[1]);return {...v,fields:[actual?.namespace||v.fields[0],...v.fields.slice(1)]};}),module.fields[2]]};
   const book=oracle.normalizationBook();
   const names=oracle.declarations.map(d=>d.key);
   const expected=normalizeCoreBook(book,names,imports,item.file).semantic;
   const actual=canonicalCore(adjusted,book,source).semantic;
   actual.imports=normalizeImports(importNodes.map((v:any)=>({path:v.fields[0],alias:v.fields[1]})));
   row.stage0ModuleASTHash=hash(expected);row.compiledModuleASTHash=hash(actual);row.semanticParity=firstDiff(expected,actual)===null;row.firstDifference=firstDiff(expected,actual);
  }catch(error){row.semanticParity=false;row.normalizationError=String(error);}
 }
 rows.push(row);writeFileSync('checkpoints/bootstrap-real-source-parser-baseline.json',JSON.stringify({stage0Acceptance:rows.filter(r=>r.stage0Accepted).length,compiledAcceptance:rows.filter(r=>r.compiledAccepted).length,semanticParity:rows.filter(r=>r.semanticParity).length,rows},null,2)+'\n');console.log(JSON.stringify(row));Bun.gc(true);
}
