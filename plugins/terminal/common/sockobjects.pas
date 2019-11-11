{$ifdef FPC}
  {$mode DELPHI}
{$else}
  {$define MSWINDOWS}
{$endif}

unit  sockobjects;

interface

uses  {$ifdef MSWINDOWS}
        windows, winsock2,
      {$else}
        baseunix, linux, sockets, termio,
      {$endif}
      classes, sysutils;

{$ifdef MSWINDOWS}
type  TSocket                 = winsock2.TSocket;

type  pBufVector              = PWSABUF;
      tBufVector              = WSABUF;
{$else}
type  TSocket                 = sockets.TSocket;

type  pBufVector              = piovec;
      tBufVector              = tiovec;

type  pEventList              = ^tEventList;
      tEventList              = array[0..0] of EPoll_Event;

const EPOLLRDHUP              = $2000;
      EPOLL_ERRORS            = EPOLLERR or EPOLLHUP or EPOLLRDHUP;

const SD_SEND                 = 1;

const INVALID_SOCKET          = TSocket(not(0));
{$endif}

type  tSocketState            = (ss_online, ss_closed, ss_error);

type  tCustomSocket           = class;

      tSocketObjectList       = class(tList)
      private
        fDestroying           : boolean;
        {$ifdef MSWINDOWS}
        FFDSet                : TFDSet;
        {$else}
        FEpollHndl            : TSocket;
        FEventBuffer          : pEventList;
        {$endif}
        FPollTimeout          : longint;

        function    fGetSocket(ahandle: TSocket): tCustomSocket;
      protected
        procedure   Notify(Ptr: Pointer; Action: TListNotification); override;
        function    poll(atimeout: longint): longint; virtual;
      public
        constructor create; virtual;
        destructor  destroy; override;

        procedure   CleanupClients(asocket: tCustomSocket);
        procedure   idle; virtual;

        property    sockets[ahandle: TSocket]: tCustomSocket read fGetSocket;
        {$ifndef MSWINDOWS}
        property    handle: TSocket read FEpollHndl;
        {$endif}
        property    polltimeout: longint read FPollTimeout write FPollTimeout;
      end;

      tSocketObjectListClass  = class of tSocketObjectList;

      tCustomSocket           = class(tObject)
      private
        fAddr                 : TSockAddr;
        fSocketHandle         : TSocket;
        {$ifndef MSWINDOWS}
        FEpollEvent           : EPoll_Event;
        FEpollEventPtr        : PEPoll_Event;
        {$endif}

        function    FGetStringAddress: ansistring;
        function    FGetPort: longint;
      protected
        function    getstate: tSocketState; virtual;
      public
        constructor create;

        function    to_vector(alen: longint; abuf: pAnsiChar): tBufVector;
        procedure   closesocket; virtual;
        procedure   idle; virtual;

        property    addr: TSockAddr read fAddr;
        property    address: ansistring read FGetStringAddress;
        property    port: longint read FGetPort;
        property    handle: TSocket read fSocketHandle write fSocketHandle;
        property    socketstate: tSocketState read getstate;
        {$ifndef MSWINDOWS}
        property    EpollEvent: PEPoll_Event read FEpollEventPtr;
        {$endif}
      end;

      tCustomDatagramSocket   = class(tCustomSocket)
        constructor create; virtual;
        destructor  destroy; override;

        function    bind(const aaddress: ansistring; aport: longint): longint;

        function    recv(var buffer; bufsize: longint): longint; virtual;

        function    receive: longint; virtual;
      end;

      tNULLDatagramSocket   = class(tCustomDatagramSocket)
        function    receive: longint; override;
      end;

      tCustomServerSocket     = class;

      tCustomClientSocket     = class(tCustomSocket)
      private
        fServerSocket         : tCustomServerSocket;
      protected
        function    datapending: boolean; virtual;
      public
        constructor create(ahandle: TSocket); virtual;
        destructor  destroy; override;

        procedure   connected; virtual;
        function    recv(var buffer; bufsize: longint): longint; virtual;
        function    send(var buffer; bufsize: longint): longint; virtual;
        function    wsasend(bufs: pBufVector; bufcount: longint): longint; virtual;

        function    receive: longint; virtual;

        property    serversocket: tCustomServerSocket read fServerSocket;
      end;

      tClientSocketClass      = class of tCustomClientSocket;

      tCustomServerSocket     = class(tCustomSocket)
      private
        fSocketClass          : tClientSocketClass;
        fAddress, fMask       : cardinal;
      public
        constructor create;
        destructor  destroy; override;

        function    bind(aport: longint): longint;
        function    listen(const aaddress, amask: ansistring): longint;
        function    accept: tCustomClientSocket; virtual;

        procedure   log(const alogstr: ansistring); virtual;

        property    clientsocketclass: tClientSocketClass write fSocketClass;
      end;

