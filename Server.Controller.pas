unit Server.Controller;

interface

uses System.Classes, System.StrUtils, Vcl.Dialogs, Datasnap.DSServer, Datasnap.DSAuth,
     IPPeerServer, Datasnap.DSCommonServer, IdTCPClient, REST.Json, System.JSON,
     Server.Model, Videos.Model, System.NetEncoding, Vcl.StdCtrls, System.Net.HttpClient;

type
{$METHODINFO ON}
  TServerController = class(TComponent)

  public
    class function CreateServer(AName, AIPAddress: string; AIPPort: Integer): TJSONObject;
    class function CreateVideo(Server: TServer; Description, Content: String; InclusionDate: TDateTime): TJSONObject;
    class function UpdateServer(AID: TGUID; AName, AIPAddress: string; AIPPort: Integer): TJSONObject;
    class function DeleteServer(AID: TGUID): Boolean;
    class function DeleteVideo(ServerID, VideoID: TGUID): Boolean;
    class function GetServer(AID: TGUID): TJSONObject;
    class function GetVideo(ServerID, VideoID: TGUID): TJSONObject;
    class function CheckServerAvailability(AID: TGUID): Boolean;
    class function GetAllServers: TJSONArray;
    class function GetAllVideos: TJSONArray;
    class function DownloadBinaryVideo(Video: TVideo): TStream;
    class procedure LoadServersToComboBox(ComboBox: TComboBox);  //

    class function FindServerByID(AID: TGUID): TServer;
    class function FindServerByName(ServerName: String): TServer;      //
    class function FindVideoByIDs(ServerID, VideoID: TGUID): TVideo;
  end;
{$METHODINFO OFF}

implementation

uses
  System.Generics.Collections, System.SysUtils;

{ TServerController }

class function TServerController.CheckServerAvailability(AID: TGUID): Boolean;
var
  Servidor: TServer;
  TCPClient: TIdTCPClient;
begin
  // Encontrar o servidor com base no ID fornecido
  Servidor := FindServerByID(AID);
  if Assigned(Servidor) then
  begin
    TCPClient := TIdTCPClient.Create(nil);
    try
      TCPClient.Host := Servidor.IPAddress;
      TCPClient.Port := Servidor.IPPort;
      try
        TCPClient.ConnectTimeout := 5000; // Timeout de 5 segundos
        TCPClient.Connect;
        Result := TCPClient.Connected;
      except
        Result := False;
      end;
    finally
      TCPClient.Free;
    end;
  end
  else
  begin
    // Se o servidor n�o for encontrado, retornar false
    Result := False;
  end;
end;

class function TServerController.CreateServer(AName, AIPAddress: string;
  AIPPort: Integer): TJSONObject;
var
  Servidor: TServer;
begin
  Servidor := TServer.Create;
  try
    Servidor.ID := TGUID.NewGuid;
    Servidor.Name := AName;
    Servidor.IPAddress := AIPAddress;
    Servidor.IPPort := AIPPort;
    ServerList.Add(Servidor);
    Result := TJson.ObjectToJsonObject(Servidor);
  except
    Servidor.Free;
    raise;
  end;
end;

class function TServerController.CreateVideo(Server: TServer; Description,
  Content: String; InclusionDate: TDateTime): TJSONObject;
var
  Video: TVideo;
begin
  if not Assigned(Server.VideoList) then
    Server.VideoList := TObjectList<TVideo>.Create;

  Video := TVideo.Create;
  try
    Video.ID := TGUID.NewGuid;
    Video.Description := Description;
    Video.Content := TNetEncoding.Base64.DecodeStringToBytes(Content);
    Video.DataInclusao := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', InclusionDate);
    Server.VideoList.Add(Video);
    Result := TJson.ObjectToJsonObject(Video);
  except
    Video.Free;
    raise;
  end;
end;

class function TServerController.DeleteServer(AID: TGUID): Boolean;
var
  Servidor: TServer;
begin
  for Servidor in ServerList do
  begin
    if Servidor.ID = AID then
    begin
      ServerList.Remove(Servidor);
      Servidor.Free;
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;

class function TServerController.DeleteVideo(ServerID, VideoID: TGUID): Boolean;
var
  Servidor: TServer;
  Video: TVideo;
begin
  for Servidor in ServerList do
  begin
    if Servidor.ID = ServerID then
    begin
      for Video in Servidor.VideoList do
      begin
        if Video.ID = VideoID then
        begin
          Servidor.VideoList.Remove(Video);
          Result := True;
        end;
      end;

      Servidor.Free;
      Exit;
    end;
  end;
  Result := False;
