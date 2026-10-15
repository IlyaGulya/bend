import type {Rows} from '../bend2/bend.ts';
export type SuffixEligibility=
  | {eligible:true;boundary:number;wildcardSuffixRows:number}
  | {eligible:false;reason:'no-selected-constructor'|'before-or-between-wildcard'|'no-trailing-wildcard'};
/** Observation only: neither rewrites rows nor selects a compiler path. */
export function trailingSuffixEligibility(rows:Rows,constructor:string):SuffixEligibility {
  let last=-1;
  for(let index=0;index<rows.length;index++){const pattern=rows[index].p[0];if(pattern?.$==='PCtr'&&pattern.k===constructor)last=index;}
  if(last<0)return {eligible:false,reason:'no-selected-constructor'};
  for(let index=0;index<last;index++)if(rows[index].p[0]?.$==='PVar')return {eligible:false,reason:'before-or-between-wildcard'};
  const boundary=last+1;
  let wildcardSuffixRows=0;
  for(let index=boundary;index<rows.length;index++)if(rows[index].p[0]?.$==='PVar')wildcardSuffixRows++;
  return wildcardSuffixRows?{eligible:true,boundary,wildcardSuffixRows}:{eligible:false,reason:'no-trailing-wildcard'};
}