procedure InitializeSocketIO(asocklistclass: tSocketObjectListClass);
function  ProcessSocketIO: boolean;
procedure FinalizeSocketIO;

const GlobalSocketList        : tSocketObjectList = nil;

implementation

{$ifdef MSWINDOWS}
var   GInitData               : TWSADATA;
{$endif}

{$ifdef MSWINDOWS}
procedure FD_COPY(var src, dest: TFDSet);
begin
  dest.fd_count:= src.fd_count;
  system.move(src.fd_array, dest.fd_array, src.fd_count * sizeof(TSocket));
end;
{$endif}

{ tObjectList }

constructor tSocketObjectList.create;
begin
  inherited create;
  fDestroying:= false;
  FPollTimeout:= 0;
  {$ifdef MSWINDOWS}
  FD_ZERO(FFDSet);
  {$else}
  FEpollHndl:= epoll_create(128);
  FEventBuffer:= nil;
  {$endif}
end;

destructor tSocketObjectList.destroy;
begin
  fDestroying:= true;
  Clear;
  {$ifndef MSWINDOWS}
  fpclose(FEpollHndl);
  if assigned(FEventBuffer) then freemem(FEventBuffer);
  {$endif}
  inherited destroy;
end;

function tSocketObjectList.fGetSocket(ahandle: TSocket): tCustomSocket;
var i : longint;
begin
  result:= nil;
  i:= 0;
  while (i < count) do begin
    result:= tCustomSocket(items[i]);
    if assigned(result) and (result.handle = ahandle) then begin
      i:= count;
    end else begin
      result:= nil;
      inc(i);
    end;
  end;
end;

procedure tSocketObjectList.Notify(Ptr: Pointer; Action: TListNotification);
begin
  if assigned(ptr) then with tCustomSocket(ptr) do
    case Action of
      lnAdded                : if (handle <> INVALID_SOCKET) then begin
                                 {$ifdef MSWINDOWS}
                                 FD_SET(handle, FFDSet);
                                 {$else}
                                 reallocmem(FEventBuffer, count * sizeof(EPoll_Event));
                                 epoll_ctl(FEpollHndl, EPOLL_CTL_ADD, handle, EpollEvent);
                                 {$endif}
                               end;
      lnExtracted, lnDeleted : begin
                                 {$ifdef MSWINDOWS}
                                 FD_CLR(handle, FFDSet);
                                 {$else}
                                 epoll_ctl(FEpollHndl, EPOLL_CTL_DEL, handle, EpollEvent);
                                 {$endif}
                                 if fDestroying then free;
                               end;
    end;
end;

function tSocketObjectList.poll(atimeout: longint): longint;
{$ifdef MSWINDOWS}
var fdset  : TFDset;
    fdwset : TFDset;
    fdeset : TFDset;
    tm     : TTimeVal;
{$endif}
var i      : longint;
    cs     : tCustomSocket;
