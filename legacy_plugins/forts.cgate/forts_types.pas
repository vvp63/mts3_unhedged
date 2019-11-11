unit forts_types;

interface

uses cgate;

// --- transactions ----------------------------------------------

type
  pFutAddOrder              = ^tFutAddOrder;
  tFutAddOrder              = packed record
    broker_code             : array[0..4] of ansichar;          // ofs: 0  size: 5
    isin                    : array[0..25] of ansichar;          // ofs: 5  size: 26
    client_code             : array[0..3] of ansichar;          // ofs: 31  size: 4
    _pad0                   : array[0..0] of ansichar;
    type_                   : longint;          // ofs: 36  size: 4
    dir                     : longint;          // ofs: 40  size: 4
    amount                  : longint;          // ofs: 44  size: 4
    price                   : array[0..17] of ansichar;          // ofs: 48  size: 18
    comment                 : array[0..20] of ansichar;          // ofs: 66  size: 21
    broker_to               : array[0..20] of ansichar;          // ofs: 87  size: 21
    ext_id                  : longint;          // ofs: 108  size: 4
    du                      : longint;          // ofs: 112  size: 4
    date_exp                : array[0..8] of ansichar;          // ofs: 116  size: 9
    _pad1                   : array[0..2] of ansichar;
    hedge                   : longint;          // ofs: 128  size: 4
    dont_check_money        : longint;          // ofs: 132  size: 4
    local_stamp             : tcg_time;          // ofs: 136  size: 10
    match_ref               : array[0..10] of ansichar;          // ofs: 146  size: 11
    ncc_request             : byte;          // ofs: 157  size: 1
  end;

type
  pFutDelOrder              = ^tFutDelOrder;
  tFutDelOrder              = packed record
    broker_code             : array[0..4] of ansichar;          // ofs: 0  size: 5
    _pad0                   : array[0..2] of ansichar;
    order_id                : int64;          // ofs: 8  size: 8
    local_stamp             : tcg_time;          // ofs: 16  size: 10
    ncc_request             : byte;          // ofs: 26  size: 1
  end;

type
  pFutMoveOrder             = ^tFutMoveOrder;
  tFutMoveOrder             = packed record
    broker_code             : array[0..4] of ansichar;          // ofs: 0  size: 5
    _pad0                   : array[0..2] of ansichar;
    regime                  : longint;          // ofs: 8  size: 4
    order_id1               : int64;          // ofs: 12  size: 8
    amount1                 : longint;          // ofs: 20  size: 4
    price1                  : array[0..17] of ansichar;          // ofs: 24  size: 18
    _pad1                   : array[0..1] of ansichar;
    ext_id1                 : longint;          // ofs: 44  size: 4
    order_id2               : int64;          // ofs: 48  size: 8
    amount2                 : longint;          // ofs: 56  size: 4
    price2                  : array[0..17] of ansichar;          // ofs: 60  size: 18
    _pad2                   : array[0..1] of ansichar;
    ext_id2                 : longint;          // ofs: 80  size: 4
    local_stamp             : tcg_time;          // ofs: 84  size: 10
    ncc_request             : byte;          // ofs: 94  size: 1
  end;

type
  pFORTS_MSG99              = ^tFORTS_MSG99;
  tFORTS_MSG99              = packed record
    queue_size              : longint;          // ofs: 0  size: 4
    penalty_remain          : longint;          // ofs: 4  size: 4
    message                 : array[0..128] of ansichar;          // ofs: 8  size: 129
  end;

type
  pFORTS_MSG100             = ^tFORTS_MSG100;
  tFORTS_MSG100             = packed record
    code                    : longint;          // ofs: 0  size: 4
    message                 : array[0..255] of ansichar;          // ofs: 4  size: 256
  end;

type
  pFORTS_MSG101             = ^tFORTS_MSG101;
  tFORTS_MSG101             = packed record
    code                    : longint;          // ofs: 0  size: 4
    message                 : array[0..255] of ansichar;          // ofs: 4  size: 256
    order_id                : int64;          // ofs: 260  size: 8
  end;

