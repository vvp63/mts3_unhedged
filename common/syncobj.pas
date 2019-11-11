{$ifdef FPC}
  {$mode DELPHI}
{$else}
  {$define MSWINDOWS}
{$endif}

unit syncobj;

interface

uses  {$ifdef MSWINDOWS}
        windows,
      {$else}
        unix, linux, 
      {$endif}
      sysutils;

const lt_Read                  = false;
      lt_Write                 = true;

type  tSleeper                 = class(tObject)
      private
        finterval              : cardinal;
        ftc                    : cardinal;
        fdelta                 : cardinal;
        fsuspended             : boolean;
      public
        constructor create(ainterval: longint);
        procedure   reset; virtual;
        function    expired: boolean; virtual;
        procedure   delay(ainterval:longint); virtual;
        procedure   suspend; virtual;
        procedure   resume; virtual;
        property    interval: cardinal read finterval write finterval;
      end;

type  tPreciseSleeper          = class(tObject)
      private
        finterval              : int64;
        ftc                    : int64;
      public
        constructor create(ainterval: longint);
        procedure   reset; virtual;
        function    expired: boolean; virtual;
        function    msecs: longint; virtual;
        property    interval: int64 read finterval write finterval;
      end;

{$ifdef MSWINDOWS}
type  TPreciseTime = class(tObject)
      private
        fTime: tDateTime;
        fStart: int64;
        fFreq: int64;
      public
        constructor create;
        function    Now: TDateTime;
        function    Msecs: cardinal;
        function    MKsecs: int64;
      end;
{$endif}

type  tAdvancedCritSect        = class(tObject)
      private
        fLockCSect             : tRTLCriticalSection;
      public
        constructor create;
        destructor  destroy; override;
        procedure   enter; virtual;
        procedure   leave; virtual;
        function    enterifunlocked:boolean; virtual;
        function    enterfixeddelay(ainterval: longint): boolean; virtual;
      end;

      tAdvancedCriticalSection = tAdvancedCritSect;

      tRWCriticalSection       = class(tObject)
      private
        fLockCSect             : tRTLCriticalSection;
        fReadLockCount         : longint;
      public
        constructor create;
        destructor  destroy; override;
        procedure   enter(aLockType: boolean); virtual;
        procedure   leave(aLockType: boolean); virtual;
      end;

function  GetMksCount: int64;
function  GetCPUClock: int64;

implementation

function GetMksCount: int64;
{$ifndef MSWINDOWS}
var t : timeval;
{$else}
var ffreq, ftc : int64;
{$endif}
begin
{$ifdef MSWINDOWS}
  QueryPerformanceFrequency(ffreq);
  QueryPerformanceCounter(ftc);
  result:= (ftc * 1000000) div fFreq;
{$else}
  fpgettimeofday(@t, nil);
  result := (int64(t.tv_sec) * 1000000) + t.tv_usec;
{$endif}
end;

function GetCPUClock: int64;
{$ifndef MSWINDOWS}
var t : timeval;
{$endif}
begin
{$ifdef MSWINDOWS}
  QueryPerformanceCounter(result);
{$else}
  fpgettimeofday(@t, nil);
  result := (int64(t.tv_sec) * 1000000) + t.tv_usec;
{$endif}
end;

{ tSleeper }

constructor tSleeper.create;
begin inherited create; finterval:= ainterval; fdelta:= 0; fsuspended:= false; ftc:= GetMksCount div 1000; end;

procedure tSleeper.reset;
begin fdelta:= 0; ftc:= GetMksCount div 1000; end;

function tSleeper.expired;
var tc : cardinal;
begin
  if not fsuspended then begin
    tc:= GetMksCount div 1000; inc(fdelta, tc - ftc); ftc:= tc;
    result:= (fdelta >= finterval);
  end else result:= false;
end;

procedure tSleeper.delay;
var slp : tSleeper;
begin
  slp:= tSleeper.create(ainterval);
  while not (expired or slp.expired) do sleep(1);
  slp.free;
end;

