#!/usr/bin/env python3
"""Offline only: authenticate historical construction records and freeze source bytes.
No compiler, generator, profiler or runtime workload is invoked.
"""
import hashlib, json, os, pathlib, re, subprocess, sys
ROOT = pathlib.Path('/Users/ilyagulya/Projects/My/bend')
OUT = pathlib.Path(__file__).resolve().parent
sha = lambda b: hashlib.sha256(b).hexdigest()
def load(p): return json.loads(pathlib.Path(p).read_text())
def save(name, obj):
    (OUT/name).write_text(json.dumps(obj, indent=2, ensure_ascii=False)+'\n')
def absolute(p): return pathlib.Path(p) if str(p).startswith('/') else ROOT/p
def walk(v):
    if isinstance(v, dict):
        yield v
        for x in v.values(): yield from walk(x)
    elif isinstance(v, list):
        for x in v: yield from walk(x)
def pin(p):
    p=absolute(p)
    if not p.is_file(): return {'path':str(p),'exists':False,'sha256':None}
    b=p.read_bytes(); return {'path':str(p),'exists':True,'sha256':sha(b),'bytes':len(b)}
INDEX=load(ROOT/'evals/receipts/experiments_e01_e13_completed.json')
primary=[]; documents=[]
for e in INDEX['experiments']:
    q=e['primary']; a=pin(q['path']); a.update(expectedSha256=q['sha256'],matches=a['sha256']==q['sha256'],experiment=e['id']); primary.append(a)
    if not a['matches']: raise RuntimeError('Primary authentication failed: '+q['path'])
    documents.append(load(a['path']))
restoration=load(ROOT/'checkpoints/local2039g39e12-restored/restored.json'); documents.append(restoration)
paths={'R12':'local2039g24r12','G35':'local2039g35e08-full','G36':'local2039g36e05-full','G37':'local2039g37e06full01','G38':'local2039g38e10full01','G39':'local2039g39e12full01'}
records={}
for tag,d in paths.items():
    folder=ROOT/'checkpoints'/d
    records[tag]={n:load(folder/n) for n in ['root.native.corpus.json','root-native-build.json','root-native-build.json.inputs.json','receipt.json']}
    documents.extend(records[tag].values())
# Content addresses in retained receipts can resolve restored/overwritten paths.
by_hash={}; authorities={}; expected_paths={}
for doc in documents:
    for v in walk(doc):
        h=v.get('sha256'); p=v.get('path')
        if isinstance(h,str) and re.fullmatch('[0-9a-f]{64}',h):
            if isinstance(p,str): by_hash.setdefault(h,[]).append(absolute(p)); expected_paths.setdefault(str(absolute(p)),set()).add(h)
            a=v.get('authority',{})
            if a.get('checkpointSource'): by_hash.setdefault(h,[]).append(absolute(a['checkpointSource']))
            if a.get('gitCommit') and a.get('path'): authorities.setdefault(h,[]).append((a['gitCommit'],a['path']))
# Scan names only, not bulk artifacts. Only content-addressed source snapshots qualify.
for folder, dirs, files in os.walk(ROOT/'checkpoints'):
    dirs[:]=[x for x in dirs if x not in ['node_modules','.git'] and not x.endswith('.cases') and not x.startswith(('matrix-','throughput'))]
    for f in files:
        if re.match(r'^[0-9a-f]{64}-',f): by_hash.setdefault(f[:64],[]).append(pathlib.Path(folder)/f)
