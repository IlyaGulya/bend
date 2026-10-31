import assert from 'node:assert/strict';
import {readFileSync,writeFileSync,mkdirSync,existsSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {serialize} from 'node:v8';
import {dirname,resolve,sep} from 'node:path';
import {fileURLToPath} from 'node:url';
const directory=dirname(fileURLToPath(import.meta.url));
const HOOK='__e05CaptureOriginalBIR',BOUNDARY='emitter_steps_v1.emitter_body_cps_provider_8_js_scalar_program';
const IMAGE='85aff9e534c18b4a1d6acac5f3237571dabc58f2c1a75a7ea2040f1c477ab60e';
const sha=bytes=>createHash('sha256').update(bytes).digest('hex');
let report={status:'uninstalled',calls:0};
export function instrument(source,context){
 assert.equal(globalThis[HOOK],undefined,'capture hook already installed');
 const original=readFileSync(context.image,'utf8');assert.equal(sha(original),IMAGE,'immutable R12 image required');
 const rows=[...original.matchAll(/^\$D\[("(?:[^"\\]|\\.)*")\]=[^\n]+/gm)].filter(m=>JSON.parse(m[1])===BOUNDARY);assert.equal(rows.length,1);
 const functions=[...new Set(rows[0][0].match(/\$b\d+(?=\()/g)??[])];assert.equal(functions.length,1);
 const fn=functions[0],escaped=fn.replace('$','\\$'),entries=[...source.matchAll(new RegExp('^function '+escaped+'\\(([^\\n)]*)\\)\\{','gm'))];
 assert.equal(entries.length,1);assert.equal(entries[0][1],'$v0,$td=0');
 const originalBody=original.match(new RegExp('^function '+escaped+'\\([^\\n]*','m'))?.[0];assert.ok(originalBody?.includes('../bend2/selfhost/backend_ir.Program'));assert.ok(originalBody.includes('$v0.codes'));
 const fields={};for(const m of original.matchAll(/^\$FIELDS\[("(?:[^"\\]|\\.)*")\]=(\[[^\n]*\]);$/gm)){
  const key=JSON.parse(m[1]);if(key.startsWith('../bend2/selfhost/backend_ir.')||key==='../bend2/selfhost/ast.SpanOf'||['Con','Nil','Some','None'].includes(key)){assert.equal(fields[key],undefined);fields[key]=JSON.parse(m[2]);}
 }
 assert.deepEqual(fields['../bend2/selfhost/backend_ir.Program'],['codes','declarations','constructors','families','type_functions','ending']);
 const output=resolve(process.env.E05_CAPTURE_DIRECTORY??resolve(directory,'capture'));
 assert.ok(output.startsWith(directory+sep),'capture writes must remain inside candidate');
 mkdirSync(output,{recursive:true});const snapshot=resolve(output,'original-bir.v8'),metadata=resolve(output,'original-bir.json');
 assert.ok(!existsSync(snapshot)&&!existsSync(metadata),'fresh capture destination required');
 report={status:'armed',calls:0,image:{path:context.image,sha256:IMAGE},boundary:{key:BOUNDARY,function:fn,declarationSha256:sha(rows[0][0]),bodySha256:sha(originalBody)},snapshot,metadata};
 globalThis[HOOK]=program=>{
  report.calls++;assert.equal(report.calls,1,'one exact full-root boundary required');assert.equal(program?.$,'../bend2/selfhost/backend_ir.Program');
  // Serialization is an explicit diagnostic export, not graph retention in the
  // census observer. It preserves original tags, aliasing and primitive values.
  const bytes=serialize(program);assert.ok(bytes.byteLength<=512*1024*1024,'bounded snapshot size');
  writeFileSync(snapshot,bytes,{flag:'wx'});report={...report,status:'captured',bytes:bytes.byteLength,sha256:sha(bytes)};
  writeFileSync(metadata,JSON.stringify({...report,schema:fields,transport:'node:v8 serialize; unmodified original nominal tags; no target closure invocation',runtime:process.versions},null,2)+'\n',{flag:'wx'});
 };
 const at=entries[0].index+entries[0][0].length;
 return {source:source.slice(0,at)+'globalThis.'+HOOK+'($v0);'+source.slice(at),metadata:{imageSha256:IMAGE,boundary:report.boundary,snapshot,semantics:'passive synchronous BIR snapshot before original JS scalarization; arguments and result unchanged'}};
}
export function snapshot(){return {...report};}
