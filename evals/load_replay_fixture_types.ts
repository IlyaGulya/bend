import type * as B from '../bend2/bend.ts';
export type ReplayFixture={
 name:string;
 features:string[];
 source:string;
 expected:string;
 expectedError?:string;
 rawOverrides?:Record<string,(kernel:typeof B)=>B.LTerm>;
};