begin
  {$ifdef MSWINDOWS}
  FD_COPY(FFDSet, fdset);
  FD_COPY(FFDSet, fdeset);

  FD_ZERO(fdwset);
  for i:= 0 to count - 1 do begin
    cs:= tCustomSocket(items[i]);
    if assigned(cs) then
      if (cs is tCustomClientSocket) and tCustomClientSocket(cs).datapending then FD_SET(cs.handle, fdwset);
  end;

  TM.tv_sec  := atimeout  div 1000;
  TM.tv_usec := (atimeout mod 1000) * 1000;

  result:= winsock2.select(0, @fdset, @fdwset, @fdeset, @tm);

  for i:= 0 to fdset.fd_count - 1 do begin
    cs:= sockets[fdset.fd_array[i]];
    if assigned(cs) then begin
      if (cs is tCustomClientSocket) and (tCustomClientSocket(cs).receive = 0) then tCustomClientSocket(cs).free else
      if (cs is tCustomDatagramSocket) and (tCustomDatagramSocket(cs).receive = 0) then tCustomDatagramSocket(cs).free else
      if (cs is tCustomServerSocket) then tCustomServerSocket(cs).accept;
    end;  
  end;
  for i:= 0 to fdeset.fd_count - 1 do begin
    cs:= sockets[fdset.fd_array[i]];
    if assigned(cs) then cs.free;
  end;
  {$else}
  result:= epoll_wait(FEpollHndl, pointer(FEventBuffer), count, atimeout);
  for i:= 0 to result - 1 do
    with FEventBuffer^[i] do begin
      cs:= tCustomSocket(data.ptr);
      if assigned(cs) then begin
        if (events and EPOLLIN <> 0) then begin
          if (cs is tCustomClientSocket) and (tCustomClientSocket(cs).receive = 0) then freeandnil(cs) else
          if (cs is tCustomDatagramSocket) and (tCustomDatagramSocket(cs).receive = 0) then freeandnil(cs) else
          if (cs is tCustomServerSocket) then tCustomServerSocket(cs).accept;
        end;  
        if assigned(cs) and (events and EPOLL_ERRORS <> 0) then freeandnil(cs);
      end;
    end;
  {$endif}
end;

procedure tSocketObjectList.CleanupClients(asocket: tCustomSocket);
var i   : longint;
    tmp : tCustomSocket;
begin
  for i:= 0 to count - 1 do begin
    tmp:= tCustomSocket(items[i]);
    if assigned(tmp) and (tmp is tCustomClientSocket) then
      with tCustomClientSocket(tmp) do
        if (fserversocket = asocket) then fserversocket:= nil;
  end;
end;

procedure tSocketObjectList.idle;
var i  : longint;
    cs : tCustomSocket;
begin
  if (count > 0) then begin
    poll(FPollTimeout);
    for i:= count - 1 downto 0 do begin
      cs:= tCustomSocket(items[i]);
      with cs do
        if (socketstate = ss_online) then idle else free;
    end;
  end;
end;

{ tCustomSocket }
constructor tCustomSocket.create;
begin
  inherited create;
  {$ifndef MSWINDOWS}
  FEpollEvent.events:= EPOLLIN or EPOLL_ERRORS;
  FEpollEvent.data.ptr:= Self;
  FEpollEventPtr:= @FEpollEvent;
  {$endif}
end;

function tCustomSocket.FGetStringAddress: ansistring;
begin
  {$ifdef MSWINDOWS}
  result:= inet_ntoa(addr.sin_addr);
  {$else}
  result:= NetAddrToStr(addr.sin_addr);
  {$endif}
end;

function tCustomSocket.FGetPort: longint;
begin result:= htons(fAddr.sin_port); end;

function tCustomSocket.to_vector(alen: longint; abuf: pAnsiChar): tBufVector;
begin with result do begin {$ifdef MSWINDOWS}len:= alen; buf:= abuf;{$else}iov_len:= alen; iov_base:= abuf;{$endif} end; end;

procedure tCustomSocket.closesocket;
begin
  if (fSocketHandle <> INVALID_SOCKET) then begin
    {$ifdef MSWINDOWS}
    winsock2.shutdown(handle, SD_SEND);
    winsock2.closesocket(handle);
    {$else}
    fpshutdown(handle, SD_SEND);
    fpclose(handle);
    {$endif}
  end;
end;

function tCustomSocket.getstate: tSocketState;
begin result:= ss_online; end;

procedure tCustomSocket.idle;
begin end;

{ tCustomServerSocket }

constructor tCustomServerSocket.create;
var temp : cardinal;
begin
  inherited create;
  fSocketClass:= tCustomClientSocket;
  {$ifdef MSWINDOWS}
  handle := winsock2.socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  {$ifdef FPC}
    temp:= 1; winsock2.ioctlsocket(handle, longint(FIONBIO), temp);
  {$else}
    temp:= 1; winsock2.ioctlsocket(handle, FIONBIO, temp);
  {$endif}
  temp:= 1; winsock2.setsockopt(handle, IPPROTO_TCP, TCP_NODELAY, @temp, sizeof(temp));
  temp:= 1; winsock2.setsockopt(handle, IPPROTO_TCP, SO_REUSEADDR, @temp, sizeof(temp));
  {$else}
  handle := fpsocket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  temp:= 1; fpIOCtl(handle, FIONBIO, @temp);
  temp:= 1; fpsetsockopt(handle, IPPROTO_TCP, TCP_NODELAY, @temp, sizeof(temp));
  temp:= 1; fpsetsockopt(handle, IPPROTO_TCP, SO_REUSEADDR, @temp, sizeof(temp));
  {$endif}

  if assigned(GlobalSocketList) then GlobalSocketList.Add(Self);
