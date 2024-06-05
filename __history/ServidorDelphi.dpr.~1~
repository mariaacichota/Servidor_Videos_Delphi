program ServidorDelphi;
{$APPTYPE GUI}

uses
  Vcl.Forms,
  Web.WebReq,
  IdHTTPWebBrokerBridge,
  Server.View in 'Server.View.pas' {Form1},
  Server.Controller in 'Server.Controller.pas',
  Server.Container in 'Server.Container.pas' {ServerContainer: TDataModule},
  Web.Module in 'Web.Module.pas' {WebModule1: TWebModule},
  Server.Model in 'Server.Model.pas',
  Videos.Model in 'Videos.Model.pas';

{$R *.res}

begin
  if WebRequestHandler <> nil then
    WebRequestHandler.WebModuleClass := WebModuleClass;
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
