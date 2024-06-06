unit Server.Testes;

interface

uses
  DUnitX.TestFramework, System.JSON, IdHTTP;

type
  [TestFixture]
  TServidorDelphiTestes = class
  private
    HTTPClient: TIdHTTP;

  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestCreateServer;
    [Test]
    procedure TestRemoveServer;
    [Test]
    procedure TestGetServer;
    [Test]
    procedure TestCheckServerAvailability;
    [Test]
    procedure TestListServers;
    [Test]
    procedure TestAddVideoToServer;
    [Test]
    procedure TestRemoveVideo;
    [Test]
    procedure TestGetVideoData;
    [Test]
    procedure TestDownloadBinaryVideo;
    [Test]
    procedure TestListVideos;
    [Test]
    procedure TestRecycleOldVideos;
    [Test]
    procedure TestRecyclerStatus;

  end;

implementation

uses
  Server.Controller, Server.Model, System.SysUtils, IdSSLOpenSSL, System.Classes,
  System.NetEncoding, System.DateUtils;

{ TServidorDelphiTestes }

procedure TServidorDelphiTestes.Setup;
begin
  HTTPClient := TIdHTTP.Create(nil);
  HTTPClient.IOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  HTTPClient.Request.ContentType := 'application/json';
end;

procedure TServidorDelphiTestes.TearDown;
begin
  HTTPClient.Free;
end;

procedure TServidorDelphiTestes.TestAddVideoToServer;
var
  Response: string;
  JSONObj: TJSONObject;
  idServidor: string;
begin
  idServidor := '{BF9EADEA-3F71-4008-97BD-A192AB797307}';
  JSONObj := TJSONObject.Create;
  try
    JSONObj.AddPair('description', 'My Test Video');
    JSONObj.AddPair('content', TNetEncoding.Base64.EncodeBytesToString(TEncoding.UTF8.GetBytes('Hello, World!')));
    JSONObj.AddPair('inclusion_date', DateToISO8601(Now, False));

    Response := HTTPClient.Post('http://localhost:8080/api/servers/' + idServidor + '/videos', TStringStream.Create(JSONObj.ToString, TEncoding.UTF8));
    Assert.IsNotEmpty(Response, 'Response should not be empty');

  finally
    JSONObj.Free;
  end;
end;

procedure TServidorDelphiTestes.TestCheckServerAvailability;
var
  idServidor, Response: string;
begin
  idServidor := '{BF9EADEA-3F71-4008-97BD-A192AB797307}';
  Response := HTTPClient.Get('http://localhost:8080/api/servers/available/' + idServidor);
  Assert.IsNotEmpty(Response, 'Response should not be empty');
end;

procedure TServidorDelphiTestes.TestCreateServer;
var
  Response: string;
  JSONObj: TJSONObject;
begin
  JSONObj := TJSONObject.Create;
  try
    JSONObj.AddPair('name', 'ServerTest');
    JSONObj.AddPair('ip_address', '127.0.0.1');
    JSONObj.AddPair('ip_port', '8080');

    Response := HTTPClient.Post('http://localhost:8080/api/server', TStringStream.Create(JSONObj.ToString, TEncoding.UTF8));
    Assert.IsNotEmpty(Response, 'Response should not be empty');
  finally
    JSONObj.Free;
  end;
end;

procedure TServidorDelphiTestes.TestDownloadBinaryVideo;
var
  idServidor, idVideo: string;
  Response: TMemoryStream;
begin
  idServidor := '{BF9EADEA-3F71-4008-97BD-A192AB797307}';
  idVideo := '{20BC80F9-8F4C-4C4E-A271-69C246248FE2}';
  Response := TMemoryStream.Create;
  try
    HTTPClient.Get('http://localhost:8080/api/servers/' + idServidor + '/videos/' + idVideo + '/binary', Response);
    Assert.IsTrue(Response.Size > 0, 'Response stream should not be empty');

  finally
    Response.Free;
  end;
end;

procedure TServidorDelphiTestes.TestGetServer;
var
  idServidor, Response: string;
begin
  idServidor := '{BF9EADEA-3F71-4008-97BD-A192AB797307}';
  Response := HTTPClient.Get('http://localhost:8080/api/servers/' + idServidor);
  Assert.IsNotEmpty(Response, 'Response should not be empty');
end;

procedure TServidorDelphiTestes.TestGetVideoData;
var
  idServidor, idVideo, Response: string;
begin
  idServidor := '{BF9EADEA-3F71-4008-97BD-A192AB797307}';
  idVideo := '{20BC80F9-8F4C-4C4E-A271-69C246248FE2}';
  Response := HTTPClient.Get('http://localhost:8080/api/servers/' + idServidor + '/videos/' + idVideo);
  Assert.IsNotEmpty(Response, 'Response should not be empty');
end;

procedure TServidorDelphiTestes.TestListServers;
var
  Response: string;
begin
  Response := HTTPClient.Get('http://localhost:8080/api/servers');
  Assert.IsNotEmpty(Response, 'Response should not be empty');
end;

procedure TServidorDelphiTestes.TestListVideos;
var
  idServidor, Response: string;
begin
  idServidor := '{BF9EADEA-3F71-4008-97BD-A192AB797307}';
  Response := HTTPClient.Get('http://localhost:8080/api/servers/' + idServidor + '/videos');
  Assert.IsNotEmpty(Response, 'Response should not be empty');
end;

procedure TServidorDelphiTestes.TestRecycleOldVideos;
var
  Days, Response: string;
begin
  Days := '30';
  Response := HTTPClient.Get('http://localhost:8080/api/recycler/process/' + Days);
  Assert.IsNotEmpty(Response, 'Response should not be empty');
end;

procedure TServidorDelphiTestes.TestRecyclerStatus;
var
  Response: string;
begin
  Response := HTTPClient.Get('http://localhost:8080/api/recycler/status');
  Assert.IsNotEmpty(Response, 'Response should not be empty');
end;

procedure TServidorDelphiTestes.TestRemoveServer;
var
  idServidor: string;
begin
  idServidor := '{BF9EADEA-3F71-4008-97BD-A192AB797307}';
  HTTPClient.Delete('http://localhost:8080/api/servers/' + idServidor);
end;

procedure TServidorDelphiTestes.TestRemoveVideo;
var
  idServidor, idVideo: string;
begin
  idServidor := '{BF9EADEA-3F71-4008-97BD-A192AB797307}';
  idVideo := '{20BC80F9-8F4C-4C4E-A271-69C246248FE2}';
  HTTPClient.Delete('http://localhost:8080/api/servers/' + idServidor + '/videos/' + idVideo);
end;

initialization
  TDUnitX.RegisterTestFixture(TServidorDelphiTestes);

end.
