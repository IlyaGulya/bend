import {expect,test} from 'bun:test';
import {mkdtemp,readdir,readFile,writeFile,rm,access} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join,resolve} from 'node:path';
import {runHeavyGate,type HeavyGateResult} from './heavy_gate.ts';

const gate=resolve(import.meta.dir,'heavy_gate.ts');
const safe={memoryMiB:512,rssMiB:512,pollMs:20,termGraceMs:150,timeoutMs:5000};
async function eventually(path:string):Promise<void>{
 // This integration test awaits an external filesystem marker. The native C
 // supervisor polls the real OS clock; JS fake timers cannot drive that clock.
 const deadline=Date.now()+5000;
 while(Date.now()<deadline){
  try{await access(path);return;}catch{}
  await Bun.sleep(20);
 }
 throw Error(`fixture did not become ready: ${path}`);
}
async function expectStopped(pid:number):Promise<void>{
 const child=Bun.spawn(['/bin/ps','-p',String(pid),'-o','stat='],{stdout:'pipe',stderr:'ignore'});
 const state=(await new Response(child.stdout).text()).trim();
 const exit=await child.exited;
 // Darwin may leave an orphan zombie briefly; it no longer consumes work.
 expect(exit===1||state.startsWith('Z')).toBe(true);
}

// These tests launch only bounded fixtures, never a parser/checker/generator.
// All tests intentionally use a private lock, leaving the real heavy lane alone.

test('normal and failed command exits have distinct recorded outcomes and stale metadata is reusable',async()=>{
 const directory=await mkdtemp(join(tmpdir(),'heavy-gate-test-')),lockPath=join(directory,'gate.lock');
 try{
  // A dead owner's file is not a live kernel lease. It must not block new work.
  await writeFile(lockPath,'999999 0 999998 stale-token\n',{mode:0o600});
  const pass=await runHeavyGate(['/bin/sh','-c','sleep 0.1; exit 0'],{...safe,lockPath,label:'normal exit'});
  expect(pass.status).toBe('PASS');expect(pass.exitCode).toBe(0);
  expect(pass.commandExitCode).toBe(0);expect(pass.reason).toBe('command_exit');
  expect(pass.elapsedMs).toBeGreaterThanOrEqual(80);
  expect(pass.timeoutMs).toBe(safe.timeoutMs);
  expect(pass.peakFootprintBytes).toBeGreaterThan(0);expect(pass.peakRssBytes).toBeGreaterThan(0);
  expect(pass.command).toEqual(['/bin/sh','-c','sleep 0.1; exit 0']);
  const fail=await runHeavyGate(['/bin/sh','-c','exit 7'],{...safe,lockPath});
  expect(fail.status).toBe('FAIL');expect(fail.commandExitCode).toBe(7);expect(fail.exitCode).toBe(1);
 }finally{await rm(directory,{recursive:true,force:true});}
},10000);

test('a contending gate never starts its command and the lease is reusable after exit',async()=>{
 const directory=await mkdtemp(join(tmpdir(),'heavy-gate-test-')),lockPath=join(directory,'gate.lock');
 const ready=join(directory,'ready'),release=join(directory,'release'),forbidden=join(directory,'forbidden');
 let owner:Promise<HeavyGateResult>|undefined;
 try{
  owner=runHeavyGate(['/bin/sh','-c','touch "$1"; while [ ! -f "$2" ]; do sleep 0.05; done','fixture',ready,release],{...safe,lockPath});
  await eventually(ready);
  const busy=await runHeavyGate(['/bin/sh','-c','touch "$1"','fixture',forbidden],{...safe,lockPath});
  expect(busy.status).toBe('LOCK_BUSY');expect(busy.exitCode).toBe(75);
  expect(busy.reason).toBe('exclusive_lock_busy');
  expect(await Bun.file(forbidden).exists()).toBe(false);
  await writeFile(release,'release');expect((await owner).status).toBe('PASS');
  expect((await runHeavyGate(['true'],{...safe,lockPath})).status).toBe('PASS');
 }finally{
  await writeFile(release,'release');if(owner)await owner;
  await rm(directory,{recursive:true,force:true});
 }
},10000);

