program TestesServidorDelphi;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.TestFramework,
  DUnitX.Loggers.XML.NUnit,
  DUnitX.Loggers.XML.JUnit,
  IdHTTPServer,
  IdSSLOpenSSL,
  Server.Testes in 'Server.Testes.pas';

var
  Server: TIdHTTPServer;
  Runner: ITestRunner;
  ConsoleLogger: TDUnitXConsoleLogger;
  SSLHandler: TIdServerIOHandlerSSL;

begin
  try
    Writeln('Inicializando o servidor...');
    Server := TIdHTTPServer.Create(nil);
    try
      SSLHandler := TIdServerIOHandlerSSL.Create(nil);
      try
        SSLHandler.SSLOptions.Method := sslvTLSv1_2;
        SSLHandler.SSLOptions.Mode := sslmServer;
        Server.IOHandler := SSLHandler;
        Server.DefaultPort := 8080;
        Server.Active := True;
        Writeln('Servidor inicializado na porta 8080.');

        Writeln('Criando o runner de testes...');
        Runner := TDUnitX.CreateRunner;
        ConsoleLogger := TDUnitXConsoleLogger.Create(true);
        Runner.AddLogger(consoleLogger);

        Writeln('Executando os testes...');
        Runner.Execute;
        Writeln('Testes concluídos.');
      finally
        SSLHandler.Free;
      end;
    finally
      Server.Free;
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.

