import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';

// Explicit typed data reconstruction, NOT a suffix-tag cast. Source constructor
// identities/layouts come from authenticated R12 $FIELDS. Destination identities
// are observations of real values constructed by the compiled Bend schema probe.
export function nominalBridge(schema,samples,base,sourceFields){
 const bySource=new Map(),types=new Set(schema.arms.map(row=>row.type)),witness=new Map();
 const samplesArray=[];let cursor=samples;
 while(cursor?.$===base.cons.$){samplesArray.push(cursor.head);cursor=cursor.tail;assert.ok(samplesArray.length<1000);}
 assert.equal(cursor?.$,base.nil.$);assert.equal(samplesArray.length,schema.arms.length);
 for(const sample of samplesArray){assert.equal(typeof sample.key,'string');assert.ok(!witness.has(sample.key));witness.set(sample.key,sample.value);}
 const mappings=[];
 for(const arm of schema.arms){
  const value=witness.get(arm.source);assert.ok(value&&typeof value.$==='string','missing typed witness '+arm.source);
  const fields=arm.fields.map(field=>field.name);assert.deepEqual(sourceFields[arm.source],fields,'source nominal schema drift '+arm.source);
  assert.deepEqual(Object.keys(value).filter(key=>key!=='$').sort(),[...fields].sort(),'destination constructor layout '+arm.source);
  assert.ok(!bySource.has(arm.source));bySource.set(arm.source,{...arm,destination:value.$});mappings.push({source:arm.source,destination:value.$,fields});
 }
 const generic={Nil:base.nil.$,Con:base.cons.$,None:base.none.$,Some:base.some.$};
 for(const [tag,fields]of Object.entries({Nil:[],Con:['head','tail'],None:[],Some:['value']}))assert.deepEqual(sourceFields[tag],fields,'source Base schema drift '+tag);
 assert.deepEqual(Object.keys(base.nil),['$']);assert.deepEqual(Object.keys(base.cons).sort(),['$','head','tail']);assert.deepEqual(Object.keys(base.none),['$']);assert.deepEqual(Object.keys(base.some).sort(),['$','value']);
 const mappingSha256=createHash('sha256').update(JSON.stringify({mappings,generic})).digest('hex');
 function importRoot(input,rootType,key){
   const memo=new WeakMap(),holder={},work=[{input,type:rootType,parent:holder,key:'value'}];let nodes=0,scalars=0;
   while(work.length){
    const job=work.pop();if(job.finish){job.finish.active=false;continue;}
    let type=job.type;if(types.has('BIR.'+type))type='BIR.'+type;
    const value=job.input;
    if(['U32','Nat','String','Bool'].includes(type)){
     if(type==='String')assert.equal(typeof value,'string');
     else if(type==='Bool')assert.equal(typeof value,'boolean');
     else {assert.equal(typeof value,'number');assert.ok(Number.isInteger(value)&&value>=0&&value<=(type==='U32'?4294967295:9007199254740992),'invalid '+type);}
     job.parent[job.key]=value;scalars++;continue;
    }
    assert.ok(value&&typeof value==='object'&&!Array.isArray(value),'record expected '+type);
    let known=memo.get(value);const prior=known?.get(type);
    if(prior){assert.equal(prior.active,false,'cyclic BIR transport');job.parent[job.key]=prior.value;continue;}
    assert.ok(++nodes<=16000000,'transport object bound');
    let destination,fields;
    const genericType=type.match(/^(List|Maybe)<&2,\s*(.+)>$/);
    if(genericType){
     const [_,kind,element]=genericType;
     if(kind==='List'){
      if(value.$==='Nil'){destination=generic.Nil;fields=[];}
      else {assert.equal(value.$,'Con');destination=generic.Con;fields=[{name:'head',type:element},{name:'tail',type}];}
     }else if(value.$==='None'){destination=generic.None;fields=[];}
     else {assert.equal(value.$,'Some');destination=generic.Some;fields=[{name:'value',type:element}];}
    }else{
     const arm=bySource.get(value.$);assert.ok(arm,'unknown exact source constructor '+String(value.$));assert.equal(arm.type,type,'wrong nominal type '+value.$);destination=arm.destination;fields=arm.fields;
    }
    assert.deepEqual(Object.keys(value).filter(key=>key!=='$').sort(),fields.map(field=>field.name).sort(),'input layout '+value.$);
    const output={$:destination},entry={value:output,active:true};if(!known){known=new Map();memo.set(value,known);}known.set(type,entry);job.parent[job.key]=output;
    work.push({finish:entry});for(let i=fields.length-1;i>=0;i--){const field=fields[i];work.push({input:value[field.name],type:field.type,parent:output,key:field.name});}
   }
   return {[key]:holder.value,objects:nodes,scalars,mappingSha256};
 }
 return {mappings,generic,mappingSha256,
  importProgram:program=>importRoot(program,'BIR.Program','program'),
  importSources:sources=>importRoot(sources,'List<&2, BIR.SourceFile>','sources')
 };
}