test('an authenticated descendant runs under the existing lease and preserves its own exit outcome',async()=>{
 const directory=await mkdtemp(join(tmpdir(),'heavy-gate-test-')),lockPath=join(directory,'gate.lock');
 const script=join(directory,'guarded.ts');
 try{
  await writeFile(script,`import {guardHeavyGate} from ${JSON.stringify(gate)};
await guardHeavyGate(import.meta.path,{label:'fixture guard'});
if(process.argv[2]==='child')process.exit(7);
const child=Bun.spawn([process.execPath,import.meta.path,'child'],{stdout:'inherit',stderr:'inherit'});
process.exitCode=await child.exited;
`);
  const result=await runHeavyGate([process.execPath,script,'parent','--memory-mib','512','--rss-mib=512'],{...safe,lockPath});
  expect(result.status).toBe('FAIL');
  expect(result.reason).toBe('command_exit');
  expect(result.commandExitCode).toBe(7);
 }finally{await rm(directory,{recursive:true,force:true});}
},10000);

test('deadline cancels authenticated detached descendants without resetting the parent allowance and releases the lease',async()=>{
 const directory=await mkdtemp(join(tmpdir(),'heavy-gate-test-')),lockPath=join(directory,'gate.lock');
 const script=join(directory,'deadline.ts');
 const rootPid=join(directory,'root.pid'),childPid=join(directory,'child.pid');
 const rootTerm=join(directory,'root.term'),childTerm=join(directory,'child.term');
 try{
  // Native monotonic deadlines and TERM/KILL act on real processes; fake JS
  // timers cannot advance the supervisor clock or keep this fixture alive.
  await writeFile(script,`import {guardHeavyGate} from ${JSON.stringify(gate)};
import {spawn} from 'node:child_process';
import {writeFileSync} from 'node:fs';
await guardHeavyGate(import.meta.path,{label:'deadline fixture'});
const child=process.argv[2]==='child';
writeFileSync(child?${JSON.stringify(childPid)}:${JSON.stringify(rootPid)},String(process.pid));
process.on('SIGTERM',()=>writeFileSync(child?${JSON.stringify(childTerm)}:${JSON.stringify(rootTerm)},'TERM received'));
if(!child)spawn(process.execPath,[import.meta.path,'child','--timeout-ms=10000'],{
 detached:true,stdio:'inherit',env:{...process.env,HEAVY_GATE_TIMEOUT_MS:'10000'},
});
setInterval(()=>{},20);
`);
  const result=await runHeavyGate([process.execPath,script],{...safe,timeoutMs:2000,lockPath});
  expect(result.status).toBe('FAIL');expect(result.reason).toBe('deadline_exceeded');
  expect(result.exitCode).toBe(1);expect(result.timeoutMs).toBe(2000);
  expect(result.elapsedMs).toBeGreaterThanOrEqual(2000);
  expect(result.elapsedMs).toBeLessThan(5000);
  expect(await Bun.file(rootTerm).exists()).toBe(true);
  expect(await Bun.file(childTerm).exists()).toBe(true);
  await expectStopped(Number(await readFile(rootPid,'utf8')));
  await expectStopped(Number(await readFile(childPid,'utf8')));
  const receipt=JSON.parse(await readFile(result.reportPath,'utf8'));
  expect(receipt.status).toBe('FAIL');expect(receipt.reason).toBe('deadline_exceeded');
  expect(receipt.timeoutMs).toBe(2000);
  expect((await runHeavyGate(['true'],{...safe,lockPath})).status).toBe('PASS');
 }finally{await rm(directory,{recursive:true,force:true});}
},10000);