end;

destructor tCustomServerSocket.destroy;
begin
  if assigned(GlobalSocketList) then begin
    GlobalSocketList.Extract(Self);
    GlobalSocketList.CleanupClients(Self);
  end;

  closesocket;
  inherited destroy;
end;

function tCustomServerSocket.bind(aport: longint): longint;
begin
  fillchar(faddr, sizeof(faddr), 0);
  with faddr do begin
    sin_family := AF_INET;
    sin_addr.s_addr := INADDR_ANY;
    sin_port := htons(aport);
  end;
  {$ifdef MSWINDOWS}
  result:= winsock2.bind(handle, @faddr, sizeof(faddr));
  {$else}
  result:= fpbind(handle, @faddr, sizeof(faddr));
  {$endif}
end;

function tCustomServerSocket.listen(const aaddress, amask: ansistring): longint;
begin
  {$ifdef MSWINDOWS}
  if (length(aaddress) > 0) then fAddress:= inet_addr(pAnsiChar(aaddress)) else fAddress:= 0;
  if (length(amask) > 0)    then fMask:= inet_addr(pAnsiChar(amask))       else fMask:= 0;
  result:= winsock2.listen(handle, SOMAXCONN);
  {$else}
  if (length(aaddress) > 0) then fAddress:= StrToNetAddr(pAnsiChar(aaddress)).s_addr else fAddress:= 0;
  if (length(amask) > 0)    then fMask:= StrToNetAddr(pAnsiChar(amask)).s_addr       else fMask:= 0;
  result:= fplisten(handle, SOMAXCONN);
  {$endif}
end;

function tCustomServerSocket.accept: tCustomClientSocket;
var temp     : longint;
    tmpaddr  : TSockAddr;
    hsock    : TSocket;
begin
  result:= nil;
  temp:= sizeof(tmpaddr);
  {$ifdef MSWINDOWS}
  {$ifdef FPC}
    hsock:= winsock2.accept(handle, @tmpaddr, temp);
  {$else}
    hsock:= winsock2.accept(handle, tmpaddr, temp);
  {$endif}
  {$else}
  fillchar(tmpaddr, sizeof(tmpaddr), 0);
  hsock:= fpaccept(handle, @tmpaddr, @temp);
  {$endif}
  if (((tmpaddr.sin_addr.S_addr xor fAddress) and fMask) = 0) then begin
    if assigned(fSocketClass) and (hsock <> INVALID_SOCKET) then begin
      result:= tCustomClientSocket(fSocketClass.NewInstance);
      if assigned(result) then with result do begin
        fAddr:= tmpaddr;
        fServerSocket:= Self;
        Create(hsock);
        Connected;
      end;
    end;
  end;
  {$ifdef MSWINDOWS}
  if not assigned(result) then winsock2.closesocket(hsock);
  {$else}
  if not assigned(result) then fpclose(hsock);
  {$endif}
end;

procedure tCustomServerSocket.log(const alogstr: ansistring);
begin end;

{ tCustomDatagramSocket }

constructor tCustomDatagramSocket.create;
begin
  inherited create;
  {$ifdef MSWINDOWS}
  handle := winsock2.socket(AF_INET, SOCK_DGRAM, 0);
  {$else}
  handle := fpsocket(AF_INET, SOCK_DGRAM, 0);
  {$endif}

  if assigned(GlobalSocketList) then GlobalSocketList.Add(Self);
end;

destructor tCustomDatagramSocket.destroy;
begin
  if assigned(GlobalSocketList) then GlobalSocketList.Extract(Self);

  closesocket;
  inherited destroy;
end;

function tCustomDatagramSocket.bind(const aaddress: ansistring; aport: longint): longint;
var namelen : integer;
begin
  fillchar(faddr, sizeof(faddr), 0);
  with faddr do begin
    sin_family := AF_INET;
    if (length(aaddress) > 0) then sin_addr.s_addr:= inet_addr(pAnsiChar(aaddress))
                              else sin_addr.s_addr:= htonl(INADDR_LOOPBACK);
    sin_port := htons(aport);
  end;
  {$ifdef MSWINDOWS}
  result:= winsock2.bind(handle, @faddr, sizeof(faddr));
  {$else}
  result:= fpbind(handle, @faddr, sizeof(faddr));
  {$endif}

  namelen:= sizeof(faddr);
  getsockname(handle, faddr, namelen);
