{$A+}{ word align }
{$O+}{ ?? ?? }

unit lzh;

{$R-}{ NO range checking !! }

interface

type
  Int16 = smallint;

type
  TPackData = record
    InBuf, OutBuf: PChar;
    SSize, DSize: longint;
    InPos, OutPos: longint;
    RSSize, WDSize: longint;
    case byte of
      0: (Bytes_Written: longint);
      1: (TextSize: longint);
  end;

procedure PackUnpack(pack: boolean; var PackData: TPackData);

implementation

const
  EXIT_OK = 0;
  EXIT_FAILED = 1;
  { LZSS Parameters }
  N = 4096;  { Size of string buffer }
  F = 60;     { Size of look-ahead buffer }
  THRESHOLD = 2;
  NUL = N;     { End of tree's node  }

  { Huffman coding parameters }
  N_CHAR = (256 - THRESHOLD + F);
  { character code (:= 0..N_CHAR-1) }
  T = (N_CHAR * 2 - 1);   { Size of table }
  R = (T - 1);           { root position }
  MAX_FREQ = $8000;
  { update when cumulative frequency }
  { reaches to this value }
{
 * Tables FOR encoding/decoding upper 6 bits of
 * sliding dictionary pointer
 }
  { encoder table }
  p_len: array[0..63] of byte =
    ($03, $04, $04, $04, $05, $05, $05, $05,
    $05, $05, $05, $05, $06, $06, $06, $06,
    $06, $06, $06, $06, $06, $06, $06, $06,
    $07, $07, $07, $07, $07, $07, $07, $07,
    $07, $07, $07, $07, $07, $07, $07, $07,
    $07, $07, $07, $07, $07, $07, $07, $07,
    $08, $08, $08, $08, $08, $08, $08, $08,
    $08, $08, $08, $08, $08, $08, $08, $08);

  p_code: array [0..63] of byte =
    ($00, $20, $30, $40, $50, $58, $60, $68,
    $70, $78, $80, $88, $90, $94, $98, $9C,
    $A0, $A4, $A8, $AC, $B0, $B4, $B8, $BC,
    $C0, $C2, $C4, $C6, $C8, $CA, $CC, $CE,
    $D0, $D2, $D4, $D6, $D8, $DA, $DC, $DE,
    $E0, $E2, $E4, $E6, $E8, $EA, $EC, $EE,
    $F0, $F1, $F2, $F3, $F4, $F5, $F6, $F7,
    $F8, $F9, $FA, $FB, $FC, $FD, $FE, $FF);

  { decoder table }
  d_code: array [0..255] of byte =
    ($00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00,
    $01, $01, $01, $01, $01, $01, $01, $01,
    $01, $01, $01, $01, $01, $01, $01, $01,
    $02, $02, $02, $02, $02, $02, $02, $02,
    $02, $02, $02, $02, $02, $02, $02, $02,
    $03, $03, $03, $03, $03, $03, $03, $03,
    $03, $03, $03, $03, $03, $03, $03, $03,
    $04, $04, $04, $04, $04, $04, $04, $04,
    $05, $05, $05, $05, $05, $05, $05, $05,
    $06, $06, $06, $06, $06, $06, $06, $06,
    $07, $07, $07, $07, $07, $07, $07, $07,
    $08, $08, $08, $08, $08, $08, $08, $08,
    $09, $09, $09, $09, $09, $09, $09, $09,
    $0A, $0A, $0A, $0A, $0A, $0A, $0A, $0A,
    $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B,
    $0C, $0C, $0C, $0C, $0D, $0D, $0D, $0D,
    $0E, $0E, $0E, $0E, $0F, $0F, $0F, $0F,
    $10, $10, $10, $10, $11, $11, $11, $11,
    $12, $12, $12, $12, $13, $13, $13, $13,
    $14, $14, $14, $14, $15, $15, $15, $15,
    $16, $16, $16, $16, $17, $17, $17, $17,
    $18, $18, $19, $19, $1A, $1A, $1B, $1B,
    $1C, $1C, $1D, $1D, $1E, $1E, $1F, $1F,
    $20, $20, $21, $21, $22, $22, $23, $23,
    $24, $24, $25, $25, $26, $26, $27, $27,
    $28, $28, $29, $29, $2A, $2A, $2B, $2B,
    $2C, $2C, $2D, $2D, $2E, $2E, $2F, $2F,
    $30, $31, $32, $33, $34, $35, $36, $37,
    $38, $39, $3A, $3B, $3C, $3D, $3E, $3F);

  d_len: array[0..255] of byte =
    ($03, $03, $03, $03, $03, $03, $03, $03,
    $03, $03, $03, $03, $03, $03, $03, $03,
    $03, $03, $03, $03, $03, $03, $03, $03,
    $03, $03, $03, $03, $03, $03, $03, $03,
    $04, $04, $04, $04, $04, $04, $04, $04,
    $04, $04, $04, $04, $04, $04, $04, $04,
    $04, $04, $04, $04, $04, $04, $04, $04,
    $04, $04, $04, $04, $04, $04, $04, $04,
    $04, $04, $04, $04, $04, $04, $04, $04,
    $04, $04, $04, $04, $04, $04, $04, $04,
    $05, $05, $05, $05, $05, $05, $05, $05,
    $05, $05, $05, $05, $05, $05, $05, $05,
    $05, $05, $05, $05, $05, $05, $05, $05,
    $05, $05, $05, $05, $05, $05, $05, $05,
    $05, $05, $05, $05, $05, $05, $05, $05,
    $05, $05, $05, $05, $05, $05, $05, $05,
    $05, $05, $05, $05, $05, $05, $05, $05,
    $05, $05, $05, $05, $05, $05, $05, $05,
    $06, $06, $06, $06, $06, $06, $06, $06,
    $06, $06, $06, $06, $06, $06, $06, $06,
    $06, $06, $06, $06, $06, $06, $06, $06,
    $06, $06, $06, $06, $06, $06, $06, $06,
    $06, $06, $06, $06, $06, $06, $06, $06,
    $06, $06, $06, $06, $06, $06, $06, $06,
    $07, $07, $07, $07, $07, $07, $07, $07,
    $07, $07, $07, $07, $07, $07, $07, $07,
    $07, $07, $07, $07, $07, $07, $07, $07,
    $07, $07, $07, $07, $07, $07, $07, $07,
    $07, $07, $07, $07, $07, $07, $07, $07,
    $07, $07, $07, $07, $07, $07, $07, $07,
    $08, $08, $08, $08, $08, $08, $08, $08,
    $08, $08, $08, $08, $08, $08, $08, $08);

procedure PackUnpack(pack: boolean; var PackData: TPackData);

  procedure GetBytes(var DTA; NBytes: word; var Bytes_Got: word);
  begin
    with PackData do
    begin
      if InPos + NBytes > SSize then
        Bytes_Got := SSize - InPos
      else
        Bytes_Got := NBytes;
      Move((InBuf + InPos)^, DTA, Bytes_Got);
      Inc(InPos, Bytes_Got);
    end;
  end;

  procedure PutBytes(var DTA; NBytes: word; var Bytes_Put: word);
  begin
    with PackData do
    begin
      Bytes_Put := 0;
      if NBytes > 0 then
        if OutPos + NBytes <= DSize then
        begin
          if OutPos + NBytes > WDSize then
            WDSize := OutPos + NBytes;
          Move(DTA, (OutBuf + OutPos)^, NBytes);
          Inc(OutPos, NBytes);
          Bytes_Put := NBytes;
        end;
    end;
  end;

type
  Freqtype = array[0..T] of word;
  //  FreqPtr = ^freqtype;
  FreqPtr = freqtype;
  PntrType = array[0..PRED(T + N_Char)] of Int16;
  //  pntrPtr = ^pntrType;
  pntrPtr = pntrType;
  SonType = array[0..PRED(T)] of Int16;
  //  SonPtr = ^SonType;
  SonPtr = SonType;

  TextBufType = array[0..N + F - 2] of byte;
  //  TBufPtr = ^TextBufType;
  TBufPtr = TextBufType;
  WordRay = array[0..N] of Int16;
  //  WordRayPtr = ^WordRay;
  WordRayPtr = WordRay;
  BWordRay = array[0..N + 256] of Int16;
  //  BWordRayPtr = ^BWordRay;
  BWordRayPtr = BWordRay;

var

  getbuf: word;
  getlen: byte;
  putlen: byte;
  putbuf: word;
  textsize: longint;
  codesize: longint;
  match_position: Int16;
  match_length: Int16;

  text_buf: TBufPtr;
  lson, dad: WordRayPtr;
  rson: BWordRayPtr;
  freq: FreqPtr;  { cumulative freq table }

{
 * pointing parent nodes.
 * area [T..(T + N_CHAR - 1)] are pointers FOR leaves
 }
  prnt: PntrPtr;

  { pointing children nodes (son[], son[] + 1)}
  son: SonPtr;

  procedure InitTree;  { Initializing tree }
  var
    i: Int16;
  begin
    for i := N + 1 to N + 256 do
      rson[i] := NUL;  { root }
    for i := 0 to N do
      dad[i] := NUL;      { node }
  end;

  procedure InsertNode(r: Int16);  { Inserting node to the tree }
  var
    tmp, i, p, cmp: Int16;
    key: ^TBufPtr;
    c: word;
  begin
    cmp := 1;
    key := @text_buf[r];
    p := SUCC(N) + key^[0];
    rson[r] := NUL;
    lson[r] := NUL;
    match_length := 0;
    while match_length < F do
    begin
      if (cmp >= 0) then
      begin
        if (rson[p] <> NUL) then
          p := rson[p]
        else
        begin
          rson[p] := r;
          dad[r] := p;
          exit;
        end;
      end
      else if (lson[p] <> NUL) then
        p := lson[p]
      else
      begin
        lson[p] := r;
        dad[r] := p;
        exit;
      end;
      i := 0;
      cmp := 0;
      while (i < F) and (cmp = 0) do
      begin
        Inc(i);
        cmp := key^[i] - text_buf[p + i];
      end;
      if (i > THRESHOLD) then
      begin
        tmp := PRED((r - p) and PRED(N));
        if (i > match_length) then
        begin
          match_position := tmp;
          match_length := i;
        end;
        if (match_length < F) and (i = match_length) then
        begin
          c := tmp;
          if (c < word(match_position)) then
            match_position := c;
        end;
      end; { if i > threshold }
    end; { WHILE match_length < F }
    dad[r] := dad[p];
    lson[r] := lson[p];
    rson[r] := rson[p];
    dad[lson[p]] := r;
    dad[rson[p]] := r;
    if (rson[dad[p]] = p) then
      rson[dad[p]] := r
    else
      lson[dad[p]] := r;
    dad[p] := NUL;  { remove p }
  end;

  procedure DeleteNode(p: Int16);  { Deleting node from the tree }

  var
    q: Int16;

  begin
    if (dad[p] = NUL) then
      exit;      { unregistered }

    if (rson[p] = NUL) then
      q := lson[p]
    else if (lson[p] = NUL) then
      q := rson[p]
    else
    begin
      q := lson[p];
      if (rson[q] <> NUL) then
      begin
        repeat
          q := rson[q];
        until (rson[q] = NUL);
        rson[dad[q]] := lson[q];
        dad[lson[q]] := dad[q];
        lson[q] := lson[p];
        dad[lson[p]] := q;
      end;
      rson[q] := rson[p];
      dad[rson[p]] := q;
    end;
    dad[q] := dad[p];

    if (rson[dad[p]] = p) then
      rson[dad[p]] := q
    else
      lson[dad[p]] := q;

    dad[p] := NUL;

  end;

  { Huffman coding parameters }

  function GetBit: Int16;  { get one bit }
  var
    i: byte;
    i2: Int16;
    Wresult: word;

  begin
    while (getlen <= 8) do
    begin
      GetBytes(i, 1, Wresult);
      if Wresult = 1 then
        i2 := i
      else
        i2 := 0;

      getbuf := getbuf or (i2 shl (8 - getlen));
      Inc(getlen, 8);
    end;
    i2 := getbuf;
    getbuf := getbuf shl 1;
    Dec(getlen);
    result := Int16((i2 < 0));
  end;

  function GetByte: Int16;  { get a byte }
  var
    j: byte;
    i, Wresult: word;
  begin
    while (getlen <= 8) do
    begin
      GetBytes(j, 1, Wresult);
      if Wresult = 1 then
        i := j
      else
        i := 0;

      getbuf := getbuf or (i shl (8 - getlen));
      Inc(getlen, 8);
    end;
    i := getbuf;
    getbuf := getbuf shl 8;
    Dec(getlen, 8);
    result := Int16(i shr 8);
  end;

  procedure Putcode(l: Int16; c: word);    { output c bits }
  var
    Temp: byte;
    Got: word;
  begin
    putbuf := putbuf or (c shr putlen);
    Inc(putlen, l);
    if (putlen >= 8) then
    begin
      Temp := putbuf shr 8;
      PutBytes(Temp, 1, Got);
      Dec(putlen, 8);
      if (putlen >= 8) then
      begin
        Temp := Lo(PutBuf);
        PutBytes(Temp, 1, Got);
        Inc(codesize, 2);
        Dec(putlen, 8);
        putbuf := c shl (l - putlen);
      end
      else
      begin
        putbuf := putbuf shl 8;
        Inc(codesize);
      end;
    end;
  end;

  { initialize freq tree }

  procedure StartHuff;
  var
    i, j: Int16;
  begin
    for i := 0 to PRED(N_CHAR) do
    begin
      freq[i] := 1;
      son[i] := i + T;
      prnt[i + T] := i;
    end;
    i := 0;
    j := N_CHAR;
    while (j <= R) do
    begin
      freq[j] := freq[i] + freq[i + 1];
      son[j] := i;
      prnt[i] := j;
      prnt[i + 1] := j;
      Inc(i, 2);
      Inc(j);
    end;
    freq[T] := $ffff;
    prnt[R] := 0;
  end;

  { reconstruct freq tree }

  procedure reconst;
  var
    i, j, k, tmp: Int16;
    f, l: word;
  begin
    { halven cumulative freq FOR leaf nodes }
    j := 0;
    for i := 0 to PRED(T) do
      if (son[i] >= T) then
      begin
        freq[j] := SUCC(freq[i]) div 2;    {@@ Bug Fix MOD -> DIV @@}
        son[j] := son[i];
        Inc(j);
      end;
    { make a tree : first, connect children nodes }
    i := 0;
    j := N_CHAR;
    while (j < T) do
    begin
      k := SUCC(i);
      f := freq[i] + freq[k];
      freq[j] := f;
      k := PRED(j);
      while f < freq[k] do
        Dec(K);
      Inc(k);
      l := (j - k) shl 1;
      tmp := SUCC(k);
      move(freq[k], freq[tmp], l);
      freq[k] := f;
      move(son[k], son[tmp], l);
      son[k] := i;
      Inc(i, 2);
      Inc(j);
    end;
    { connect parent nodes }
    for i := 0 to PRED(T) do
    begin
      k := son[i];
      if (k >= T) then
        prnt[k] := i
      else
      begin
        prnt[k] := i;
        prnt[SUCC(k)] := i;
      end;
    end;

  end;

  { update freq tree }

  procedure update(c: Int16);
  var
    i, j, k, l: Int16;
  begin
    if (freq[R] = MAX_FREQ) then
      reconst;
    c := prnt[c + T];
    repeat
      Inc(freq[c]);
      k := freq[c];

      { swap nodes to keep the tree freq-ordered }
      l := SUCC(C);
      if (word(k) > freq[l]) then
      begin
        while (word(k) > freq[l]) do
          Inc(l);
        Dec(l);
        freq[c] := freq[l];
        freq[l] := k;

        i := son[c];
        prnt[i] := l;
        if (i < T) then
          prnt[SUCC(i)] := l;

        j := son[l];
        son[l] := i;

        prnt[j] := c;
        if (j < T) then
          prnt[SUCC(j)] := c;
        son[c] := j;

        c := l;
      end;
      c := prnt[c];
    until (c = 0);  { REPEAT it until reaching the root }
  end;

  procedure EncodeChar(c: word);
  var
    i: word;
    j, k: Int16;
  begin
    i := 0;
    j := 0;
    k := prnt[c + T];
    { search connections from leaf node to the root }
    repeat
      i := i shr 1;
      { IF node's address is odd, output 1 ELSE output 0 }
      if boolean(k and 1) then Inc(i, $8000);
      Inc(j);
      k := prnt[k];
    until (k = R);
    Putcode(j, i);
    update(c);
  end;

  procedure EncodePosition(c: word);
  var
    i, j: word;
  begin
    { output upper 6 bits with encoding }
    i := c shr 6;
    j := p_code[i];
    Putcode(p_len[i], j shl 8);

    { output lower 6 bits directly }
    Putcode(6, (c and $3f) shl 10);
  end;

  procedure EncodeEnd;
  var
    Temp: byte;
    Got: word;
  begin
    if boolean(putlen) then
    begin
      Temp := byte(putbuf shr 8);
      PutBytes(Temp, 1, Got);
      Inc(codesize);
    end;
  end;

  function DecodeChar: Int16;
  var
    c: word;
  begin
    c := son[R];

    {
     * start searching tree from the root to leaves.
     * choose node #(son[]) IF input bit = 0
     * ELSE choose #(son[]+1) (input bit = 1)
    }
    while (c < T) do
    begin
      c := c + GetBit;
      c := son[c];
    end;
    c := c - T;
    update(c);
    result := Int16(c);
  end;

  function DecodePosition: word;
  var
    i, j, c: word;
  begin
    { decode upper 6 bits from given table }
    i := GetByte;
    c := word(d_code[i] shl 6);
    j := d_len[i];

    { input lower 6 bits directly }
    Dec(j, 2);
    while j <> 0 do
    begin
      i := (i shl 1) + GetBit;
      Dec(J);
    end;
    result := c or i and $3f;
  end;

  { Compression }

  procedure InitLZH;
  begin
    getbuf := 0;
    getlen := 0;
    putlen := 0;
    putbuf := 0;
    textsize := 0;
    codesize := 0;
    match_position := 0;
    match_length := 0;
  end;

  procedure _LZHPack(var Bytes_Written: longint);
  var
    ct: byte;
    i, len, r, s, last_match_length: Int16;
    Got: word;
  begin

    InitLZH;

    textsize := 0;      { rewind and rescan }
    StartHuff;
    InitTree;
    s := 0;
    r := N - F;
    FillChar(Text_buf[0], r, ' ');
    len := 0;
    Got := 1;
    while (len < F) and (Got <> 0) do
    begin
      GetBytes(ct, 1, Got);
      if Got <> 0 then
      begin
        text_buf[r + len] := ct;
        Inc(len);
      end;
    end;
    textsize := len;
    for i := 1 to F do
      InsertNode(r - i);
    InsertNode(r);
    repeat
      if (match_length > len) then
        match_length := len;
      if (match_length <= THRESHOLD) then
      begin
        match_length := 1;
        EncodeChar(text_buf[r]);
      end
      else
      begin
        EncodeChar(255 - THRESHOLD + match_length);
        EncodePosition(match_position);
      end;
      last_match_length := match_length;
      i := 0;
      Got := 1;
      while (i < last_match_length) and (Got <> 0) do
      begin
        GetBytes(ct, 1, Got);
        if Got <> 0 then
        begin
          DeleteNode(s);
          text_buf[s] := ct;
          if (s < PRED(F)) then
            text_buf[s + N] := ct;
          s := SUCC(s) and PRED(N);
          r := SUCC(r) and PRED(N);
          InsertNode(r);
          Inc(i);
        end;
      end; { endwhile }
      Inc(textsize, i);
      while (i < last_match_length) do
      begin
        Inc(i);
        DeleteNode(s);
        s := SUCC(s) and PRED(N);
        r := SUCC(r) and PRED(N);
        Dec(len);
        if boolean(len) then
          InsertNode(r);
      end; { endwhile }
    until (len <= 0);  { end repeat }
    EncodeEnd;

    Bytes_Written := TextSize;

  end;

  procedure _LZHUnpack(TextSize: longint);
  var
    c, i, j, k, r: Int16;
    c2: byte;
    Count: longint;
    Put: word;

  begin
    InitLZH;
    StartHuff;
    r := N - F;
    FillChar(text_buf[0], r, ' ');
    Count := 0;
    while Count < textsize do
    begin
      c := DecodeChar;
      if (c < 256) then
      begin
        c2 := Lo(c);
        PutBytes(c2, 1, Put);
        text_buf[r] := c;
        Inc(r);
        r := r and PRED(N);
        Inc(Count);
      end
      else
      begin                {c >= 256 }
        i := (r - SUCC(DecodePosition)) and PRED(N);
        j := c - 255 + THRESHOLD;
        for k := 0 to PRED(j) do
        begin
          c := text_buf[(i + k) and PRED(N)];
          c2 := Lo(c);
          PutBytes(c2, 1, Put);
          text_buf[r] := c;
          Inc(r);
          r := r and PRED(N);
          Inc(Count);
        end;  { for }
      end;  { if c < 256 }
    end; {endwhile count < textsize }
  end;

begin
  with PackData do
    if Pack then
      _LZHPack(Bytes_Written)
    else
      _LZHUnpack(TextSize);
end;

end.
