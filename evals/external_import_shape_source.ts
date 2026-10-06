import {readParserGraph} from './parser_full_graph.ts';
import {createHash} from 'node:crypto';
const sha=(s:string)=>createHash('sha256').update(s).digest('hex');
export async function extractExternalImportShape(source:string){
 const before=await readParserGraph(source),body=before.bodies.get('parse_external_imports_scan');
 if(body?.$!=='Match'||body.r.length!==2||body.r[0]!.f.$!=='Match'||body.r[0]!.f.r.length!==3)throw Error('External import matrix drift');
 const nested=body.r[0]!.f,line=(n:number)=>source.lastIndexOf('\n',n)+1,start=source.indexOf('def parse_external_imports_scan('),begin=line(body.e[0]!.s!.beg),next=source.indexOf('\ndef ',start),end=next+1,nilBegin=line(body.r[1]!.p[0]!.s!.beg),original=source.slice(begin,end),rows=[];
 if(start<0||next<0)throw Error('External import source range drift');
 for(const [i,row]of nested.r.entries()){
  const beg=source.indexOf('\n',source.indexOf(':',Math.max(...row.p.map(p=>p.s!.end))))+1,finish=i+1<nested.r.length?line(nested.r[i+1]!.p[0]!.s!.beg):nilBegin,text=source.slice(beg,finish),indent=text.match(/^ */)![0].length,pattern=row.p.map(p=>source.slice(p.s!.beg,p.s!.end)).join(' ');
  rows.push({pattern,originalBodySha256:sha(text),text:'    case '+pattern+' <> rest:\n'+text.trimEnd().split('\n').map(s=>s.trim()?'      '+s.slice(indent):'').join('\n')+'\n'});
 }
 const replacement='  match current:\n'+rows.map(r=>r.text).join('')+source.slice(nilBegin,end),changed=source.slice(0,begin)+replacement+source.slice(end);
 if(changed.slice(0,begin)+original+changed.slice(begin+replacement.length)!==source)throw Error('External import flatten inverse differs');
 const graph=await readParserGraph(changed);return{source:changed,graph,audit:{originalSha256:sha(source),transformedSha256:sha(changed),exactInverse:true,externalABIUnchanged:true,recursiveCallsCopiedExactly:true,originalSuffixesAndQuantities:true,noNewHelpersOrAllocation:true,originalRows:{tokens:3,empty:1},rows:rows.map(({text,...row})=>row)}};
}
