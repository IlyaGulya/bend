#!/usr/bin/env bun
/** Node diagnostic driver: compile a Bend fixture to C through the actual
 * native_stage_profile_build.compilePhases API. It adds no compiler pipeline
 * and writes only the requested C output plus a JSON digest.
 *
 * node --experimental-transform-types --max-old-space-size=3072
 *   --stack-size=262144 evals/physical_storage_emit.ts <fixture.bend> <out.c>
 */
import {createHash} from 'node:crypto';
import {readFileSync, writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {compilePhases} from './native_stage_profile_build.ts';
const [fixture, out] = process.argv.slice(2);
if (!fixture || !out) throw Error('usage: physical_storage_emit.ts <fixture.bend> <out.c>');
const {c} = await compilePhases(null, resolve(fixture));
writeFileSync(resolve(out), c);
console.log(JSON.stringify({bytes: Buffer.byteLength(c), sha256: createHash('sha256').update(c).digest('hex')}));
