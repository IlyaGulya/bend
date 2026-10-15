/** Replay the rejected A1 kernel for its retained tests; never imports it into production. */
import {resolve} from 'node:path';
import {unlink} from 'node:fs/promises';
import {createHash,randomUUID} from 'node:crypto';
import type * as Kernel from '../bend2/bend.ts';
export type {LTerm,Body,Patt} from '../bend2/bend.ts';
type A1Kernel=typeof Kernel & {term_occurs(t:Kernel.LTerm,i:number):boolean};
const sourcePath=resolve(import.meta.dir,'../checkpoints/stage0-a1-kernel.ts.txt');
const source=await Bun.file(sourcePath).text();
if(createHash('sha256').update(source).digest('hex')!=='f718dace1297be624a3d32422f51da61a8d5c4e720bfd70a70a5aa9092bf47ef')throw Error('Rejected A1 replay source changed');
// Original BEND_DIR resolves normally: the transient file lives beside the real kernel.
const temporary=resolve(import.meta.dir,'../bend2/.stage0-a1-replay-'+randomUUID()+'.ts');
let replay:A1Kernel;
try {await Bun.write(temporary,source);replay=await import(temporary);}finally{await unlink(temporary);}
export const {body_sub,term_occurs,term_wnf,book_nil,term_higher,App}=replay;