type
  pFORTS_MSG102             = ^tFORTS_MSG102;
  tFORTS_MSG102             = packed record
    code                    : longint;          // ofs: 0  size: 4
    message                 : array[0..255] of ansichar;          // ofs: 4  size: 256
    amount                  : longint;          // ofs: 260  size: 4
  end;

type
  pFORTS_MSG105             = ^tFORTS_MSG105;
  tFORTS_MSG105             = packed record
    code                    : longint;          // ofs: 0  size: 4
    message                 : array[0..255] of ansichar;          // ofs: 4  size: 256
    order_id1               : int64;          // ofs: 260  size: 8
    order_id2               : int64;          // ofs: 268  size: 8
  end;

// --- tables ----------------------------------------------------

type
  pfut_sess_contents        = ^tfut_sess_contents;
  tfut_sess_contents        = packed record
    replID                  : int64;          // ofs: 0  size: 8
    replRev                 : int64;          // ofs: 8  size: 8
    replAct                 : int64;          // ofs: 16  size: 8
    sess_id                 : longint;          // ofs: 24  size: 4
    isin_id                 : longint;          // ofs: 28  size: 4
    short_isin              : array[0..25] of ansichar;          // ofs: 32  size: 26
    isin                    : array[0..25] of ansichar;          // ofs: 58  size: 26
    name                    : array[0..75] of ansichar;          // ofs: 84  size: 76
    inst_term               : longint;          // ofs: 160  size: 4
    code_vcb                : array[0..25] of ansichar;          // ofs: 164  size: 26
    limit_up                : array[0..10] of byte;          // ofs: 190  size: 11
    limit_down              : array[0..10] of byte;          // ofs: 201  size: 11
    old_kotir               : array[0..10] of byte;          // ofs: 212  size: 11
    buy_deposit             : array[0..9] of byte;          // ofs: 223  size: 10
    sell_deposit            : array[0..9] of byte;          // ofs: 233  size: 10
    _pad0                   : array[0..0] of ansichar;
    roundto                 : longint;          // ofs: 244  size: 4
    min_step                : array[0..10] of byte;          // ofs: 248  size: 11
    _pad1                   : array[0..0] of ansichar;
    lot_volume              : longint;          // ofs: 260  size: 4
    step_price              : array[0..10] of byte;          // ofs: 264  size: 11
    _pad2                   : array[0..0] of ansichar;
    d_pg                    : tcg_time;          // ofs: 276  size: 10
    is_spread               : byte;          // ofs: 286  size: 1
    _pad3                   : array[0..0] of ansichar;
    d_exp_start             : tcg_time;          // ofs: 288  size: 10
    is_percent              : byte;          // ofs: 298  size: 1
    percent_rate            : array[0..4] of byte;          // ofs: 299  size: 5
    last_cl_quote           : array[0..10] of byte;          // ofs: 304  size: 11
    _pad4                   : array[0..0] of ansichar;
    signs                   : longint;          // ofs: 316  size: 4
    is_trade_evening        : byte;          // ofs: 320  size: 1
    _pad5                   : array[0..2] of ansichar;
    ticker                  : longint;          // ofs: 324  size: 4
    state                   : longint;          // ofs: 328  size: 4
    multileg_type           : longint;          // ofs: 332  size: 4
    legs_qty                : longint;          // ofs: 336  size: 4
    step_price_clr          : array[0..10] of byte;          // ofs: 340  size: 11
    step_price_interclr     : array[0..10] of byte;          // ofs: 351  size: 11
    step_price_curr         : array[0..10] of byte;          // ofs: 362  size: 11
    _pad6                   : array[0..0] of ansichar;
    d_start                 : tcg_time;          // ofs: 374  size: 10
    pctyield_coeff          : array[0..10] of byte;          // ofs: 384  size: 11
    pctyield_total          : array[0..10] of byte;          // ofs: 395  size: 11
    d_exp_end               : tcg_time;          // ofs: 406  size: 10
    base_contract_code      : array[0..25] of ansichar;          // ofs: 416  size: 26
    settlement_price_open   : array[0..10] of byte;          // ofs: 442  size: 11
    settlement_price        : array[0..10] of byte;          // ofs: 453  size: 11
    last_trade_date         : tcg_time;          // ofs: 464  size: 10
  end;

