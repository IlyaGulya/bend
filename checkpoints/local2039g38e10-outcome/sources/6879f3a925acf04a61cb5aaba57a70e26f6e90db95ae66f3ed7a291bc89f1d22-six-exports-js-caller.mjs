import assert from "node:assert/strict";
import lib from "file:///Users/ilyagulya/Projects/My/bend/checkpoints/local2039g38e10admission01/consumers/six-exports-js-clean.js";
assert.deepEqual(Object.keys(lib),["add","symbol_add","partial","zero","factory","mk"]);assert.equal(lib.add(2,3),5);assert.equal(lib.symbol_add(2,3),5);assert.equal(lib.partial(5,7),12);assert.equal(lib.zero(),9);assert.equal(lib.mk(),9);assert.equal(lib.factory(7),12);assert.equal(lib.factory()(8),13);console.log("export ok");