test('CLI and environment deadlines are finite and reported',async()=>{
 const directory=await mkdtemp(join(tmpdir(),'heavy-gate-test-')),lockPath=join(directory,'gate.lock');
 try{
  const run=async(args:string[],timeout:string)=>{
   const child=Bun.spawn([process.execPath,gate,'--lock-path',lockPath,'--poll-ms=20','--term-grace-ms=100',...args,'--','/bin/sleep','30'],{
    env:{...process.env,HEAVY_GATE_TIMEOUT_MS:timeout},stdout:'ignore',stderr:'pipe',
   });
   const stderr=await new Response(child.stderr).text();
   expect(await child.exited).toBe(1);
   const record=stderr.trim().split('\n').find(line=>line.startsWith('HEAVY_GATE '));
   expect(record).toBeDefined();
   return JSON.parse(record!.slice('HEAVY_GATE '.length));
  };
  const environment=await run([],'250');
  expect(environment.status).toBe('FAIL');expect(environment.reason).toBe('deadline_exceeded');
  expect(environment.timeoutMs).toBe(250);
  const cli=await run(['--timeout-ms','300'],'10000');
  expect(cli.status).toBe('FAIL');expect(cli.reason).toBe('deadline_exceeded');
  expect(cli.timeoutMs).toBe(300);
  for(const timeoutMs of [0,-1,0.5,NaN,Infinity,2147483648])
   await expect(runHeavyGate(['true'],{...safe,timeoutMs,lockPath})).rejects.toThrow('timeout-ms must be an integer between 1 and 2147483647');
  expect((await runHeavyGate(['true'],{...safe,lockPath})).status).toBe('PASS');
 }finally{await rm(directory,{recursive:true,force:true});}
},10000);

test('helper compilation has a deadline and kills its compiler descendants',async()=>{
 const directory=await mkdtemp(join(tmpdir(),'heavy-gate-test-')),lockPath=join(directory,'gate.lock');
 const compiler=join(directory,'compiler'),rootPid=join(directory,'compiler.pid'),childPid=join(directory,'compiler-child.pid');
 try{
  // No compilation is performed: an isolated TMPDIR forces a cache miss and a
  // bounded stand-in exercises the helper's real process-group cancellation.
  await writeFile(compiler,`#!/bin/sh
trap '' TERM
echo $$ > "${rootPid}"
sleep 30 &
echo $! > "${childPid}"
wait
`,{mode:0o700});
  const child=Bun.spawn([process.execPath,gate,'--lock-path',lockPath,'--timeout-ms=250','--','true'],{
   env:{...process.env,TMPDIR:directory,CC:compiler},stdout:'ignore',stderr:'pipe',
  });
  const stderr=await new Response(child.stderr).text();
  expect(await child.exited).toBe(125);
  const record=stderr.trim().split('\n').find(line=>line.startsWith('HEAVY_GATE '));
  expect(record).toBeDefined();
  const receipt=JSON.parse(record!.slice('HEAVY_GATE '.length));
  expect(receipt.status).toBe('FAIL');expect(receipt.reason).toBe('helper_deadline_exceeded');
  expect(receipt.timeoutMs).toBe(250);
  await expectStopped(Number(await readFile(rootPid,'utf8')));
  await expectStopped(Number(await readFile(childPid,'utf8')));
  expect(await Bun.file(lockPath).exists()).toBe(false);
 }finally{await rm(directory,{recursive:true,force:true});}
},10000);

test('a forged inherited token cannot bypass a busy gate',async()=>{
 const directory=await mkdtemp(join(tmpdir(),'heavy-gate-test-')),lockPath=join(directory,'gate.lock');
 const ready=join(directory,'ready'),release=join(directory,'release'),marker=join(directory,'forbidden'),script=join(directory,'forged.ts');
 let owner:Promise<HeavyGateResult>|undefined;
 try{
  await writeFile(script,`import {guardHeavyGate} from ${JSON.stringify(gate)};
await guardHeavyGate(import.meta.path,{label:'forged guard'});
await Bun.write(${JSON.stringify(marker)},'unsafe');`);
  owner=runHeavyGate(['/bin/sh','-c','touch "$1"; while [ ! -f "$2" ]; do sleep 0.05; done','fixture',ready,release],{...safe,lockPath});
  await eventually(ready);
  const child=Bun.spawn([process.execPath,script,'--lock-path',lockPath],{
   env:{...process.env,HEAVY_GATE_LEASE_PATH:lockPath,HEAVY_GATE_LEASE_TOKEN:'0'.repeat(64)},stdout:'ignore',stderr:'inherit',
  });
  expect(await child.exited).toBe(75);expect(await Bun.file(marker).exists()).toBe(false);
  // Even the correct capability, copied into an unrelated process, is not an
  // inherited lease: native authentication also checks ancestry/process group.
  const actualToken=(await readFile(lockPath,'utf8')).trim().split(/\s+/)[3]!;
  const unrelated=Bun.spawn([process.execPath,script,'--lock-path',lockPath],{
   env:{...process.env,HEAVY_GATE_LEASE_PATH:lockPath,HEAVY_GATE_LEASE_TOKEN:actualToken},stdout:'ignore',stderr:'inherit',
  });
  expect(await unrelated.exited).toBe(75);expect(await Bun.file(marker).exists()).toBe(false);
 }finally{
  await writeFile(release,'release');if(owner)await owner;
  await rm(directory,{recursive:true,force:true});
 }
},10000);

