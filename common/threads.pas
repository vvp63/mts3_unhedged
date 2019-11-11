{$ifdef FPC}
  {$mode DELPHI}
{$else}
  {$define MSWINDOWS}
{$endif}

unit threads;

interface

uses  {$ifdef MSWINDOWS} windows, {$endif} classes;

type  tCustomThread    = class(tThread)
      private
       fstartimmediate : boolean;
      public
       constructor create(createsuspended : boolean = true);
       procedure   afterconstruction; override;
       procedure   synchronize(method: TThreadMethod); reintroduce; virtual;
       procedure   terminate; reintroduce; virtual;
      end;

implementation

constructor tCustomThread.create;
begin inherited create(true); freeonterminate:= false; fstartimmediate:= not createsuspended; end;

procedure tCustomThread.afterconstruction;
begin if fstartimmediate then resume; end;

procedure tCustomThread.synchronize(method: TThreadMethod);
begin inherited synchronize(method); end;

procedure tCustomThread.terminate;
begin inherited terminate; end;

end.