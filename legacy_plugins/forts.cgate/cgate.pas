{__$define CGATE_EX}
{$define CGATE_VER5}

{$ifdef FPC}
  {$mode DELPHI}
{$else}
  {$define MSWINDOWS}
{$endif}

unit cgate;

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

const gate_dll = 'cgate'{$ifdef CGATE_EX}+'_ex'{$endif}{$ifdef MSWINDOWS}{$ifdef GATE64}+'64'{$endif}+'.dll'{$endif};

// version control

const {$ifdef CGATE_VER5}
      CG_VERSION_MAJOR                     = 5;
      CG_VERSION_MINOR                     = 1;
      CG_VERSION_PATCH                     = 0;
      {$else}
      CG_VERSION_MAJOR                     = 1;
      CG_VERSION_MINOR                     = 3;
      CG_VERSION_PATCH                     = 2;
      {$endif}
      CG_VERSION                           = (CG_VERSION_MAJOR shl 24) or (CG_VERSION_MINOR shl 16) or CG_VERSION_PATCH;

// error codes

const CG_RANGE_BEGIN                       = $20000;

      CG_ERR_OK                            = 0;

      CG_ERR_INTERNAL                      = CG_RANGE_BEGIN;
      CG_ERR_INVALIDARGUMENT               = 1  + CG_RANGE_BEGIN;
      CG_ERR_UNSUPPORTED                   = 2  + CG_RANGE_BEGIN;
      CG_ERR_TIMEOUT                       = 3  + CG_RANGE_BEGIN;
      CG_ERR_MORE                          = 4  + CG_RANGE_BEGIN;
      CG_ERR_INCORRECTSTATE                = 5  + CG_RANGE_BEGIN;
      CG_ERR_DUPLICATEID                   = 6  + CG_RANGE_BEGIN;
      CG_ERR_BUFFERTOOSMALL                = 7  + CG_RANGE_BEGIN;
      CG_ERR_OVERFLOW                      = 8  + CG_RANGE_BEGIN;
      CG_ERR_UNDERFLOW                     = 9  + CG_RANGE_BEGIN;
      CG_RANGE_END                         = 10 + CG_RANGE_BEGIN;

// scheme types
const CG_SCHEME_BINARY                     = 1;

      CG_SCHEME_BIN_MSG_HAS_ID             = $00000001;
      CG_SCHEME_BIN_MSG_HAS_NAME           = $00000002;
      CG_SCHEME_BIN_MSG_HAS_DESC           = $00000004;
      CG_SCHEME_BIN_MSG_HAS_INDICES        = $00000008;
      CG_SCHEME_BIN_MSG_HAS_TIMESTAMP_HINT = $00000010;
      CG_SCHEME_BIN_MSG_HAS_USER_HINT      = $00000020;
      CG_SCHEME_BIN_FIELD_HAS_ID           = $00000100;
      CG_SCHEME_BIN_FIELD_HAS_NAME         = $00000200;
      CG_SCHEME_BIN_FIELD_HAS_DESC         = $00000400;
      CG_SCHEME_BIN_FIELD_HAS_TYPE         = $00000800;
      CG_SCHEME_BIN_FIELD_HAS_DEFVAL       = $00001000;

// states
const CG_STATE_CLOSED                      = 0;
      CG_STATE_ERROR                       = 1;
      CG_STATE_OPENING                     = 2;
      CG_STATE_ACTIVE                      = 3;

// message creation flags
const CG_KEY_INDEX                         = 0;
      CG_KEY_ID                            = 1;
      CG_KEY_NAME                          = 2;

// publisher flags
const CG_PUB_NEEDREPLY                     = 1;

