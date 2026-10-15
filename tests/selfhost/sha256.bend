import Base
import ../../bend2/selfhost/sha256.bend as SHA256

def repeat_a(n: Nat) -> String:
  match n:
    case 0n: ""
    case 1n+p: String.append("a", repeat_a(p))

law main:
  IO(Unit)

def main():
  IO.print(String.join([
    SHA256.hash(""),
    SHA256.hash("abc"),
    SHA256.hash("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"),
    SHA256.hash(repeat_a(55n)),
    SHA256.hash(repeat_a(56n)),
    SHA256.hash(repeat_a(63n)),
    SHA256.hash(repeat_a(64n)),
    SHA256.hash(repeat_a(65n)),
    SHA256.hash(repeat_a(1000n)),
    SHA256.hash("🙂")
  ], "\n"))

#|e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
#|ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
#|248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1
#|9f4390f8d30c2dd92ec9f095b65e2b9ae9b0a925a5258e241c9f1e910f734318
#|b35439a4ac6f0948b6d6f9e3c6af0f5f590ce20f1bde7090ef7970686ec6738a
#|7d3e74a05d7db15bce4ad9ec0658ea98e3f06eeecf16b4c6fff2da457ddc2f34
#|ffe054fe7ae0cb6dc65c3af9b61d5209f439851db43d0ba5997337df154668eb
#|635361c48bb9eab14198e76ea8ab7f1a41685d6ad62aa9146d301d4f17eb0ae0
#|41edece42d63e8d9bf515a9ba6932e1c20cbc9f5a5d134645adb5db1b9737ea3
#|d06f1525f791397809f9bc98682b5c13318eca4c3123433467fd4dffda44fd14
