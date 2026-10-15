import {expect,test} from 'bun:test';
import * as B from './stage0_a1_replay.ts';

test('substituting an absent binder preserves the original immutable Reply',()=>{
  const term:B.LTerm={$:'Var',k:'same',i:12};
  const body:B.Body={$:'Reply',x:term};
  const replacement:B.Patt={$:'PCtr',k:'Zero',x:[]};
  expect(B.body_sub(body,11,replacement)).toBe(body);
  expect(body.x).toBe(term);
});

const variable=(i:number,k='same'):B.LTerm=>({$:'Var',k,i});
const zero:B.Patt={$:'PCtr',k:'Zero',x:[]};
const reply=(x:B.LTerm):B.Body=>({$:'Reply',x});
const pattern=(i:number):B.Patt=>({$:'PVar',k:'same',i,q:{$:'Lone'}});

test('occurrence distinguishes exact IDs, including beneath all expression constructors',()=>{
  const x=variable(11),other=variable(12),ref:B.LTerm={$:'Ref',k:'same'};
  const terms:B.LTerm[]=[
    x,{$:'Typ',g:x},{$:'Min',a:ref,b:x},{$:'App',f:ref,x},
    {$:'ADT',k:'Box',x:[ref,x],r:[]},{$:'Ctr',k:'Box',x:[ref,x]},
    {$:'Mat',k:'Box',h:ref,m:x},{$:'Eql',a:ref,b:ref,T:x},
    {$:'Rwt',e:ref,p:ref,f:x},{$:'Ann',x:ref,T:x},
    {$:'Lam',k:'same',i:12,f:x},
    {$:'All',q:{$:'Lone'},k:'same',i:12,A:ref,B:x},
    {$:'Let',k:['same'],i:[12],q:[{$:'Lone'}],v:[ref],f:x},
    {$:'Sub',i:12,v:pattern(11),f:other},
    {$:'Sub',i:12,v:{$:'PCtr',k:'Box',x:[pattern(11)]},f:other},
  ];
  for(const term of terms){expect(B.term_occurs(term,11)).toBe(true);expect(B.term_occurs(term,99)).toBe(false);}
  for(const term of [other,ref,{$:'Qnt'},{$:'Qua',q:{$:'Many'}},{$:'Efq'},{$:'Rfl'},{$:'Hol',k:'same'}] as B.LTerm[])expect(B.term_occurs(term,11)).toBe(false);
});

test('lambda, forall, let and substitution bind IDs only in their own scopes',()=>{
  const x=variable(11),ref:B.LTerm={$:'Ref',k:'Nat'};
  for(const term of [
    {$:'Lam',k:'same',i:11,f:x},
    {$:'All',q:{$:'Lone'},k:'same',i:11,A:ref,B:x},
    {$:'Let',k:['same'],i:[11],q:[{$:'Lone'}],v:[ref],f:x},
    {$:'Sub',i:11,v:zero,f:x},
  ] as B.LTerm[])expect(B.term_occurs(term,11)).toBe(false);
  for(const term of [
    {$:'All',q:{$:'Lone'},k:'same',i:11,A:x,B:x},
    {$:'Let',k:['same'],i:[11],q:[{$:'Lone'}],v:[x],f:x},
    {$:'Sub',i:11,v:pattern(11),f:x},
  ] as B.LTerm[])expect(B.term_occurs(term,11)).toBe(true);
});

test('present IDs retain actual substitution semantics beneath constructors and lambdas',()=>{
  const x:B.LTerm={$:'Ctr',k:'Box',x:[variable(11),{$:'Lam',k:'same',i:12,f:variable(11)}]};
  const result=B.body_sub(reply(x),11,zero);
  if(result.$!=='Reply')throw Error('Expected Reply');
  const value=B.term_wnf(B.book_nil(),B.term_higher(result.x));
  if(value.$!=='Ctr'||value.k!=='Box')throw Error('Expected Box value');
  const first=B.term_wnf(B.book_nil(),value.x[0]);
  const captured=B.term_wnf(B.book_nil(),B.App(value.x[1],{$:'Ctr',k:'Zero',x:[]}));
  expect(first.$==='Ctr'&&first.k==='Zero').toBe(true);
  expect(captured.$==='Ctr'&&captured.k==='Zero').toBe(true);
});

test('Match no-op shares node and arrays; partial substitution shares unchanged rows',()=>{
  const unchanged=reply(variable(12)),changed=reply(variable(11));
  const rows=[{p:[pattern(20)],f:unchanged},{p:[pattern(21)],f:changed}];
  const body:B.Body={$:'Match',e:[variable(12)],r:rows};
  expect(B.body_sub(body,99,zero)).toBe(body);
  const result=B.body_sub(body,11,zero);
  if(result.$!=='Match')throw Error('Expected Match');
  expect(result.e).toBe(body.e);expect(result.r[0]).toBe(rows[0]);expect(result.r[1].p).toBe(rows[1].p);
  expect(rows[1].f).toBe(changed);
  const scrutineeOnly=B.body_sub(body,12,zero);
  if(scrutineeOnly.$!=='Match')throw Error('Expected Match');
  expect(scrutineeOnly.e[0]).toEqual({$:'Ctr',k:'Zero',x:[],s:undefined});
  expect(body.e[0]).toEqual(variable(12));
});

test('Local copy-on-write keeps untouched values and body identities',()=>{
  const tail=reply(variable(12));
  const body:B.Body={$:'Local',k:[pattern(20),pattern(21)],q:{$:'Lone'},v:[variable(11),variable(12)],f:tail};
  expect(B.body_sub(body,99,zero)).toBe(body);
  const result=B.body_sub(body,11,zero);
  if(result.$!=='Local')throw Error('Expected Local');
  expect(result.v[1]).toBe(body.v[1]);expect(result.f).toBe(tail);expect(result.k).toBe(body.k);expect(result.q).toBe(body.q);
  expect(body.v[0]).toEqual(variable(11));
  const bodyOnly=B.body_sub({...body,v:[variable(13),variable(14)]},12,zero);
  if(bodyOnly.$!=='Local')throw Error('Expected Local');
  expect(bodyOnly.f===tail).toBe(false);
});