// message types
const CG_MSG_OPEN                          = $100;
      CG_MSG_CLOSE                         = $101;
      CG_MSG_DATA                          = $110;
      CG_MSG_STREAM_DATA                   = $120;
      CG_MSG_DATAARRAY                     = $150;
      CG_MSG_OBJFAILED                     = $180;

      CG_MSG_TN_BEGIN                      = $200;
      CG_MSG_TN_COMMIT                     = $210;
      CG_MSG_TN_ROLLBACK                   = $220;

      CG_MSG_P2MQ_RANGE_START              = $1000;
      CG_MSG_P2MQ_TIMEOUT                  = ($1 + CG_MSG_P2MQ_RANGE_START);

      CG_MSG_P2REPL_RANGE_START            = $1100;
      CG_MSG_P2REPL_LIFENUM                = ($10 + CG_MSG_P2REPL_RANGE_START);
      CG_MSG_P2REPL_CLEARDELETED           = ($11 + CG_MSG_P2REPL_RANGE_START);
      CG_MSG_P2REPL_ONLINE                 = ($12 + CG_MSG_P2REPL_RANGE_START);
      CG_MSG_P2REPL_REPLSTATE              = ($15 + CG_MSG_P2REPL_RANGE_START);

const CG_REASON_UNDEFINED                  = 0;
      CG_REASON_USER                       = 1;
      CG_REASON_ERROR                      = 2;
      CG_REASON_DONE                       = 3;
      CG_REASON_SNAPSHOT_DONE              = 4;

const CG_REPLACT_INSERT                    = 0;
      CG_REPLACT_UPDATE                    = 1;
      CG_REPLACT_DELETE                    = 2;

const CG_LIFENUM_CHANGE__DONT_CLEAR_STORAGE = 1;

const CG_INDEX_INVALID                     = size_t(-1);
      CG_ID_INVALID                        = size_t(-1);
      CG_MAX_REVISON                       = $7FFFFFFFFFFFFFFF;

const CG_OWNER_UNKNOWN                     = 0;


// General purpose message
type  pcg_msg               = ^tcg_msg;
      tcg_msg               = record
        msg_type            : longint;         // Message type
        data_size           : size_t;          // Data size
        data                : pointer;         // Data pointer
        {$ifdef CGATE_VER5}
        owner_id            : int64;           // Owner ID
        {$endif}
      end;

// Time message
type  pcg_msg_time          = ^tcg_msg_time;
      tcg_msg_time          = record
        msg_type            : longint;         // Message type
        data_size           : size_t;          // Data size
        data                : pointer;         // Data pointer
        {$ifdef CGATE_VER5}
        owner_id            : int64;           // Owner ID
        {$endif}
        usec                : int64;           // Microseconds from epoch
      end;

// Stream data message
type  pcg_msg_streamdata    = ^tcg_msg_streamdata;
      tcg_msg_streamdata    = record
        msg_type            : longint;         // Message type = CG_MSG_STREAM_DATA
        data_size           : size_t;          // Data size
        data                : pointer;         // Data pointer
        {$ifdef CGATE_VER5}
        owner_id            : int64;           // Owner ID
        {$endif}
        msg_index           : size_t;          // Message number in active scheme
        msg_id              : longint;         // Unique message ID (if applicable)
        msg_name            : pAnsiChar;       // Message name in active scheme
        rev                 : int64;           // Message sequence number
        num_nulls           : size_t;          // Size of presence map
        nulls               : pAnsiChar;       // Presence map. Contains 1 for NULL fields
        {$ifdef CGATE_VER5}
        user_id             : int64;           // User ID
        {$endif}
      end;

// Data message
type  tcg_user_id           = record
        {$ifdef CGATE_VER5}
        case boolean of
          true  : (user_id  : longint);        // User ID
          false : (user_ptr : pointer);        // User pointer
        {$else}
        user_id             : longint;
        {$endif}
      end;

type  pcg_msg_data          = ^tcg_msg_data;
      tcg_msg_data          = record
        msg_type            : longint;         // Message type = CG_MSG_DATA
        data_size           : size_t;          // Data size
        data                : pointer;         // Data pointer
        {$ifdef CGATE_VER5}
        owner_id            : int64;           // Owner ID
        {$endif}
        msg_index           : size_t;          // Message number in active scheme
        msg_id              : longint;         // Unique message ID (if applicable)
        msg_name            : pAnsiChar;       // Message name in active scheme
        user_id             : tcg_user_id;     // User message id (the value sent back in reply)
        addr                : pAnsiChar;       // Remote address
        ref_msg             : pcg_msg_data;    // Reference message
      end;

