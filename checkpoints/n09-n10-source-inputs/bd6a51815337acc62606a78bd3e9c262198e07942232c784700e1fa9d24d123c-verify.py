#!/usr/bin/env python3
"""Verify completed N09/N10 outputs; stream scalar logs, never load AST/images."""
import collections, hashlib, json, os, re, sys, platform
from pathlib import Path
root,w9,w10,out=map(Path,sys.argv[1:])
def load(p):return json.loads(p.read_text())
def digest(p):
 h=hashlib.sha256()
 with open(p,'rb') as f:
  for b in iter(lambda:f.read(1048576),b''):h.update(b)
 return h.hexdigest()
def pin(p):return {'path':str(p),'sha256':digest(p),'bytes':p.stat().st_size}
n9=load(w9/'run-01/receipt.json');n10=load(w10/'run-01/receipt.json')
p9=load(w9/'plan.json');p10=load(w10/'plan.json');shape=load(w9/'source-shape.json')
assert len(n9['lanes'])==2 and len(n10['cells'])==4 and n10['allCellsExecuted']
source_checks=[]
for p in [p9,p10]:
 for lane in p['lanes'].values():
  for x in lane['inputs']:
   assert digest(Path(x['path']))==x['sha256'],x['path']
   source_checks.append((x['path'],x['sha256']))
 for x in p['toolPins']:assert digest(Path(x['path']))==x['sha256'],x['path']
 assert digest(Path(p['bun']['path']))==p['bun']['sha256']
def normalized(s):
 for p in p9['lanes'].values():s=s.replace(p['directory'],'<INPUT>')
 return re.sub(r'local2039g(?:24r12|39e12full01)','<RUN>',s)
def structural_row(x):
 d={k:x[k] for k in ['sequence','stage','name','pass','state']};d['name']=normalized(d['name'])
 return (json.dumps(d,sort_keys=True,separators=(',',':'))+'\n').encode()
n9_prefix_hashes=[hashlib.sha256(),hashlib.sha256()]
paths=[Path(x['eventPath']) for x in n9['lanes']]
field_counts=collections.Counter();different=0;first=None;count=0
with open(paths[0]) as a,open(paths[1]) as b:
 while True:
  aa=a.readline();bb=b.readline()
  if not aa or not bb:
   assert not aa and not bb;break
  x=json.loads(aa);y=json.loads(bb);count+=1
  if count<=p10['targetEvent']['sequence']:
   n9_prefix_hashes[0].update(structural_row(x));n9_prefix_hashes[1].update(structural_row(y))
  assert x['sequence']==y['sequence']==count
  assert (x['stage'],normalized(x['name']),x['pass'])==(y['stage'],normalized(y['name']),y['pass'])
  fields=[k for k in set(x['state'])|set(y['state']) if x['state'].get(k)!=y['state'].get(k)]
  assert set(fields)<={'literalFacts','imageWords','constantKeys'},(count,fields)
  if fields:
   different+=1;field_counts.update(fields)
   if first is None:first=count
  assert y['state'].get('imageWords',0)-x['state'].get('imageWords',0)==2*(y['state'].get('literalFacts',0)-x['state'].get('literalFacts',0))
assert count==250000 and first==129879
for i,path in enumerate(paths):assert digest(path)==n9['lanes'][i]['eventSha256']
assert n9['comparison']['structuralMismatchEvents']==different
assert n9['comparison']['matchedPrefixEvents']==first-1
literal_deltas={name:shape['runtimeLiterals']['G39']['literals'][name]['unicodeScalars']-x['unicodeScalars'] for name,x in shape['runtimeLiterals']['R12']['literals'].items()}
assert sum(literal_deltas.values())==245
for x in n9['lanes']:
 assert x['guardian']['status']=='PASS' and x['guardian']['ownedTreeStopped']
 assert x['reason']=='observer-event-budget' and x['observerEvents']==250000
 assert x['checkedDefinitions']==12456 and x['eventsFullyValidated']==13050
 assert x['noCOutputPublished'] and len(x['passRows'])==1
 assert x['last']['pass']==2 and x['last']['sequence']==250000
 assert x['runtime']['execArgv']==[]
