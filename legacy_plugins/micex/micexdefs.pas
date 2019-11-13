{$DEFINE no_SOError_on_MTETSMR}
{$DEFINE InterfaceV12}
{__$DEFINE AllTradesLowPriority}
{$DEFINE MessagesLowPriority}
{$DEFINE LogOrdersUpdates}
{$DEFINE LogREPOOrdersUpdates}
{$DEFINE LogTradesUpdates}
{$DEFINE FixMicexAccruedintBug}
{__$DEFINE EnableAuction}
{__$DEFINE useexceptionhandler}
{__$DEFINE UseSetOrderFlag}
{__$DEFINE UseSecList}
{$DEFINE usefastmm4}

{$ifndef FPC}
  {$undef usefastmm4}
  {$undef useexceptionhandler}
{$endif}