type  pcg_msg_dataarray     = ^tcg_msg_dataarray;
      tcg_msg_dataarray     = record
        msg_type            : longint;         // Message type = CG_MSG_DATA
        data_size           : size_t;          // Data size
        data                : pointer;         // Data pointer
        {$ifdef CGATE_VER5}
        owner_id            : int64;           // Owner ID
        {$endif}
        msg_index           : size_t;          // Message number in active scheme
        msg_id              : longint;         // Unique message ID (if applicable)
        msg_name            : pAnsiChar;       // Message name in active scheme
        user_id             : tcg_user_id;     // User message id (the value sent back in reply)
        addr                : pAnsiChar;       // Remote address
        ref_msg             : pcg_msg_data;    // Reference message
        cnt                 : longint;         // Count
      end;

// User message callback function
type  tcg_LISTENER_CB       = function (hconn: THandle; hlistener: THandle; msg: pcg_msg; data: pointer): longint; cdecl;

// List of key-value pairs
type  pcg_value_pair        = ^tcg_value_pair;
      tcg_value_pair        = record
        // Pointer to the next list entry
        next                : pcg_value_pair;
        // Key, required
        key                 : pAnsiChar;
        // Value, may be null
        value               : pAnsiChar;
      end;

// Field value description
type  pcg_field_value_desc  = ^tcg_field_value_desc;
      tcg_field_value_desc  = record
        // Pointer to the next value
        next                : pcg_field_value_desc;
        // Value name
        name                : pAnsiChar;
        // Description
        // may be NULL if not defined
        desc                : pAnsiChar;
        // Pointer to value
        value               : pointer;
        // Used for integer fields only (i[1-8], u[1-8])
        // A mask that defines range of bits used by the value
        mask                : pointer;
      end;

// Field description
type  pcg_field_desc        = ^tcg_field_desc;
      tcg_field_desc        = record
        // Pointer to the next value
        next                : pcg_field_desc;
        // Field ID. May be 0 if not defined
        // May be NULL if not defined
        id                  : longint;
        // Field name
        // May be NULL if not defined
        name                : pAnsiChar;
        // Description
        // May be NULL if not defined
        desc                : pAnsiChar;
        // Field type
        field_type          : pAnsiChar;
        // Size in bytes
        size                : size_t;
        // Offset from beginning of data in bytes
        offset              : size_t;
        // Pointer to default value of the field
        // Points to the buffer of size "size"
        // May be NULL if not defined
        def_value           : pointer;
        // Number of values for the field values
        num_values          : size_t;
        // Pointer to the list of values
        // which can be taken by the field
        values              : pcg_field_value_desc;
        // Field options
        hints               : pcg_value_pair;
        {$ifdef CGATE_VER5}
        // Maximum number of fields, 1 by default
        max_count           : size_t;
        // Link to description of count field
        count_field         : pcg_field_value_desc;
        // Pointer to message description for type = 'm' fields
        type_msg            : pcg_field_desc;
        {$endif}
      end;

// Index component description
type  pcg_indexfield_desc   = ^tcg_indexfield_desc;
      tcg_indexfield_desc   = record
        // Pointer to the next value
        next                : pcg_indexfield_desc;
        // Points to field of index
        field               : pcg_field_desc;
        // Sort order (0 for asc, 1 for desc)
        sort_order          : longint;
      end;

// Index description
type  pcg_index_desc        = ^tcg_index_desc;
      tcg_index_desc        = record
        // Pointer to the next index
        next                : pcg_index_desc;
        // Number of fields in the index
        num_fields          : size_t;
        // Pointer to the first index component
        fields              : pcg_indexfield_desc;
        // Index name
        // May be NULL if not defined
        name                : pAnsiChar;
        // Description
        // May be NULL if not defined
        desc                : pAnsiChar;
        // Index hints
        hints               : pcg_value_pair;
      end;

