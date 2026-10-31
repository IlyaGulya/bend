import assert from 'node:assert/strict';
import {readFileSync,writeFileSync,existsSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {dirname,resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
const here=dirname(fileURLToPath(import.meta.url));
const [reportPath,output]=process.argv.slice(2);
assert.ok(reportPath&&output&&!existsSync(output),'expected census report and fresh decision output');
const report=JSON.parse(readFileSync(reportPath,'utf8'));
const config=JSON.parse(readFileSync(resolve(here,'config.json'),'utf8'));
const hash=path=>createHash('sha256').update(readFileSync(path)).digest('hex');
assert.equal(report.status,'PASS');assert.equal(report.guardian?.status,'PASS');
assert.deepEqual(report.stepCounts,config.expectedSteps);
assert.equal(report.output.sha256,'c33227e028d767df9a9fff75663e42eb7374919dcf8e7dff14936a98d20008fb');
assert.equal(report.output.bytes,29948466);
assert.equal(report.request.sha256,hash(config.request));
const path=resolve(here,'plugin.mjs'),entry=report.plugins.find(p=>p.path===path);
assert.ok(entry);assert.equal(entry.sha256,hash(path));
assert.equal(entry.inputSha256,'85aff9e534c18b4a1d6acac5f3237571dabc58f2c1a75a7ea2040f1c477ab60e');
const snapshot=report.snapshots[path];assert.ok(snapshot);
assert.deepEqual(snapshot.inFlight,{captureSearch:false,appendMode:0,stringActive:false});
const c=snapshot.counters,n=key=>c[key]??0;
// Explicit work thresholds, NOT a runtime/performance verdict. No timings from
// an instrumented image qualify a candidate. Synthetic fixtures cannot satisfy
// these thresholds: this command accepts only the original frozen census.
const n05=n('lookup.hitAgeAtLeast4')>=1000&&n('lookup.hitTraversalBeyondFirst')>=4*n('lookup.requests');
const n06=n('descriptorApply.prefixAtLeast4')>=1000&&n('descriptorApply.traversedAppendCells')>=4*n('descriptorApply.ref');
const result={schemaVersion:1,status:'PASS',diagnosticOnly:true,compilerAccepted:false,performanceAccepted:false,
 report:{path:resolve(reportPath),sha256:hash(reportPath)},nativeLane:'NOT_OBSERVED',
 N05:{decision:n05?'GO_CONTROLLED_SOURCE_COMPARISON':'STOP_PRODUCTION_INDEX',
  criterion:'at least 1000 hits with age >=4, and hit traversal beyond first >=4 times all lookup requests',
  evidence:{requests:n('lookup.requests'),comparisons:n('lookup.comparisons'),hits:n('lookup.hits'),misses:n('lookup.misses'),oldHits:n('lookup.hitAgeAtLeast4'),avoidableHitCells:n('lookup.hitTraversalBeyondFirst'),collisionComparisons:n('lookup.identityCollisionDifferentOwner')},
  ...(n05?{candidate:'Frame-local composite (owner,identity) index alongside authoritative ordered capture list; discard at leave. Preserve first-use capture numbering, insertion/reversal and affine behavior. Count index construction and lookup work before acceptance.'}:{})},
 N06:{decision:n06?'GO_CONTROLLED_SOURCE_COMPARISON':'STOP_PRODUCTION_SPINE_REWRITE',
  criterion:'at least 1000 Ref prefixes >=4 and total traversed prefix cells >=4 times Ref applications',
  evidence:{ref:n('descriptorApply.ref'),nonRef:n('descriptorApply.nonRef'),prefixCells:n('descriptorApply.traversedAppendCells'),maxPrefix:n('descriptorApply.maxPrefix'),longPrefixes:n('descriptorApply.prefixAtLeast4'),sugarCells:n('descriptorSugar.traversedAppendCells')},
  ...(n06?{candidate:'Local single-application-spine builder with one final DescriptorRef materialization, retaining strict head/argument evaluation order and existing non-Ref behavior; no global cache and no descriptor/NF schema or fuel changes.'}:{})},
 N08:{decision:n('descriptorString.termStringRoutes')===0?'STOP_NO_ACTUAL_DESCRIPTOR_STRING_RELEVANCE':'RELEVANT_BUT_STOP_SCHEMA_CHANGE_PENDING_FUEL_AND_CONSUMERS',
  criterion:'Zero actual TermString routes ends this performance branch. Nonzero construction is relevance only; fuel/materialization/selected-name and N07 obligations still block migration.',
  evidence:{routes:n('descriptorString.termStringRoutes'),chars:n('descriptorString.chars'),word32Starts:n('descriptorString.word32Starts'),bitSteps:n('descriptorString.wordBitSteps'),constructed:n('descriptorString.constructedDescriptors')}},
 requiredBeforeAnyProductionAcceptance:['source-authored candidate receipt','descriptor/BIR identity, capture ordering, erasure/drop/region preservation','clean C and JS consumers','normalizer failure/fuel-boundary preservation','original full qualification, native construction, fixedpoint and all 12 strict paired gates']};
writeFileSync(output,JSON.stringify(result,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({output:resolve(output),N05:result.N05.decision,N06:result.N06.decision,N08:result.N08.decision}));
