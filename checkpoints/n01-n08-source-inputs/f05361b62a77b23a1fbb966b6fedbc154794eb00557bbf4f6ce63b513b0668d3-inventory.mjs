import {readFileSync,writeFileSync,existsSync} from 'node:fs';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {instrument} from './plugin.mjs';
const here=dirname(fileURLToPath(import.meta.url));
const [output]=process.argv.slice(2);
if(!output||existsSync(output)) throw Error('Expected fresh inventory output path');
const config=JSON.parse(readFileSync(resolve(here,'config.json'),'utf8'));
const request=JSON.parse(readFileSync(config.request,'utf8'));
// Static authentication/instrumentation only. Never import or execute the image.
const {metadata}=instrument(readFileSync(request.image,'utf8'),{repository:'/Users/ilyagulya/Projects/My/bend',image:request.image,directory:dirname(resolve(output))});
writeFileSync(output,JSON.stringify({schemaVersion:1,status:'SOURCE_ONLY',executedCompiler:false,executedFixtures:false,metadata},null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({status:'SOURCE_ONLY',output:resolve(output),mappedDeclarations:metadata.mapping.length,constructionFunctions:metadata.constructionSites.length}));
