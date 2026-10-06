import type {Match} from '../bend2/bend.ts';
import {createHash} from 'node:crypto';
const sha=(s:string)=>createHash('sha256').update(s).digest('hex');
/** Source edits use native raw AST spans. No telescope/body/call edits. */
export function swapMatchSource(source:string,body:Match){
 if(body.e.length!==2||body.r.some(r=>r.p.length!==2))throw Error('Expected two-column match');
 const edits:{beg:number;end:number;before:string;after:string}[]=[];
 function pair(a:{s?:{beg:number;end:number}},b:{s?:{beg:number;end:number}}){
  if(!a.s||!b.s)throw Error('Missing native source spans');
  const first=source.slice(a.s.beg,a.s.end).trimEnd(),second=source.slice(b.s.beg,b.s.end).trimEnd();
  const end=b.s.beg+second.length,between=source.slice(a.s.beg+first.length,b.s.beg);
  if(!/^\s+$/.test(between))throw Error('Non-whitespace between columns');
  const before=source.slice(a.s.beg,end),after=second+between+first;
  if(before.length!==after.length)throw Error('Column swap changed source offsets');
  edits.push({beg:a.s.beg,end,before,after});return{original:[first,second],transformed:[second,first]};
 }
 const scrutinees=pair(body.e[0],body.e[1]);
 const rows=body.r.map((r,index)=>({index,...pair(r.p[0],r.p[1])}));
 let changed=source;for(const e of [...edits].sort((a,b)=>b.beg-a.beg))changed=changed.slice(0,e.beg)+e.after+changed.slice(e.end);
 let recovered=changed;for(const e of [...edits].sort((a,b)=>b.beg-a.beg)){if(recovered.slice(e.beg,e.end)!==e.after)throw Error('Unexpected transformed slice');recovered=recovered.slice(0,e.beg)+e.before+recovered.slice(e.end);}
 if(recovered!==source)throw Error('Swap not exactly invertible');
 const sorted=[...edits].sort((a,b)=>a.beg-b.beg);let pos=0;for(const e of sorted){if(source.slice(pos,e.beg)!==changed.slice(pos,e.beg))throw Error('Unrelated source drift');pos=e.end;}if(source.slice(pos)!==changed.slice(pos))throw Error('Unrelated tail drift');
 const auditRows=rows.map((r,index)=>{
  const patternEnd=edits[index+1].end;
  const end=index+1<rows.length?source.lastIndexOf('\n',edits[index+2].beg)+1:(source.indexOf('\ndef ',patternEnd)<0?source.length:source.indexOf('\ndef ',patternEnd));
  const originalBody=source.slice(patternEnd,end),transformedBody=changed.slice(patternEnd,end);
  if(originalBody!==transformedBody)throw Error('Row body bytes changed');
  return{...r,bodySha256:sha(originalBody),transformedBodySha256:sha(transformedBody),bodyOffsets:{beg:patternEnd,end}};
 });
 return{source:changed,audit:{rowCount:rows.length,scrutinees,rows:auditRows,editCount:edits.length,originalSha256:sha(source),transformedSha256:sha(changed),inverseByteExact:true,unrelatedBytesIdentical:true,bodyOffsetsIdentical:true,rowOrderUnchanged:true,signaturesAndRecursiveCallsUnchanged:true}};
}