end;

function tCustomDatagramSocket.recv(var buffer; bufsize: Integer): longint;
begin
  {$ifdef MSWINDOWS}
  result:= winsock2.recv(handle, buffer, bufsize, 0);
  {$else}
  result:= fprecv(handle, @buffer, bufsize, 0);
  {$endif}
end;

function tCustomDatagramSocket.receive: longint;
begin result:= 0; end;

{ tNULLDatagramSocket }

function tNULLDatagramSocket.receive: longint;    // dump datagrams by default
var dummy : array[0..2048] of ansichar;
begin result:= recv(dummy, sizeof(dummy)); end;

{ tCustomClientSocket }

constructor tCustomClientSocket.create(ahandle: TSocket);
var temp : cardinal;
begin
  inherited create;
  handle:= ahandle;

  {$ifdef MSWINDOWS}
  {$ifdef FPC}
    temp:= 1; winsock2.ioctlsocket(handle, longint(FIONBIO), temp);
  {$else}
    temp:= 1; winsock2.ioctlsocket(handle, FIONBIO, temp);
  {$endif}
  temp:= 1; winsock2.setsockopt(handle, IPPROTO_TCP, TCP_NODELAY, @temp, sizeof(temp));
  {$else}
  temp:= 1; fpIOCtl(handle, FIONBIO, @temp);
  temp:= 1; fpsetsockopt(handle, IPPROTO_TCP, TCP_NODELAY, @temp, sizeof(temp));
  {$endif}

  if assigned(GlobalSocketList) then GlobalSocketList.Add(Self);
end;

destructor tCustomClientSocket.destroy;
begin
  if assigned(GlobalSocketList) then GlobalSocketList.Extract(Self);

  closesocket;
  inherited destroy;
end;

function tCustomClientSocket.datapending: boolean;
begin result:= false; end;

procedure tCustomClientSocket.connected;
begin end;

function tCustomClientSocket.recv(var buffer; bufsize: longint): longint;
begin
  {$ifdef MSWINDOWS}
  result:= winsock2.recv(handle, buffer, bufsize, 0);
  {$else}
  result:= fprecv(handle, @buffer, bufsize, 0);
  {$endif}
end;

function tCustomClientSocket.send(var buffer; bufsize: longint): longint;
begin
  {$ifdef MSWINDOWS}
  result:= winsock2.send(handle, buffer, bufsize, 0);
  if (result = SOCKET_ERROR) then
    if (winsock2.WSAGetLastError = WSAEWOULDBLOCK) then result:= 0;
  {$else}
  result:= fpsend(handle, @buffer, bufsize, 0);
  {$endif}
end;

function tCustomClientSocket.wsasend(bufs: pBufVector; bufcount: longint): longint;
begin
  {$ifdef MSWINDOWS}
  result:= 0; winsock2.WSASend(handle, bufs, bufcount, DWORD(result), 0, nil, nil);
  {$else}
  result:= fpwritev(handle, bufs, bufcount);
  {$endif}
end;

function tCustomClientSocket.receive: longint;
begin result:= 0; end;

{ custom functions }

procedure InitializeSocketIO(asocklistclass: tSocketObjectListClass);
begin
  FinalizeSocketIO;
  if assigned(asocklistclass) then begin
    GlobalSocketList:= tSocketObjectList(asocklistclass.NewInstance);
    if assigned(GlobalSocketList) then GlobalSocketList.create;
  end;
end;

function ProcessSocketIO: boolean;
begin
  if assigned(GlobalSocketList) then begin
    GlobalSocketList.Idle;
    result:= true;
  end else result:= false;
end;

procedure FinalizeSocketIO;
begin if assigned(GlobalSocketList) then freeandnil(GlobalSocketList); end;

initialization
  {$ifdef MSWINDOWS}
  WSAStartup(MAKEWORD(2, 0), GInitData);
  {$endif}
  InitializeSocketIO(tSocketObjectList);

finalization
  FinalizeSocketIO;
  {$ifdef MSWINDOWS}
  WSACleanup;
  {$endif}
end.