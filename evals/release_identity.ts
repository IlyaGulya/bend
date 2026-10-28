/**
 * The one upstream release this selfhost source baseline is migrated to.
 *
 * Active parser producers, drivers and gates authenticate the working kernel
 * against this exact Git object, so the release commit, its tag and the
 * `bend2/bend.ts` blob digest have a single declared source of truth here.
 * Frozen historical probes keep their own explicit old pins: a new release
 * never rewrites evidence about an older run.
 */
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';

/** Bend 2.0.39 (`v2.0.39`), the exact upstream release object. */
export const OFFICIAL_BEND_RELEASE = 'a3efe8a3801f423827424227172eed9802c5e6cb';
export const OFFICIAL_BEND_VERSION = '2.0.39';

const sha = (bytes: string | Uint8Array) => createHash('sha256').update(bytes).digest('hex');

/** Exact `bend2/bend.ts` bytes of the official release, read from Git. */
export function officialKernelSource(repository: string): string {
  return execFileSync('git', ['show', OFFICIAL_BEND_RELEASE + ':bend2/bend.ts'],
    {cwd: repository, encoding: 'utf8'});
}

/** Digest of the official release kernel; the working kernel must match it. */
export function officialKernelSha256(repository: string): string {
  return sha(officialKernelSource(repository));
}
