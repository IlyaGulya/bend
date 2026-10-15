import * as B from '../bend2/bend.ts';
import {js_lib} from '../bend2/comp.ts';
import {SourceDeclarations} from './parser_full_declarations.ts';
import {sourceOracle} from './bootstrap_source_oracle.ts';
import {normalizeCoreBook} from './parser_full_semantic_normalize.ts';
import {extractF32Words} from './parser_float_differential.ts';
import {floatFixtures} from './parser_float_fixtures.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {createHash} from 'node:crypto';
import {mkdtempSync,mkdirSync,writeFileSync,rmSync} from 'node:fs';
import {dirname,join,resolve} from 'node:path';
import {tmpdir} from 'node:os';

// A small, fully validated native helper build, NOT a public-parser pass.
// Usage: bun --smol evals/parser_float_native_gate.ts
//   --parser=bend2/selfhost/parser.bend --report=checkpoints/float-native-gate.json
// --minimal-only runs pi plus the deterministic arbitrary-denominator checks.
const MAX_NAT=(1n<<48n)-1n;
type NativeFixture={literal: string; category: string; pinnedBits?: string; numerator?: bigint; denominator?: bigint};
// Exact rational equivalents of stage0 literals exercise the encoder's
// exponent predicates when multiplying an arbitrary denominator would overflow.
const arbitraryRatioFixtures: readonly NativeFixture[]=[
  {literal:'1.0',category:'arbitrary-near-M-exact-one',pinnedBits:'0x3f800000',numerator:MAX_NAT,denominator:MAX_NAT},
  {literal:'0.5',category:'arbitrary-near-M-exact-half',pinnedBits:'0x3f000000',numerator:(MAX_NAT-1n)/2n,denominator:MAX_NAT-1n},
  {literal:'2.0',category:'arbitrary-large-denominator-exact-two',pinnedBits:'0x40000000',numerator:MAX_NAT-1n,denominator:(MAX_NAT-1n)/2n},
];
function option(name: string): string | undefined {
  const inline=process.argv.find(arg=>arg.startsWith('--'+name+'='));
  if(inline)return inline.slice(name.length+3);
  const index=process.argv.indexOf('--'+name);
  if(index<0)return undefined;
  const value=process.argv[index+1];
  if(!value||value.startsWith('--'))throw Error('Missing --'+name+' value');
  return value;
}
function record(value: unknown): Record<string,unknown> {
  if(!value||typeof value!=='object'||Array.isArray(value))throw Error('Expected native helper object');
  return value as Record<string,unknown>;
}

/** Test setup only: no scanner or decimal-conversion implementation is
 * substituted into the actual Bend encoder. Keep the unreduced raw ratio. */
function fixtureRatio(literal: string): {numerator: bigint; denominator: bigint} {
  const match=/^(\d+)\.(\d+)(?:[eE]([+-]?\d+))?$/.exec(literal);
  if(!match)throw Error('Fixture is not stage0 decimal notation: '+literal);
  const exponent=Number(match[3]??0);
  if(!Number.isSafeInteger(exponent)||Math.abs(exponent)>1000)throw Error('Invalid test exponent');
  const scale=match[2].length-exponent;
  const mantissa=BigInt(match[1]+match[2]);
  const numerator=mantissa*(scale<0?10n**BigInt(-scale):1n);
  const denominator=scale>0?10n**BigInt(scale):1n;
  return {numerator,denominator};
}
function limbs(value: bigint): unknown {
  const digits: number[] = [];
  for (; value > 0n; value >>= 24n) digits.push(Number(value & 0xffffffn));
  return digits.reduceRight<unknown>((tail, head) => ({ $: 'Con', head, tail }), { $: 'Nil' });
}

