import assert from 'node:assert/strict';
import {readFileSync,writeFileSync,mkdirSync,realpathSync} from 'node:fs';
import {resolve,dirname,relative} from 'node:path';
import {createHash} from 'node:crypto';
import {normalizeNativeMatchSource} from '/Users/ilyagulya/Projects/My/bend/evals/native_match_source.ts';
const [repo,suite]=process.argv.slice(2);assert.ok(repo&&suite);
const sha=(s:string|Uint8Array)=>createHash('sha256').update(s).digest('hex');
const original=resolve(repo,'evals/descriptor_nf_smoke.bend'),files=new Map<string,{source:string;staged:string}>(),order:string[]=[];
function visit(input:string){
  input=realpathSync(input);if(files.has(input))return;
  const source=readFileSync(input,'utf8'),staged=resolve(suite,'descriptor-sources',relative(repo,input));assert.ok(staged.startsWith(resolve(suite)+'/'));
  files.set(input,{source,staged});
  for(const m of source.matchAll(/^import (\S+)(?: as \w+)?\s*$/gm))if(m[1]!=='Base'&&m[1].endsWith('.bend'))visit(resolve(dirname(input),m[1]));
  order.push(input);
}
visit(original);
for(const [input,file]of files){
  const rebased=file.source.replace(/^import (\S+)(.*)$/gm,(_line,path,suffix)=>{if(path==='Base')return'import Base'+suffix;const target=resolve(dirname(input),path);return'import '+(files.get(target)?.staged??target)+suffix;});
  mkdirSync(dirname(file.staged),{recursive:true});writeFileSync(file.staged,rebased,{flag:'wx'});
}
const normalizedInputs=[];
for(const input of order){
  const file=files.get(input)!,rebased=readFileSync(file.staged,'utf8'),normalized=await normalizeNativeMatchSource(file.staged,rebased);
  writeFileSync(file.staged,normalized.source);
  normalizedInputs.push({original:input,originalSha256:sha(file.source),staged:file.staged,rebasedSha256:sha(rebased),normalizedSha256:sha(normalized.source),extractions:normalized.extractions});
}
const implementation=files.get(original)!.staged,wrapper=resolve(suite,'descriptor-semantics.bend');
writeFileSync(wrapper,'import Base\nimport '+implementation+' as Smoke\n\ndef print_smoke(value: Smoke.NfSmoke) -> IO(Unit):\n  match value:\n    case Smoke.NfSmoke{bits}: IO.print(bits)\n\ndef main() -> IO(Unit):\n  print_smoke(Smoke.main(Nil{}))\n\n#|11111111111111111111111111111111111111\n',{flag:'wx'});
const report={original,originalSha256:sha(readFileSync(original)),implementation,implementationSha256:sha(readFileSync(implementation)),wrapper,wrapperSha256:sha(readFileSync(wrapper)),normalizedInputs,normalizer:resolve(repo,'evals/native_match_source.ts'),normalizerSha256:sha(readFileSync(resolve(repo,'evals/native_match_source.ts'))),scope:'The existing source-only native-match extraction over every original transitive smoke implementation module. Only source-owned scrutinee/continuation factoring; no descriptor algorithm, budgets or expected36bits changed. Base remains the original source. Actual own frontend/renderers and C/JS execution still required.'};
writeFileSync(resolve(suite,'descriptor-generation.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify(report));
