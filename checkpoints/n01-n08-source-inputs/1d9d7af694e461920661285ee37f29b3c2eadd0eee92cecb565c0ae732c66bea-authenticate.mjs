import {writeFileSync} from 'node:fs';
import {authenticate} from './authority.mjs';
const {proof}=authenticate();writeFileSync(process.argv[2],JSON.stringify(proof,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify(proof));