test('descendant footprint breaches report RESOURCE_LIMIT and TERM precedes bounded KILL',async()=>{
 const directory=await mkdtemp(join(tmpdir(),'heavy-gate-test-')),lockPath=join(directory,'gate.lock');
 const pidFile=join(directory,'pid'),term=join(directory,'term'),script=join(directory,'allocate.ts');
 try{
  // 96 MiB touched once: small fixed fixture, not an unbounded allocator. The
  // shell itself stays tiny; only its Bun descendant crosses the footprint cap.
  // Genuine clock behavior is intentional here: TERM grace and KILL are native
  // OS actions and cannot be driven with fake JavaScript timers.
  await writeFile(script,`import {writeFileSync} from 'node:fs';
writeFileSync(${JSON.stringify(pidFile)},String(process.pid));
process.on('SIGTERM',()=>writeFileSync(${JSON.stringify(term)},'TERM received'));
const retained=Buffer.alloc(96*1024*1024,1);
setInterval(()=>{if(retained[0]!==1)process.exit(2);},20);
`);
  const result=await runHeavyGate(['/bin/sh','-c','"$1" "$2" & wait','fixture',process.execPath,script],{
   ...safe,memoryMiB:96,rssMiB:512,termGraceMs:150,lockPath,
  });
  expect(result.status).toBe('RESOURCE_LIMIT');expect(result.exitCode).toBe(73);
  expect(result.reason).toBe('physical_footprint_limit');
  expect(result.peakFootprintBytes).toBeGreaterThan(96*1024*1024);
  expect(await Bun.file(term).exists()).toBe(true);
  const pid=Number(await readFile(pidFile,'utf8'));
  await expectStopped(pid);
  expect((await runHeavyGate(['true'],{...safe,lockPath})).status).toBe('PASS');
 }finally{await rm(directory,{recursive:true,force:true});}
},10000);

test('RSS has an independent resource-limit outcome',async()=>{
 const directory=await mkdtemp(join(tmpdir(),'heavy-gate-test-')),lockPath=join(directory,'gate.lock');
 try{
  const result=await runHeavyGate([process.execPath,'--eval','const b=Buffer.alloc(96*1024*1024,1);setInterval(()=>b[0],20)'],{
   ...safe,memoryMiB:512,rssMiB:96,lockPath,
  });
  expect(result.status).toBe('RESOURCE_LIMIT');expect(result.reason).toBe('rss_limit');
  expect(result.peakRssBytes).toBeGreaterThan(96*1024*1024);
 }finally{await rm(directory,{recursive:true,force:true});}
},10000);

test('root exit cleans remaining process-group descendants before releasing its lease',async()=>{
 const directory=await mkdtemp(join(tmpdir(),'heavy-gate-test-')),lockPath=join(directory,'gate.lock');
 const pidFile=join(directory,'pid');
 try{
  const result=await runHeavyGate(['/bin/sh','-c','sleep 30 & echo $! > "$1"; sleep 0.1; exit 0','fixture',pidFile],{...safe,lockPath});
  expect(result.status).toBe('FAIL');expect(result.reason).toBe('descendants_after_exit');
  const pid=Number((await readFile(pidFile,'utf8')).trim());
  expect(pid).toBeGreaterThan(0);
  await expectStopped(pid);
  expect((await runHeavyGate(['true'],{...safe,lockPath})).status).toBe('PASS');
 }finally{await rm(directory,{recursive:true,force:true});}
},10000);

