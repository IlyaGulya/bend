#!/Users/ilyagulya/bend-g12-borrow-7782b78a-1e88-4ffd-9889-14cb52c6a5b9/.tools/node
import {spawnSync} from "node:child_process";
const a=process.argv.slice(2);
if(a.includes("-x")&&a.some(x=>x.endsWith("/part.bc3")))process.exit(7);
const r=spawnSync("/usr/bin/clang",a,{stdio:"inherit"});
if(r.error)throw r.error;process.exit(r.status??1);