type
  pcommon                   = ^tcommon;
  tcommon                   = packed record
    replID                  : int64;          // ofs: 0  size: 8
    replRev                 : int64;          // ofs: 8  size: 8
    replAct                 : int64;          // ofs: 16  size: 8
    sess_id                 : longint;          // ofs: 24  size: 4
    isin_id                 : longint;          // ofs: 28  size: 4
    best_buy                : array[0..10] of byte;          // ofs: 32  size: 11
    _pad0                   : array[0..0] of ansichar;
    xamount_buy             : int64;          // ofs: 44  size: 8
    orders_buy_qty          : longint;          // ofs: 52  size: 4
    xorders_buy_amount      : int64;          // ofs: 56  size: 8
    best_sell               : array[0..10] of byte;          // ofs: 64  size: 11
    _pad1                   : array[0..0] of ansichar;
    xamount_sell            : int64;          // ofs: 76  size: 8
    orders_sell_qty         : longint;          // ofs: 84  size: 4
    xorders_sell_amount     : int64;          // ofs: 88  size: 8
    open_price              : array[0..10] of byte;          // ofs: 96  size: 11
    close_price             : array[0..10] of byte;          // ofs: 107  size: 11
    price                   : array[0..10] of byte;          // ofs: 118  size: 11
    trend                   : array[0..10] of byte;          // ofs: 129  size: 11
    xamount                 : int64;          // ofs: 140  size: 8
    deal_time               : tcg_time;          // ofs: 148  size: 10
    _pad2                   : array[0..1] of ansichar;
    deal_time_ns            : int64;          // ofs: 160  size: 8
    min_price               : array[0..10] of byte;          // ofs: 168  size: 11
    max_price               : array[0..10] of byte;          // ofs: 179  size: 11
    avr_price               : array[0..10] of byte;          // ofs: 190  size: 11
    _pad3                   : array[0..2] of ansichar;
    xcontr_count            : int64;          // ofs: 204  size: 8
    capital                 : array[0..14] of byte;          // ofs: 212  size: 15
    _pad4                   : array[0..0] of ansichar;
    deal_count              : longint;          // ofs: 228  size: 4
    old_kotir               : array[0..10] of byte;          // ofs: 232  size: 11
    settlement_price_open   : array[0..10] of byte;          // ofs: 243  size: 11
    _pad5                   : array[0..1] of ansichar;
    xpos                    : int64;          // ofs: 256  size: 8
    mod_time                : tcg_time;          // ofs: 264  size: 10
    _pad6                   : array[0..1] of ansichar;
    mod_time_ns             : int64;          // ofs: 276  size: 8
    cur_kotir               : array[0..10] of byte;          // ofs: 284  size: 11
    market_price            : array[0..10] of byte;          // ofs: 295  size: 11
    local_time              : tcg_time;          // ofs: 306  size: 10
  end;

type
  porders_aggr              = ^torders_aggr;
  torders_aggr              = packed record
    replID                  : int64;          // ofs: 0  size: 8
    replRev                 : int64;          // ofs: 8  size: 8
    replAct                 : int64;          // ofs: 16  size: 8
    isin_id                 : longint;          // ofs: 24  size: 4
    price                   : array[0..10] of byte;          // ofs: 28  size: 11
    _pad0                   : array[0..0] of ansichar;
    volume                  : int64;          // ofs: 40  size: 8
    moment                  : tcg_time;          // ofs: 48  size: 10
    _pad1                   : array[0..1] of ansichar;
    moment_ns               : int64;          // ofs: 60  size: 8
    dir                     : byte;          // ofs: 68  size: 1
    _pad2                   : array[0..0] of ansichar;
    timestamp               : tcg_time;          // ofs: 70  size: 10
    sess_id                 : longint;          // ofs: 80  size: 4
  end;

