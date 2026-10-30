import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {sha,tag} from './common.mjs';
const KEY='__reusePreflightProbe';
const escape=s=>s.replace(/[.*+?^${}()|[\]\\]/g,'\\$&');
/** Only entry observers are inserted. No return, argument, algorithm or consumer output is replaced. */
export function instrument(source,{repo,manifest,experiment,target}){
 assert.equal(globalThis[KEY],undefined);
 const generated=readFileSync(resolve(repo,manifest.generationConfig.output),'utf8');
 const sites=[],edits=[];
 const ids=new WeakMap();let next=1;
 const id=x=>{assert.ok(x&&typeof x==='object','expected native object');let n=ids.get(x);if(!n){n=next++;ids.set(x,n);}return n;};
 const context=x=>({families:id(x.families),functions:id(x.type_functions)});
 const pair=(f,t)=>[id(f),id(t)];
 const counts={},evidence=[];let nfPair,producerContext,catalogContext,catalogPair,handoffCalls,definitionsStarted=false,mapId,markerPair;
 function observe(name,a){
  counts[name]=(counts[name]??0)+1;
  if(name==='nf_context'){if(!nfPair)nfPair=pair(a[0],a[1]);}
  if(name==='normalize_foreign_definitions'&&!producerContext)producerContext=context(a[1]);
  if(name==='lower_catalog'&&a[0]?.catalog){
   const c=a[0].catalog;catalogContext=context(c.normalizer);catalogPair=pair(c.families,c.type_functions);handoffCalls=counts.nf_context;
   assert.deepEqual(catalogPair,nfPair,'Catalog lists differ from original nf_context inputs');
   assert.deepEqual(catalogContext,producerContext,'Catalog did not carry producer index maps');
   assert.equal(handoffCalls,1,'context rebuilt before catalog handoff');
   evidence.push({boundary:name,inputPair:catalogPair,indexMaps:catalogContext,nfCalls:handoffCalls});
  }
  if(name==='definitions'&&!definitionsStarted){
   definitionsStarted=true;assert.equal(tag(a[0].normalizer),'Some');assert.deepEqual(context(a[0].normalizer.value),catalogContext);
   assert.equal(counts.nf_context,handoffCalls,'context rebuilt at lowering handoff');
   evidence.push({boundary:name,indexMaps:context(a[0].normalizer.value),nfCalls:counts.nf_context});
  }
  if(name==='describe'){assert.equal(tag(a[0].normalizer),'Some');assert.deepEqual(context(a[0].normalizer.value),catalogContext,'lowering descriptor context changed');}
  if(name==='js_native_markers'){assert.equal(counts[name],1,'marker map rebuilt');markerPair=pair(a[0].families,a[0].type_functions);}
  if(name==='ending_check'){mapId=id(a[1]);evidence.push({boundary:name,map:mapId,inputPair:markerPair});}
  if(name==='emit_checked_exports'||name==='emit_effects'||name==='program_source'||name==='declarations'||name==='ending'){
   const index=name==='emit_checked_exports'?4:name==='declarations'||name==='ending'?1:2;
   assert.equal(id(a[index]),mapId,'marker map identity changed at '+name);
   if(name==='program_source'){assert.deepEqual(pair(a[0].families,a[0].type_functions),markerPair);evidence.push({boundary:name,map:mapId,inputPair:markerPair});}
  }
 }
 const hooks=experiment==='e06'?[
  ['descriptor_nf','nf_context',2],['lower_catalog','normalize_foreign_definitions',2],['backend_lower','lower_catalog',1],['backend_lower','definitions',4],['backend_lower','describe',2],
 ]:target==='js'?[
  ['js_backend','js_native_markers',1],['js_backend','ending_check',2],['js_backend','emit_checked_exports',5],['js_backend','emit_effects',3],['js_backend','program_source',3],['js_backend','declarations',3],['js_backend','ending',2],
 ]:[];
 for(const [module,name,arity]of hooks){
  const path='bend2/selfhost/'+module+'.bend';
  const owners=manifest.canonicalComposition.sources.filter(s=>s.canonical===path);assert.equal(owners.length,1);
  const symbol=owners[0].symbols[name];assert.equal(typeof symbol,'string');
  const declaration='emitter_body_'+symbol;
  assert.ok(new RegExp('^def '+escape(declaration)+'\\(','m').test(generated),'missing generated source declaration '+declaration);
  const pattern=new RegExp('^function (\\$[A-Za-z0-9_]*_'+escape(declaration)+')\\(([^)]*)\\) \\{','gm');
  const matches=[...source.matchAll(pattern)];assert.equal(matches.length,1,'ambiguous/missing compiled source boundary '+declaration);
  const m=matches[0],args=m[2].split(',').map(s=>s.trim()).filter(Boolean);assert.equal(args.length,arity,'live arity '+name);assert.ok(args.every(s=>/^[$A-Za-z_][$A-Za-z_0-9]*$/.test(s)));
  sites.push({authored:path,authoredSha256:owners[0].canonicalSha256,symbol,generatedDeclaration:declaration,compiledFunction:m[1],entrySha256:sha(m[0]),arity});
  edits.push({at:m.index+m[0].length,text:'\nglobalThis.'+KEY+'.observe('+JSON.stringify(name)+',['+args.join(',')+']);'});
 }
 globalThis[KEY]={observe};
 for(const e of edits.sort((a,b)=>b.at-a.at))source=source.slice(0,e.at)+e.text+source.slice(e.at);
 return {source,sites,finish(success){
  if(success&&experiment==='e06')assert.ok(definitionsStarted,'lowering handoff not exercised');
  if(success&&experiment==='e10'&&target==='js'){assert.equal(counts.js_native_markers,1);for(const n of ['ending_check','emit_checked_exports','emit_effects','program_source','declarations','ending'])assert.ok(counts[n]>0,'missing map consumer '+n);}
  const report={diagnosticOnly:true,scalarIdentityObservation:true,retainsOwners:false,counts,evidence,positiveRequired:success&&(experiment==='e06'||target==='js'),positivePassed:success&&(experiment==='e06'?definitionsStarted:target==='js'?counts.program_source===1:false)};
  delete globalThis[KEY];return report;
 }};
}