// Message description
type  pcg_message_desc      = ^tcg_message_desc;
      tcg_message_desc      = record
        // Pointer to the next message
        next                : pcg_message_desc;
        // Message data block size
        size                : size_t;
        // Number of fields in the message
        num_fields          : size_t;
        // Pointer to the first message description
        fields              : pcg_field_desc;
        // Message unique ID
        // May be 0 if not defined
        id                  : longint;
        // Message name
        // May be NULL if not defined
        name                : pAnsiChar;
        // Description
        // May be NULL if not defined
        desc                : pAnsiChar;
        // message hints (in string format)
        // may be NULL if not defined
        hints               : pcg_value_pair;
        // Number of indices for the message
        num_indices         : size_t;
        // Pointer to the first index description
        indices             : pcg_index_desc;
        {$ifdef CGATE_VER5}
        // Size of alignment
        align               : size_t;
        {$endif}
      end;

// Scheme description
type  pcg_scheme_desc       = ^tcg_scheme_desc;
      tcg_scheme_desc       = record
        // Scheme type
        // 1 for binary scheme which is the only type supported now
        scheme_type         : longint;
        // Scheme features (combination of CG_SCHEME_BIN_* constants)
        features            : longint;
        // Number of messages in the scheme
        num_messages        : size_t;
        // Pointer to the first message description
        messages            : pcg_message_desc;
        // Scheme options
        hints               : pcg_value_pair;
      end;

// Date-time type
type  pcg_time              = ^tcg_time;
      tcg_time              = record
        year                : word;            // Year
        month               : byte;            // Month of year (1-12)
        day                 : byte;            // Day of month (1-31)
        hour                : byte;            // Hour (0-23)
        minute              : byte;            // Minute (0-59)
        second              : byte;            // Second (0-59)
        msec                : word;            // Millisecond (0-999)
      end;

// Structure that describes data format
// for CG_MSG_P2REPL_CLEARDELETED message
type  pcg_data_cleardeleted = ^tcg_data_cleardeleted;
      tcg_data_cleardeleted = packed record
        table_idx           : longint;
        table_rev           : int64;
      end;

type pcg_repl_act           = ^tcg_repl_act;
     tcg_repl_act           = packed record
       act                  : byte; // INSERT, UPDATE, DELETE
       idx_id               : byte;
       reserved             : array[0..5] of byte;
     end;

type pcg_data_lifenum       = ^tcg_data_lifenum;
     tcg_data_lifenum       = packed record
       life_number          : longint;
       flags                : longint; // CG_LIFENUM_CHANGE_
     end;


const CG_LOGGER_PRIORITY_TRACE             = 0;
      CG_LOGGER_PRIORITY_DEBUG             = 1;
      CG_LOGGER_PRIORITY_INFO              = 2;
      CG_LOGGER_PRIORITY_NOTICE            = 3;
      CG_LOGGER_PRIORITY_WARN              = 4;
      CG_LOGGER_PRIORITY_ERROR             = 5;
      CG_LOGGER_PRIORITY_CRIT              = 6;


// Initialize environment
function cg_env_open(const settings: pAnsiChar): longint; cdecl;

// Deinitialize environment
function cg_env_close: longint; cdecl;

{
 Create new connection
 @param settings Connection initialization string
 @param connptr Where pointer to new connection will be stored

 Connection initialization string has the following format:
 "TYPE://HOST:PORT&param1=value1&param2=value2..."
 ,where
 - TYPE defines connection type
   - "p2tcp" means TCP connection with Plaza-2 router process
   - "p2lrcpq" meanes shared memory connection with Plaza-2 router process
 - HOST is host of the machine where Plaza-2 router runs
 - PORT is port of Plaza-2 router
 - param1 ... paramN - parameters which depend on type of connection.

 Parameters for "p2tcp" and "p2lrpcq" connections:
 - app_name - a string, Plaza-2 application name for connection
            each connection must have unique name
 - timeout - a number, timeout of Plaza-2 router connection, ms
 - local_timeout - a number, timeout of Plaza-2 router interactions, ms
}
function cg_conn_new(settings: pAnsiChar; var hConn: THandle): longint; cdecl;

// Destroys connection
function cg_conn_destroy(hConn: THandle): longint; cdecl;

{
  Open connection
  @param settings Connection open string
  Parameter "settigns" is not used for both p2tcp and p2lrpcq connection types.
}
function cg_conn_open(hConn: THandle; const settings: pAnsiChar): longint; cdecl;

