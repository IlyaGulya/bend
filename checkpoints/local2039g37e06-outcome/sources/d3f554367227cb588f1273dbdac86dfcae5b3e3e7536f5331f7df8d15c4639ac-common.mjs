import assert from 'node:assert/strict';
import {readFileSync,writeFileSync,mkdirSync,existsSync,realpathSync,statSync,lstatSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
import {resolve,relative,dirname,basename,extname,isAbsolute} from 'node:path';
export {assert,readFileSync,existsSync,resolve,relative,dirname,basename,extname,realpathSync};
import {createHash} from 'node:crypto';
export const LIMITS={memoryMiB:8192,rssMiB:8192,pollMs:10,timeoutMs:600000};
export const ABI=['parsed_module','parse_with_fuel','expand_modules_start','template_step','check_expanded_start','inspect_checked_start','checker_step','emit_modules_start','emit_library_start','emitter_step','emit_c_modules_start','emit_c_library_start','c_emitter_step'];
export const sha=b=>createHash('sha256').update(b).digest('hex');
export const hash=p=>sha(readFileSync(p));
export const json=p=>JSON.parse(readFileSync(p,'utf8'));
export const pin=p=>({path:resolve(p),sha256:hash(p),bytes:statSync(p).size});
export function save(p,value){mkdirSync(dirname(p),{recursive:true});writeFileSync(p,JSON.stringify(value,null,2)+'\n',{flag:'wx'});}
export function put(p,bytes){mkdirSync(dirname(p),{recursive:true});writeFileSync(p,bytes,{flag:'wx'});}
export function fresh(p){assert.ok(!existsSync(p),'Fresh output directory required: '+p);mkdirSync(p,{recursive:true});}
export function rel(p){assert.equal(typeof p,'string');assert.ok(p.length&&!isAbsolute(p)&&!p.split('/').some(x=>x==='..'||x==='.'||!x),'Repository-relative path required: '+p);assert.ok(!p.includes('\\')&&!p.includes('\0'));return p;}
export function within(root,p){const r=relative(root,resolve(root,p));rel(r);return r;}
export function file(p){assert.ok(lstatSync(p).isFile(),'Regular non-symlink file required: '+p);return readFileSync(p);}
export function git(repo,...args){const r=spawnSync('/usr/bin/git',args,{cwd:repo,encoding:null,maxBuffer:64*1024*1024,timeout:30000});assert.equal(r.status,0,'git '+args.join(' ')+': '+String(r.stderr));return r.stdout;}
export function commit(repo,c){assert.match(c,/^[0-9a-f]{7,40}$/,'Explicit hexadecimal commit required');return git(repo,'rev-parse',c+'^{commit}').toString().trim();}
export function blob(repo,c,p){rel(p);const r=spawnSync('/usr/bin/git',['show',c+':'+p],{cwd:repo,encoding:null,maxBuffer:64*1024*1024,timeout:30000});if(r.status===0)return r.stdout;assert.ok(!r.error,'Git source lookup failed: '+r.error);assert.ok(r.status===128,'Unexpected git failure: '+r.stderr);return null;}
export function config(action){assert.equal(process.argv.length,4,'Usage: node '+basename(process.argv[1])+' '+action+' CONFIG.json');assert.equal(process.argv[2],action);const path=resolve(process.argv[3]);return {path,value:json(path)};}
export function limits(x){assert.deepEqual(x,LIMITS,'Original resource limits required');}
export function guardian(g){assert.ok(g);assert.equal(g.status,'PASS');assert.equal(g.ownedTreeStopped,true);assert.equal(g.reportPhase,'complete');assert.equal(g.commandExitCode,0);assert.equal(g.timeoutMs,600000);assert.equal(g.memoryLimitBytes,8589934592);assert.equal(g.rssLimitBytes,8589934592);for(const k of ['peakRssBytes','peakFootprintBytes'])assert.ok(Number.isFinite(g[k])&&g[k]>0&&g[k]<=8589934592,k);}
export function sourceKind(p,kind){assert.ok(['source','manifest','tooling'].includes(kind));assert.ok(!/(^|\/)(node_modules|\.git)(\/|$)/.test(p));assert.ok(!/(\.ast\.|\.heapsnapshot$|\.cpuprofile$|\.v8$|\.log$|\.stdout$|\.stderr$|package(?:-lock)?\.json$|bun\.lock$)/i.test(p),'Forbidden checkpoint input: '+p);assert.ok(kind==='manifest'?extname(p)==='.json':['.bend','.ts','.mjs','.js','.c','.h','.md'].includes(extname(p)),'Unsupported source input: '+p);}
export function rejectEmitted(p){assert.ok(!/(?:^|\/)(?:root|stage-one|stage-two|native)\.(?:js|mjs|c)$|\.(?:output|compiler|instrumented)\.(?:js|mjs|c)$|\/checkpoints\/.*\.(?:js|mjs|c)$/.test(p),'Emitted compiler/consumer output is not SOURCE: '+p);}
// Compact only diagnostic tails and embedded generated outputs. Scalar measurements,
// commands, statuses, source pins and every sample remain unchanged.
export function compact(v){if(Array.isArray(v))return v.map(compact);if(!v||typeof v!=='object')return v;return Object.fromEntries(Object.entries(v).filter(([k])=>!['stderrTail','stdoutTail','generatedSource','generatedCode','ast','profile'].includes(k)).map(([k,x])=>[k,compact(x)]));}
export function verifyPin(x){assert.equal(hash(x.path),x.sha256,'Changed evidence: '+x.path);return x;}