test('parent death triggers cleanup and automatically releases the stale kernel owner',async()=>{
 const directory=await mkdtemp(join(tmpdir(),'heavy-gate-test-')),lockPath=join(directory,'gate.lock');
 const ready=join(directory,'ready'),term=join(directory,'term'),script=join(directory,'owner.ts');
 try{
  const command=['/bin/sh','-c','echo $$ > "$1"; trap \'echo TERM > "$2"; exit 0\' TERM; sleep 30 & wait','fixture',ready,term];
  await writeFile(script,`import {runHeavyGate} from ${JSON.stringify(gate)};\nawait runHeavyGate(${JSON.stringify(command)},${JSON.stringify({...safe,lockPath})});`);
  const owner=Bun.spawn([process.execPath,script],{stdout:'ignore',stderr:'ignore'});
  try{
   await eventually(ready);
   owner.kill('SIGKILL');await owner.exited;
   await eventually(term);
   const pid=Number((await readFile(ready,'utf8')).trim());
   // Wait on the observable lock condition, not an arbitrary guessed delay.
   // Native parent-death polling and TERM grace require the real platform clock.
   const deadline=Date.now()+5000;
   let result:HeavyGateResult;
   do{
    result=await runHeavyGate(['true'],{...safe,lockPath});
    if(result.status!=='LOCK_BUSY')break;
    if(Date.now()>deadline)throw Error('dead parent retained the heavy lease');
    await Bun.sleep(20);
   }while(true);
   expect(result.status).toBe('PASS');await expectStopped(pid);
  }finally{owner.kill('SIGKILL');await owner.exited;}
 }finally{await rm(directory,{recursive:true,force:true});}
},10000);

test('launcher process-group kill leaves the supervisor independent and terminal',async()=>{
 const directory=await mkdtemp(join(tmpdir(),'heavy-gate-test-')),lockPath=join(directory,'gate.lock');
 const ready=join(directory,'ready'),script=join(directory,'launcher.ts');
 const reportDir=join(tmpdir(),`bend-heavy-gate-${process.getuid?.()??0}`);
 const before=new Set(await readdir(reportDir).catch(()=>[] as string[]));
 let launcher:Bun.Subprocess|undefined;
 try{
  const command=['/bin/sh','-c','echo $$ > "$1"; exec sleep 30','fixture',ready];
  await writeFile(script,`import {runHeavyGate} from ${JSON.stringify(gate)};
await runHeavyGate(${JSON.stringify(command)},${JSON.stringify({...safe,lockPath,timeoutMs:3000,label:'launcher group kill'})});`);
  // The launcher is its own process-group leader so the fixture can kill the
  // whole group exactly as a job-control launcher would.
  launcher=Bun.spawn([process.execPath,script],{detached:true,stdio:['ignore','ignore','ignore']});
  await eventually(ready);
  process.kill(-launcher.pid,'SIGKILL');await launcher.exited;
  // The detached native supervisor survives the group kill, observes the
  // lifeline EOF, stops the owned command and writes a bounded terminal
  // receipt. It must not leave an empty report or a hanging lease.
  const deadline=Date.now()+8000;let receipt:Record<string,unknown>|undefined;
  while(Date.now()<deadline){
   for(const name of (await readdir(reportDir).catch(()=>[] as string[])).filter(name=>name.startsWith('report-')&&!before.has(name))){
    try{const text=await readFile(join(reportDir,name),'utf8');if(text.trim()){receipt=JSON.parse(text);break;}}catch{}
   }
   if(receipt)break;
   await Bun.sleep(20);
  }
  expect(receipt).toBeDefined();
  expect(receipt!.status).toBe('FAIL');
  expect(['interrupted','deadline_exceeded','command_signal','descendants_after_exit','cleanup_incomplete']).toContain(receipt!.reason);
  expect((await runHeavyGate(['true'],{...safe,lockPath})).status).toBe('PASS');
  await expectStopped(Number((await readFile(ready,'utf8')).trim()));
 }finally{
  if(launcher)launcher.kill('SIGKILL');
  await rm(directory,{recursive:true,force:true});
 }
},20000);
