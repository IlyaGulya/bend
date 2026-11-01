// One-off diagnostic only. Preserve the original indexer and rethrow its error.
import {LexicalTypes} from '/private/var/folders/0r/pkz80d0154z37ybnv69pqclh0000gn/T/bend-build-acceleration-3cg3qjns/reach-before-42139224/evals/parser_full_type_env.ts';
import {checkerStepConfig,generateNativeSteps} from '/private/var/folders/0r/pkz80d0154z37ybnv69pqclh0000gn/T/bend-build-acceleration-3cg3qjns/reach-before-42139224/evals/checker_core_step_lower.ts';
const original=LexicalTypes.prototype.indexBody;
LexicalTypes.prototype.indexBody=function(body,parameters,result){
 try{return original.call(this,body,parameters,result);}
 catch(error){
  const span=value=>value?{beg:value.beg,end:value.end}:undefined;
  try{
  const id=error?.binderId,matches=[],seen=new WeakSet();let remaining=20000;
  function visit(value){
   if(--remaining<0||!value||typeof value!=='object'||seen.has(value))return;
   seen.add(value);
   if(typeof id==='number'&&matches.length<16&&(value.i===id||Array.isArray(value.i)&&value.i.includes(id)))matches.push({
    tag:value.$,id:value.i,key:value.k,span:span(value.s)});
   for(const[key,child]of Object.entries(value))if(key!=='s'){
    if(Array.isArray(child))for(const item of child)visit(item);else visit(child);
   }
  }
  visit(body);
  const expression=error?.expression,scope=expression&&this.environments.get(expression);
  console.error('LEXICAL_ERROR_OBSERVATION '+JSON.stringify({acceptanceEvidence:false,
   error:{name:error?.name,reason:error?.reason,binderId:id,span:span(error?.expression?.s)},
   expression:{tag:expression?.$,id:expression?.i,key:expression?.k,span:span(expression?.s)},
   scope:scope?[...scope.values()].map(binding=>({id:binding.id,name:binding.name})):null,
   parameters:parameters.map(([,name,id])=>({name,id})),matches,truncated:remaining<0,
   stack:String(error?.stack).split('\n').slice(0,14)},(_key,value)=>typeof value==='bigint'?String(value):value));
  }finally{throw error;}
 }
};
await generateNativeSteps({...checkerStepConfig,mode:'template',root:'main',result:'ClaySmoke',
 canonical:'evals/clay_layout_smoke.bend',owned:'checkpoints/clay_layout_smoke_owned.bend',
 ownedManifest:'checkpoints/clay-layout-smoke-owned.json',dependency:'checkpoints/clay-layout-smoke-dependency.json',
 generator:'evals/clay_layout_step_smoke.ts',output:'checkpoints/clay_layout_steps_v1.bend',
 component:'checkpoints/clay_layout_steps_component_v1.bend',manifest:'checkpoints/clay-layout-steps-v1.json',
 driver:undefined,ownedDriver:undefined,
 providerClosure:['bend2/selfhost/c_backend_layout.bend','bend2/selfhost/descriptor_nf.bend']});
