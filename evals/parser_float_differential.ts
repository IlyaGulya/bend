import * as B from '../bend2/bend.ts';
import {canonicalSourceBook,canonicalCore,normalizeCoreBook,normalizeImports,type Value,type Node,type CorePayload} from './parser_full_semantic_normalize.ts';
import {installCompiledLexerABI,feedbackParserResult} from './bootstrap_parser_eval_abi.ts';
import {sourceOracle} from './bootstrap_source_oracle.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {floatFixtures,floatExclusions,type FloatFixture,type FloatExclusion} from './parser_float_fixtures.ts';
import {writeFileSync,mkdtempSync,mkdirSync,rmSync} from 'node:fs';
import {resolve,dirname,join} from 'node:path';
import {tmpdir} from 'node:os';
import {Readable} from 'node:stream';
import {createInterface} from 'node:readline';
import type {ReadableStream as NodeReadableStream} from 'node:stream/web';

// Usage: bun --smol evals/parser_float_differential.ts --layer=canonical
//   --parser=bend2/selfhost/parser.bend --report=checkpoints/float-canonical.json
// Compiled runs use --layer=compiled --artifact=<exact JS artifact>.
// --minimal-only evaluates only the first (pi) regression, not the exclusions.

type Semantic = CorePayload['semantic'];
type FloatWord = {path: string; bits: string; leastSignificantFirst: number[]};
type FloatRow = FloatFixture & {
  source: string; stage0Accepted: boolean; accepted: boolean;
  expectedBits: string | null; actualBits: string | null;
  bitParity: boolean; semanticParity: boolean; error?: string;
  stage0Failure?: unknown; failure?: Node;
  expectedWords?: FloatWord[]; actualWords?: FloatWord[];
  expected?: Semantic; actual?: Semantic;
};
type ExclusionRow = FloatExclusion & {
  source: string; disposition: 'oracle-only-exclusion'; compared: false;
  stage0Accepted: boolean | null; expectedBits: string | null; actualBits: null;
  stage0Failure?: unknown; stage0FailureCategory?: string; error?: string;
  expectedWords?: FloatWord[];
};

function record(value: unknown): Record<string,unknown> {
  if(!value || typeof value!=='object' || Array.isArray(value)) throw Error('Expected compiled protocol object');
  return value as Record<string,unknown>;
}

/** Read the actual normalized core F32{Word}, not float pretty-printing,
 * Number(literal), or an acceptance surrogate. Both oracles use this seam. */
export function extractF32Words(semantic: Semantic): FloatWord[] {
  const words: FloatWord[] = [];
  const tasks: {value: unknown; path: string}[] = semantic.declarations.map((value,i) => ({value,path:'declarations/'+i})).reverse();
  while(tasks.length) {
    const {value,path} = tasks.pop()!;
    if(Array.isArray(value) && value[0] === 'Lit' && value[1] === 'F32') {
      const raw=value[2];
      if(typeof raw!=='number'||!Number.isInteger(raw)||raw<0||raw>0xffffffff)throw Error('Malformed compact F32 bits at '+path);
      words.push({path,bits:'0x'+raw.toString(16).padStart(8,'0'),leastSignificantFirst:Array.from({length:32},(_,bit)=>(raw>>>bit)&1)});
    } else if(Array.isArray(value) && value[0] === 'Ctr' && value[1] === 'F32') {
      const fields = value[2];
      if(!Array.isArray(fields) || fields.length !== 1) throw Error('Malformed core F32 at '+path);
      let word: unknown = fields[0], valueBits = 0;
      const bits: number[] = [];
      while(Array.isArray(word) && word[0] === 'Ctr' && word[1] === 'WCon') {
        if(!Array.isArray(word[2]) || word[2].length !== 2 || bits.length >= 32) throw Error('Malformed F32 Word at '+path);
        const bit = word[2][0];
        if(!Array.isArray(bit) || bit[0] !== 'Ctr' || !['True','False'].includes(bit[1]) || !Array.isArray(bit[2]) || bit[2].length) throw Error('Malformed F32 bit at '+path);
        const set = bit[1] === 'True' ? 1 : 0;
        valueBits += set * 2 ** bits.length;
        bits.push(set);
        word = word[2][1];
      }
      if(bits.length !== 32 || !Array.isArray(word) || word[0] !== 'Ctr' || word[1] !== 'WNil' || !Array.isArray(word[2]) || word[2].length) throw Error('F32 Word must contain exactly 32 bits at '+path);
      words.push({path,bits:'0x'+valueBits.toString(16).padStart(8,'0'),leastSignificantFirst:bits});
    } else if(Array.isArray(value)) {
      for(let i=value.length-1;i>=0;i--) tasks.push({value:value[i],path:path+'/'+i});
    } else if(value && typeof value === 'object') {
      const entries = Object.entries(value);
      for(let i=entries.length-1;i>=0;i--) tasks.push({value:entries[i][1],path:path+'/'+entries[i][0]});
    }
  }
  return words;
}

