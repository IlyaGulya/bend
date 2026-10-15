import {guardHeavyGate} from './heavy_gate.ts';
import {resolve,dirname} from 'node:path';
import {realpathSync,writeFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
await guardHeavyGate(import.meta.path,{label:'Compiled parser actual bootstrap AST template census'});
const root='/Users/ilyagulya/Projects/My/bend';
const artifact=root+'/checkpoints/parser-explicit-fuel-822e8460.js';
const roots=[root+'/checkpoints/checker_core_driver.bend',root+'/bend2/selfhost/.parser_definition_body_shape_generated_fuel.bend'];
const tag=(x:any)=>typeof x?.$==='string'?x.$.split('.').at(-1):undefined;
function list(x:any){const result=[];while(tag(x)==='Con'){result.push(x.head);x=x.tail;}if(tag(x)!=='Nil')throw Error('Invalid AST list');return result;}
function resolveImport(file:string,path:string){if(path==='Base')return root+'/bend2/base.bend';return resolve(dirname(file),path.endsWith('.bend')?path:path+'.bend');}
async function parse(file:string,importsOnly=false){
 const child=Bun.spawn(['node','evals/checker_core_census_node.mjs',file,...(importsOnly?['--imports-only']:[])],{stdout:'pipe',stderr:'pipe'});
 const text=await new Response(child.stdout).text(),err=await new Response(child.stderr).text();
 if(await child.exited!==0)throw Error('Compiled artifact Node runtime: '+err);
 const run=JSON.parse(text,(_,v)=>v?.$==='$NativeNat'?BigInt(v.value):v);
 if(tag(run)!=='FeedbackComplete')throw Error('Compiled parser '+tag(run)+' at '+file);
 return Object.entries(run.value).find(([k])=>k!=='$')?.[1] as any;
}
const pending=[...roots],seen=new Set<string>(),modules:any[]=[],constructs:any[]=[],failures:any[]=[];
const stem=root+'/checkpoints/bootstrap-template-census';
function save(status:string,extra:any={}){
 const complete=failures.length===0;
 writeFileSync(stem+'.json',JSON.stringify({status,roots,artifact,explicitFuel:200000,runtime:'Unchanged JS artifact in Node worker with256 MiB stack, process-tree eight GiB guardian. JSON transport preserves constructor fields and BigInt.',closureDiscovery:'Imports from full compiled-parser ASTs; failed modules use exact import/type prefix parsed by the SAME artifact only to discover imports. Prefix declarations are NOT counted as full modules.',modules,totalDeclarations:complete?modules.reduce((n,m)=>n+(m.declarations??0),0):null,totalTemplateDefinitions:complete?modules.reduce((n,m)=>n+(m.templateDefinitions??0),0):null,totalTemplateApplicationSites:complete?constructs.filter(c=>c.constructor==='TermTemplate').length:null,parsedDeclarationsLowerBound:modules.reduce((n,m)=>n+(m.declarations??0),0),parsedTemplateDefinitionsLowerBound:modules.reduce((n,m)=>n+(m.templateDefinitions??0),0),parsedTemplateBindersLowerBound:constructs.filter(c=>c.constructor==='TemplateBinder').length,parsedTemplateApplicationSitesLowerBound:constructs.filter(c=>c.constructor==='TermTemplate').length,constructs,failures,...extra},(_,v)=>typeof v==='bigint'?String(v):v,2)+'\n');
}
try{
 while(pending.length){
  const file=realpathSync(pending.shift()!);if(seen.has(file))continue;seen.add(file);
  const source=await Bun.file(file).text();console.log(JSON.stringify({stage:'parse',file,bytes:Buffer.byteLength(source)}));
  let payload=await parse(file),complete=tag(payload)==='ParseSuccess';
  if(!complete){
   failures.push({file,payload});console.log(JSON.stringify({stage:'compiled-parser-rejection',file,diagnostic:payload},(_,v)=>typeof v==='bigint'?String(v):v));
   payload=await parse(file,true);
   if(tag(payload)!=='ParseSuccess')throw Error('Even exact import-prefix recovery rejected: '+file);
  }
  const module=payload.module,imports=list(module.imports),declarations=complete?list(module.declarations):[];
  let definitions=0,templateDefinitions=0;
  for(const decl of declarations){
   const d=decl.definition??decl.declaration,definition=d.key;
   if(tag(decl)==='DefTop'){definitions++;if(list(d.binders).some(b=>tag(b)==='TemplateBinder'))templateDefinitions++;}
   const todo:[any,string][]=[[decl,'declaration']];
   while(todo.length){const [value,path]=todo.pop()!;if(!value||typeof value!=='object')continue;
    const t=tag(value);if(t==='TemplateBinder'||t==='TermTemplate')constructs.push({file,definition,constructor:t,path,span:value.span});
    for(const [key,child]of Object.entries(value))if(key!=='$')todo.push([child,path+'.'+key]);
   }
  }
  const row={file,sourceSha256:createHash('sha256').update(source).digest('hex'),fullParsePassed:complete,declarations:complete?declarations.length:null,definitions:complete?definitions:null,templateDefinitions:complete?templateDefinitions:null,imports:imports.map(i=>({path:i.path,alias:i.alias,resolved:resolveImport(file,i.path)}))};
  modules.push(row);pending.push(...row.imports.map(i=>i.resolved));save('IN_PROGRESS');Bun.gc(true);
 }
 const status=failures.length?'COMPILED_PARSER_BLOCKER_CENSUS_INCOMPLETE':constructs.length?'T1':'T0';
 save(status,{moduleClosureDiscovered:failures.length===0,headerImportClosureDiscovered:true,specialConstructorPolicy:'TemplateBinder and TermTemplate are compile-time template syntax. TermApp/TermRef/TermBang participate in dispatch when referring to collected templates. PatternCtr names mentioning these constructors are ordinary implementation patterns, not template feature use. Failed-module import prefixes discover only header imports; counts and completeness remain unknown.'});
 console.log(JSON.stringify({status,modules:modules.length,fullParsedModules:modules.filter(m=>m.fullParsePassed).length,failedModules:failures.length,parsedTemplateConstructs:constructs.length}));
 if(failures.length)process.exitCode=2;
}catch(error){save('BLOCKED',{error:String(error)});console.error(String(error));process.exitCode=2;}
