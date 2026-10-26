// Host seam witness for the full-u32 Char domain: a Char and a String cross as
// text, so a code that is no Unicode scalar arrives as U+FFFD and comes back as
// 65533. The boundary scalars cross unchanged, and an answer that is not text
// either (a lone surrogate) is read back as U+FFFD, never as a Char code.
function echo_char(c) {
  return c;
}

// A lone high surrogate is not a Char code, and a lone low surrogate is not a
// packed Char either; both are host text that the answer seam must sanitize.
function lone_char() {
  return "\uD800";
}

function lone_text() {
  return "a\uDC00b";
}

io_eff(CID(echo), echo_char);
io_eff(CID(lone_char), lone_char);
io_eff(CID(lone_text), lone_text);
