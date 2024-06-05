program TestesServidorDelphi;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Server.Testes in 'Server.Testes.pas';

begin
  try
    { TODO -oUser -cConsole Main : Insert code here }
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
