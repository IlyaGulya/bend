/* C side of the text-pipeline probe: the literals below are exactly the text
 * Link.c_string_literal produced in `bun bend2/main.ts evals/c_text_probe.bend`
 * output (lambda as two UTF-8 octal bytes, NUL as three-digit octal, quote /
 * newline / backslash as short escapes). Compiling this with clang proves the
 * emitted escape text denotes the byte sequences the renderer counts:
 *   clang -std=c11 -Wall -Werror -o /tmp/litcheck evals/c_literal_bytes_check.c
 * Expected: L1_bytes=3 (λ = 0xCE 0xBB), L2_bytes=1 (NUL), L3_bytes=3.
 */
#include <stdio.h>

int main(void) {
  const char l1[] = "\316\273x";
  const char l2[] = "\000";
  const char l3[] = "\"\n\\";
  printf("L1_bytes=%zu L2_bytes=%zu L3_bytes=%zu\n", sizeof l1 - 1, sizeof l2 - 1, sizeof l3 - 1);
  printf("L1_codes=%u,%u,%u\n", (unsigned char)l1[0], (unsigned char)l1[1], (unsigned char)l1[2]);
  printf("L3_codes=%u,%u,%u\n", (unsigned char)l3[0], (unsigned char)l3[1], (unsigned char)l3[2]);
  return 0;
}
