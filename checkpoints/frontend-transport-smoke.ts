import * as B from '../bend2/bend.ts';
import * as Comp from '../bend2/comp.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {mkdtempSync,writeFileSync,rmSync} from 'node:fs';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
import {createHash} from 'node:crypto';
await guardHeavyGate(import.meta.path,{label:'Compiled parser native AST/shared module identity transport'});
const root='/Users/ilyagulya/Projects/My/bend',artifact=root+'/checkpoints/parser-explicit-fuel-822e8460.js',dir=mkdtempSync(join(tmpdir(),'bend-native-transport-'));
try{
 const code='import Base\nimport '+root+'/bend2/selfhost/loaded_module.bend as Modules\nimport '+root+'/bend2/selfhost/ast.bend as Ast\ndef wrap(namespace: String, module: Ast.Module) -> Modules.LoadedModule:\n  Modules.LoadedModule{namespace, module}\n';
 const file=join(dir,'contract.bend');writeFileSync(file,code);const book=B.book_nil();await B.book_load(book,file,'',new Map());B.book_valid(book);if(book.hols||book.open)throw Error('Incomplete shared contract validation');
 const js=join(dir,'contract.js');writeFileSync(js,Comp.js_lib(book,['wrap'],['wrap']));
 const worker=join(dir,'worker.mjs');writeFileSync(worker,`import parser from ${JSON.stringify(artifact)};import contract from ${JSON.stringify(js)};const source="type Flag is Data:\\n  On{}\\ndef main() -> Flag:\\n  On{}\\n";let fuel={$:'FeedbackFuelEnd'};for(let i=0;i<10000;i++)fuel={$:'FeedbackFuelCell',tail:fuel};const run=parser.parse_with_fuel(fuel,'transport-target.bend',source);if(run.$!=='FeedbackComplete')throw Error(run.$);const payload=Object.entries(run.value).find(([k])=>k!=='$')[1];if(payload.$!=='ParseSuccess')throw Error(JSON.stringify(payload));const module=payload.module;const loaded=contract.wrap('',module);if(loaded.$!=='LoadedModule'||loaded.namespace!==''||loaded.module!==module)throw Error('AST transport changed identity');console.log(JSON.stringify({status:'PASS',identityPreserved:true,parsedModuleTag:module.$,moduleFields:Object.keys(module),source}));`);
 const child=Bun.spawn([process.execPath,worker],{stdout:'pipe',stderr:'pipe'});const out=await new Response(child.stdout).text(),err=await new Response(child.stderr).text();if(await child.exited)throw Error(err);
 const record={...JSON.parse(out),artifactSha256:createHash('sha256').update(await Bun.file(artifact).text()).digest('hex'),contractSource:code,proof:'Exact native JS object identity retained; all constructors/fields and BigInt values preserved without serialization or source re-parsing',selfhostGreen:false};writeFileSync(root+'/checkpoints/frontend-transport-smoke.json',JSON.stringify(record,null,2)+'\n');console.log(JSON.stringify(record));
}finally{rmSync(dir,{recursive:true,force:true});}