/** Independent unbounded test oracle, never used to produce actual values. */
function referenceRound(numerator: bigint,denominator: bigint,shift: bigint): bigint {
  const scaled=numerator<<shift;
  const quotient=scaled/denominator,remainder=scaled%denominator;
  return quotient+(2n*remainder>denominator||(2n*remainder===denominator&&quotient%2n===1n)?1n:0n);
}
type RoundFixture={name: string; numerator: bigint; denominator: bigint; shift: bigint};
const evenNearMax=MAX_NAT-1n;
const oddTieDenominator=evenNearMax/3n;
const evenTieDenominator=(evenNearMax/5n)/2n*2n;
const roundFixtures: readonly RoundFixture[]=[
  {name:'near-M odd denominator below half',numerator:MAX_NAT/2n,denominator:MAX_NAT,shift:0n},
  {name:'near-M odd denominator above half',numerator:MAX_NAT/2n+1n,denominator:MAX_NAT,shift:0n},
  {name:'near-M remainder doubling crosses without overflowing',numerator:MAX_NAT-1n,denominator:MAX_NAT,shift:24n},
  {name:'near-M remainder doubling stays below denominator',numerator:MAX_NAT/2n-1n,denominator:MAX_NAT,shift:24n},
  {name:'near-M even denominator tie to even zero',numerator:evenNearMax/2n,denominator:evenNearMax,shift:0n},
  {name:'large arbitrary denominator odd quotient tie rounds up',numerator:oddTieDenominator/2n*3n,denominator:oddTieDenominator,shift:0n},
  {name:'large arbitrary denominator even quotient tie stays even',numerator:evenTieDenominator/2n*5n,denominator:evenTieDenominator,shift:0n},
  {name:'near-M doubled remainder exact crossing',numerator:evenNearMax/2n,denominator:evenNearMax,shift:1n},
  {name:'near-M scaled rounding approaches U48 quotient bound',numerator:MAX_NAT-1n,denominator:MAX_NAT,shift:47n},
  {name:'small rational half tie retains even quotient',numerator:1n,denominator:2n,shift:0n},
  {name:'small rational odd quotient half tie rounds up',numerator:3n,denominator:2n,shift:0n},
];
type Row={literal: string; category: string; numerator?: string; denominator?: string; stage0Accepted: boolean; expectedBits: string|null; actualBits: string|null; nativeAccepted: boolean; bitParity: boolean; error?: string};
type RoundRow={name: string; numerator: string; denominator: string; shift: string; expectedRounded: string; actualRounded: string|null; parity: boolean; error?: string};