function singleBits(semantic: Semantic): {bits: string; words: FloatWord[]} {
  const words = extractF32Words(semantic);
  if(words.length !== 1) throw Error('Expected exactly one core F32 literal, got '+words.length);
  return {bits:words[0].bits,words};
}

function option(name: string): string | undefined {
  const prefix = '--'+name+'=';
  const inline = process.argv.find(arg => arg.startsWith(prefix));
  if(inline) return inline.slice(prefix.length);
  const index = process.argv.indexOf('--'+name);
  if(index < 0) return undefined;
  const value = process.argv[index+1];
  if(!value || value.startsWith('--')) throw Error('Missing --'+name+' value');
  return value;
}

async function main(): Promise<void> {
  process.argv.push('--memory-mib','8192','--rss-mib','8192','--poll-ms','10');
  await guardHeavyGate(import.meta.path,{label:'Four-layer F32 bit-pattern differential'});
  const layer = option('layer') ?? 'canonical';
  const defaults: Record<string,string> = {canonical:'bend2/selfhost/parser.bend'};
  if(!['canonical','factored','generated','compiled'].includes(layer)) throw Error('Unsupported --layer='+layer);
  const parserPath = option('parser') ?? defaults[layer] ?? null;
  const artifact = option('artifact');
  if(layer==='compiled'?!artifact:!parserPath)throw Error('Pass the exact current parser/source or compiled artifact');
  const report = option('report') ?? 'checkpoints/float-'+layer+'.json';
  const minimalOnly = process.argv.includes('--minimal-only');
  const shapeOnly = process.argv.includes('--shape-only');
  const shapeLiterals = ['3.14159265', '3.14', '0.5', '0.0', '1.00000006'];
  const chosen = minimalOnly ? floatFixtures.slice(0,1)
    : shapeOnly ? shapeLiterals.map(literal => {
      const fixture = floatFixtures.find(row => row.literal === literal);
      if(!fixture) throw Error('Missing F32 shape fixture '+literal);
      return fixture;
    }) : floatFixtures;
  const rows: FloatRow[] = [], exclusions: ExclusionRow[] = [];
  const failures: string[] = [];
  mkdirSync(dirname(resolve(report)),{recursive:true});
  function publish(): void {
    writeFileSync(report,JSON.stringify({
      layer,parserPath,artifact:layer==='compiled'?artifact:null,minimalOnly,shapeOnly,
      bitExtraction:'Actual normalized core F32{Word}, exactly 32 least-significant-first bits',
      corpus:floatFixtures,exclusionCorpus:floatExclusions,
      rows,exclusions,exclusionsEvaluated:!minimalOnly && exclusions.length===floatExclusions.length,
      passed:rows.length===chosen.length && (minimalOnly || shapeOnly || exclusions.length===floatExclusions.length) && failures.length===0,
      failures,
    },null,2)+'\n');
  }
  let book: B.Book | undefined, fuel: B.HTerm = B.Ctr('FeedbackFuelEnd',[]);
  if(layer !== 'compiled') {
    book = await canonicalSourceBook(await Bun.file(parserPath!).text(), resolve(parserPath!));
    await installCompiledLexerABI(book);
    if(layer==='generated') for(let i=0;i<2000000;i++) fuel=B.Ctr('FeedbackFuelCell',[fuel]);
  }
  function closed(source: string): B.HTerm {return B.Lit('String',source);}
  function ctor(term: B.HTerm) {
    const raw=B.term_wnf(book!,term),value=raw.$==='Lit'?B.lit_step(raw):raw;
    if(value.$!=='Ctr') throw Error('Expected constructor, got '+value.$);
    return {...value,k:B.name_key(value.k)};
  }
  function nat(term: B.HTerm): number {
    let n=0;
    for(;;) {const raw=B.term_wnf(book!,term);if(raw.$==='Lit'&&raw.k==='Nat')return n+raw.v;const value=ctor(raw);if(value.k==='Zero')return n;if(value.k!=='Succ')throw Error('Malformed Nat');n++;term=value.x[0];}
  }
  function text(term: B.HTerm): string {
    let out='';
    for(;;) {
      const value=ctor(term);
      if(value.k==='SNil') return out;
      if(value.k!=='SCon') throw Error('Malformed String');
      let word=ctor(ctor(value.x[0]).x[0]).x[0],code=0,bit=1;
      for(;;) {const cell=ctor(word);if(cell.k==='WNil')break;if(cell.k!=='WCon')throw Error('Malformed character Word');if(ctor(cell.x[0]).k==='True')code+=bit;bit*=2;word=cell.x[1];}
      out+=String.fromCodePoint(code);term=value.x[1];
    }
  }
  function decode(term: B.HTerm): Value {
    const value=ctor(term),tag=value.k.split('.').at(-1)!;
    if(tag==='Zero'||tag==='Succ') return nat(term);
    if(tag==='True'||tag==='False') return tag==='True';
    if(tag==='SNil'||tag==='SCon') return text(term);
    if(tag==='Nil'||tag==='Con') {
      const list: Value[]=[];
      for(;;) {const cell=ctor(term);if(cell.k==='Nil')return list;if(cell.k!=='Con')throw Error('Malformed List');list.push(decode(cell.x[0]));term=cell.x[1];}
    }
    return {tag,fields:value.x.map(decode)};
  }
  function native(value: unknown): Value {
    if(typeof value==='string' || typeof value==='boolean') return value;
    if(typeof value==='number' && Number.isFinite(value)) return value;
    const item=record(value);
    if(item.$==='$NativeNat') {
      if(typeof item.value!=='string' || !/^\d+$/.test(item.value)) throw Error('Malformed compiled Nat');
      const n=Number(item.value);
      if(!Number.isSafeInteger(n)) throw Error('Compiled Nat exceeds exact observation range');
      return n;
    }
    if(item.$==='Nil'||item.$==='Con') {
      const list: Value[]=[];
      let cell=item;
      while(cell.$==='Con') {list.push(native(cell.head));cell=record(cell.tail);}
      if(cell.$!=='Nil') throw Error('Malformed compiled List');
      return list;
    }
    if(typeof item.$!=='string') throw Error('Malformed compiled constructor');
    return {tag:item.$.split('.').at(-1)!,fields:Object.entries(item).filter(([key])=>key!=='$').map(([,child])=>native(child))};
  }
  const worker=layer==='compiled'?Bun.spawn(['node','evals/bootstrap_parser_artifact_worker.mjs',resolve(artifact)],{stdin:'pipe',stdout:'pipe',stderr:'inherit'}):undefined;
  // Bun and Node expose the same Web stream; their declaration types differ.
  const nodeStream=worker?.stdout as unknown as NodeReadableStream<Uint8Array> | undefined;
  const lines=nodeStream?createInterface({input:Readable.fromWeb(nodeStream)}):undefined;
  const iterator=lines?.[Symbol.asyncIterator]();
  const fixtureDir=mkdtempSync(join(tmpdir(),'bend-float-differential-'));
  const file=join(fixtureDir,'source.bend');
  async function parse(source: string,id: number): Promise<Node> {
    let result: Value;
    if(worker) {
      worker.stdin.write(JSON.stringify({id,file,source})+'\n');await worker.stdin.flush();
      const line=await iterator!.next();if(line.done)throw Error('Compiled worker ended without a result');
      const payload: unknown=JSON.parse(line.value);
      const response=record(payload);
      if(response.id!==id)throw Error('Compiled worker response id mismatch');
      if(response.error!==undefined) {
        if(typeof response.error!=='string')throw Error('Malformed compiled worker error');
        throw Error(response.error);
      }
      if(!('result' in response))throw Error('Missing compiled worker result');
      result=native(response.result);
    } else {
      let term: B.HTerm;
      if(layer==='generated') term=feedbackParserResult(book!,B.App(B.App(B.App(B.Ref('parse_with_fuel'),fuel),closed(file)),closed(source)));
      else term=B.App(B.App(B.Ref('parse'),closed(file)),closed(source));
      result=decode(term);
    }
    if(!result||typeof result!=='object'||Array.isArray(result)||!['ParseSuccess','ParseFailure'].includes(result.tag)) throw Error('Invalid public parser result');
    return result;
  }
  try {
    for(const [id,fixture] of chosen.entries()) {
      const source=`def f() -> F32:\n  ${fixture.literal}\n`;
      const row: FloatRow={...fixture,source,stage0Accepted:false,accepted:false,expectedBits:null,actualBits:null,bitParity:false,semanticParity:false};
      rows.push(row);
      try {
        writeFileSync(file,source);
        const oracle=await sourceOracle(file,source);
        row.stage0Accepted=oracle.accepted;
        if(!oracle.accepted) {row.stage0Failure=oracle.error;throw Error('Stage0 rejected a required supported fixture');}
        const environment=oracle.normalizationBook();
        const expected=normalizeCoreBook(environment,oracle.declarations.map(d=>d.key),oracle.imports.map(i=>({path:i.path,alias:i.alias})),file,dirname(file)+'/').semantic;
        const expectedWord=singleBits(expected);
        row.expectedBits=expectedWord.bits;row.expectedWords=expectedWord.words;row.expected=expected;
        const result=await parse(source,id);
        row.accepted=result.tag==='ParseSuccess';
        if(!row.accepted) {row.failure=result;throw Error('Parser rejected a required supported fixture');}
        const actual=canonicalCore(result.fields[0],environment,source).semantic;
        actual.imports=normalizeImports(oracle.imports.map(i=>({path:i.path,alias:i.alias})));
        row.actual=actual;
        const actualWord=singleBits(actual);
        row.actualBits=actualWord.bits;row.actualWords=actualWord.words;row.actual=actual;
        row.bitParity=row.expectedBits===row.actualBits;
        row.semanticParity=JSON.stringify(expected)===JSON.stringify(actual);
        if(fixture.pinnedBits && row.expectedBits!==fixture.pinnedBits) throw Error('Stage0 disagrees with pinned IEEE binary32 regression');
        if(!row.bitParity) throw Error('F32 bit-pattern mismatch');
        if(!row.semanticParity) throw Error('Supplementary normalized core mismatch');
      } catch(error) {
        row.error=error instanceof Error?error.message:String(error);
        failures.push(fixture.literal+': '+row.error);
      }
      console.log(JSON.stringify({layer,literal:row.literal,expectedBits:row.expectedBits,actualBits:row.actualBits,accepted:row.accepted,bitParity:row.bitParity,error:row.error}));
      publish();
    }
    if(!minimalOnly && !shapeOnly) for(const fixture of floatExclusions) {
      const source=`def f() -> F32:\n  ${fixture.literal}\n`;
      const row: ExclusionRow={...fixture,source,disposition:'oracle-only-exclusion',compared:false,stage0Accepted:null,expectedBits:null,actualBits:null};
      exclusions.push(row);
      try {
        writeFileSync(file,source);
        const oracle=await sourceOracle(file,source);
        row.stage0Accepted=oracle.accepted;
        if(!oracle.accepted) {row.stage0Failure=oracle.error;row.stage0FailureCategory=oracle.failure?.category;}
        if(oracle.failure?.category==='observation-seam') throw Error('Stage0 observation seam failed, not an unsupported notation result');
        if(oracle.accepted!==fixture.stage0ShouldAccept) throw Error('Stage0 acceptance differs from the declared exclusion category');
        if(oracle.accepted) {
          const expected=normalizeCoreBook(oracle.normalizationBook(),oracle.declarations.map(d=>d.key),[],file,dirname(file)+'/').semantic;
          const observed=singleBits(expected);row.expectedBits=observed.bits;row.expectedWords=observed.words;
        }
      } catch(error) {
        row.error=error instanceof Error?error.message:String(error);
        failures.push('exclusion '+fixture.literal+': '+row.error);
      }
      publish();
    }
  } finally {
    if(worker) {lines!.close();worker.stdin.end();const code=await worker.exited;if(code!==0)failures.push('Compiled worker exit '+code);}
    rmSync(fixtureDir,{recursive:true,force:true});
    publish();
  }
  if(failures.length) {console.error(failures.join('\n'));process.exitCode=1;}
}

if(import.meta.main) await main();