end;

class function TServerController.DownloadBinaryVideo(Video: TVideo): TStream;
begin
  Result := TMemoryStream.Create;
  try
    Result.WriteBuffer(Video.Content[0], Length(Video.Content));
    Result.Position := 0;
  except
    Result.Free;
    raise;
  end;
end;

class function TServerController.FindServerByID(AID: TGUID): TServer;
var
  Servidor: TServer;
begin
  Result := nil;

  for Servidor in ServerList do
  begin
    if Servidor.ID = AID then
    begin
      Result := Servidor;
      Exit;
    end;
  end;
end;

class function TServerController.FindServerByName(ServerName: String): TServer;
var
  Servidor: TServer;
begin
  Result := nil;

  for Servidor in ServerList do
  begin
    if Servidor.Name = ServerName then
    begin
      Result := Servidor;
      Exit;
    end;
  end;
end;

class function TServerController.FindVideoByIDs(ServerID,
  VideoID: TGUID): TVideo;
var
  Servidor: TServer;
  Video: TVideo;
begin
  Result := nil;

  for Servidor in ServerList do
  begin
    if Servidor.ID = ServerID then
    begin
      for Video in Servidor.VideoList do
        if Video.ID = VideoID then
        begin
          Result := Video;
          Exit;
        end;
    end;
  end;
end;

class function TServerController.GetAllServers: TJSONArray;
var
  Servidor: TServer;
  JSONArray: TJSONArray;
begin
  JSONArray := TJSONArray.Create;
  try
    for Servidor in ServerList do
    begin
      JSONArray.AddElement(TJson.ObjectToJsonObject(Servidor));
    end;
    Result := JSONArray;
  except
    JSONArray.Free;
    raise;
  end;
end;

class function TServerController.GetAllVideos: TJSONArray;
var
  Video: TVideo;
  Servidor: TServer;
  JSONArray: TJSONArray;
begin
  JSONArray := TJSONArray.Create;
  try
    for Servidor in ServerList do
    begin
      for Video in Servidor.VideoList do
        JSONArray.AddElement(TJson.ObjectToJsonObject(Video));
    end;
    Result := JSONArray;
  except
    JSONArray.Free;
    raise;
  end;
end;

class function TServerController.GetServer(AID: TGUID): TJSONObject;
var
  Servidor: TServer;
begin
  for Servidor in ServerList do
  begin
    if Servidor.ID = AID then
    begin
      Result := TJson.ObjectToJsonObject(Servidor);
      Exit;
    end;
  end;
  Result := nil;
end;

class function TServerController.GetVideo(ServerID, VideoID: TGUID): TJSONObject;
var
  Servidor: TServer;
  Video: TVideo;
begin
  for Servidor in ServerList do
  begin
    if Servidor.ID = ServerID then
    begin
      for Video in Servidor.VideoList do
        if Video.ID = VideoID then
        begin
          Result := TJson.ObjectToJsonObject(Video);
          Exit;
        end;
    end;
  end;
  Result := nil;
end;


class procedure TServerController.LoadServersToComboBox(ComboBox: TComboBox);
var
  HttpClient: THttpClient;
  Response: IHTTPResponse;
  JSONValue: TJSONValue;
  JSONArray: TJSONArray;
  i: Integer;
begin
  HttpClient := THttpClient.Create;
  try
    Response := HttpClient.Get('http://localhost:8080/api/servers');
    if Response.StatusCode = 200 then
    begin
      JSONValue := TJSONObject.ParseJSONValue(Response.ContentAsString);
      try
        JSONArray := JSONValue as TJSONArray;
        for i := 0 to JSONArray.Count - 1 do
        begin
          ComboBox.Items.Add(JSONArray.Items[i].GetValue<string>('name'));
        end;
      finally
        JSONValue.Free;
      end;
    end
    else
      ShowMessage('Failed to load servers. Status code: ' + Response.StatusCode.ToString);
  finally
    HttpClient.Free;
  end;
end;

class function TServerController.UpdateServer(AID: TGUID; AName, AIPAddress: string;
  AIPPort: Integer): TJSONObject;
var
  Servidor: TServer;
begin
  for Servidor in ServerList do
  begin
    if Servidor.ID = AID then
    begin
      Servidor.Name := AName;
      Servidor.IPAddress := AIPAddress;
      Servidor.IPPort := AIPPort;
      Result := TJson.ObjectToJsonObject(Servidor);
      Exit;
    end;
  end;
  Result := nil;
end;

end.

