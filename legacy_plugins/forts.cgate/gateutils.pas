unit gateutils;

interface

uses  {$ifdef MSWINDOWS}
        windows, 
      {$endif}
      sysutils, math, cgate;

const set_date_time_date     = $00000001;
      set_date_time_time     = $00000002;

function cg_datetime_to_unixtime(Value: TDateTime): longint;

function cg_utils_get_int(valuetype: pChar; var buffer): int64;
function cg_utils_get_time(var buffer): tDateTime;
function cg_utils_get_time_as_int(var buffer): int64;

function cg_utils_set_int(valuetype: pChar; const data: int64; var buffer): longint;
function cg_utils_set_char(valuetype: pChar; const data: string; var buffer): longint;
function cg_utils_set_bcd(valuetype: pChar; const data: double; var buffer): longint;
function cg_utils_set_datetime(valuetype: pChar; const data: tDateTime; datepart: longint; var buffer): longint;

function cg_get_devider(decimals: longint): double;
function cg_utils_get_bcd(var buffer): double;

implementation

type  pbyte = ^byte;

const UnixStartDate : TDateTime = 25569.0;

function cg_datetime_to_unixtime(Value: TDateTime): longint;
begin Result := Round((Value - UnixStartDate) * 86400); end;

function cg_utils_get_int(valuetype: pChar; var buffer): int64;
begin
  result:= 0;
  if assigned(valuetype) and (strlen(valuetype) > 0) then begin
    case UpCase(valuetype[0]) of
      'I' : begin
              inc(valuetype);
              case strtointdef(valuetype, 0) of
                1  : result:= ShortInt(buffer);
                2  : result:= SmallInt(buffer);
                4  : result:= LongInt(buffer);
                8  : result:= Int64(buffer);
              end;
            end;
      'U' : begin
              inc(valuetype);
              case strtointdef(valuetype, 0) of
                1  : result:= Byte(buffer);
                2  : result:= Word(buffer);
                4  : result:= Cardinal(buffer);
                8  : result:= Int64(buffer);
              end;
            end;
    end;
  end;
end;

function cg_utils_get_time(var buffer): tDateTime;
begin with tcg_time(buffer) do result:= EncodeDate(year, month, day) + EncodeTime(hour, minute, second, msec); end;

function cg_utils_get_time_as_int(var buffer): int64;
begin
  with tcg_time(buffer) do
    result:= year * 10000000000000 + month * 100000000000 + day * 1000000000 +
             hour * 10000000 + minute * 100000 + second * 1000 + msec;
end;

function cg_utils_set_int(valuetype: pChar; const data: int64; var buffer): longint;
begin
  result:= CG_ERR_OK;
  if assigned(valuetype) and (strlen(valuetype) > 0) then begin
    case UpCase(valuetype[0]) of
      'I' : begin
              inc(valuetype);
              case strtointdef(valuetype, 0) of
                1  : ShortInt(buffer) := data;
                2  : SmallInt(buffer) := data;
                4  : LongInt(buffer)  := data;
                8  : Int64(buffer)    := data;
                else result:= CG_ERR_INTERNAL;
              end;
            end;
      'U' : begin
              inc(valuetype);
              case strtointdef(valuetype, 0) of
                1  : Byte(buffer)     := data;
                2  : Word(buffer)     := data;
                4  : Cardinal(buffer) := data;
                8  : Int64(buffer)    := data;
                else result:= CG_ERR_INTERNAL;
              end;
            end;
      else result:= CG_ERR_INTERNAL;
    end;
  end else result:= CG_ERR_INTERNAL;
end;

function cg_utils_set_char(valuetype: pChar; const data: string; var buffer): longint;
begin
  result:= CG_ERR_INTERNAL;
  if assigned(valuetype) and (strlen(valuetype) > 0) then begin
    if (UpCase(valuetype[0]) = 'C') then begin
      inc(valuetype);
      strplcopy(@buffer, data, strtointdef(valuetype, 0));
      result:= CG_ERR_OK;
    end;
  end;
end;

function cg_utils_set_bcd(valuetype: pChar; const data: double; var buffer): longint;
var i, len, preclen : longint;
    tmpi            : int64;
    sign            : boolean;
    pt              : pChar;
begin
  result:= CG_ERR_INTERNAL;
  if assigned(valuetype) and (strlen(valuetype) > 0) then begin
    if (UpCase(valuetype[0]) = 'D') then begin

      len:= 0; preclen:= 0;

      i:= pos('.', valuetype);
      if (i > 0) then begin
        len:= strtointdef(copy(valuetype, 2, i - 2), 0);
        preclen:= strtointdef(copy(valuetype, i + 1, strlen(valuetype)), 0);
      end;

      Word(buffer):= len shl 8 or preclen;
      tmpi:= round(data * intpower(10, preclen + preclen mod 2));

      sign:= (tmpi < 0);
      if sign then tmpi:= -tmpi;

      pt:= pChar(@buffer) + sizeof(word);
      // конвертируем в bcd
      for i:= ((len shr 1) + ((len or preclen) and 1)) - 1 downto 0 do begin
        pbyte(pt + i)^:= tmpi mod 100;
        tmpi:= tmpi div 100;
      end;
      // знак числа
      if sign then pbyte(pt)^:= pbyte(pt)^ or 128;

      result:= CG_ERR_OK;
    end;
  end;
end;

function cg_utils_set_datetime(valuetype: pChar; const data: tDateTime; datepart: longint; var buffer): longint;
var y, m, d : word;
    h, n, s, ms: word;
begin
  result:= CG_ERR_INTERNAL;
  if assigned(valuetype) and (strlen(valuetype) > 0) then begin
    if (UpCase(valuetype[0]) = 'T') then begin
      if (datepart and set_date_time_date <> 0) then begin
        DecodeDate(data, y, m, d);
        with tcg_time(buffer) do begin
          year   := y;
          month  := m;
          day    := d;
        end;
        result:= CG_ERR_OK;
      end;
      if (datepart and set_date_time_time <> 0) then begin
        DecodeTime(data, h, n, s, ms);
        with tcg_time(buffer) do begin
          hour   := h;
          minute := n;
          second := s;
          msec   := ms;
        end;
        result:= CG_ERR_OK;
      end;
    end;
  end;
end;

function cg_get_devider(decimals: longint): double;
const pwr : array[-8..8] of double = (0.00000001, 0.0000001, 0.000001, 0.00001, 0.0001, 0.001, 0.01, 0.1,
                                      1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000);
begin
  if (decimals >= low(pwr)) and (decimals <= high(pwr)) then result:= pwr[decimals] else result:= intpower(10, decimals);
end;

function cg_utils_get_bcd(var buffer): double;
var   intpart : int64;
      scale   : byte;
begin
  cg_bcd_get(@buffer, intpart, scale);
  result:= intpart / cg_get_devider(scale);
end;

end.