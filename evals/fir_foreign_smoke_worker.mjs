import {readFileSync,unlinkSync,writeFileSync} from 'node:fs';
import {join} from 'node:path';
import {pathToFileURL} from 'node:url';
import {spawnSync} from 'node:child_process';
import {
 runTemplateSteps,runCheckerSteps,runLibraryEmitterSteps,runEmitterSteps,
 sourceFileEntries,sourceFiles,declaredSourcePaths,OFFICIAL_SOURCE_FILE_TAG,
} from './checker_core_step_runtime.mjs';

const request=JSON.parse(readFileSync(process.argv[2],'utf8'));
const tag=value=>value?.$?.split('.').at(-1);
const list=values=>values.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const failure=(stage,result)=>{throw Error(stage+' failed: '+String(result?.message??result?.diagnostic?.message??tag(result)));};

const component=(await import(pathToFileURL(request.component).href)).default;
const parser=(await import(pathToFileURL(request.parser).href)).default;
const needed=['parsed_module','expand_modules_start','template_step','check_expanded_start','checker_step','emit_modules_start','emit_library_start','emitter_step'];
if(!component||needed.some(name=>typeof component[name]!=='function'))throw Error('Smoke component lacks the current typed ABI');

function parse(file,source){
 let fuel={$:'FeedbackFuelEnd'};for(let i=0;i<2000000;i++)fuel={$:'FeedbackFuelCell',tail:fuel};
 const feedback=parser.parse_with_fuel(fuel,file,source);fuel=undefined;
 if(tag(feedback)!=='FeedbackComplete')throw Error('Compiled parser feedback did not complete: '+tag(feedback));
 const result=feedback.value?.result;
 if(tag(result)!=='ParseSuccess')failure('parse',result);
 return result.module;
}
function modulesOf(base,modulePath,sourceText){
 return list([component.parsed_module('',base),component.parsed_module('',parse(modulePath,sourceText))]);
}
function checkedProgram(base,modulePath,sourceText){
 let modules=modulesOf(base,modulePath,sourceText);
 let expanded=runTemplateSteps({...component,expand_modules_start:input=>{modules=undefined;return component.expand_modules_start(input);}},modules);
 if(tag(expanded)!=='ExpandSuccess')failure('expand',expanded);
 let checked=runCheckerSteps({...component,check_expanded_start:input=>{expanded=undefined;return component.check_expanded_start(input);}},expanded.modules);
 if(tag(checked)!=='CheckSuccess')failure('check',checked);
 return checked.program;
}
function execute(artifact){
 const run=spawnSync(process.execPath,[artifact],{encoding:'utf8',timeout:120000,killSignal:'SIGKILL'});
 if(run.error||run.status!==0)throw Error('Emitted smoke artifact failed: '+String(run.error??run.stderr));
 return run.stdout.trim();
}

// A library artifact is an ES module, so the host imports the unchanged file
// rather than executing it; only the actual spliced effect bytes print.
function importLibrary(artifact,runner){
 writeFileSync(runner,'await import('+JSON.stringify(pathToFileURL(artifact).href)+');\n');
 const run=spawnSync(process.execPath,[runner],{encoding:'utf8',timeout:120000,killSignal:'SIGKILL'});
 if(run.error||run.status!==0)throw Error('Emitted library import failed: '+String(run.error??run.stderr));
 return run.stdout.trim();
}

const base=parse(request.base,readFileSync(request.base,'utf8'));
const source=parse(request.file,request.source);
// The bag is built once, from the declared `.js` alternatives of the real
// modules only, then the effect file is removed: any later emission that still
// produced the effect could only have read the host's bytes, not the disk.
const entries=[
 ...sourceFileEntries(request.base,declaredSourcePaths(base)),
 ...sourceFileEntries(request.file,declaredSourcePaths(source)),
];
const files=sourceFiles(entries,OFFICIAL_SOURCE_FILE_TAG);
const effectSha=request.effectSha256;
if(!entries.some(entry=>entry.path===request.effectPath&&entry.source===readFileSync(request.effectPath,'utf8')))throw Error('Bag is missing the declared effect bytes');
unlinkSync(request.effectPath);
const rows=[];
try{
 const libraryProgram=checkedProgram(base,request.file,request.source);
 const library=runLibraryEmitterSteps(component,libraryProgram,list(request.exports),files);
 if(tag(library)!=='EmitSuccess')failure('emit-library',library);
 if(!library.source.includes(request.marker))throw Error('Library emission did not splice the effect bytes');
 if(!library.source.includes('io_fir_mark'))throw Error('Library emission lost the actual effect handler name');
 const libraryPath=join(request.sidecars,'library.mjs');
 writeFileSync(libraryPath,library.source);
 const api=(await import(pathToFileURL(libraryPath).href)).default;
 if(!api||request.exports.some(name=>typeof api[name]!=='function'))throw Error('Emitted library lacks the requested API');
 const observed=importLibrary(libraryPath,join(request.sidecars,'import_library.mjs'));
 if(observed!==request.loadMarker)throw Error('Spliced effect bytes did not execute: expected '+request.loadMarker+', observed '+observed);
 rows.push({lane:'emit_library_start',passed:true,artifact:libraryPath,exports:request.exports,output:observed,splicedBytes:true,effectSha256:effectSha,sourceBytes:Buffer.byteLength(library.source)});

 const moduleProgram=checkedProgram(base,request.file,request.source);
 const emitted=runEmitterSteps(component,moduleProgram,files);
 if(tag(emitted)!=='EmitSuccess')failure('emit-modules',emitted);
 const artifact=join(request.sidecars,'program.js');
 writeFileSync(artifact,emitted.source);
 const output=execute(artifact),expected=[request.loadMarker,request.expected].join('\n');
 if(output!==expected)throw Error('Emitted program output mismatch: expected '+expected+', observed '+output);
 rows.push({lane:'emit_modules_start',passed:true,artifact,output,effectSha256:effectSha,sourceBytes:Buffer.byteLength(emitted.source)});
 writeFileSync(join(request.sidecars,'result.json'),JSON.stringify({passed:true,rows},null,2)+'\n');
}catch(error){
 writeFileSync(join(request.sidecars,'result.json'),JSON.stringify({passed:false,error:String(error),rows},null,2)+'\n');
 throw error;
}
