/** Experimental, AST-only source factoring. Not installed in production emission.
 * Peel one shared constructor from a large first column. Ordered wildcard rows
 * remain in the constructor branch and in the default branch, so an earlier
 * wildcard can still shadow a later constructor row. No decision-tree search,
 * constructor inventory, declaration names, source coordinates or type guesses.
 */
import {body_sub,quant_join,type Body,type Match,type Patt,type PCtr,type PVar,type Quant} from '../bend2/bend.ts';
export type MatchFactorAudit = {considered:number;eligible:number;factored:number;sourceSpecificExceptions:0;matches:Array<{beforeRows:number;beforeColumns:number;outerRows:number;outerColumns:number;branches:Array<{rows:number;columns:number}>;status:string}>};
export function factorMatches(body:Body,options:{minimumRows?:number;minimumFreshId?:number}={}):{body:Body;audit:MatchFactorAudit} {
  const minimumRows=options.minimumRows??4;
  let fresh=options.minimumFreshId??0;const seen=new WeakSet<object>();
  function reserve(value:unknown){if(!value||typeof value!=='object'||seen.has(value))return;seen.add(value);for(const [key,item]of Object.entries(value)){if(key==='s')continue;if(key==='i'&&typeof item==='number')fresh=Math.max(fresh,item+1);else reserve(item);}}
  reserve(body);
  const audit:MatchFactorAudit={considered:0,eligible:0,factored:0,sourceSpecificExceptions:0,matches:[]};
  function variable(q:Quant):PVar {const i=fresh++;return {$:'PVar',k:'factor_'+i,i,q};}
  function visit(node:Body):Body {
    if(node.$!=='Local'&&node.$!=='Match')return node;
    if(node.$==='Local')return {...node,f:visit(node.f)};
    audit.considered++;
    const current:Match={...node,r:node.r.map(row=>({...row,f:visit(row.f)}))};
    if(current.r.length<minimumRows||current.e.length<2)return current;
    audit.eligible++;
    const constructors=current.r.map(row=>row.p[0]).filter((p):p is PCtr=>p?.$==='PCtr');
    const first=constructors[0];
    const entry={beforeRows:current.r.length,beforeColumns:current.e.length,outerRows:current.r.length,outerColumns:current.e.length,branches:[] as Array<{rows:number;columns:number}>,status:'no-shared-constructor'};
    audit.matches.push(entry);
    if(!first||constructors.some(p=>p.k!==first.k||p.x.length!==first.x.length)||current.e[0]?.$!=='Var')return current;
    let mark:Quant={$:'None'};
    for(const row of current.r){const p=row.p[0];if(p.$==='PVar')mark=quant_join(mark,p.q);}
    const fields=first.x.map(p=>variable(quant_join(mark,p.$==='PVar'?p.q:{$:'None'})));
    const prefix:PCtr={$:'PCtr',k:first.k,x:fields};
    const constructorRows=current.r.map(row=>{
      const p=row.p[0];
      if(p.$==='PCtr')return {p:[...p.x,...row.p.slice(1)],f:row.f};
      const wildcards=fields.map(()=>variable(p.q));
      return {p:[...wildcards,...row.p.slice(1)],f:body_sub(row.f,p.i,prefix)};
    });
    const constructorBody:Match={$:'Match',e:[...fields.map(p=>({$: 'Var' as const,k:p.k,i:p.i})),...current.e.slice(1)],r:constructorRows};
    const rows:Array<{p:Patt[];f:Body}>=[{p:[prefix],f:constructorBody}];
    const defaults=current.r.filter(row=>row.p[0].$==='PVar');
    entry.branches.push({rows:constructorRows.length,columns:constructorBody.e.length});
    if(defaults.length){const fallback=variable(mark);const defaultBody:Match={$:'Match',e:current.e.slice(1),r:defaults.map(row=>({p:row.p.slice(1),f:body_sub(row.f,(row.p[0] as PVar).i,fallback)}))};rows.push({p:[fallback],f:defaultBody});entry.branches.push({rows:defaults.length,columns:defaultBody.e.length});}
    audit.factored++;entry.status='shared-constructor-prefix';entry.outerRows=rows.length;entry.outerColumns=1;
    return {$:'Match',e:[current.e[0]],r:rows,s:current.s};
  }
  return {body:visit(body),audit};
}
