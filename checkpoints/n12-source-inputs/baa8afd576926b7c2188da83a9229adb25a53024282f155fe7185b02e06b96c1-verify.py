#!/usr/bin/env python3
"""Verify actual unset-caller native build/consumer; never overwrite old authorities."""
import hashlib,json,sys
from pathlib import Path
root,work,out=map(Path,sys.argv[1:])
def load(p):return json.loads(p.read_text())
def digest(p):
 h=hashlib.sha256()
 with open(p,'rb') as f:
  for b in iter(lambda:f.read(1048576),b''):h.update(b)
 return h.hexdigest()
def pin(p):return {'path':str(p),'sha256':digest(p),'bytes':p.stat().st_size}
def guard(r,timeout):
 g=r['guardian'];assert g['status']=='PASS' and g['reportPhase']=='complete' and g['ownedTreeStopped']
 assert g['memoryLimitBytes']==g['rssLimitBytes']==8192*1024*1024 and g['timeoutMs']==timeout
 assert g['commandExitCode']==g['supervisorExitCode']==g['commandSignal']==0
 return g
plan=load(work/'plan.json');consume_plan=load(work/'consume-plan.json');build=load(work/'build.json');run=load(work/'native-consume.json')
assert build['status']=='NATIVE_EXECUTABLE_BUILT_NOT_YET_RUN'
bg=guard(build,600000);rg=guard(run,300000)
assert run['status']=='NATIVE_FULL_COMPILE_PASS'
launcher=root/'evals/native_compiler_experiment.ts'
assert digest(launcher)==plan['afterLauncher']['sha256']
assert build['compilerSha256']==plan['expectedCompilerSha256']==digest(root/'bend2/comp.ts')
assert build['checksExcluded']==build['outputPatches']==0
assert build['checkedDefinitions']==build['expectedSourceDefinitions']==12456 and build['eventsFullyValidated']==13050
runtime=build['runtime'];assert runtime['name']=='bun' and runtime['bun']=='1.4.3' and runtime['execArgv']==[] and runtime['manualGC'] is False
assert runtime['automaticGcRamHint']['bytes']=='4294967296' and runtime['automaticGcRamHint']['hardLimit'] is False
assert plan['buildCommand'][:3]==['/usr/bin/env','-u','BUN_JSC_forceRAMSize']
assert consume_plan['command'][:3]==['/usr/bin/env','-u','BUN_JSC_forceRAMSize']
all_pin_checks=[]
for label,r in [('build',build),('run',run)]:
 for k in ['protectedPins']+(['loadedInputs'] if label=='build' else []):
  for p,h in r[k].items():assert digest(Path(p))==h,p;all_pin_checks.append({'owner':label,'path':p,'sha256':h})
assert run['build']==str(work/'build.json') and run['buildSha256']==digest(work/'build.json')
assert run['command'][0]==build['artifact'] and run['command'][0]==str(work/'native')
assert digest(Path(build['artifact']))==build['artifactSha256']
assert digest(Path(build['cPath']))==build['cSha256']==plan['expectedC']['sha256']
manifest=load(Path(plan['corpus']['path']));assert digest(Path(plan['corpus']['path']))==plan['corpus']['sha256']
assert run['exports']==manifest['exports'] and len(run['exports'])==13 and run['threads']==1
assert [x['phase'] for x in run['phases']]==[x['phase'] for x in run['phaseStarts']]==['parse','expand','check','emit']
assert all(x['chunkQuantum']==64 for x in run['phases'] if x['phase']!='parse')
expected_modules=sum(not x.get('external') for x in manifest['files'])
assert run['result']['result']=='EmitSuccess' and run['result']['modules']==expected_modules
assert len(run['fuel'])==expected_modules and all(x['cells']==8000000 for x in run['fuel'])
image=Path(run['output']);expected=consume_plan['expectedJS']
assert digest(image)==run['outputSha256']==expected['sha256']
assert image.stat().st_size==run['outputBytes']==expected['bytes']
restored=load(root/'checkpoints/local2039g39e12-restored/restored.json');base=[]
for r in restored['baselineSourceChecks']+restored['generatedSources']:
 p=root/r['path'];ok=not(p.exists() or p.is_symlink()) if r.get('expectedAbsent') else digest(p)==r['sha256']
 assert ok,r['path'];base.append(dict(r,matches=ok))
accepted={}
for k,r in restored['acceptedArtifacts'].items():
 p=Path(r['path']);assert digest(p)==r['sha256'];accepted[k]=dict(pin(p),matches=True)
result={'schemaVersion':1,'status':'PASS_CANONICAL_UNSET_CALLER_BUILD_AND_NATIVE_COMPILER_CONSUMER','diagnosticOnly':True,'acceptedCompiler':'G24R12','compilerSourceChanged':False,'launcherChanged':True,'newPerformanceAcceptance':False,'newFixedpointClaim':False,'command':[sys.executable]+sys.argv,'verifier':pin(Path(__file__)),'protocol':pin(work/'plan.json'),'consumerProtocol':pin(work/'consume-plan.json'),'callerHintAbsenceEvidence':'Actual parent command uses env -u; independent child report observes startup hint4GiB. Not reconstructed historical environment.','build':{'receipt':pin(work/'build.json'),'runtime':runtime,'guardian':bg,'checkedDefinitions':build['checkedDefinitions'],'bookEvents':build['eventsFullyValidated'],'C':pin(Path(build['cPath'])),'native':pin(Path(build['artifact'])),'CByteIdenticalToAccepted':True,'nativeByteIdenticalToAccepted':build['artifactSha256']==accepted['native']['sha256'],'codegenMs':build['codegenMs'],'elapsedMs':build['elapsedMs']},'consumer':{'receipt':pin(work/'native-consume.json'),'command':run['command'],'guardian':rg,'result':run['result'],'phases':run['phases'],'fuelRows':len(run['fuel']),'exports':run['exports'],'image':pin(image),'byteIdenticalToAcceptedR12Image':True},'authenticatedPins':all_pin_checks,'baselineChecks':base,'acceptedArtifactsUnchanged':accepted,'limitations':['Fresh build report binds the changed launcher. Historical protected-pin receipts were not rewritten or weakened.','Explicit hint overrides and Node profiling are intentionally preserved by the narrow undefined-only ordinary-Bun branch; not separately rerun.','No fresh stage1->stage2 fixedpoint or12paired performance qualification claimed.','No retrospective historical G36-G39 environment attribution.']}
with open(out,'x') as f:json.dump(result,f,ensure_ascii=False,indent=2);f.write('\n')
print(json.dumps({'status':result['status'],'nativeCMatchesAccepted':True,'nativeImageMatchesAccepted':result['build']['nativeByteIdenticalToAccepted'],'compilerJSMatchesAccepted':True,'buildPeakRssBytes':bg['peakRssBytes'],'consumerPeakRssBytes':rg['peakRssBytes'],'output':str(out)}))