type
  pdeal                     = ^tdeal;
  tdeal                     = packed record
    replID                  : int64;          // ofs: 0  size: 8
    replRev                 : int64;          // ofs: 8  size: 8
    replAct                 : int64;          // ofs: 16  size: 8
    sess_id                 : longint;          // ofs: 24  size: 4
    isin_id                 : longint;          // ofs: 28  size: 4
    id_deal                 : int64;          // ofs: 32  size: 8
    xpos                    : int64;          // ofs: 40  size: 8
    xamount                 : int64;          // ofs: 48  size: 8
    id_ord_buy              : int64;          // ofs: 56  size: 8
    id_ord_sell             : int64;          // ofs: 64  size: 8
    price                   : array[0..10] of byte;          // ofs: 72  size: 11
    _pad0                   : array[0..0] of ansichar;
    moment                  : tcg_time;          // ofs: 84  size: 10
    _pad1                   : array[0..1] of ansichar;
    moment_ns               : int64;          // ofs: 96  size: 8
    nosystem                : byte;          // ofs: 104  size: 1
  end;

type
  puser_deal                = ^tuser_deal;
  tuser_deal                = packed record
    replID                  : int64;          // ofs: 0  size: 8
    replRev                 : int64;          // ofs: 8  size: 8
    replAct                 : int64;          // ofs: 16  size: 8
    sess_id                 : longint;          // ofs: 24  size: 4
    isin_id                 : longint;          // ofs: 28  size: 4
    id_deal                 : int64;          // ofs: 32  size: 8
    id_deal_multileg        : int64;          // ofs: 40  size: 8
    id_repo                 : int64;          // ofs: 48  size: 8
    xpos                    : int64;          // ofs: 56  size: 8
    xamount                 : int64;          // ofs: 64  size: 8
    id_ord_buy              : int64;          // ofs: 72  size: 8
    id_ord_sell             : int64;          // ofs: 80  size: 8
    price                   : array[0..10] of byte;          // ofs: 88  size: 11
    _pad0                   : array[0..0] of ansichar;
    moment                  : tcg_time;          // ofs: 100  size: 10
    _pad1                   : array[0..1] of ansichar;
    moment_ns               : int64;          // ofs: 112  size: 8
    nosystem                : byte;          // ofs: 120  size: 1
    _pad2                   : array[0..2] of ansichar;
    xstatus_buy             : int64;          // ofs: 124  size: 8
    xstatus_sell            : int64;          // ofs: 132  size: 8
    ext_id_buy              : longint;          // ofs: 140  size: 4
    ext_id_sell             : longint;          // ofs: 144  size: 4
    code_buy                : array[0..7] of ansichar;          // ofs: 148  size: 8
    code_sell               : array[0..7] of ansichar;          // ofs: 156  size: 8
    comment_buy             : array[0..20] of ansichar;          // ofs: 164  size: 21
    comment_sell            : array[0..20] of ansichar;          // ofs: 185  size: 21
    fee_buy                 : array[0..14] of byte;          // ofs: 206  size: 15
    fee_sell                : array[0..14] of byte;          // ofs: 221  size: 15
    login_buy               : array[0..20] of ansichar;          // ofs: 236  size: 21
    login_sell              : array[0..20] of ansichar;          // ofs: 257  size: 21
    code_rts_buy            : array[0..7] of ansichar;          // ofs: 278  size: 8
    code_rts_sell           : array[0..7] of ansichar;          // ofs: 286  size: 8
  end;