procedure tSleeper.suspend;
begin if not expired then fsuspended:= true; end;

procedure tSleeper.resume;
begin if fsuspended then begin fsuspended:= false; ftc:= GetMksCount div 1000; end; end;

{ tPreciseSleeper }

constructor tPreciseSleeper.create(ainterval: longint);
begin
  inherited create;
  finterval:= ainterval;
  ftc:= GetMksCount;
end;

function tPreciseSleeper.expired: boolean;
begin result:= (msecs >= finterval); end;

function tPreciseSleeper.msecs: longint;
var cur : int64;
begin
  cur:= GetMksCount;
  result:= (cur - ftc) div 1000;
end;

procedure tPreciseSleeper.reset;
begin ftc:= GetMksCount; end;

{ TPreciseTime }

{$ifdef MSWINDOWS}
constructor TPreciseTime.create;
begin
  inherited create;
  QueryPerformanceFrequency(fFreq);
  FTime:= SysUtils.now;
  QueryPerformanceCounter(fStart);
end;

function TPreciseTime.Now: TDateTime;
var fEnd : int64;
begin
  QueryPerformanceCounter(fEnd);
  result:= fTime + (((fEnd - fStart) * 1000) div fFreq) / 86400000.0;
end;

function TPreciseTime.Msecs: cardinal;
var fEnd : int64;
begin
  QueryPerformanceCounter(fEnd);
  result:= (fEnd * 1000) div fFreq;
end;

function TPreciseTime.MKsecs: int64;
var fEnd : int64;
begin
  QueryPerformanceCounter(fEnd);
  result:= (fEnd * 1000) div (fFreq div 1000);
end;
{$endif}

{ tAdvancedCritSect }

constructor tAdvancedCritSect.create;
begin
  inherited create;
  {$ifdef MSWINDOWS}
  InitializeCriticalSection(fLockCSect);
  {$else}
  InitCriticalSection(fLockCSect);
  {$endif}
end;

destructor tAdvancedCritSect.destroy;
begin
  {$ifdef MSWINDOWS}
  DeleteCriticalSection(fLockCSect);
  {$else}
  DoneCriticalSection(fLockCSect);
  {$endif}
  inherited destroy;
end;

procedure tAdvancedCritSect.enter;
begin EnterCriticalSection(fLockCSect); end;

procedure tAdvancedCritSect.leave;
begin LeaveCriticalSection(fLockCSect); end;

function tAdvancedCritSect.enterifunlocked: boolean;
begin result:= boolean(TryEnterCriticalSection(fLockCSect)); end;

function tAdvancedCritSect.enterfixeddelay(ainterval: longint): boolean;
begin
  with tSleeper.create(ainterval) do try
    repeat
      result:= enterifunlocked;
      if not result then sleep(1);
    until result or expired;
  finally free; end;
end;

{ tRWCriticalSection }

constructor tRWCriticalSection.create;
begin
  inherited create;
  {$ifdef MSWINDOWS}
  InitializeCriticalSection(fLockCSect);
  {$else}
  InitCriticalSection(fLockCSect);
  {$endif}
  fReadLockCount:= 0;
end;

destructor tRWCriticalSection.destroy;
begin
  {$ifdef MSWINDOWS}
  DeleteCriticalSection(fLockCSect);
  {$else}
  DoneCriticalSection(fLockCSect);
  {$endif}
  inherited destroy;
end;

procedure tRWCriticalSection.enter(aLockType: boolean);
begin
  if (aLockType = lt_Write) then begin
    EnterCriticalSection(fLockCSect);
    while (fReadLockCount > 0) do sleep(0);
  end else begin
    EnterCriticalSection(fLockCSect);
    InterLockedIncrement(fReadLockCount);
    LeaveCriticalSection(fLockCSect);
  end;
end;

procedure tRWCriticalSection.leave(aLockType: boolean);
begin
  if (aLockType = lt_Read) then begin
    InterLockedDecrement(fReadLockCount);
  end else LeaveCriticalSection(fLockCSect);
end;

end.
