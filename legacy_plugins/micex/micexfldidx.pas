{$I micexdefs.pas}

unit  micexfldidx;

interface

uses  sysutils, sortedlist;

type  pFieldEnumRec    = ^tFieldEnumRec;
      tFieldEnumRec    = record
       fldname         : string;
       flduniidx       : longint;
      end;

type  tFielfNameIndex  = class(tSortedList)
       constructor create;
       procedure   freeitem(item: pointer); override;
       function    checkitem(item: pointer): boolean; override;
       function    compare(item1, item2: pointer): longint; override;
       function    indexbyname(const aname: string): longint;
      end;

const fldUnknownField  =  -1;

      fldSECBOARD      =   0;     // securities
      fldSECCODE       =   1;
      fldSHORTNAME     =   2;
      fldBID           =   3;
      fldOFFER         =   4;
      fldOPEN          =   5;
      fldHIGH          =   6;
      fldLOW           =   7;
      fldWAPRICE       =   8;
      fldCHANGE        =   9;
      fldVOLTODAY      =  10;
      fldVALTODAY      =  11;
      fldLOTSIZE       =  12;
      fldLAST          =  13;
      fldVALUE         =  14;
      fldTIME          =  15;
      fldYIELD         =  16;
      fldMATDATE       =  17;
      fldCOUPONVALUE   =  18;
      fldNEXTCOUPON    =  19;
      fldCOUPONPERIOD  =  20;
      fldDECIMALS      =  21;
      fldFACEVALUE     =  22;
      fldBIDDEPTHT     =  23;
      fldOFFERDEPTHT   =  24;
      fldNUMBIDS       =  25;
      fldNUMOFFERS     =  26;
      fldTRADINGSTATUS =  27;
      fldCLOSEPRICE    =  28;
      fldQTY           =  29;
      fldACCRUEDINT    =  30;
      fldPREVPRICE     =  31;
      fldISSUESIZE     =  32;
      fldBUYBACKPRICE  =  33;
      fldBUYBACKDATE   =  34;
      fldMARKETPRICE   =  58;

      fldORDERNO       =  35;     // orders
      fldORDERTIME     =  36;
      fldSTATUS        =  37;
      fldBUYSELL       =  38;
      fldACCOUNT       =  39;
      fldPRICE         =  40;
      fldQUANTITY      =  41;
      fldBALANCE       =  42;
      fldBROKERREF     =  43;
      fldEXTREF        =  44;

      fldDEALNO        =  45;     // repo orders
      fldDEALTIME      =  46;

      fldTRADENO       =  47;     // trades
      fldTRADETIME     =  48;
      fldSETTLECODE    =  49;

      fldTRADEDATE     =  50;     // repo trades
      fldTRDACCID      =  51;

      fldFIRMID        =  52;     // firms table
      fldFIRMNAME      =  53;

      fldDESCRIPTION   =  54;     // settlecodes
      fldSETTLEDATE    =  55;
      fldSETTLEDATE2   =  56;

      fldDATE          =  57;     // tesystemtime

      fldREPORATE      =  59;     // alltrades
      fldREPOTERM      =  60;

      fldFROMUSER      =  61;     // messages
      fldMSGTIME       =  62;
      fldMSGTEXT       =  63;

                                  // kotirovki

      fldINDEXBOARD    =  64;     // indexes
      fldINDEXCODE     =  65;
      fldCURRENTVALUE  =  66;
      fldLASTVALUE     =  67;
      fldOPENVALUE     =  68;

