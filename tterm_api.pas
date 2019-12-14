{$i tterm_defs.pas}

unit tterm_api;

interface

{$ifdef MSWINDOWS}
uses   windows;
{$endif}       

const  PLUGIN_ERROR                     = 0;
       PLUGIN_OK                        = 1;

type   tMainIdleHandler                 = procedure; stdcall;
       tWriteLogHandler                 = function (logstr: pAnsiChar): longint; stdcall;

type   tEnumerateTableRecFunc           = function  (aref: pointer; atable_id: longint; abuf: pAnsiChar; abufsize: longint; aparams: pAnsiChar; aparamsize: longint): longint; stdcall;

type   tInitializeFunc                  = function  (aexeinstance: HModule; ainifilename: pAnsiChar): longint; stdcall;
       tInitializeExFunc                = function  (aexeinstance, alibinstance: HModule; alibname, ainifilename: pAnsiChar): longint; stdcall;
       tUninitializeFunc                = function: longint; stdcall;

       tProcessUserCommand              = function  (acommandline: pAnsiChar): longint; stdcall;
       tSetSQLEventResult               = function  (aresulthandle: pointer; adata: pAnsiChar; adatasize: longint): longint; stdcall;

       tLockAccount                     = function: boolean; stdcall;
       tUnlockAccount                   = function: boolean; stdcall;
       tGetAccount                      = function  (aaccount: pointer; accsize: longint): pointer; stdcall;
       tReleaseAccount                  = procedure (aaccount: pointer; accsize: longint); stdcall;
       tGetAccountData                  = function  (aaccount: pointer; accsize: longint; buffer: pAnsiChar; buflen: longint; var actlen: longint): boolean; stdcall;

const  PLG_Initialize                   = 'plg_initialize';
       PLG_InitializeEx                 = 'plg_initialize_ex';
       PLG_Uninitialize                 = 'plg_uninitizliae';

       PLG_ProcessUserCommand           = 'plg_processusercommand';
       PLG_SetSQLEventResult            = 'plg_setsqleventresult';

       PLG_LockAccount                  = 'plg_lockaccount';
       PLG_UnlockAccount                = 'plg_unlockaccount';
       PLG_GetAccount                   = 'plg_getaccount';
       PLG_ReleaseAccount               = 'plg_releaseaccount';
       PLG_GetAccountData               = 'plg_getaccountdata';

       PLG_ExecuteConsoleCommand        = 'plg_executeconsolecommand';
       PLG_ReadConsoleCommandEx         = 'plg_readconsolecommandex';

type   tAllocmemFunc                    = function  (asize: longint): pointer; stdcall;
       tFreememFunc                     = procedure (apointer: pointer); stdcall;
       tReallocmemFunc                  = function  (apointer: pointer; anewsize: longint): pointer; stdcall;

       tGetPluginsCount                 = function: longint; stdcall;
       tGetPluginsHandlesFunc           = function  (buffer: pointer; buflen: longint): longint; stdcall;
       tGetPluginsProcAddressList       = function  (buffer: pointer; buflen: longint; procname: pAnsiChar): longint; stdcall;

       tSetWriteLogHandler              = function  (anewhandler: tWriteLogHandler): tWriteLogHandler; stdcall;
       tWriteLog                        = function  (logstr: pAnsiChar): longint; stdcall;
       tWriteExceptionLog               = procedure (buffer: pAnsiChar; BufferSize: Integer; CallStack, Registers, CustomInfo: pAnsiChar); stdcall;

       tExecuteConsoleCommand           = function  (acommand: pAnsiChar): longint; stdcall;
       tReadConsoleCommandEx            = function  (prompt: pAnsiChar; masked: boolean; buf: pAnsiChar; buflen: longint; idle: boolean; idleproc: tMainIdleHandler): longint; stdcall;
       tReadConsoleCommand              = function  (prompt: pAnsiChar; masked: boolean; buf: pAnsiChar; buflen: longint): longint; stdcall;

       tEnumerateTables                 = function  (aref: pointer; acallback: tEnumerateTableRecFunc): longint; stdcall;
       tEnumerateTableRecords           = function  (aref: pointer; atable_id, aexpected_recsize: longint; aparams: pAnsiChar; aparamsize: longint; acallback: tEnumerateTableRecFunc): longint; stdcall;

       tGetLegacyAPIs                   = function  (var apis: pointer; var acount: longint): longint; stdcall;

const  SRV_Allocmem                     = 'srv_allocmem';
       SRV_Freemem                      = 'srv_freemem';
       SRV_Reallocmem                   = 'srv_reallocmem';

       SRV_GetPluginsCount              = 'srv_getpluginscount';
       SRV_GetPluginsHandles            = 'srv_getpluginshandles';
       SRV_GetPluginsProcAddressList    = 'srv_getpluginsprocaddresslist';

       SRV_SetWriteLogHandler           = 'srv_setwriteloghandler';
       SRV_StartLog                     = 'srv_startlog';
       SRV_StopLog                      = 'srv_stoplog';
       SRV_FlushLog                     = 'srv_flushlog';
       SRV_WriteLog                     = 'srv_writelog';
       SRV_WriteExceptionLog            = 'srv_writeexceptionlog';

       SRV_ExecuteConsoleCommand        = 'srv_executeconsolecommand';
       SRV_ReadConsoleCommandEx         = 'srv_readconsolecommandex';
       SRV_ReadConsoleCommand           = 'srv_readconsolecommand';

       SRV_EnumerateTables              = 'srv_numeratetables';
       SRV_EnumerateTableRecords        = 'srv_enumeratetablerecords';

       SRV_GetLegacyAPIs                = 'srv_getlegacyapis';

implementation

end.



                                        