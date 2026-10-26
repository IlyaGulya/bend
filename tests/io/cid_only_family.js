function cid_only_sum_run() {
  const pair = { $: CID(CidOnlyPair), left: 20, right: 22 };
  return pair.left + pair.right;
}

io_eff(CID(cid_only_sum), cid_only_sum_run);
