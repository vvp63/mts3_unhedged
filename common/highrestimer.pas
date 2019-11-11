unit highrestimer;

interface

uses  windows;

type  NTSTATUS       = ULONG;

const STATUS_SUCCESS = NTSTATUS(0);

function NtQueryTimerResolution(LowRes: PULONG; HighRes: PULONG; CurrRes: PULONG): NTSTATUS; stdcall; external 'ntdll.dll' name 'NtQueryTimerResolution';
function NtSetTimerResolution(RequestedRes: ULONG; Set_: Boolean; ActualRes: PULONG): NTSTATUS; stdcall; external 'ntdll.dll' name 'NtSetTimerResolution';

implementation

//var ResSet: ULONG;

//initialization
//  NtSetTimerResolution(5000, true, @ResSet);

end.