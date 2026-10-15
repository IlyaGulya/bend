import {guardHeavyGate} from './heavy_gate.ts';
import {Readable} from 'node:stream';
import {createInterface} from 'node:readline';
import {writeFileSync} from 'node:fs';
await guardHeavyGate(import.meta.path,{label:'Bootstrap real-source compiled parser declaration prefix diagnosis'});
const manifest=await Bun.file('checkpoints/bootstrap-real-source-corpus.json').json();
const child=Bun.spawn(['node','evals/bootstrap_compiled_parser_worker.mjs'],{stdin:'pipe',stdout:'pipe',stderr:'inherit'});
const lines=createInterface({input:Readable.fromWeb(child.stdout as any)});
let nextId=0;const pending=new Map<number,{resolve:(x:any)=>void,reject:(x:any)=>void}>();
lines.on('line',line=>{const result=JSON.parse(line,(_,v)=>v?.$==='$NativeNat'?BigInt(v.value):v);const waiter=pending.get(result.id);if(!waiter)throw Error('Unknown probe');pending.delete(result.id);if(result.error)waiter.reject(Error(result.error));else waiter.resolve(result.payload);});
async function parse(file:string,source:string){const id=nextId++;const promise=new Promise<any>((resolve,reject)=>pending.set(id,{resolve,reject}));child.stdin.write(JSON.stringify({id,file,source})+'\n');await child.stdin.flush();return promise;}
const rows:any[]=[];
function save(){writeFileSync('checkpoints/bootstrap-compiled-prefix-candidates.json',JSON.stringify({status:'CANDIDATE_BOUNDARIES_AWAITING_STAGE0_CONFIRMATION',method:'Column-zero declaration starts are candidate cutoffs only. Stage0 raw parser must confirm every accepted boundary before any repair.',rows},(_,v)=>typeof v==='bigint'?String(v):v,2)+'\n');}
try{
 for(const item of manifest.modules){
  if(item.compiledBaselineAccepted){const source=await Bun.file(item.snapshot).text();const payload=await parse(item.file,source);writeFileSync('checkpoints/bootstrap-real-source/'+String(item.id).padStart(2,'0')+'.compiled-ast.json',JSON.stringify(payload,(_,v)=>typeof v==='bigint'?{$:'$NativeNat',value:String(v)}:v)+'\n');continue;}
  const source=await Bun.file(item.snapshot).text();
  let offset=0;const candidates:{beg:number;header:string}[]=[];
  for(const line of source.split('\n')){if(['def ','type ','law ','@unsafe'].some(prefix=>line.startsWith(prefix)))candidates.push({beg:offset,header:line});offset+=line.length+1;}
  let lastPassing:any=null,firstFailure:any=null;const probes:any[]=[];
  const empty=await parse(item.file,source.slice(0,candidates[0]?.beg??0));if(empty.$!=='ParseSuccess')throw Error('Import prefix rejected for '+item.file);lastPassing={end:candidates[0]?.beg??0,declarations:0};
  for(let i=0;i<candidates.length;i++){
   const end=candidates[i+1]?.beg??source.length,payload=await parse(item.file,source.slice(0,end));
   probes.push({candidate:i+1,end,accepted:payload.$==='ParseSuccess',header:candidates[i].header});
   if(payload.$!=='ParseSuccess'){firstFailure={candidate:i+1,beg:candidates[i].beg,end,header:candidates[i].header,payload,source:source.slice(candidates[i].beg,end)};break;}
   lastPassing={end,declarations:i+1};
  }
  const row={file:item.file,snapshot:item.snapshot,lastPassing,firstFailure,probes};rows.push(row);save();console.log(JSON.stringify({file:item.file,lastPassing,firstFailure:firstFailure&&{header:firstFailure.header,beg:firstFailure.beg,end:firstFailure.end,payload:firstFailure.payload}},(_,v)=>typeof v==='bigint'?String(v):v));
 }
 save();
}finally{lines.close();child.stdin.end();await child.exited;}