type
  porders_log               = ^torders_log;
  torders_log               = packed record
    replID                  : int64;          // ofs: 0  size: 8
    replRev                 : int64;          // ofs: 8  size: 8
    replAct                 : int64;          // ofs: 16  size: 8
    id_ord                  : int64;          // ofs: 24  size: 8
    sess_id                 : longint;          // ofs: 32  size: 4
    isin_id                 : longint;          // ofs: 36  size: 4
    xamount                 : int64;          // ofs: 40  size: 8
    xamount_rest            : int64;          // ofs: 48  size: 8
    id_deal                 : int64;          // ofs: 56  size: 8
    xstatus                 : int64;          // ofs: 64  size: 8
    price                   : array[0..10] of byte;          // ofs: 72  size: 11
    _pad0                   : array[0..0] of ansichar;
    moment                  : tcg_time;          // ofs: 84  size: 10
    _pad1                   : array[0..1] of ansichar;
    moment_ns               : int64;          // ofs: 96  size: 8
    dir                     : byte;          // ofs: 104  size: 1
    action                  : byte;          // ofs: 105  size: 1
    deal_price              : array[0..10] of byte;          // ofs: 106  size: 11
    client_code             : array[0..7] of ansichar;          // ofs: 117  size: 8
    login_from              : array[0..20] of ansichar;          // ofs: 125  size: 21
    comment                 : array[0..20] of ansichar;          // ofs: 146  size: 21
    _pad2                   : array[0..0] of ansichar;
    ext_id                  : longint;          // ofs: 168  size: 4
    broker_to               : array[0..7] of ansichar;          // ofs: 172  size: 8
    broker_to_rts           : array[0..7] of ansichar;          // ofs: 180  size: 8
    broker_from_rts         : array[0..7] of ansichar;          // ofs: 188  size: 8
    date_exp                : tcg_time;          // ofs: 196  size: 10
    _pad3                   : array[0..1] of ansichar;
    id_ord1                 : int64;          // ofs: 208  size: 8
    local_stamp             : tcg_time;          // ofs: 216  size: 10
    _pad4                   : array[0..1] of ansichar;
    aspref                  : longint;          // ofs: 228  size: 4
  end;

type
  psys_events               = ^tsys_events;
  tsys_events               = packed record
    replID                  : int64;          // ofs: 0  size: 8
    replRev                 : int64;          // ofs: 8  size: 8
    replAct                 : int64;          // ofs: 16  size: 8
    event_id                : int64;          // ofs: 24  size: 8
    sess_id                 : longint;          // ofs: 32  size: 4
    event_type              : longint;          // ofs: 36  size: 4
    message                 : array[0..64] of ansichar;          // ofs: 40  size: 65
  end;

type
  pusd_online               = ^tusd_online;
  tusd_online               = packed record
    replID                  : int64;          // ofs: 0  size: 8
    replRev                 : int64;          // ofs: 8  size: 8
    replAct                 : int64;          // ofs: 16  size: 8
    id                      : int64;          // ofs: 24  size: 8
    rate                    : array[0..9] of byte;          // ofs: 32  size: 10
    moment                  : tcg_time;          // ofs: 42  size: 10
  end;

type
  prts_index                = ^trts_index;
  trts_index                = packed record
    replID                  : int64;          // ofs: 0  size: 8
    replRev                 : int64;          // ofs: 8  size: 8
    replAct                 : int64;          // ofs: 16  size: 8
    name                    : array[0..25] of ansichar;          // ofs: 24  size: 26
    moment                  : tcg_time;          // ofs: 50  size: 10
    value                   : array[0..10] of byte;          // ofs: 60  size: 11
    prev_close_value        : array[0..10] of byte;          // ofs: 71  size: 11
    open_value              : array[0..10] of byte;          // ofs: 82  size: 11
    max_value               : array[0..10] of byte;          // ofs: 93  size: 11
    min_value               : array[0..10] of byte;          // ofs: 104  size: 11
    usd_rate                : array[0..6] of byte;          // ofs: 115  size: 7
    cap                     : array[0..10] of byte;          // ofs: 122  size: 11
    volume                  : array[0..10] of byte;          // ofs: 133  size: 11
    value_highprec          : array[0..10] of byte;          // ofs: 144  size: 11
    prev_close_value_highprec: array[0..10] of byte;          // ofs: 155  size: 11
    open_value_highprec     : array[0..10] of byte;          // ofs: 166  size: 11
    max_value_highprec      : array[0..10] of byte;          // ofs: 177  size: 11
    min_value_highprec      : array[0..10] of byte;          // ofs: 188  size: 11
  end;

implementation

end.