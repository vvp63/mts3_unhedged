{$i terminal_defs.pas}

unit  terminal_server;

interface

uses  {$ifdef MSWINDOWS}
        windows, inifiles,
      {$else}
        fclinifiles,
      {$endif}
      classes, sysutils,
      sockobjects, crc32,
      itzip, rc5, md5, protodef,
      terminal_common;

type  tClientSessionState = (cli_sess_new, cli_sess_cli_keys, cli_sess_working, cli_sess_closed);

type  tClientStream       = class(tMemoryStream)
      public
        procedure   appenddata(adata: pAnsiChar; adatasize: longint);

        procedure   deletedata(asize: longint);

        procedure   writebuffer(const astring: ansistring);
        procedure   writestream(astream: tMemoryStream; aclear: boolean = false);

        function    checkframe: boolean;
        function    currentptr: pAnsiChar;
      end;

type  tTerminalServer     = class(tCustomServerSocket)
      private
        fininame          : ansistring;
        fIni              : tIniFile;
        function    fGetPassword(const ausername: ansistring): ansistring;
        function    fGetIniFile: tIniFile;
      public
        constructor create(const aininame, anodename: ansistring);
        destructor  destroy; override;
        procedure   log(const alogstr: ansistring); override;

        property    ininame: ansistring read fininame write fininame;
        property    inifile: tIniFile read fGetIniFile;

        property    passwords[const ausername: ansistring]: ansistring read fGetPassword;
      end;

type  tTerminalClientSock = class(tCustomClientSocket)
      private
        fBuffer           : array[0..65535] of char;
        state             : tClientSessionState;

        fClientInfo       : tClientInfo;
        fHandshakeMsg     : tHandshakeMsg;
        fUserFlags        : longint;

        fuser_pass        : ansistring;

        fnewdecoder       : boolean;

        function    fGetClientName: ansistring;
        function    fGetIniFile: tIniFile;
      protected
        in_buf            : tClientStream;
        in_key            : tKey;
        out_buf           : tClientStream;
        out_key           : tKey;
        temp_buffer       : tMemoryStream;

        function    getstate: tSocketState; override;
        procedure   cleanup(astate: tClientSessionState);
      public
        constructor create(ahandle: TSocket); override;
        destructor  destroy; override;

        procedure   log(const alogstr: ansistring); overload;
        procedure   log(const atpl: ansistring; const aparams: array of const); overload;

        procedure   connected; override;
        function    receive: longint; override;
        function    sendbuffer(abuffer: tClientStream): longint;
        procedure   terminate;

        function    check_user: byte; virtual; abstract;
        procedure   on_client_login; virtual; abstract;
        procedure   on_message(const aframe: tProtocolRec; amessage: pAnsiChar; amsgsize: longint); virtual; abstract;

        procedure   ReceiveData(adata: pAnsiChar; adatasize: longint);
        procedure   SendData;

        procedure   idle; override;

        property    ClientInfo: tClientInfo read fClientInfo;
        property    ClientName: ansistring read fGetClientName;
        property    UserFlags: longint read fUserFlags write fUserFlags;
        property    NewDecoder: boolean read fnewdecoder;
        property    IniFile: tIniFile read fGetIniFile;
      end;

implementation

procedure fixshortstring(s: pshortstring; maxlen: longint);
var i : longint;
begin
  if length(s^) > maxlen then setlength(s^, maxlen);
  for i:= 1 to length(s^) do
    if not (s^[i] in ['0'..'9','A'..'Z','a'..'z']) then s^[i]:= '-';
end;

{ tClientStream }

procedure tClientStream.appenddata(adata: pAnsiChar; adatasize: longint);
var pos: longint;
begin
  if assigned(adata) and (adatasize > 0) then begin
    pos:= Position;
    seek(0, soFromEnd);
    write(adata^, adatasize);
    seek(pos, soFromBeginning);
  end;
end;

procedure tClientStream.deletedata(asize: longint);
var sz : longint;
begin
  if (asize > 0) then begin
    sz:= Size;
    if (sz > asize) then begin
      move(pAnsiChar(pAnsiChar(memory) + asize)^, memory^, sz - asize);
      Seek(-asize, soFromCurrent);
      SetSize(sz - asize);
    end else Clear;
  end;
end;

procedure tClientStream.writebuffer(const astring: ansistring);
begin if (length(astring) > 0) then write(astring[1], length(astring)); end;

function tClientStream.checkframe: boolean;
var frame : tProtocolRec;
    crc   : longint;
begin
  if (Position + sizeof(tProtocolRec) <= Size) then begin
    read(frame, sizeof(tProtocolRec));
    with frame do begin crc:= signature; signature:= sgProtSign; end;
    if (BufCRC32(frame,sizeof(tProtocolRec)) = crc) and (frame.datasize >= 0) then begin
      result:= (Position + frame.datasize <= Size);
      Seek(-sizeof(tProtocolRec), soFromCurrent);
    end else raise Exception.CreateFmt('Error receiving packet: magic: %.8x datasize: %d', [crc, frame.datasize]);
  end else result:= false;
