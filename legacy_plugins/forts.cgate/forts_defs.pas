{$ifdef FPC}
  {$mode DELPHI}
{$else}
  {$define MSWINDOWS}
{$endif}

{$ifndef FPC}
  {$define use_fastmm4}
  {__$define useexceptionhandler}
{$endif}

{__$define useexceptionhandler}

{$define alltradesbeginupdate}
{$define tradesbeginupdate}
{$define ordersbeginupdate}

{__$define rts_before_after_update}
{__$define after_update_always}

{$define use_session_list_to_expire_orders}
{__$define use_full_client_code_in_account}

{$define measure_transaction_costs}
{$define enable_flood_penalty}
