unit RC5Const;

interface

const RC5Ok         = 0;
      RC5Error      = 1;

const _w            = 32;                    // word size in bits
      _r            = 12;                    // number of rounds
      _b            = 16;                    // number of bytes in key
      _u            = _w/8;                  // word size in bytes
      _c            = (_b*8+_w-1) div _w;    // number words in key = ceil(8*b/w)
      _t            = 2*(_r+1);              // size of table S = 2*(r+1) words

type  pQWord        = ^QWord;
      QWord         = array [0..1] of cardinal;

type  pKey          = ^tKey;
      tKey          = array[0.._b-1] of byte;

type  pExpandedKey  = ^tExpandedKey;
      tExpandedKey  = array[0.._t-1] of cardinal;

implementation

end.