// Close connection
function cg_conn_close(hConn: THandle): longint; cdecl;

// Get connection state
function cg_conn_getstate(hConn: THandle; var state: longint): longint; cdecl;

// Process one iteration of connection internal logic
function cg_conn_process(hConn: THandle; timeout: longint; reserved: pointer): longint; cdecl;

{
  Create new listener
   @param conn Connection to create listener on
   @param settings Connection initialization string
   @param cb Pointer to user message callback
   @param data User data that will be passed as one of the callback parameters
   @param lsnptr Where pointer to new listener will be stored

   There are following types of listeners supported:
   p2repl - datastream replication client
   p2mqreply - messages reply listener
   p2ordbook - optimized orderbook datastream listener

   Initialization string for "p2repl":
   p2repl://STREAM[;scheme=SCHEMEURL]
     * STREAM - datastream name
         * SCHEMEURL - scheme URL in format "|SRC|PATH|NAME"
           where SRC is either FILE or MQ,
                 PATH is path to scheme INI file for FILE source
                         PATH is scheme service name for MQ soruce
                         NAME is name of the scheme in file or scheme service

   Initialization string for "p2mqreply":
   p2mqreply://;ref=REFERENCE
     * REFERENCE - name of the publisher that is used to send messages

   Initialization string for "p2ordbook":
   p2ordbook://STREAM;snapshot=STREAMSS[;scheme=SCHEME][;snapshot.scheme=SCHEMESS]
     * STREAM - name of orderbook online stream
         * STREAMSS - name of orderbook snapshot stream
         * SCHEME - scheme URL for online stream
         * SCHEMESS - scheme URL for snapshot stream
}
function cg_lsn_new(hConn: THandle; const settings: pAnsiChar; cb: tcg_LISTENER_CB; data: pointer; var hLsn: THandle): longint; cdecl;

// Destroy listener
function cg_lsn_destroy(hLsn: THandle): longint; cdecl;

// Get listener state
function cg_lsn_getstate(hLsn: THandle; var state: longint): longint; cdecl;

{
  Open listener
        @param settings Listener open string

        Open string for "p2repl":
        [mode=STREAMTYPES][;replstate=REPLSTATE]
                * STREAMTYPES - stream mode ('snapshot', 'online', 'snapshot+online')
                * REPLSTATE - previously saved stream stated (string received in CG_MSG_P2REPL_REPLSTATE message)

        Parameter "settings" is ignored for other types of listeners.
}
function cg_lsn_open(hLsn: THandle; const settings: pAnsiChar): longint; cdecl;

// Close listener
function cg_lsn_close(hLsn: THandle): longint; cdecl;

// Get current data scheme for listener
function cg_lsn_getscheme(hLsn: THandle; var desc: pcg_scheme_desc): longint; cdecl;

{
  Create publisher

        There are following types of publishers supported::
        p2mq - posts messages to specified Plaza-2 service

        Initialization string for "p2mq":
        p2mq://SERVICE[;scheme=SCHEMEURL][;timeout=TIMEOUT][;name=NAME]
                * SERVICE - destination service name
                * SCHEMEURL - scheme URL
                * TIMEOUT - reply timeout, ms
                * NAME - unique publisher name to be referenced by p2mqreply listener
}
function cg_pub_new(hConn: THandle; const settings: pAnsiChar; var hPub: THandle): longint; cdecl;

// Destroy publisher
function cg_pub_destroy(hPub: THandle): longint; cdecl;

{
 Open publisher
  @param settings Publisher open string

  Parameter "settings" is not used currently and should be empty.}
function cg_pub_open(hPub: THandle; const settings: pAnsiChar): longint; cdecl;

// Close publisher
function cg_pub_close(hPub: THandle): longint; cdecl;

// Get publisher state
function cg_pub_getstate(hPub: THandle; var state: longint): longint; cdecl;

// Get data scheme description
function cg_pub_getscheme(hPub: THandle; var desc: pcg_scheme_desc): longint; cdecl;

