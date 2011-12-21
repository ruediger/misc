⍝ reads 'foo.txt' and prints a character count
⍝ ohne Sortierung { (∪⍵),¨(+⌿⍵∘.=∪⍵) }{⎕NREAD ⍵ 82(⎕NSIZE ⍵)0}('foo.txt'⎕NTIE 0 32)
{ (∪⍵[⍋⍵]),¨(+⌿⍵∘.=∪⍵[⍋⍵]) }{⎕NREAD ⍵ 82(⎕NSIZE ⍵)0}('foo.txt'⎕NTIE 0 32)