end;

function tClientStream.currentptr: pAnsiChar;
begin result:= pAnsiChar(Memory) + Position; end;

procedure tClientStream.writestream(astream: tMemoryStream; aclear: boolean = false);
begin
  if assigned(astream) then begin
    write(astream.memory^, astream.size);
    if aclear then astream.clear;
  end;
end;

{ tTerminalServer }

constructor tTerminalServer.create(const aininame, anodename: ansistring);
begin
  inherited create;
  fininame:= aininame;

  log('Server started');
end;

destructor tTerminalServer.destroy;
begin
  log('Server closed');

  if assigned(fIni) then freeandnil(fIni);
  inherited destroy;
end;

function  tTerminalServer.fGetIniFile: tIniFile;
begin
  if not assigned(fIni) and (length(fininame) > 0) then fIni:= tIniFile.Create(fininame);
  result:= fIni;
end;

function  tTerminalServer.fGetPassword(const ausername: ansistring): ansistring;
var ini : tIniFile;
begin
  ini:= inifile;
  if assigned(ini) then result:= ini.ReadString('auth', ausername, '') else setlength(result, 0);
end;

procedure tTerminalServer.log(const alogstr: ansistring);
begin terminal_common.log(alogstr); end;

{ tTerminalClientSock }

constructor tTerminalClientSock.create(ahandle: TSocket);
begin
  inherited create(ahandle);
  temp_buffer:= tMemoryStream.create;
  in_buf:= tClientStream.create;
  out_buf:= tClientStream.create;
  state:= cli_sess_new;
  fnewdecoder:= false;
  log('new connection address: %s:%d', [address, port]);
end;

destructor tTerminalClientSock.destroy;
begin
  log('connection closed');
  if assigned(out_buf) then freeandnil(out_buf);
  if assigned(in_buf) then freeandnil(in_buf);
  if assigned(temp_buffer) then freeandnil(temp_buffer);
  inherited destroy;
end;

function tTerminalClientSock.fGetClientName: ansistring;
begin with ClientInfo do result:= format('%s@%s', [id, username]); end;

function tTerminalClientSock.fGetIniFile: tIniFile;
begin if assigned(serversocket) then result:= tTerminalServer(serversocket).inifile else result:= nil; end;

function tTerminalClientSock.getstate: tSocketState;
begin if (state = cli_sess_closed) then result:= ss_error else result:= ss_online; end;

procedure tTerminalClientSock.cleanup(astate: tClientSessionState);
begin
  state:= astate;
  in_buf.Clear;
  out_buf.Clear;
end;

procedure tTerminalClientSock.log(const alogstr: ansistring);
begin if assigned(serversocket) then serversocket.log(format('(0x%p) %s', [pointer(Self), alogstr])); end;

procedure tTerminalClientSock.log(const atpl: ansistring; const aparams: array of const);
begin log(format(atpl, aparams)); end;

procedure tTerminalClientSock.connected;
begin cleanup(cli_sess_new); end;

function tTerminalClientSock.receive: longint;
begin
  result:= recv(fBuffer, sizeof(fBuffer));
  if (result > 0) then ReceiveData(@fbuffer, result);
end;

function tTerminalClientSock.sendbuffer(abuffer: tClientStream): longint;
begin
  if assigned(abuffer) then with abuffer do begin
    result:= send(abuffer.memory^, abuffer.size);
  end else result:= 0;
end;

procedure tTerminalClientSock.terminate;
begin cleanup(cli_sess_closed); end;

procedure tTerminalClientSock.ReceiveData(adata: pAnsiChar; adatasize: longint);
var totalsize      : longint;
    bufptr, uncomp : pAnsiChar;
    frame          : tProtocolRec;
    enc_pass       : tEncryptedPwd;
    tmpbuf         : array[0..sizeof(tKey) + 8] of byte;
    sz             : longint;
    tmpstr         : ansistring;
    passhash       : TMD5Code;
    tsync          : tTimeSync;
