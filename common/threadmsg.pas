{$ifdef FPC}
  {$mode DELPHI}
{$else}
  {$define MSWINDOWS}
{$endif}

unit threadmsg;

interface

{$ifdef MSWINDOWS}
uses windows;
{$endif}

{$ifdef FPC}
  {$ifdef CPU32}
    type size_t = cardinal;
  {$else}
    {$ifdef CPU64}
      {$define GATE64}
      type size_t = QWord;
    {$else}
      PLATFORM IS NOT SUPPORTED
    {$endif}
  {$endif}
  {$ifdef Unix}
    type THandle = size_t;
  {$endif}
{$else}
  type size_t = cardinal;
  {$A+}
{$endif}

const
  DLL_PROCESS_ATTACH = 1;
  DLL_THREAD_ATTACH = 2;
  DLL_THREAD_DETACH = 3;
  DLL_PROCESS_DETACH = 0;

const
  PM_NOREMOVE = 0;
  PM_REMOVE = 1;

type
  HWND = type LongWord;

  WPARAM = Longint;
  LPARAM = Longint;
  LRESULT = Longint;

  UINT = LongWord;
  DWORD = LongWord;
  BOOL = LongBool;

type
  PPoint = ^TPoint;
  TPoint = record
    x: Longint;
    y: Longint;
  end;

  PMsg = ^TMsg;
  {$EXTERNALSYM tagMSG}
  tagMSG = packed record
    hwnd: HWND;
    message: UINT;
    wParam: WPARAM;
    lParam: LPARAM;
    time: DWORD;
    pt: TPoint;
  end;
  TMsg = tagMSG;

function PostThreadMessage(idThread: THandle; Msg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL;
function PeekMessage(var lpMsg: TMsg; hWnd: HWND; wMsgFilterMin, wMsgFilterMax, wRemoveMsg: UINT): BOOL;

implementation

uses  sysutils,
      sortedlist;

type  tThreadMessageQueue = class;

      pThreadQueueItm = ^tThreadQueueItm;
      tThreadQueueItm = record
        ThreadID      : tHandle;
        Queue         : tThreadMessageQueue;
      end;

      tThreadMessageQueue = class(tCustomList)
        procedure   freeitem(item:pointer); override;
      end;

      tThreadMessageStorage = class(tSortedThreadList)
        procedure   freeitem(item:pointer); override;
        function    checkitem(item:pointer):boolean; override;
        function    compare(item1,item2:pointer):longint; override;

        function    push(idThread: THandle; Msg: UINT; wParam: WPARAM; lParam: LPARAM): boolean;
        function    pop(var lpMsg: TMsg): boolean;
      end;

const MessageQueue : tThreadMessageStorage = nil;

function PostThreadMessage(idThread: THandle; Msg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL;
begin
  if assigned(MessageQueue) then result:= MessageQueue.push(idThread, Msg, wParam, lParam)
                            else result:= false;
end;

function PeekMessage(var lpMsg: TMsg; hWnd: HWND; wMsgFilterMin, wMsgFilterMax, wRemoveMsg: UINT): BOOL;
begin
  if assigned(MessageQueue) and (wRemoveMsg = PM_REMOVE) then result:= MessageQueue.pop(lpMsg)
                                                         else result:= false;
end;

{ tThreadMessageQueue }

procedure tThreadMessageQueue.freeitem(item: pointer);
begin if assigned(item) then dispose(PMsg(item)); end;

{ tThreadMessageStorage }

procedure tThreadMessageStorage.freeitem(item: pointer);
begin
  if assigned(item) then begin
    with pThreadQueueItm(item)^ do
      if assigned(Queue) then freeandnil(Queue);
    dispose(pThreadQueueItm(item));
  end;
end;

function tThreadMessageStorage.checkitem(item: pointer): boolean;
begin result:= assigned(item); end;

function tThreadMessageStorage.compare(item1, item2: pointer): longint;
var tmp : int64;
begin
  tmp:= pThreadQueueItm(item1)^.ThreadID - pThreadQueueItm(item2)^.ThreadID;
  if (tmp < 0) then result:= -1 else
  if (tmp > 0) then result:= 1 else result:= 0;
end;

function tThreadMessageStorage.push(idThread: THandle; Msg: UINT; wParam: WPARAM; lParam: LPARAM): boolean;
var sitm : tThreadQueueItm;
    idx  : longint;
    itm  : pThreadQueueItm;
    que  : tThreadMessageQueue;
    ms   : PMsg;
begin
  result:= false;
  with locklist do try
    sitm.ThreadID:= idThread;
    if not search(@sitm, idx) then begin
      que:= tThreadMessageQueue.Create;
      itm:= new(pThreadQueueItm);
      itm^.ThreadID:= sitm.ThreadID;
      itm^.Queue:= que;
      insert(idx, itm);
    end else que:= pThreadQueueItm(items[idx])^.Queue;
    if assigned(que) then begin
      ms:= new(PMsg);
      fillchar(ms^, sizeof(TMsg), 0);
      ms^.message:= Msg;
      ms^.wParam:= wParam;
      ms^.lParam:= lParam;
      que.add(ms);
      while (que.count > 100) do que.delete(0);
      result:= true;
    end;
  finally unlocklist; end;
end;

function tThreadMessageStorage.pop(var lpMsg: TMsg): boolean;
var sitm : tThreadQueueItm;
    idx  : longint;
begin
  result:= false;
  with locklist do try
    sitm.ThreadID:= GetCurrentThreadID;
    if search(@sitm, idx) then with pThreadQueueItm(items[idx])^ do
      if assigned(queue) then with queue do
        if (count > 0) then begin
          lpMsg:= PMsg(items[0])^;
          delete(0);
          result:= true;
        end;
  finally unlocklist; end;
end;

initialization
  MessageQueue:= tThreadMessageStorage.create;

finalization
  if assigned(MessageQueue) then freeandnil(MessageQueue);

end.