cache={}; attempts={}
def resolve_source(path,h):
    key=(str(path),h)
    if key in cache: return cache[key]
    tried=[]
    for p in dict.fromkeys([absolute(path)]+by_hash.get(h,[])):
        if p.is_file():
            b=p.read_bytes(); got=sha(b)
            if got==h:
                ans=(b,{'kind':'file','path':str(p),'sha256':got}); cache[key]=ans; return ans
            tried.append({'path':str(p),'actualSha256':got})
    # Immutable commits found by git log on the authenticated primary receipts.
    # Expected SHA256, not commit naming, decides whether a blob is admissible.
    rel=str(absolute(path).relative_to(ROOT)) if absolute(path).is_relative_to(ROOT) else None
    if rel:
        authorities.setdefault(h,[]).extend((commit,rel) for commit in [
            '914b218ca43c18cade3cc40904bde55e87cd5775',
            'ce28d3c08532d32151d4d900562f19ddfb2a7540'])
    for commit,p in authorities.get(h,[]):
        run=subprocess.run(['/usr/bin/git','show',commit+':'+p],cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
        if run.returncode==0 and sha(run.stdout)==h:
            ans=(run.stdout,{'kind':'git-blob','commit':commit,'path':p,'sha256':h});cache[key]=ans;return ans
    attempts[key]=tried; cache[key]=(None,None);return None,None
inventory=[]
def source_record(tag,role,path,h):
    b,authority=resolve_source(path,h)
    row={'version':tag,'role':role,'logicalPath':str(path),'expectedSha256':h,'authenticated':b is not None,'authority':authority}
    if b is not None:
        row['bytes']=len(b)
        if str(path).endswith(('.bend','.ts','.mjs','.c','.js')):
            t=b.decode('utf-8'); row['sourceShape']={'utf16Units':len(t.encode('utf-16-le'))//2,'lines':t.count('\n'),'rawSha256':h,'diagnosticNormalizedSha256':sha(re.sub(r'local2039g(?:24r12|3[5-9][A-Za-z0-9]*)','<RUN>',t).encode()),'normalization':'run-id spelling only; not semantic equivalence'}
    else: row['missingReason']='No matching retained file or receipt-authorized git blob';row['attempts']=attempts.get((str(path),h),[])
    inventory.append(row);return row
rows=[]
for tag,d in paths.items():
    folder=ROOT/'checkpoints'/d; rec=records[tag]; corpus=rec['root.native.corpus.json']; build=rec['root-native-build.json']; pins=rec['root-native-build.json.inputs.json']
    sources=[source_record(tag,'constructor-corpus',f['path'],f['sha256']) for f in corpus['files']]
    protected=[source_record(tag,'constructor-protected',p,h) for p,h in pins.items()]
    loaded=[source_record(tag,'observed-loaded',p,h) for p,h in build.get('loadedInputs',{}).items()]
    logfile=folder/'logs/native-build.stderr'; log=logfile.read_text() if logfile.exists() else ''
    events=[]
    for line in log.splitlines():
        if line.startswith('NATIVE_BUILD_PROGRESS '):
            try: events.append(json.loads(line[len('NATIVE_BUILD_PROGRESS '):]))
            except json.JSONDecodeError: pass
    def last(phase,event): return next((v for v in reversed(events) if v.get('phase')==phase and v.get('event')==event),None)
    validation=last('book_valid','complete'); child=last('codegen-process','start'); start=last('compile_book','start')
    evidence=[]
    for name in ['root.native.corpus.json','root-native-build.json','root-native-build.json.inputs.json','receipt.json','logs/native-build.stderr']:
        a=pin(folder/name); expected=sorted(expected_paths.get(a['path'],set()));a['priorExpectedSha256']=expected;a['matchesPriorPin']=a['sha256'] in expected if expected else None;evidence.append(a)
    row={'version':tag,'constructorDirectory':str(folder),'evidence':evidence,'status':build.get('status'),'root':next(x for x in sources if x['logicalPath']==corpus['root']),
      'coverage':{'corpusFiles':len(sources),'authenticatedCorpusFiles':sum(x['authenticated'] for x in sources),'protectedFiles':len(protected),'authenticatedProtectedFiles':sum(x['authenticated'] for x in protected),'observedLoadedFiles':len(loaded),'checkedDefinitions':build.get('checkedDefinitions',validation.get('checkedDefinitions') if validation else None),'eventsFullyValidated':build.get('eventsFullyValidated',validation.get('events') if validation else None),'checksExcluded':build.get('checksExcluded',build.get('boundary',{}).get('checksExcluded')),'outputPatches':build.get('outputPatches',build.get('boundary',{}).get('outputPatches'))},
      'generated':[{k:x[k] for k in ['logicalPath','expectedSha256','authenticated','bytes','sourceShape'] if k in x} for x in sources if x['logicalPath'].startswith('checkpoints/')],
      'kernelCompilerBase':{p:h for p,h in pins.items() if p.endswith(('/bend.ts','/comp.ts','/base.bend'))},'guard':build.get('guardian'),
      'tools':rec['receipt.json'].get('tools'),
      'observedGcRamHint':build.get('runtime',{}).get('automaticGcRamHint'),
      'lastCompletedEvent':next((v for v in reversed(events) if v.get('event')=='complete'),None),'lastPhase':build.get('failure',{}).get('phase',build.get('lastProgress',{}).get('phase')),
      'child':{'launch':child,'compileStart':start,'pid':start.get('pid') if start else None,'runtime':build.get('runtime'),'environment':None,'missingEnvironmentReason':'Original logs do not serialize complete child environment; current env is not historic evidence','argvModeNotCause':True},
      'artifacts':{name:pin(folder/name) for name in ['native.c','native','bootstrap.json.cases/stage-one.js']}}
    rows.append(row)
# Authenticate all explicit source inventories of the candidate outcomes, not just corpus imports.
for tag,doc in [('G35',load(ROOT/'evals/receipts/producer2039g35e08_qualification.json')),('G36',load(ROOT/'evals/receipts/producer2039g36e05_rejected.json'))]+[(t,load(ROOT/f'checkpoints/{paths[t].replace("full01","-outcome")}/outcome.json')) for t in ['G37','G38','G39']]:
    entries=doc.get('sourceInputs',[]) or doc.get('requiredFrozenInputs',[]) or list(walk(doc.get('frozenSources',{})))
    for x in entries:
        if x.get('path') and x.get('sha256'): source_record(tag,'receipt-source-input',x.get('logicalPath',x['path']),x['sha256'])
    for path,h in doc.get('sourcePins',doc.get('plan',{}).get('data',{}).get('sourcePins',{})).items(): source_record(tag,'provider-source',path,h)
for x in restoration['baselineSourceChecks']:
    if x.get('sha256'): source_record('R12','restoration-source',x['path'],x['sha256'])
# Current restored manifests are not falsely labeled historic R12 bytes.
for path in ['checkpoints/checker-core-steps-v1.json','checkpoints/emitter-steps-v1.json']:
    source_record('R12','restored-manifest',path,sha((ROOT/path).read_bytes()))
# Read authenticated retained manifests; summarize exact shape counts without regenerating.
manifest_rows=[]; seen=set()
for item in list(inventory):
    path=item['logicalPath'];h=item['expectedSha256']
    if not path.endswith(('emitter-steps-v1.json','checker-core-steps-v1.json')) or (item['version'],h) in seen: continue
    seen.add((item['version'],h)); b,a=resolve_source(path,h)
    if b is None: continue
    m=json.loads(b); composition=m.get('canonicalComposition',{}); declarations=m.get('normalizedSourceDeclarationHashes',{})
    manifest_rows.append({'version':item['version'],'manifest':path,'sha256':h,'definitionCount':m.get('definitionCount'),'excludedDefinitions':m.get('excludedDefinitions'),'exactCanonicalCoverage':m.get('exactCanonicalCoverage'),'compositionSourceSha256':composition.get('sourceSha256'),'providerCount':len(composition.get('sources',[])),'normalizedDeclarationCount':len(declarations),'normalizedDeclarationMapSha256':sha(json.dumps(declarations,sort_keys=True,separators=(',',':')).encode())})
    manifest_rows[-1]['composedDeclarationMapSha256']=sha(json.dumps(composition.get('declarations'),sort_keys=True,separators=(',',':')).encode()) if 'declarations' in composition else None
    manifest_rows[-1]['generatedHelperEdgesSha256']=sha(json.dumps(m.get('generatedHelperEdges'),sort_keys=True,separators=(',',':')).encode()) if 'generatedHelperEdges' in m else None
    manifest_rows[-1]['generatedHelperEdgesCount']=len(m['generatedHelperEdges']) if isinstance(m.get('generatedHelperEdges'),(dict,list)) else None
    manifest_rows[-1]['generationEnvironment']=m.get('generationEnvironment')
    for s in composition.get('sources',[]):
        if s.get('canonical') and s.get('canonicalSha256'): source_record(item['version'],'composed-provider',s['canonical'],s['canonicalSha256'])
    for k,v in m.items():
        if k.lower().endswith(('inputs','pins')) and isinstance(v,dict):
            for path,h in v.items():
                if isinstance(h,str) and re.fullmatch('[a-f0-9]{64}',h): source_record(item['version'],'manifest-input',path,h)
control_manifest=load(ROOT/'checkpoints/emitter-steps-v1.json')
candidate_item=next(x for x in inventory if x['version']=='G39' and x['logicalPath'].endswith('/emitter-steps-v1.json'))
candidate_manifest=json.loads(resolve_source(candidate_item['logicalPath'],candidate_item['expectedSha256'])[0])
left=control_manifest['normalizedSourceDeclarationHashes']; right=candidate_manifest['normalizedSourceDeclarationHashes']
changed_names=sorted(k for k in left.keys()|right.keys() if left.get(k)!=right.get(k))
shape_delta={'controlManifest':pin(ROOT/'checkpoints/emitter-steps-v1.json'),'candidateManifest':candidate_item,
    'changedNormalizedDeclarations':[{'name':k,'R12':left.get(k),'G39':right.get(k),
        'origin':next((d for d in candidate_manifest['canonicalComposition']['declarations'] if d['name']==k),None)} for k in changed_names],
    'warning':'Restored R12 generated output is raw-identical to accepted construction input; restored manifest bytes are not claimed historic-identical.'}
save('source-shape-delta.json',shape_delta)
# Freeze the real R12/G39 construction closure, unchanged bytes, in equal-depth roots.
# Common base/kernel/foreign inputs are taken from the accepted constructor and authenticated.
lanes={}; baseline=records['R12']['root-native-build.json']; baseline_inputs=baseline.get('loadedInputs',{})
for tag in ['R12','G39']:
    rec=records[tag]; c=rec['root.native.corpus.json']; required={f['path']:f['sha256'] for f in c['files']}
    required.update({str(pathlib.Path(p).relative_to(ROOT)):h for p,h in rec['root-native-build.json.inputs.json'].items() if str(p).startswith(str(ROOT)) and not p.endswith('.json')})
    for path,h in baseline_inputs.items():
        rel=str(pathlib.Path(path).relative_to(ROOT)) if path.startswith(str(ROOT)) else None
        if rel and rel not in required and not rel.startswith('checkpoints/'): required[rel]=h
    lane=OUT/'inputs'/tag; lane_rows=[]
    for path,h in required.items():
        b,a=resolve_source(path,h)
        if b is None: raise RuntimeError(f'Cannot prepare real source lane {tag}: {path} {h}')
        dest=lane/path;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(b)
        lane_rows.append({'logicalPath':path,'path':str(dest),'sha256':h,'bytes':len(b),'origin':a})
    lanes[tag]={'directory':str(lane),'root':str(lane/c['root']),'bridge':str(lane/'evals/native_compiler_driver.bend'),'inputs':lane_rows}
def logical(p): return re.sub(r'\.bootstrap_compiler_root_[^.]+\.bend','.bootstrap_compiler_root_<RUN>.bend',p)
a={logical(f['path']):f['sha256'] for f in records['R12']['root.native.corpus.json']['files']}
b={logical(f['path']):f['sha256'] for f in records['G39']['root.native.corpus.json']['files']}
delta=[{'logicalPath':k,'R12':a.get(k),'G39':b.get(k)} for k in sorted(a.keys()|b.keys()) if a.get(k)!=b.get(k)]
assert len(delta)==1 and delta[0]['logicalPath']=='checkpoints/emitter_steps_v1.bend',delta
save('source-inventory.json',{'scope':'All six constructor corpus/protected inputs; observed loaded inputs; explicit retained outcome source inputs; available composed providers and manifest pins. Missing historic fields remain explicit. No regeneration.','entries':inventory,'manifests':manifest_rows})
save('prepared-inputs.json',lanes)
result={'schemaVersion':1,'status':'OFFLINE_AUDIT_EXECUTED','compilerExecuted':False,'primaryAuthentication':primary,'index':pin(ROOT/'evals/receipts/experiments_e01_e13_completed.json'),'restoration':pin(ROOT/'checkpoints/local2039g39e12-restored/restored.json'),'rows':rows,'generatedManifests':manifest_rows,'sourceInventory':pin(OUT/'source-inventory.json'),'preparedInputs':pin(OUT/'prepared-inputs.json'),'selectedPair':{'control':'R12','candidate':'G39','rawConstructorDelta':delta,'question':'Where does the one changed generated emitter input first change canonical observer structural state under the original Bun child invocation?','historicalMatchedControl':'Missing contemporary paired construction observation; historical R12 native construction is retained, not substituted by native throughput RSS.','runtimeModeCause':'UNESTABLISHED; outer --smol versus child omission is observed argv only.'},'warnings':['Raw hashes remain authoritative; separate run-id normalization is diagnostic only.','Memory rows are construction process-tree measurements only, never seed-runtime throughput.','Missing child env prevents historic allocator-mode equivalence claims.','Source counters and RSS/physical footprint are different observables; no retained-byte attribution.']}
result['selectedPair']['shapeDelta']=pin(OUT/'source-shape-delta.json')
result['auditEnvironment']={'BUN_JSC_forceRAMSize':os.environ.get('BUN_JSC_forceRAMSize'),'authority':'audit process current environment only; not historical child environment'}
result['runtimeTools']={name:{'receipt':value,'current':pin(value['path'])} for name,value in INDEX['runtime'].items() if value.get('path')}
save('n01.json',result)
tool_paths=[OUT/'audit.py',OUT/'probe-worker.mjs',OUT/'run-probe.mjs',
    ROOT/'evals/compiler_codegen_probe.ts',ROOT/'evals/compiler_profile.mjs',
    ROOT/'evals/heavy_gate.ts',ROOT/'evals/heavy_gate_native.c',
    ROOT/'evals/receipts/compiler_codegen_probe_verified.json',OUT/'n01.json',
    OUT/'source-shape-delta.json',OUT/'prepared-inputs.json']
plan={'schemaVersion':1,'status':'PREDECLARED_NOT_EXECUTED','axis':'R12 versus G39 source shape at fixed accepted-control Bun environment',
    'diagnosticOnly':True,'acceptanceEvidence':False,'compilerAccepted':False,
    'question':'Find first canonical preparation/pass/definition structural divergence caused by the authenticated generated emitter source delta, not infer allocator cause from old failed runs.',
    'bun':{'path':INDEX['runtime']['bun']['path'],'sha256':INDEX['runtime']['bun']['sha256'],'version':'1.4.3'},
    'environment':{'BUN_JSC_forceRAMSize':'4294967296'},
    'environmentAuthority':'Observed in both R12 and G35 successful native construction receipts; absent field in G36-G39 is UNKNOWN, not observed unset. Current audit process hint is recorded separately.',
    'guard':{'memoryMiB':8192,'rssMiB':8192,'pollMs':10,'timeoutMs':600000,'termGraceMs':1000},
    'guardOwner':'run-probe.mjs calls existing runHeavyGate exactly once per lane; worker authenticates inherited lease. No outer guard wrapper.',
    'prefix':{'passes':1,'events':50000,'codegenMs':120000},
    'cutoff':'First completed canonical pass OR 50000 total observer/progress events OR 120000 codegen ms at next existing observer seam. External 600000ms deadline and both8192MiB guards remain authoritative even while a definition is uninterruptible.',
    'expectedCheckedDefinitions':12456,'expectedBookEvents':13050,
    'guardSource':str(ROOT/'evals/heavy_gate.ts'),'observerSource':str(ROOT/'evals/compiler_profile.mjs'),
    'changedDeclarations':changed_names,'shapeDelta':shape_delta,'lanes':lanes,'toolPins':[pin(p) for p in tool_paths],
    'qualificationBoundary':'Original Bun executable, empty child execArgv, full raw-authenticated source and original guard caps. Diagnostic observer harness, equal-depth relocated input roots and fixed accepted-control hint; not original qualification, not unchanged failed-target retry, not a runtime-mode experiment.',
    'decisions':{'GO':'Only to inspect a source-mapped first structural divergence; source fix requires parent actual result and explicit new assignment.',
        'STOP':'Control failure, missing/drifting input, incomplete coverage, unvisited changed region, or equal structural prefix. Never fabricate a control, retry unchanged fulltarget, widen caps or infer GC cause.',
        'physicalBytes':'Guard RSS/footprint separate from source facts, memo sizes, emitted UTF16 units and process heapUsed; none establishes retained bytes.'}}
save('n04-plan.json',plan)
print(json.dumps({'status':result['status'],'primaryChecks':len(primary),'rows':[{k:x[k] for k in ['version','status','coverage','lastPhase']} for x in rows],'inventoryEntries':len(inventory),'missingSourceEntries':sum(not x['authenticated'] for x in inventory),'selectedDelta':delta,'output':str(OUT/'n01.json')}))
