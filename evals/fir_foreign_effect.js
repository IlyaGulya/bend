// Real foreign effect used by the FIR/Backend IR consumer-ABI smoke. The host
// must load these exact bytes from the declared path and splice them verbatim.
// The load marker is observable by importing the unchanged emitted library.
console.log("fir-foreign-loaded");

function io_fir_mark(text) {
  io_out(1, io_bytes("fir-foreign:" + text + "\n"));
  return { $: CID(Unit) };
}

io_eff(CID(fir_mark), io_fir_mark);
