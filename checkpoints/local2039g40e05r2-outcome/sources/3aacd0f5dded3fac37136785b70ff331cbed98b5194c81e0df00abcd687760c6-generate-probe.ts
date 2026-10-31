import {createHash} from 'node:crypto';
import {readFileSync,writeFileSync,existsSync,mkdirSync,realpathSync} from 'node:fs';
import {dirname,basename,relative,resolve,sep} from 'node:path';
import {fileURLToPath} from 'node:url';
import {composeCanonicalCPSSource} from '/Users/ilyagulya/Projects/My/bend/evals/canonical_cps_source.ts';
import {normalizeNativeMatchSource} from '/Users/ilyagulya/Projects/My/bend/evals/native_match_source.ts';
import {checkerStepConfig,generateNativeSteps} from '/Users/ilyagulya/Projects/My/bend/evals/checker_core_step_lower.ts';

// Parent executes this source-only generator under the existing heavy gate.
// Every write is confined to this candidate; production inputs are read-only.
const root='/Users/ilyagulya/Projects/My/bend',sourceDirectory=dirname(fileURLToPath(import.meta.url)),directory=process.argv[2]?resolve(process.argv[2]):sourceDirectory;
if(realpathSync(process.cwd())!==realpathSync(root))throw Error('Run from repository root');
const sha=(x:string|Uint8Array)=>createHash('sha256').update(x).digest('hex');
const hash=(p:string)=>sha(readFileSync(p));
const out=(rel:string)=>resolve(directory,rel);
function inside(path:string){if(path!==directory&&!path.startsWith(directory+sep))throw Error('Write outside candidate: '+path);return path;}
function create(path:string,text:string|Uint8Array){inside(path);mkdirSync(dirname(path),{recursive:true});writeFileSync(path,text,{flag:'wx'});}
const staged:Record<string,string>={},seen=new Set<string>();
function stage(path:string){
 path=inside(resolve(path));if(seen.has(path))return;seen.add(path);
 if(!existsSync(path)){const rel=relative(directory,path),candidate=resolve(sourceDirectory,rel),source=existsSync(candidate)?candidate:resolve(root,rel);create(path,readFileSync(source));}
 staged[path]=hash(path);
 for(const m of readFileSync(path,'utf8').matchAll(/^import (\S+) as [A-Za-z_]\w*$/gm)){
  if(!m[1].endsWith('.bend'))continue;
  stage(resolve(dirname(path),m[1]));
 }
}
const bir=out('bend2/selfhost/backend_ir.bend'),ast=out('bend2/selfhost/ast.bend');
stage(bir);stage(ast);
function splitTypes(text:string){const result:string[]=[];let depth=0,start=0;for(let i=0;i<text.length;i++){if(text[i]==='<')depth++;if(text[i]==='>')depth--;if(text[i]===','&&depth===0){result.push(text.slice(start,i).trim());start=i+1;}}if(text.trim())result.push(text.slice(start).trim());if(depth!==0)throw Error('Unbalanced schema type');return result;}
type Arm={type:string;name:string;source:string;fields:{name:string;type:string}[]};
const arms:Arm[]=[];let current='';
for(const line of readFileSync(bir,'utf8').split('\n')){
 const type=line.match(/^type (\w+) is Data:$/);if(type){current=type[1];continue;}
 const arm=line.match(/^  (\w+)\{(.*)\}$/);if(arm){if(!current)throw Error('Constructor outside schema');arms.push({type:'BIR.'+current,name:arm[1],source:'../bend2/selfhost/backend_ir.'+arm[1],fields:splitTypes(arm[2]).map(field=>{const m=field.match(/^(\w+): (.+)$/);if(!m)throw Error('Unsupported schema field '+field);return{name:m[1],type:m[2]};})});continue;}
 if(line.trim()&&!line.trimStart().startsWith('#')&&!line.startsWith('import '))throw Error('Unsupported BIR schema syntax: '+line);
}
const span=readFileSync(ast,'utf8').match(/^  SpanOf\{file: String, beg: Nat, end: Nat\}$/m);if(!span)throw Error('Ast.SourceSpan schema drift');
arms.push({type:'Ast.SourceSpan',name:'SpanOf',source:'../bend2/selfhost/ast.SpanOf',fields:[{name:'file',type:'String'},{name:'beg',type:'Nat'},{name:'end',type:'Nat'}]});
const types=[...new Set(arms.map(a=>a.type))];
function seed(type:string,stack:string[]=[]):string{
 if(types.includes('BIR.'+type))type='BIR.'+type;if(type==='U32')return '0';if(type==='Nat')return '0n';if(type==='String')return '""';if(type==='Bool')return 'False{}';
 if(type.startsWith('List<'))return 'Nil{}';if(type.startsWith('Maybe<'))return 'None{}';
 if(stack.includes(type))throw Error('Recursive seed needs explicit base arm: '+type);
 const arm=arms.find(a=>a.type===type);if(!arm)throw Error('Unknown schema type '+type);
 return (type.startsWith('Ast.')?'Ast.':'BIR.')+arm.name+'{'+arm.fields.map(f=>seed(f.type,[...stack,type])).join(', ')+'}';
}
const schema=out('checkpoints/e05_schema.bend');
const schemaSource='import Base\nimport ../bend2/selfhost/backend_ir.bend as BIR\nimport ../bend2/selfhost/ast.bend as Ast\n\n# Typed constructor samples authenticate the external transport representation.\ntype NominalWitness is Data:\n'+types.map((type,i)=>'  Witness'+i+'{key: String, value: '+type+'}').join('\n')+'\ntype BaseWitness is Data:\n  BaseWitness{nil: List<&2, U32>, cons: List<&2, U32>, none: Maybe<&2, U32>, some: Maybe<&2, U32>}\ndef base() -> BaseWitness:\n  BaseWitness{Nil{}, [0], None{}, Some{0}}\ndef samples() -> List<&2, NominalWitness>:\n  [\n'+arms.map(arm=>'    Witness'+types.indexOf(arm.type)+'{'+JSON.stringify(arm.source)+', '+(arm.type.startsWith('Ast.')?'Ast.':'BIR.')+arm.name+'{'+arm.fields.map(f=>seed(f.type)).join(', ')+'}}').join(',\n')+'\n  ]\n';
create(schema,schemaSource);
const cRenderOrigin=root+'/bend2/selfhost/c_emit_core.bend',cRenderSource=readFileSync(cRenderOrigin,'utf8'),cRenderStart=cRenderSource.indexOf('# The pure C target seam:'),cRenderEnd=cRenderSource.indexOf('\ndef emit(checked:');
if(cRenderStart<0||cRenderEnd<=cRenderStart||cRenderSource.indexOf('\ndef emit(checked:',cRenderEnd+1)!==-1)throw Error('Existing C declaration/render seam boundary drift');
const cRenderCopied=cRenderSource.slice(cRenderStart,cRenderEnd),cRender=out('evals/e05_c_render_seam.bend');
create(cRender,'import Base\nimport ../bend2/selfhost/ast.bend as Ast\nimport ../bend2/selfhost/backend_ir.bend as BIR\nimport ../bend2/selfhost/c_backend.bend as CBackend\n\n'+cRenderCopied+'\n');
const canonical=out('checkpoints/e05_probe.bend'),owned=out('checkpoints/e05_probe_owned.bend');
stage(canonical);
const native:Record<string,true>={'backend_ir.bend':true,'ast.bend':true,'index_lookup.bend':true,'loaded_module.bend':true},providers:string[]=[],providerSeen=new Set([realpathSync(canonical)]);
function closure(path:string){for(const m of readFileSync(path,'utf8').matchAll(/^import (\S+) as [A-Za-z_]\w*$/gm)){
 if(!m[1].endsWith('.bend'))continue;const file=realpathSync(resolve(dirname(path),m[1]));if(providerSeen.has(file))continue;providerSeen.add(file);if(Object.hasOwn(native,basename(file)))continue;providers.push(file);closure(file);
}}
closure(canonical);
const composition=await composeCanonicalCPSSource(canonical,providers),normalized=await normalizeNativeMatchSource(canonical,composition.source);
// canonical, owned and steps are siblings, so external import coordinates stay exact.
const text=normalized.source;
function declarations(source:string){const starts=[...source.matchAll(/^def ([A-Za-z_]\w*)\(/gm)];return{names:starts.map(m=>m[1]),hashes:Object.fromEntries(starts.map((m,i)=>[m[1],sha(source.slice(m.index,starts[i+1]?.index??source.length))]))};}
const original=readFileSync(canonical,'utf8'),names=declarations(text),before=declarations(original),lowering=declarations(composition.source);
const ownedManifest=out('checkpoints/e05-probe-owned.json'),dependency=out('checkpoints/e05-probe-dependency.json'),output=out('checkpoints/e05_probe_steps.bend'),component=out('checkpoints/e05_probe_component.bend'),manifest=out('checkpoints/e05-probe-steps.json');
for(const path of [owned,ownedManifest,dependency,output,component,manifest,out('checkpoints/e05_probe_bridge.bend'),out('schema.json'),out('generation.json')])if(existsSync(path))throw Error('Refuse overwrite: '+path);
create(owned,text);create(dependency,'{}\n');
create(ownedManifest,JSON.stringify({schemaVersion:2,sourceOnlyParameterMatchFactoring:true,componentSources:[{mode:'template',canonical,owned,canonicalSha256:sha(original),sourceSha256:sha(text),definitionNames:names.names,declarationHashes:names.hashes,owners:Object.fromEntries(normalized.extractions.map(row=>[row.helper,row.owner])),canonicalDefinitionNames:before.names,canonicalDeclarationHashes:before.hashes,loweringDefinitionNames:lowering.names,loweringDeclarationHashes:lowering.hashes,composition:composition.proof}],ownedModules:[]},null,2)+'\n');
await generateNativeSteps({...checkerStepConfig,mode:'template',root:'main',result:'ProbeBatch',canonical,owned,ownedManifest,dependency,providerClosure:providers,componentAlias:'Probe',generator:fileURLToPath(import.meta.url),output,component,manifest,driver:undefined,ownedDriver:undefined});
const generated=JSON.parse(readFileSync(manifest,'utf8'));
function entry(name:string,result:string,parameter:string,argument:string){
 const rows=generated.coverage.filter((row:any)=>row.name===name);if(rows.length!==1)throw Error('No unique typed request for '+name);const row=rows[0];
 if(!/^[A-Za-z_]\w*$/.test(row.request)||!/^[A-Za-z_]\w*$/.test(row.requestEnvelope))throw Error('Invalid authenticated request names');
 return 'def '+name+'_start('+parameter+') -> Probe.TemplateRun<Probe.'+result+'>:\n  Probe.template_chunk(Probe.'+result+', 64n, Probe.TemplateRunState{Probe.'+result+', Probe.TemplatePending{Probe.'+row.requestEnvelope+'{Probe.'+row.request+'{'+argument+'}}, box => Probe.TemplateFinished{box}}, Probe.TemplateStackDone{{==}}})\n';
}
const bridge=out('checkpoints/e05_probe_bridge.bend');
create(bridge,'import Base\nimport ../bend2/selfhost/backend_ir.bend as BIR\nimport ../bend2/selfhost/loaded_module.bend as Loader\nimport ./e05_probe_steps.bend as Probe\n\n'+entry('inspect','Inspection','program: BIR.Program','program')+'\n'+entry('schema','SchemaBundle','','')+'\n'+entry('render_case','ProbeSource','program: BIR.Program, target: Bool, files: List<&2, BIR.SourceFile>','program, target, files')+'\ndef suite_start(modules: List<&2, Loader.LoadedModule>) -> Probe.TemplateRun<Probe.ProbeBatch>:\n  Probe.template_start(modules)\n\ndef template_step(-R: Type, run: Probe.TemplateRun<R>) -> Probe.TemplateRun<R>:\n  Probe.template_step(R, run)\n');
create(out('schema.json'),JSON.stringify({version:1,bir:{path:bir,sha256:hash(bir)},ast:{path:ast,sha256:hash(ast)},witness:{path:schema,sha256:hash(schema)},arms},null,2)+'\n');
create(out('generation.json'),JSON.stringify({status:'E05_SOURCE_GENERATED',targetExecution:false,canonical,bridge,manifest,providers,staged,generatedArtifacts:Object.fromEntries([owned,ownedManifest,dependency,output,component,manifest,bridge,out('schema.json')].map(path=>[path,hash(path)])),pass:{path:out('bend2/selfhost/backend_continuation.bend'),sha256:hash(out('bend2/selfhost/backend_continuation.bend'))},renderSeam:{origin:cRenderOrigin,originSha256:hash(cRenderOrigin),copiedSourceSha256:sha(cRenderCopied),source:cRender,sourceSha256:hash(cRender),scope:'Exact existing C target declaration/join/render definitions; the final checked-FIR lowering entry is not needed by a BIR consumer.'},bridgeSha256:hash(bridge),schemaSha256:hash(out('schema.json')),generatorSha256:hash(fileURLToPath(import.meta.url))},null,2)+'\n');
console.log(JSON.stringify({status:'E05_SOURCE_GENERATED',bridge,exports:['suite_start','schema_start','inspect_start','render_case_start','template_step'],manifest}));
