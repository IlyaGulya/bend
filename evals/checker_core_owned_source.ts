/** Own the complete check_modules/inspect_checked closures and their import graph.
 * The emitter explicitly composes canonical CPS providers before native match
 * factoring; source and transformed hashes remain distinct in its proof.
 * Native 0.37 matches are factored from authentic ASTs, never core patches.
 * Regenerate only after parser admission: bun evals/checker_core_owned_source.ts
 */
import {readFileSync,writeFileSync,mkdirSync,realpathSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {dirname,relative,resolve} from 'node:path';
import {sourceOracle} from './bootstrap_source_oracle.ts';
import {nativeSourceClosure,normalizeNativeMatchSource} from './native_match_source.ts';
import {composeCanonicalCPSSource, type CPSCompositionProof} from './canonical_cps_source.ts';
import {emitterStepConfig} from './emitter_step_lower.ts';
import {err_show, type Err} from '../bend2/bend.ts';
const sourcePath='bend2/selfhost/checker.bend',source=readFileSync(sourcePath,'utf8');
const dependencyPath='checkpoints/checker-core-dependency.json';
const dependency=JSON.parse(readFileSync(dependencyPath,'utf8'));
const protectedPaths=['checkpoints/checker_core_slice.bend','checkpoints/checker_core_driver.bend','checkpoints/bootstrap-real-source-corpus.json',dependencyPath];
const protectedInputs=new Map(protectedPaths.map(path=>[path,readFileSync(path,'utf8')]));
const sha=(text:string)=>createHash('sha256').update(text).digest('hex');
const definitions=[...source.matchAll(/^def ([\w.]+)\(/gm)];
if(!definitions.length)throw Error('Missing canonical Checker definitions');
const originalHeader=source.slice(0,definitions[0]!.index);
const header=originalHeader.replace('import ./template.bend as Template\n','');
const omittedEntrypoints=['check','check_template_result'];
const canonicalBlocks=new Map(definitions.map((match,index)=>[match[1]!,source.slice(match.index,definitions[index+1]?.index??source.length)]));
// Public Template entrypoints are not in this compiler component. Exclude them
// before loading imports, so native loading cannot flatten the raw Template body.
const componentSource = header + definitions
  .filter(match => !omittedEntrypoints.includes(match[1]!))
  .map(match => canonicalBlocks.get(match[1]!)!).join('');
const oracle=await sourceOracle(sourcePath,componentSource);
if(!oracle.accepted)throw Error('Canonical Checker source parse failed: '+String(oracle.error));
const included=nativeSourceClosure(oracle,'check_modules');
for(const name of nativeSourceClosure(oracle,'inspect_checked'))included.add(name);
for(const name of omittedEntrypoints)if(included.has(name))throw Error('CheckerCore root now reaches public Template entrypoint '+name);
const selected=definitions.filter(match=>included.has(match[1]!));
if(selected.length!==included.size)throw Error('CheckerCore closure definitions drift');
const blocks=selected.map(match=>canonicalBlocks.get(match[1]!)!);
const slicePath='checkpoints/checker_core_owned_v1.bend';
const modules=new Map<string,{input:string;output:string;original:string;source:string;extractions:unknown[]}>();
async function normalizeOwnedSource(path:string,text:string){
  try{return await normalizeNativeMatchSource(path,text);}
  catch(error){
    if(error&&typeof error==='object'&&'$'in error&&error.$==='Err')
      throw Error('Owned native-match normalization '+path+': '+err_show(error as Err));
    throw error;
  }
}
const normalizedRoot=await normalizeOwnedSource(sourcePath,header+blocks.join(''));
function importSpelling(from:string,to:string):string{
  const path=relative(dirname(from),to).split('\\').join('/');
  return path.startsWith('.')?path:'./'+path;
}
async function ownImports(input:string,output:string,text:string):Promise<string>{
  const imports=[...text.matchAll(/^import (\S+) as ([A-Za-z_]\w*)$/gm)];
  const replacements:{begin:number;end:number;text:string}[]=[];
  for(const item of imports){
    const file=realpathSync(resolve(dirname(input),item[1]!));
    let owned=modules.get(file);
    if(!owned){
      const original=readFileSync(file,'utf8');
      const target=resolve('checkpoints/checker_core_owned_modules_v1',relative(resolve('.'),file));
      if(relative(resolve('.'),file).startsWith('..'))throw Error('Owned source import is outside checkout '+file);
      owned={input:file,output:target,original,source:'',extractions:[]};
      modules.set(file,owned);
      const normalized=await normalizeOwnedSource(file,original);
      owned.extractions=normalized.extractions;
      owned.source=await ownImports(file,target,normalized.source);
      const relocated=[...original.matchAll(/^import (\S+) as ([A-Za-z_]\w*)$/gm)].some(item=>{
        const dependency=realpathSync(resolve(dirname(file),item[1]!));
        return modules.get(dependency)!.output!==dependency;
      });
      if(!normalized.extractions.length&&!relocated){owned.output=file;owned.source=original;}
    }
    replacements.push({begin:item.index!,end:item.index!+item[0].length,text:'import '+importSpelling(output,owned.output)+' as '+item[2]});
  }
  for(const replacement of replacements.reverse())text=text.slice(0,replacement.begin)+replacement.text+text.slice(replacement.end);
  // Moving a declaration must not move the native file it imports. Keep the
  // canonical foreign file identity while spelling it relative to the copy.
  text=text.replace(/^(\s+import )"([^"]+)"$/gm,(_,prefix,path)=>prefix+'"'+importSpelling(output,resolve(dirname(input),path))+'"');
  return text;
}
const slice=await ownImports(sourcePath,slicePath,normalizedRoot.source);
const componentSources:{mode:string;canonical:string;owned:string;canonicalSha256:string;sourceSha256:string;definitionNames:string[];declarationHashes:Record<string,string>;canonicalDefinitionNames:string[];canonicalDeclarationHashes:Record<string,string>;owners:Record<string,string>;composition?:CPSCompositionProof;loweringDefinitionNames?:string[];loweringDeclarationHashes?:Record<string,string>}[]=[];
const componentInputs=new Map<string,string>();
for(const[mode,canonical,output]of [['emitter','bend2/selfhost/emitter.bend','checkpoints/emitter_owned_v1.bend'],['template','bend2/selfhost/template.bend','checkpoints/template_owned_v1.bend']]){
  const original=readFileSync(canonical!,'utf8');
  const closure=mode==='emitter'?emitterStepConfig.providerClosure:undefined;
  const composition=closure?.length?await composeCanonicalCPSSource(canonical!,closure):undefined;
  for(const[path,text]of composition?.inputs??[[canonical!,original]]){
    if(componentInputs.has(path)&&componentInputs.get(path)!==text)throw Error('Mixed component canonical input '+path);
    componentInputs.set(path,text);
  }
  const loweringSource=composition?.source??original;
  const normalized=await normalizeOwnedSource(canonical!,loweringSource);
  const text=await ownImports(canonical!,output!,normalized.source);
  const starts=[...text.matchAll(/^def ([A-Za-z_]\w*)\(/gm)], canonicalStarts=[...original.matchAll(/^def ([A-Za-z_]\w*)\(/gm)];
  const loweringStarts=[...loweringSource.matchAll(/^def ([A-Za-z_]\w*)\(/gm)];
  componentSources.push({mode:mode!,canonical:canonical!,owned:output!,canonicalSha256:sha(original),sourceSha256:sha(text),definitionNames:starts.map(item=>item[1]!),declarationHashes:Object.fromEntries(starts.map((item,index)=>[item[1]!,sha(text.slice(item.index,starts[index+1]?.index??text.length))])),canonicalDefinitionNames:canonicalStarts.map(item=>item[1]!),canonicalDeclarationHashes:Object.fromEntries(canonicalStarts.map((item,index)=>[item[1]!,sha(original.slice(item.index,canonicalStarts[index+1]?.index??original.length))])),owners:Object.fromEntries(normalized.extractions.map(row=>[row.helper,row.owner])),...(composition?{composition:composition.proof,loweringDefinitionNames:loweringStarts.map(item=>item[1]!),loweringDeclarationHashes:Object.fromEntries(loweringStarts.map((item,index)=>[item[1]!,sha(loweringSource.slice(item.index,loweringStarts[index+1]?.index??loweringSource.length))]))}:{})});
  if(composition){
    const file=realpathSync(canonical!);
    if(modules.has(file))throw Error('CPS component was already owned through a native import '+canonical);
    // Route later component/driver imports through this authenticated root.
    // Re-owning its raw canonical imports would reintroduce the provider bodies
    // deliberately moved into CPS, and attempt native-only normalization there.
    modules.set(file,{input:file,output:resolve(output!),original,source:text,extractions:normalized.extractions});
  }else writeFileSync(output!,text);
}
for(const[path,text]of componentInputs)if(readFileSync(path,'utf8')!==text)throw Error('Component canonical source changed during generation '+path);
for(const[path,text]of protectedInputs)if(readFileSync(path,'utf8')!==text)throw Error('Protected input changed '+path);
if(readFileSync(sourcePath,'utf8')!==source)throw Error('Canonical source changed during generation');
const driver=protectedInputs.get('checkpoints/checker_core_driver.bend')!;
const anchor='import ./checker_core_slice.bend as CheckerCore';
if(driver.split(anchor).length!==2)throw Error('Frozen driver import anchor drift');
const driverPath='checkpoints/checker_core_owned_driver_v1.bend';
// The frozen driver is provenance input, not a production ABI template.
const driverTemplate='import ../bend2/selfhost/loaded_module.bend as Loader\nimport ../bend2/selfhost/ast.bend as Ast\nimport ../bend2/selfhost/backend_ir.bend as BIR\nimport ../bend2/selfhost/checked_frontend.bend as Checked\n\ndef parsed_module(namespace: String, module: Ast.Module) -> Loader.LoadedModule:\n  Loader.LoadedModule{namespace, module}\n\ndef check_expanded(modules: List<&2, Loader.LoadedModule>) -> Checked.CheckResult:\n  CheckerCore.check_modules(modules, Nil{})\n';
const driverSource=await ownImports('checkpoints/checker_core_driver.bend',driverPath,driverTemplate);
const ownedLoader=modules.get(realpathSync('bend2/selfhost/loaded_module.bend'))!;
const ownedChecked=modules.get(realpathSync('bend2/selfhost/checked_frontend.bend'))!;
for(const owned of modules.values()){
  if(readFileSync(owned.input,'utf8')!==owned.original)throw Error('Canonical dependency changed during generation '+owned.input);
  if(owned.output===owned.input)continue;
  mkdirSync(dirname(owned.output),{recursive:true});
  writeFileSync(owned.output,owned.source);
}
writeFileSync(slicePath,slice);
writeFileSync('checkpoints/checker_core_owned_component_v1.bend','import '+importSpelling('checkpoints/checker_core_owned_component_v1.bend',ownedLoader.output)+' as Loader\nimport '+importSpelling('checkpoints/checker_core_owned_component_v1.bend',ownedChecked.output)+' as Checked\nimport ./checker_core_owned_v1.bend as CheckerCore\n\ndef check_expanded(modules: List<&2, Loader.LoadedModule>) -> Checked.CheckResult:\n  CheckerCore.check_modules(modules, Nil{})\n');
writeFileSync(driverPath,'import ./checker_core_owned_v1.bend as CheckerCore\n'+driverSource);
const normalizedDefinitions=[...slice.matchAll(/^def ([A-Za-z_]\w*)\(/gm)];
const normalizedDeclarationHashes=Object.fromEntries(normalizedDefinitions.map((match,index)=>[match[1]!,sha(slice.slice(match.index,normalizedDefinitions[index+1]?.index??slice.length))]));
const normalizedOwners=Object.fromEntries(normalizedRoot.extractions.map(row=>[row.helper,row.owner]));
writeFileSync('checkpoints/checker-core-owned-source-v1.json',JSON.stringify({schemaVersion:2,source:sourcePath,sourceSha256:sha(source),slice:slicePath,sliceSha256:sha(slice),root:'check_modules',publicRoots:['check_modules','inspect_checked'],closureDiscovery:'Union of fixedpoints of binding-aware authentic sourceOracle Body references from checking and explicit owner-preserving inspection; fresh complete closure, not historical membership.',definitions:selected.length,definitionNames:selected.map(match=>match[1]!),normalizedDefinitionNames:normalizedDefinitions.map(match=>match[1]!),normalizedDeclarationHashes,normalizedOwners,componentSources,driver:driverPath,driverSha256:sha('import ./checker_core_owned_v1.bend as CheckerCore\n'+driverSource),rootClosure:selected.map(match=>({name:match[1]!,exactCanonicalBlockSha256:sha(canonicalBlocks.get(match[1]!)!)})),historicalDefinitionCount:dependency.included.length,exactCanonicalSignaturesBodiesQuantities:false,sourceOnlyParameterMatchFactoring:true,rootExtractions:normalizedRoot.extractions,ownedModules:[...modules.values()].map(owned=>({source:owned.input,sourceSha256:sha(owned.original),output:owned.output,outputSha256:sha(owned.source),extractions:owned.extractions})),unreachableEntrypoints:omittedEntrypoints,protectedInputs:[...protectedInputs].map(([path,text])=>({path,sha256:sha(text)}))},null,2)+'\n');
console.log(JSON.stringify({slice:slicePath,definitions:selected.length}));
