 r←AtoR5 a
 pre←3 10⍴'' 'I' 'II' 'III' 'IV' 'V' 'VI' 'VII' 'VIII' 'IX' '' 'X' 'XX' 'XXX' 'XL' 'L' 'LX' 'LXX' 'LXXX' 'XC' '' 'C' 'CC' 'CCC' 'CD' 'D' 'DC' 'DCC' 'DCCC' 'CM'
 r←((⌊a÷1000)⍴'M'),,/{⍵⌷pre}¨3 2 1,¨1+⌊((1000 100 10)|a)÷(100 10 1)



 r←AtoR4 a
 pre←3 10⍴'' 'I' 'II' 'III' 'IV' 'V' 'VI' 'VII' 'VIII' 'IX' '' 'X' 'XX' 'XXX' 'XL' 'L' 'LX' 'LXX' 'LXXX' 'XC' '' 'C' 'CC' 'CCC' 'CD' 'D' 'DC' 'DCC' 'DCCC' 'CM'
 r←(⌊a÷1000)⍴'M'
 a←1000|a
 r←r,(3(1+⌊a÷100))⌷pre
 a←100|a
 r←r,(2(1+⌊a÷10))⌷pre
 a←10|a
 r←r,(1(1+a))⌷pre



 r←AtoR3 a
 pre←3 10⍴'' 'I' 'II' 'III' 'IV' 'V' 'VI' 'VII' 'VIII' 'IX' '' 'X' 'XX' 'XXX' 'XL' 'L' 'LX' 'LXX' 'LXXX' 'XC' '' 'C' 'CC' 'CCC' 'CD' 'D' 'DC' 'DCC' 'DCCC' 'CM'
 thousands←⌊a÷1000
 a←1000|a
 hundreds←⌊a÷100
 a←100|a
 tens←⌊a÷10
 a←10|a
 ones←a
 r←thousands⍴'M'
 r←r,pre[3;hundreds+1]
 r←r,pre[2;tens+1]
 r←r,pre[1;ones+1]