cell_logs=[]
for c in n10['cells']:
 assert c['guardian']['reportPhase']=='complete' and c['guardian']['ownedTreeStopped']
 assert c['guardian']['memoryLimitBytes']==c['guardian']['rssLimitBytes']==8192*1024*1024
 assert c['noCOutputPublished'] and c['runtime']['execArgv']==[]
 env=c['runtime']['environment'];hint=c['gcRamHint']
 if hint is None:assert 'BUN_JSC_forceRAMSize' not in env
 else:assert env['BUN_JSC_forceRAMSize']==hint
 path=Path(c['eventPath']);total=0;last=None;invalid_tail=None
 structural_hash=hashlib.sha256()
 with open(path) as f:
  for row in f:
   try:x=json.loads(row)
   except json.JSONDecodeError as e:
    assert not f.read(),'Invalid non-final event row'
    invalid_tail={'reason':str(e),'bytes':len(row.encode())};break
   total+=1;assert x['sequence']==total;last={k:x[k] for k in ['sequence','stage','name','pass','state']}
   structural_hash.update(structural_row(x))
 if c['targetReached']:
  assert invalid_tail is None and total==129879 and c['workerTerminal']
  assert digest(path)==c['eventSha256']
  assert c['checkedDefinitions']==12456 and c['eventsFullyValidated']==13050
 cell_logs.append({'id':c['id'],'status':c['status'],'eventLog':pin(path),'structuralStreamSha256':structural_hash.hexdigest(),'parsedEvents':total,'lastCompleteEvent':last,'invalidFinalTail':invalid_tail,'workerSavedEvent':c['last']['sequence'],'targetReached':c['targetReached']})
by_id={c['id']:c for c in cell_logs}
for i,source in enumerate(['R12','G39']):
 assert by_id[source+'_hint']['structuralStreamSha256']==by_id[source+'_unset']['structuralStreamSha256']==n9_prefix_hashes[i].hexdigest()
restored=load(root/'checkpoints/local2039g39e12-restored/restored.json')
baseline=[]
for x in restored['baselineSourceChecks']+restored['generatedSources']:
 p=root/x['path'];ok=not p.exists() if x.get('expectedAbsent') else digest(p)==x['sha256']
 assert ok,x['path'];baseline.append(dict(x,matches=ok))
artifacts={}
for k,x in restored['acceptedArtifacts'].items():
 p=Path(x['path']);assert digest(p)==x['sha256'];artifacts[k]=dict(pin(p),matches=True)
result={'schemaVersion':1,'status':'PASS_EXECUTED_EVIDENCE_INTEGRITY','executionClaim':'Only N09/N10 bounded construction runs and input/log/source/artifact integrity, not full native qualification','command':sys.argv,'runtime':{'python':sys.version,'executable':sys.executable,'platform':platform.platform(),'machine':platform.machine()},'verifier':pin(Path(__file__)),'N09':{'comparedEvents':count,'matchedPrefixEvents':first-1,'firstDifference':first,'differentEvents':different,'differingFields':dict(field_counts),'allOtherStateFieldsEqual':True,'imageWordDeltaEqualsTwiceLiteralEntryDelta':True,'literalSourceScalarDeltas':literal_deltas,'eventLogs':[pin(p) for p in paths],'secondPassComplete':False},'N10':{'receipt':pin(w10/'run-01/receipt.json'),'status':n10['status'],'cells':cell_logs,'historicalFailedEnvironments':'UNKNOWN; not recovered by this intervention','statisticalPerformanceClaim':False},'sourceChecks':len(source_checks),'uniqueSourcePathHashPairs':len(set(source_checks)),'baselineSourceAndGeneratedChecks':baseline,'acceptedArtifacts':artifacts,'newFixedpointClaim':False,'productionChanged':False}
result['N10']['sameSourceStructuralStreamIdenticalAcrossHints']=True
result['N10']['structuralStreamsMatchN09SameSourcePrefixes']=True
with open(out,'x') as f:json.dump(result,f,ensure_ascii=False,indent=2);f.write('\n')
print(json.dumps({'status':result['status'],'N09FirstDifference':first,'N10Status':n10['status'],'sourceChecks':len(source_checks),'baselineChecks':len(baseline),'output':str(out)}))