async function main(): Promise<void> {
  process.argv.push('--memory-mib','8192','--rss-mib','8192','--poll-ms','10');
  await guardHeavyGate(import.meta.path,{label:'Exact canonical F32 native numeric helper differential'});
  const parserPath=option('parser')??'bend2/selfhost/parser.bend';
  const report=option('report')??'checkpoints/float-native-gate.json';
  const minimalOnly=process.argv.includes('--minimal-only');
  const original=await Bun.file(parserPath).text();
  const declarations=new SourceDeclarations(original);
  const selected=[...declarations.declarations.values()].filter(declaration=>declaration.kind==='def'&&(
    declaration.name.startsWith('round_float_')||declaration.name.startsWith('encode_float_')||
    declaration.name.startsWith('encode_float32')||declaration.name.startsWith('float_nat_')||declaration.name==='float_exponent_bits'
  ));
  const names=selected.map(declaration=>declaration.name);
  for(const root of ['encode_float32','round_float_scaled_go'])if(!names.includes(root))throw Error('Missing exact numeric helper root '+root);
  // Preserve exact source declaration text and original order. No parser,
  // scanner, pattern-quantity transform, or generated source is included.
  const isolated='import Base\n'+selected.map(declaration=>declarations.emit(declaration.name)).join('\n\n')+'\n';
  const sourceSha256=createHash('sha256').update(original).digest('hex');
  const helperSourceSha256=createHash('sha256').update(isolated).digest('hex');
  const dir=mkdtempSync(join(tmpdir(),'bend-float-native-gate-'));
  const helperPath=join(dir,'helpers.bend'),fixturePath=join(dir,'source.bend');
  const rows: Row[]=[],roundingRows: RoundRow[]=[],failures: string[]=[];
  let nativeValidity=false,nativeCompilation=false;
  const chosen: readonly NativeFixture[]=minimalOnly?floatFixtures.slice(0,1):[...floatFixtures,...arbitraryRatioFixtures];
  mkdirSync(dirname(resolve(report)),{recursive:true});
  function publish(): void {
    writeFileSync(report,JSON.stringify({
      layer:'native-numeric-helpers',parserPath,minimalOnly,sourceSha256,helperSourceSha256,
      extractedDefinitions:names,roots:['encode_float32','round_float_scaled_go'],
      nativeValidity,nativeCompilation,publicParserEvaluated:false,scannerEvaluated:false,
      actualImplementation:'Production js_lib compilation of exact canonical Bend numeric helper definitions',
      expectedImplementation:'Stage0 sourceOracle actual normalized core F32 Word; independent BigInt RN-even reference for the normalized remainder API',
      rawInputModel:{limbBits:24,maximumImmediateNat:MAX_NAT.toString(),ratioReduction:false},
      rows,roundingRows,failures,
      passed:nativeValidity&&nativeCompilation&&rows.length===chosen.length&&roundingRows.length===roundFixtures.length&&failures.length===0,
    },null,2)+'\n');
  }
  try {
    writeFileSync(helperPath,isolated);
    const book=B.book_nil();
    try {await B.book_load(book,helperPath,'',new Map());B.book_valid(book);nativeValidity=true;}
    catch(error) {if(error&&typeof error==='object'&&'$'in error&&error.$==='Err')throw Error(B.err_show(error as B.Err));throw error;}
    const roots=['encode_float32','round_float_scaled_go'];
    const code=js_lib(book,true,{roots,exports:roots});
    // The module is generated from the runtime-selected canonical source;
    // no static module exists for this exact native helper compilation.
    const imported: unknown=await import('data:text/javascript;base64,'+Buffer.from(code).toString('base64'));
    const module=record(imported),api=record(module.default);
    const encode=api.encode_float32,round=api.round_float_scaled_go;
    if(typeof encode!=='function'||typeof round!=='function')throw Error('Invalid native numeric helper exports');
    nativeCompilation=true;publish();
    for(const fixture of chosen) {
      const row: Row={literal:fixture.literal,category:fixture.category,stage0Accepted:false,expectedBits:null,actualBits:null,nativeAccepted:false,bitParity:false};
      rows.push(row);
      try {
        const {numerator,denominator}=fixture.numerator!==undefined&&fixture.denominator!==undefined
          ?{numerator:fixture.numerator,denominator:fixture.denominator}:fixtureRatio(fixture.literal);
        if(numerator<0n||denominator<=0n)throw Error('Native encoder fixture requires a nonnegative rational');
        row.numerator=numerator.toString();row.denominator=denominator.toString();
        const source=`def f() -> F32:\n  ${fixture.literal}\n`;
        writeFileSync(fixturePath,source);
        const oracle=await sourceOracle(fixturePath,source);
        row.stage0Accepted=oracle.accepted;
        if(!oracle.accepted)throw Error('Stage0 rejected required supported literal');
        const semantic=normalizeCoreBook(oracle.normalizationBook(),oracle.declarations.map(declaration=>declaration.key),oracle.imports.map(item=>({path:item.path,alias:item.alias})),fixturePath,dirname(fixturePath)+'/').semantic;
        const words=extractF32Words(semantic);
        if(words.length!==1)throw Error('Expected exactly one stage0 core F32 Word');
        row.expectedBits=words[0].bits;
        if(fixture.pinnedBits&&row.expectedBits!==fixture.pinnedBits)throw Error('Stage0 disagrees with pinned binary32 regression');
        const actual: unknown=encode(limbs(numerator),limbs(denominator));
        const tuple=record(actual);
        if(tuple.$!=='Tuple'||typeof tuple.fst!=='number'||!Number.isSafeInteger(tuple.fst)||typeof tuple.snd!=='boolean')throw Error('Malformed native encode_float32 tuple');
        row.nativeAccepted=tuple.snd;
        if(!tuple.snd)throw Error('Native numeric helper rejected required ratio');
        if(tuple.fst<0||tuple.fst>0xffffffff)throw Error('Native encode_float32 bits are outside binary32 width');
        row.actualBits='0x'+tuple.fst.toString(16).padStart(8,'0');
        row.bitParity=row.expectedBits===row.actualBits;
        if(!row.bitParity)throw Error('Native numeric helper F32 bit-pattern mismatch');
      } catch(error) {row.error=error instanceof Error?error.message:String(error);failures.push(fixture.literal+': '+row.error);}
      console.log(JSON.stringify({layer:'native-numeric-helpers',literal:row.literal,expectedBits:row.expectedBits,actualBits:row.actualBits,bitParity:row.bitParity,error:row.error}));
      publish();
    }
    for(const fixture of roundFixtures) {
      const expected=referenceRound(fixture.numerator,fixture.denominator,fixture.shift);
      const row: RoundRow={name:fixture.name,numerator:fixture.numerator.toString(),denominator:fixture.denominator.toString(),shift:fixture.shift.toString(),expectedRounded:expected.toString(),actualRounded:null,parity:false};
      roundingRows.push(row);
      try {
        if(fixture.numerator>MAX_NAT||fixture.denominator>MAX_NAT||fixture.denominator<=0n||expected>MAX_NAT)throw Error('Rounding fixture exceeds bounded helper contract');
        const quotient=fixture.numerator/fixture.denominator,remainder=fixture.numerator%fixture.denominator;
        const actual: unknown=round(Number(fixture.shift),Number(quotient),limbs(remainder),limbs(fixture.denominator));
        if(typeof actual!=='number'||!Number.isSafeInteger(actual))throw Error('Malformed native scaled rounding result');
        row.actualRounded=actual.toString();row.parity=BigInt(actual)===expected;
        if(!row.parity)throw Error('Native scaled RN-even mismatch');
      } catch(error) {row.error=error instanceof Error?error.message:String(error);failures.push(fixture.name+': '+row.error);}
      console.log(JSON.stringify({layer:'native-numeric-helpers',rounding:row.name,expectedRounded:row.expectedRounded,actualRounded:row.actualRounded,parity:row.parity,error:row.error}));
      publish();
    }
  } catch(error) {
    failures.push(error instanceof Error?error.message:String(error));
  } finally {
    rmSync(dir,{recursive:true,force:true});publish();
  }
  if(failures.length){console.error(failures.join('\n'));process.exitCode=1;}
}
if(import.meta.main)await main();
