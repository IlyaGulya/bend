// Same synchronous effect callback contract as foreign_runtime_apply.js.
function witness_reenter(step, value) {
  console.log("callback-before");
  const result = step(value);
  console.log("nested-call:" + result);
  console.log("callback-after");
  return result;
}

io_eff(CID(Host.reenter), witness_reenter);
