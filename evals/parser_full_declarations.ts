export type SourceDeclaration={name:string;kind:string;start:number;end:number;prefix:string;annotations:string[]};

/** Source association for a declaration and its own leading metadata. */
export class SourceDeclarations {
 readonly declarations=new Map<string,SourceDeclaration>();
 constructor(readonly source:string){
  const headers=[...source.matchAll(/^(def|type|law)\s+([A-Za-z_]\w*)\b/gm)];
  const rows=headers.map(header=>{
   const start=header.index!,annotations:string[]=[];
   let cursor=start,prefixStart=start;
   while(cursor>0){
    const end=cursor-1,begin=source.lastIndexOf('\n',end-1)+1;
    const line=source.slice(begin,end).trim();
    if(!line||line.startsWith('#')){cursor=begin;continue;}
    if(line.startsWith('@')){annotations.unshift(line);prefixStart=begin;cursor=begin;continue;}
    break;
   }
   return {name:header[2]!,kind:header[1]!,start,prefixStart,prefix:source.slice(prefixStart,start),annotations};
  });
  for(let index=0;index<rows.length;index++){
   const row=rows[index]!;
   this.declarations.set(row.name,{...row,end:rows[index+1]?.prefixStart??source.length});
  }
 }
 body(name:string):string {
  const declaration=this.declarations.get(name);
  if(!declaration)throw Error('Missing source declaration '+name);
  return this.source.slice(declaration.start,declaration.end).trimEnd();
 }
 emit(name:string,definition=this.body(name)):string {
  const declaration=this.declarations.get(name);
  if(!declaration)throw Error('Missing source declaration '+name);
  const header=/^(def|type|law)\s+/m.exec(definition);
  if(!header||header[1]!==declaration.kind)
   throw Error('Incompatible declaration metadata: '+name+' changed declaration kind');
  const annotations=definition.slice(0,header.index).split('\n').map(line=>line.trim()).filter(line=>line.startsWith('@'));
  if(annotations.length){
   if(JSON.stringify(annotations)!==JSON.stringify(declaration.annotations))
    throw Error('Conflicting declaration metadata: '+name);
   return definition;
  }
  return declaration.prefix+definition;
 }
 audit(emittedSource:string,owners:ReadonlyMap<string,string>){
  const emitted=new SourceDeclarations(emittedSource);
  const canonicalAnnotated=[...this.declarations.values()].filter(row=>row.annotations.length).map(row=>({name:row.name,annotations:row.annotations}));
  const generatedAnnotated=[...emitted.declarations.values()].filter(row=>row.annotations.length).map(row=>({name:row.name,annotations:row.annotations}));
  const missing:{name:string;sourceName:string;expected:string[];observed:string[]}[]=[];
  const spurious:{name:string;sourceName?:string;expected:string[];observed:string[]}[]=[];
  const represented=new Set<string>();
  for(const row of emitted.declarations.values()){
   const sourceName=owners.get(row.name)??(this.declarations.has(row.name)?row.name:undefined);
   if(sourceName!==undefined)represented.add(sourceName);
   const expected=sourceName===undefined?[]:this.declarations.get(sourceName)?.annotations??[];
   if(JSON.stringify(expected)!==JSON.stringify(row.annotations)){
    if(expected.length)missing.push({name:row.name,sourceName:sourceName!,expected,observed:row.annotations});
    if(row.annotations.length)spurious.push({name:row.name,sourceName,expected,observed:row.annotations});
   }
  }
  for(const row of canonicalAnnotated)if(!represented.has(row.name))
   missing.push({name:row.name,sourceName:row.name,expected:row.annotations,observed:[]});
  return {canonicalAnnotatedCount:canonicalAnnotated.length,generatedAnnotatedCount:generatedAnnotated.length,canonicalAnnotated,generatedAnnotated,missing,spurious};
 }
}