const allFieldsNames   : array [0..68] of tFieldEnumRec =
      ((fldname : 'SECBOARD';        flduniidx : fldSECBOARD      ),
       (fldname : 'SECCODE';         flduniidx : fldSECCODE       ),
       (fldname : 'SHORTNAME';       flduniidx : fldSHORTNAME     ),
       (fldname : 'BID';             flduniidx : fldBID           ),
       (fldname : 'OFFER';           flduniidx : fldOFFER         ),
       (fldname : 'OPEN';            flduniidx : fldOPEN          ),
       (fldname : 'HIGH';            flduniidx : fldHIGH          ),
       (fldname : 'LOW';             flduniidx : fldLOW           ),
       (fldname : 'WAPRICE';         flduniidx : fldWAPRICE       ),
       (fldname : 'CHANGE';          flduniidx : fldCHANGE        ),
       (fldname : 'VOLTODAY';        flduniidx : fldVOLTODAY      ),
       (fldname : 'VALTODAY';        flduniidx : fldVALTODAY      ),
       (fldname : 'LOTSIZE';         flduniidx : fldLOTSIZE       ),
       (fldname : 'LAST';            flduniidx : fldLAST          ),
       (fldname : 'VALUE';           flduniidx : fldVALUE         ),
       (fldname : 'TIME';            flduniidx : fldTIME          ),
       (fldname : 'YIELD';           flduniidx : fldYIELD         ),
       (fldname : 'MATDATE';         flduniidx : fldMATDATE       ),
       (fldname : 'COUPONVALUE';     flduniidx : fldCOUPONVALUE   ),
       (fldname : 'NEXTCOUPON';      flduniidx : fldNEXTCOUPON    ),
       (fldname : 'COUPONPERIOD';    flduniidx : fldCOUPONPERIOD  ),
       (fldname : 'DECIMALS';        flduniidx : fldDECIMALS      ),
       (fldname : 'FACEVALUE';       flduniidx : fldFACEVALUE     ),
       (fldname : 'BIDDEPTHT';       flduniidx : fldBIDDEPTHT     ),
       (fldname : 'OFFERDEPTHT';     flduniidx : fldOFFERDEPTHT   ),
       (fldname : 'NUMBIDS';         flduniidx : fldNUMBIDS       ),
       (fldname : 'NUMOFFERS';       flduniidx : fldNUMOFFERS     ),
       (fldname : 'TRADINGSTATUS';   flduniidx : fldTRADINGSTATUS ),
       (fldname : 'CLOSEPRICE';      flduniidx : fldCLOSEPRICE    ),
       (fldname : 'QTY';             flduniidx : fldQTY           ),
       (fldname : 'ACCRUEDINT';      flduniidx : fldACCRUEDINT    ),
       (fldname : 'PREVPRICE';       flduniidx : fldPREVPRICE     ),
       (fldname : 'ISSUESIZE';       flduniidx : fldISSUESIZE     ),
       (fldname : 'BUYBACKPRICE';    flduniidx : fldBUYBACKPRICE  ),
       (fldname : 'BUYBACKDATE';     flduniidx : fldBUYBACKDATE   ),
       (fldname : 'MARKETPRICE';     flduniidx : fldMARKETPRICE   ),

       (fldname : 'ORDERNO';         flduniidx : fldORDERNO       ),
       (fldname : 'ORDERTIME';       flduniidx : fldORDERTIME     ),
       (fldname : 'STATUS';          flduniidx : fldSTATUS        ),
       (fldname : 'BUYSELL';         flduniidx : fldBUYSELL       ),
       (fldname : 'ACCOUNT';         flduniidx : fldACCOUNT       ),
       (fldname : 'PRICE';           flduniidx : fldPRICE         ),
       (fldname : 'QUANTITY';        flduniidx : fldQUANTITY      ),
       (fldname : 'BALANCE';         flduniidx : fldBALANCE       ),
       (fldname : 'BROKERREF';       flduniidx : fldBROKERREF     ),
       (fldname : 'EXTREF';          flduniidx : fldEXTREF        ),

       (fldname : 'DEALNO';          flduniidx : fldDEALNO        ),
       (fldname : 'DEALTIME';        flduniidx : fldDEALTIME      ),

       (fldname : 'TRADENO';         flduniidx : fldTRADENO       ),
       (fldname : 'TRADETIME';       flduniidx : fldTRADETIME     ),
       (fldname : 'SETTLECODE';      flduniidx : fldSETTLECODE    ),

       (fldname : 'TRADEDATE';       flduniidx : fldTRADEDATE     ),
       (fldname : 'TRDACCID';        flduniidx : fldTRDACCID      ),

       (fldname : 'FIRMID';          flduniidx : fldFIRMID        ),
       (fldname : 'FIRMNAME';        flduniidx : fldFIRMNAME      ),

       (fldname : 'DESCRIPTION';     flduniidx : fldDESCRIPTION   ),
       (fldname : 'SETTLEDATE';      flduniidx : fldSETTLEDATE    ),
       (fldname : 'SETTLEDATE2';     flduniidx : fldSETTLEDATE2   ),

       (fldname : 'DATE';            flduniidx : fldDATE          ),

       (fldname : 'REPORATE';        flduniidx : fldREPORATE      ),
       (fldname : 'REPOTERM';        flduniidx : fldREPOTERM      ),

       (fldname : 'FROMUSER';        flduniidx : fldFROMUSER      ),
       (fldname : 'MSGTIME';         flduniidx : fldMSGTIME       ),
       (fldname : 'MSGTEXT';         flduniidx : fldMSGTEXT       ),

       (fldname : 'INDEXBOARD';      flduniidx : fldINDEXBOARD    ),
       (fldname : 'INDEXCODE';       flduniidx : fldINDEXCODE     ),
       (fldname : 'CURRENTVALUE';    flduniidx : fldCURRENTVALUE  ),
       (fldname : 'LASTVALUE';       flduniidx : fldLASTVALUE     ),
       (fldname : 'OPENVALUE';       flduniidx : fldOPENVALUE     )
      );


var   FieldNameIndex   : tFielfNameIndex;

implementation

constructor tFielfNameIndex.create;
begin inherited create; fduplicates:= dupIgnore; end;

procedure tFielfNameIndex.freeitem(item: pointer);
begin end;

function tFielfNameIndex.checkitem(item: pointer): boolean;
begin result:= true; end;

function tFielfNameIndex.compare(item1, item2: pointer): longint;
begin result:= CompareText(pFieldEnumRec(item1)^.fldname, pFieldEnumRec(item2)^.fldname); end;

function tFielfNameIndex.indexbyname(const aname: string): longint;
var itm : tFieldEnumRec;
    idx : longint;
begin
  itm.fldname:= aname;
  if search(@itm, idx) then result:= pFieldEnumRec(items[idx])^.flduniidx
                       else result:= fldUnknownField
end;

var i : longint;

initialization
  FieldNameIndex:= tFielfNameIndex.create;
  for i:= low(allFieldsNames) to high(allFieldsNames) do FieldNameIndex.add(@allFieldsNames[i]);

finalization
  if assigned(FieldNameIndex) then freeandnil(FieldNameIndex);

end.