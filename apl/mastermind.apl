⍝ Mastermind in APL
⍝ Example:
⍝ mastermind 'abcd'
⍝    abcd    +--.
⍝ this means one character is correct (+) and two characters are on the
⍝ wrong position (--) and one character is wrong (.).
⍝ No check for win or number of rounds is made.
characters ← 'abcdefghijklmnopqrstuvwxzy'
colours ← 8
no ← 4
code ← characters[no ? colours]

mastermind ← { '    ',⍵,'    ',( (+/⍵ = code) {(⍺ ↑ '++++'),(⍵ ↑ '----'),((no-⍺+⍵) ↑ '....')} +/(⍵ = code) ≠ ⍵ ∊ code ) }