begin
  with in_buf do try
    case state of
      cli_sess_new       : begin
                             appenddata(adata, adatasize);
                             if checkframe then begin
                               read(frame, sizeof(tProtocolRec));
                               if (frame.tableid = idClientInfo) and (frame.datasize = sizeof(tClientInfo)) then begin
                                 read(fClientInfo, sizeof(tClientInfo));
                                 deletedata(position);

                                 fillchar(fHandshakeMsg, sizeof(fHandshakeMsg), 0);
                                 with fHandshakeMsg do begin
                                   msgid     := protLoginMsg;
                                   version   := protocolversion;
                                   accresult := accUserAccepted;
                                   userflags := usrDisabled;
                                 end;

                                 with fClientInfo do begin
                                   fixshortstring(@id, sizeof(id) - 1);
                                   fixshortstring(@username, sizeof(username) - 1);

                                   if assigned(serversocket) then fuser_pass:= tTerminalServer(serversocket).passwords[ClientName]
                                                             else setlength(fuser_pass, 0);

                                   if (length(fuser_pass) > 0) then begin
                                     if assigned(inifile) then with inifile do begin
                                       tmpstr:= format('user:%s', [ClientName]);
                                       UnMIMEKey(pAnsiChar(readstring(tmpstr, 'key', 'AAAAAAAAAAAA')), @out_key);
                                       fHandshakeMsg.userflags:= readinteger(tmpstr, 'flags', fHandshakeMsg.userflags);
                                     end;

                                     MD5LoginPassword(pAnsiChar(ansistring(username)), pAnsiChar(fuser_pass), passhash);
                                     if not CompareMem(@passhash, @password, sizeof(password)) then fHandshakeMsg.accresult:= accAccessDenied;

                                     if (fHandshakeMsg.userflags and (usrDisabled or usrExpired) <> 0) then fHandshakeMsg.accresult:= accAccessDenied;
                                   end else  begin
                                     generatekey(@out_key);
                                     fHandshakeMsg.accresult:= accAccessDenied;
                                     fHandshakeMsg.userflags:= usrNormal;
                                   end;

                                   if (fHandshakeMsg.accresult = accUserAccepted) then fHandshakeMsg.accresult:= check_user;

                                   generatekey(@in_key);
                                   pKey(@tmpbuf)^:= in_key;
                                   sz:= rc5encryptstaticbufcrc32(@tmpbuf, sizeof(tKey), sizeof(tmpbuf), @out_key);
                                   frame:= FillProtocolFrame(idClientRC5Key, 1, sz, pfNoFlags);

                                   out_buf.write(frame, sizeof(frame));
                                   out_buf.write(tmpbuf, sz);
                                 end;

                                 state:= cli_sess_cli_keys;
                               end else cleanup(cli_sess_closed);
                             end;
                           end;
      cli_sess_cli_keys  : begin
                             appenddata(adata, adatasize);
                             if (size - position >= sizeof(tEncryptedPwd)) then begin
                               read(enc_pass, sizeof(tEncryptedPwd));
                               deletedata(position);

                               rc5decryptbuf(@enc_pass, sizeof(tEncryptedPwd), @in_key);

                               if (length(enc_pass) > MaxPwdLength) or (fuser_pass <> enc_pass) then fHandshakeMsg.accresult:= accAccessDenied;

                               frame:= FillProtocolFrame(idServerReply, 1, sizeof(fHandshakeMsg), pfNoFlags);
                               out_buf.write(frame, sizeof(frame));
                               out_buf.write(fHandshakeMsg, sizeof(fHandshakeMsg));

                               if (fHandshakeMsg.accresult = accUserAccepted) then begin
                                 frame:= FillProtocolFrame(idTimeSync, 1, sizeof(tTimeSync), pfNoFlags);

                                 out_buf.write(frame, sizeof(frame));
                                 tsync.dt:= now;
                                 out_buf.write(tsync, sizeof(tsync));

                                 state:= cli_sess_working;

                                 with fClientInfo, version do
                                   fnewdecoder:= not (((major = 2) and (minor = 0) and (build = 0)) or ((major = 1) and (minor = 0)));

                                 fUserFlags:= fHandshakeMsg.userflags;

                                 on_client_login;
                               end;
                             end;
                           end;
      cli_sess_working   : begin
                             appenddata(adata, adatasize);
                             while checkframe do begin
                               read(frame, sizeof(tProtocolRec));
                               bufptr:= currentptr;
                               totalsize:= frame.datasize;

                               if (frame.flags and pfEncrypted <> 0) then begin
                                 case fnewdecoder of
                                   true  : if (rc5decryptbuf(bufptr, frame.datasize, @in_key) <> RC5Ok) then
                                             raise Exception.Create('Error decrypting buffer');
                                   false : if (rc5decryptstaticbufcrc32(bufptr, frame.datasize, @in_key) <> RC5Ok) then
                                             raise Exception.Create('Error decrypting buffer');
                                 end;
                               end;

                               if (frame.flags and pfPacked <> 0) then begin
                                 if (frame.datasize >= 8) then begin
                                   totalsize:= StreamDecompress(bufptr, frame.datasize, pointer(uncomp), temp_buffer);
                                   if (totalsize > 0) then on_message(frame, uncomp, totalsize)
                                                      else raise Exception.Create('Error decompressing buffer');
                                 end;
                               end else on_message(frame, bufptr, totalsize);

                               seek(frame.datasize, soFromCurrent);
                               deletedata(position);
                             end;
                           end;
      cli_sess_closed    : ;
    end;
  except
    on e: exception do begin
                         log(e.message);
                         cleanup(cli_sess_closed);
                       end;
  end;
end;

procedure tTerminalClientSock.SendData;
var sz : longint;
begin
  with out_buf do try
    sz:= Size;
    if (sz > 0) then begin
      sz:= send(memory^, sz);
      if (sz > 0) then deletedata(sz) else
      if (sz < 0) then cleanup(cli_sess_closed);
    end;
  except
    on e: exception do begin
                         log(e.message);
                         cleanup(cli_sess_closed);
                       end;
  end;
end;

procedure tTerminalClientSock.idle;
begin
  SendData;
end;


end.