{
  Create new message for publishing
   @param id_type CG_KEY_INDEX Create message using its index in current publisher scheme (id points to uint32_t)
   @param id_type CG_KEY_ID Create message using its unique ID in publisher scheme (id points to uint32_t)
   @param id_type CG_KEY_NAME Create message using its name in current publisher scheme (id points to 0-terminated string)
}
function cg_pub_msgnew(hPub: THandle; id_type: longint; id: pointer; var msgptr: pcg_msg): longint; cdecl;

// Free message
function cg_pub_msgfree(hPub: THandle; msgptr: pcg_msg): longint; cdecl;

{
  Post message
   @param flags Flags of post operation
          CG_PUB_NEEDREPLY - if message reply is expected
}
function cg_pub_post(hPub: THandle; msgptr: pcg_msg; flags: longint): longint; cdecl;

{
 Dump specified message as a text. Message data will be parsed if data scheme is specified as paramater.
 This function is designed for debugging purposes.
 @param msg Message to dump
 @param scheme Data scheme (may be NULL)
 @param buffer Pointer to preallocated buffer where to store dump
 @param bufsize Points to variable holding buffer size. 

 If buffer is too small for message dump, CG_ERR_BUFFERTOOSMALL error code will be returned and
 bufsize will be filled with desired buffer size.
}
function cg_msg_dump(msgptr: pointer; scheme: pcg_scheme_desc; buffer: pAnsiChar; var bufsize: size_t): longint; cdecl;

{
 Return BCD value as integer part and position of decimal point.
 Returned values can be used the following way:
 val = bigdecimal(intpart) / 10^scale

 @param bcd Point to BCD value
 @param intpart Where to store integer part
 @param scale Where to store scale
}
function cg_bcd_get(bcd: pointer; var intpart: int64; var scale: byte): longint; cdecl;

{
 Return data represented as text
 @param type Field type (the same format as used in schemes)
 @param data Data pointer
 @param buffer Указатель на выделенный буфер, куда будет записана строка
 @param bufsize Указатель на переменную, содержащую размер буфера. При нехватке размера буфера
        в неё будет записан требуемый размер буфера
}
function cg_getstr(const valuetype: pAnsiChar; data: pointer; buffer: pAnsiChar; var bufsize: size_t): longint; cdecl;

{
 Return string representation for error code.
 @param errCode CGate error code
 @param errstr Pointer to store pointer to const string
}
function cg_err_getstr(errCode: longint): pAnsiChar; cdecl;

{
 Log user message
 @param logstr string for output
}
function cg_log_debugstr(const logstr: pAnsiChar): longint; cdecl;
function cg_log_infostr(const logstr: pAnsiChar): longint; cdecl;
function cg_log_errorstr(const logstr: pAnsiChar): longint; cdecl;

implementation

function cg_env_open; external gate_dll;
function cg_env_close; external gate_dll;
function cg_conn_new; external gate_dll;
function cg_conn_destroy; external gate_dll;
function cg_conn_open; external gate_dll;
function cg_conn_close; external gate_dll;
function cg_conn_getstate; external gate_dll;
function cg_conn_process; external gate_dll;
function cg_lsn_new; external gate_dll;
function cg_lsn_destroy; external gate_dll;
function cg_lsn_getstate; external gate_dll;
function cg_lsn_open; external gate_dll;
function cg_lsn_close; external gate_dll;
function cg_lsn_getscheme; external gate_dll;
function cg_pub_new; external gate_dll;          
function cg_pub_destroy; external gate_dll;
function cg_pub_open; external gate_dll;
function cg_pub_close; external gate_dll;
function cg_pub_getstate; external gate_dll;
function cg_pub_getscheme; external gate_dll;
function cg_pub_msgnew; external gate_dll;
function cg_pub_msgfree; external gate_dll;
function cg_pub_post; external gate_dll;
function cg_msg_dump; external gate_dll;
function cg_bcd_get; external gate_dll;
function cg_getstr; external gate_dll;
function cg_err_getstr; external gate_dll;
function cg_log_debugstr; external gate_dll;
function cg_log_infostr; external gate_dll;
function cg_log_errorstr; external gate_dll;

end.
