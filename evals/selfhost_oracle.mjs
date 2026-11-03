import {createHash} from 'node:crypto';
import {readFileSync, realpathSync} from 'node:fs';

const objectOf = value => value !== null && typeof value === 'object' && !Array.isArray(value) ? value : undefined;
const hash = path => createHash('sha256').update(readFileSync(path)).digest('hex');

// A fully checked canonical TS development image is never native/bootstrap authority.
export function authenticateSourceOracle(receiptPath, imagePath) {
  const oracle = objectOf(JSON.parse(readFileSync(receiptPath, 'utf8')));
  if (!oracle || oracle.kind !== 'selfhost-fast-ts-oracle' || oracle.status !== 'FAST_ORACLE_PASS'
    || oracle.nativeCompiler !== false || oracle.acceptanceEvidence !== false || oracle.byteFixedpointClaim !== false
    || oracle.checkOnly !== false || typeof oracle.output !== 'string' || realpathSync(oracle.output) !== realpathSync(imagePath)
    || oracle.outputSha256 !== hash(imagePath) || typeof oracle.source !== 'string'
    || typeof oracle.checkedDefinitions !== 'number' || oracle.checkedDefinitions < 1)
    throw Error('candidate-oracle is not this fully checked canonical source image');
  const pins = objectOf(oracle.loadedInputs);
  if (!pins || Object.keys(pins).length === 0 || pins[oracle.source] !== hash(oracle.source))
    throw Error('candidate-oracle lacks its exact source input');
  for (const [path, digest] of Object.entries(pins))
    if (hash(path) !== digest) throw Error('candidate-oracle source input changed: ' + path);
  return oracle;
}
