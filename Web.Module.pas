unit Web.Module;

interface

uses
  System.SysUtils, System.Classes, Web.HTTPApp, Datasnap.DSHTTPCommon,
  Datasnap.DSHTTPWebBroker, Datasnap.DSServer,
  Web.WebFileDispatcher, Web.HTTPProd,
  DataSnap.DSAuth,
  Datasnap.DSProxyJavaScript, IPPeerServer, Datasnap.DSMetadata,
  Datasnap.DSServerMetadata, Datasnap.DSClientMetadata, Datasnap.DSCommonServer,
  Datasnap.DSHTTP, System.JSON, REST.Json, Server.Controller,
  Server.Model, Server.Container;

type
  TWebModule1 = class(TWebModule)
    DSHTTPWebDispatcher1: TDSHTTPWebDispatcher;
    WebFileDispatcher1: TWebFileDispatcher;
    DSProxyGenerator1: TDSProxyGenerator;
    DSServerMetaDataProvider1: TDSServerMetaDataProvider;
    procedure WebModule1DefaultHandlerAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure WebFileDispatcher1BeforeDispatch(Sender: TObject;
      const AFileName: string; Request: TWebRequest; Response: TWebResponse;
      var Handled: Boolean);
    procedure WebModuleCreate(Sender: TObject);
    procedure WebModuleBeforeDispatch(Sender: TObject; Request: TWebRequest;
      Response: TWebResponse; var Handled: Boolean);
  private
    function GetIDsFromURL(const URL: string; out ServerID, VideoID: TGUID): Boolean;
    function FindServerByID(AID: TGUID): TServer;
    procedure PostVideoToServer(JSONObj: TJSONObject);
    procedure PostCreateServer(JSONOBj: TJSONObject);
    procedure PostDownloadBinaryVideo;
    procedure PutUpdateServer(JSONOBj: TJSONObject);
    procedure DeleteServer(JSONOBj: TJSONObject);
    procedure DeleteVideo(JSONOBj: TJSONObject); 
    procedure DeleteVideoRecyclerProcess(JSONOBj: TJSONObject); 
    procedure GetServerAvailable;
    procedure GetServer;
    procedure GetVideo;
    procedure GetAllServers;
    procedure GetAllVideos;
    procedure GetRecyclerStatus;

    var
      RecyclerIsRunning: Boolean;
  public
    { Public declarations }
  end;

var
  WebModuleClass: TComponentClass = TWebModule1;

implementation


{$R *.dfm}

uses Web.WebReq, System.StrUtils, System.DateUtils, Videos.Model;

procedure TWebModule1.WebModule1DefaultHandlerAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
begin
  Response.Content :=
    'Nenhuma a��o foi encontrada para esse caminho! Verfique se o caminho confere com os URLs pr�-estabelecidos: ' + #13+
    ' /api/server' + #13+
    ' /api/servers/{serverId}' + #13+
    ' /api/servers/available/{serverId}' + #13+
    ' /api/servers' + #13+
    ' /api/servers/{serverId}/videos' + #13+
    ' /api/servers/{serverId}/videos/{videoId}' + #13+
    ' /api/servers/{serverId}/videos/{videoId}/binary' + #13+
    ' /api/servers/{serverId}/vid' + #13+
    ' /api/recycler/process/{days}' + #13+
    ' /api/recycler/status' + #13;
end;

procedure TWebModule1.WebModuleBeforeDispatch(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  JSONObj: TJSONObject;
begin
  JSONObj := TJSONObject.ParseJSONValue(Request.Content) as TJSONObject;
  try
    if Request.Method = 'GET' then
    begin
      if ContainsText(Request.PathInfo, '/servers/available/') then
        GetServerAvailable;

      if ContainsText(Request.PathInfo, '/servers/') and not (ContainsText(Request.PathInfo, '/available/')  or ContainsText(Request.PathInfo,  '/videos/') or ContainsText(Request.PathInfo,  '/videos')) then
        GetServer;

      if Request.PathInfo = '/servers' then
        GetAllServers;

      //VERIFICAR
      if ContainsText(Request.PathInfo, '/servers/') and ContainsText(Request.PathInfo, '/videos/') then
          GetVideo;

      //VERIFICAR
      if ContainsText(Request.PathInfo, '/servers/') and ContainsText(Request.PathInfo, '/videos') then
          GetAllVideos;

      if Request.PathInfo = '/recycler/status' then
          GetRecyclerStatus;
    end
    else if Assigned(JSONObj) then
    begin
      if Request.Method = 'POST' then
      begin
        if (Request.PathInfo = '/servers/video') then
          PostVideoToServer(JSONObj); // mudar

        if Request.PathInfo = '/servers' then
          PostCreateServer(JSONOBj);

        if ContainsText(Request.PathInfo, '/servers/') and ContainsText(Request.PathInfo, '/videos/') and ContainsText(Request.PathInfo, '/binary') then
          PostDownloadBinaryVideo;
      end;

      if Request.Method = 'PUT' then
      begin
        if StartsText('/servers/', Request.PathInfo) then
          PutUpdateServer(JSONOBj);
      end;

      if Request.Method = 'DELETE' then
      begin
        if ContainsText(Request.PathInfo, '/servers/') and not ContainsText(Request.PathInfo, '/videos/') then
          DeleteServer(JSONObj);

        // VERIFICAR
        if ContainsText(Request.PathInfo, '/servers/') and ContainsText(Request.PathInfo, '/videos/') then
          DeleteVideo(JSONObj);

        if ContainsText(Request.PathInfo, '/recycler/process/') then
          DeleteVideoRecyclerProcess(JSONObj);
      end;
    end
    else
    begin
      Response.StatusCode := 400;
      Response.Content := '{"error":"Invalid JSON"}';
    end;
  finally
    Handled := True;
    JSONObj.Free;
  end;
end;

procedure TWebModule1.DeleteServer(JSONOBj: TJSONObject);
var
  ServerID: TGUID;
begin

  try
    ServerID := StringToGUID(Copy(Request.PathInfo, Length('/servers/') + 1));
  except
  on E: Exception do
    begin
      Response.StatusCode := 400; // Bad Request
      Response.Content := '{"error":"Invalid server ID"}';

      Exit;
    end;
  end;

  if TServerController.DeleteServer(ServerID) then
  begin
    Response.StatusCode := 204; // No Content (Sucess, no response needed)
  end
  else
  begin
    Response.StatusCode := 404; // Not Found
    Response.Content := '{"error":"Server not found"}';
  end;
end;

procedure TWebModule1.DeleteVideo(JSONOBj: TJSONObject);
var
  ServerID, VideoID: TGUID;
  URL: string;
begin
  URL := '/api/servers/{serverId}/videos/{videoId}';

  if GetIDsFromURL(URL, ServerID, VideoID) then
    if TServerController.DeleteVideo(ServerID, VideoID) then
    begin
      Response.StatusCode := 204; // No Content (Sucess, no response needed)
    end
    else
    begin
      Response.StatusCode := 404; // Not Found
      Response.Content := '{"error":"Video not found"}';
    end;
end;

procedure TWebModule1.DeleteVideoRecyclerProcess(JSONOBj: TJSONObject);
var
  DaysStr: string;
  Days: Integer;
  Video: TVideo;
  CurrentDate: TDateTime;
  Server: TServer;
begin
  DaysStr := Copy(Request.PathInfo, Length('/recycler/process/') + 1);

  if TryStrToInt(DaysStr, Days) then
  begin
    CurrentDate := Now;
    RecyclerIsRunning := True;
    
    for Server in ServerList do
    begin
      for Video in Server.VideoList do
      begin
        if DaysBetween(Video.DataInclusao, CurrentDate) > Days then
        begin
          Server.VideoList.Remove(Video);
          Video.Free;
        end;
      end;
    end;
          
    RecyclerIsRunning := False;
    Response.StatusCode := 204; 
  end
  else
  begin
    Response.StatusCode := 400; // Bad Request
    Response.Content := TJSONObject.Create.AddPair('error', 'Invalid days parameter').ToString;
  end;
end;

function TWebModule1.FindServerByID(AID: TGUID): TServer;
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

procedure TWebModule1.GetAllServers;
var
  ServerListJSON: TJSONArray;
begin
  ServerListJSON := TServerController.GetAllServers;
  try
    Response.ContentType := 'application/json';
    Response.Content := ServerListJSON.ToString;
  finally
    ServerListJSON.Free;
  end;
end;

procedure TWebModule1.GetAllVideos;
var
  VideoListJSON: TJSONArray;
begin
  VideoListJSON := TServerController.GetAllVideos;
  try
    Response.ContentType := 'application/json';
    Response.Content := VideoListJSON.ToString;
  finally
    VideoListJSON.Free;
  end;
end;


function TWebModule1.GetIDsFromURL(const URL: string; out ServerID, VideoID: TGUID): Boolean;
var
  ServerIDStr, VideoIDStr: string;
  ServerIDPos, VideoIDPos: Integer;
begin
  ServerIDPos := Pos('/api/servers/', URL);
  if ServerIDPos = 0 then
  begin
    Result := False;
    Exit;
  end;

  VideoIDPos := Pos('/videos/', URL);
  if VideoIDPos = 0 then
  begin
    Result := False;
    Exit;
  end;

  ServerIDStr := Copy(URL, ServerIDPos + Length('/api/servers/'), VideoIDPos - ServerIDPos - Length('/api/servers/'));
  VideoIDStr := Copy(URL, VideoIDPos + Length('/videos/'), Length(URL) - VideoIDPos - Length('/videos/'));

  try
    ServerID := StringToGUID(ServerIDStr);
    VideoID := StringToGUID(VideoIDStr);
    Result := True;
  except
    Result := False;
  end;
end;

procedure TWebModule1.GetRecyclerStatus;
begin
  if RecyclerIsRunning then
    Response.Content := TJSONObject.Create.AddPair('status', 'is running').ToString
  else
    Response.Content := TJSONObject.Create.AddPair('status', 'not running').ToString;
  Response.StatusCode := 200; 
end;

procedure TWebModule1.GetServer;
var
  ServerID: TGUID;
  ServerJSON: TJSONObject;
begin

  try
    ServerID := StringToGUID(Copy(Request.PathInfo, Length('/servers/') + 1));
  except
    on E: Exception do
    begin
      Response.StatusCode := 400; // Bad Request
      Response.Content := '{"error":"Invalid server ID"}';
      Exit;
    end;
  end;

  ServerJSON := TServerController.GetServer(ServerID);
  try
    if Assigned(ServerJSON) then
    begin
      Response.ContentType := 'application/json';
      Response.Content := ServerJSON.ToString;
    end
    else
    begin
      Response.StatusCode := 404; // Not Found
      Response.Content := '{"error":"Server not found"}';
    end;
    finally
      ServerJSON.Free;
    end;
end;

procedure TWebModule1.GetServerAvailable;
var
  ServerID: TGUID;
  ServerAvailable: Boolean;
  Server : TServer;
  JSONObjResponse : TJSONObject;
begin

  try
    ServerID := StringToGUID(Copy(Request.PathInfo, Length('/servers/available/') + 1, MaxInt));
  except
    on E: Exception do
    begin
      Response.StatusCode := 400; // Bad Request
      Response.Content := '{"error":"Invalid server ID"}';
      Exit;
    end;
  end;

  Server := FindServerByID(ServerID);
  if not Assigned(Server) then
  begin
    Response.StatusCode := 404; // Not Found
    Response.Content := '{"error":"Server not found"}';
    Exit;
  end;

  ServerAvailable := TServerController.CheckServerAvailability(ServerID);

  JSONObjResponse := TJSONObject.Create;
  try
    JSONObjResponse.AddPair('ip_address', Server.IPAddress);
    JSONObjResponse.AddPair('ip_port', Server.IPPort.ToString);
    JSONObjResponse.AddPair('available', TJSONBool.Create(ServerAvailable));

    Response.ContentType := 'application/json';
    Response.Content := JSONObjResponse.ToString;
  finally
    JSONObjResponse.Free;
  end;
end;

procedure TWebModule1.GetVideo;
var
  ServerID, VideoID: TGUID;
  VideoJSON: TJSONObject;
  URL: String;
begin
  URL := '/api/servers/{serverId}/videos/{videoId}';

  if GetIDsFromURL(URL, ServerID, VideoID) then
    VideoJSON := TServerController.GetVideo(ServerID, VideoID);
    try
      if Assigned(VideoJSON) then
      begin
        Response.ContentType := 'application/json';
        Response.Content := VideoJSON.ToString;
      end
      else
      begin
        Response.StatusCode := 404; // Not Found
        Response.Content := '{"error":"Server not found"}';
      end;
      finally
        VideoJSON.Free;
      end;
end;

procedure TWebModule1.PostCreateServer(JSONOBj: TJSONObject);
var
  ServerName, ServerIPAddress: string;
  ServerIPPort: Integer;
  ServerJSON: TJSONObject;
begin
  ServerName := JSONObj.GetValue<string>('name');
  ServerIPAddress := JSONObj.GetValue<string>('ip_address');
  ServerIPPort := JSONObj.GetValue<Integer>('ip_port');

  ServerJSON := TServerController.CreateServer(ServerName, ServerIPAddress, ServerIPPort);

  Response.ContentType := 'application/json';
  Response.Content := ServerJSON.ToString;

  Response.StatusCode := 201;
end;

procedure TWebModule1.PostDownloadBinaryVideo;
var
  ServerID, VideoID: TGUID;
  Server: TServer;
  Video: TVideo;
  VideoJSON: TJSONObject;
  URL: String;
begin
  URL := '/servers/{serverId}/videos/{videoId}/binary';

  if GetIDsFromURL(URL, ServerID, VideoID) then
  begin     
  
    Server := TServerController.FindServerByID(ServerID);     
    Video := TServerController.FindVideoByIDs(ServerID, VideoID);

    if Assigned(Video) and Assigned(Server) then
    begin
      TServerController.DownloadBinaryVideo(Video);
      Response.StatusCode := 204; // No Content (Sucess, no response needed)
    end
    else
    begin
      Response.StatusCode := 404; // Not Found
      Response.Content := '{"error":"Video not found"}';
    end;

  end;
end;

procedure TWebModule1.PostVideoToServer(JSONObj: TJSONObject);
var
  ServerID: TGUID;
  Description: string;
  Content: string;
  InclusionDate: TDateTime;
  VideoJSON: TJSONObject;
begin
  ServerID := StringToGUID(JSONObj.GetValue<string>('server_id'));
  Description := JSONObj.GetValue<string>('description');
  Content := JSONObj.GetValue<string>('content');
  InclusionDate := ISO8601ToDate(JSONObj.GetValue<string>('inclusion_date'));

  VideoJSON := TServerController.AddVideo(ServerID, Description, Content, InclusionDate);

  Response.ContentType := 'application/json';
  Response.Content := VideoJSON.ToString;
  Response.StatusCode := 201;
end;

procedure TWebModule1.PutUpdateServer(JSONOBj: TJSONObject);
var
  ServerName, ServerIPAddress: string;
  ServerIPPort: Integer;
  ServerID: TGUID;
  ServerJSON: TJSONObject;
begin

  try
   ServerID := StringToGUID(Copy(Request.PathInfo, Length('/servers/') + 1));
  except
  on E: Exception do
    begin
      Response.StatusCode := 400; // Bad Request
      Response.Content := '{"error":"Invalid server ID"}';

      Exit;
    end;
  end;

  ServerName := JSONObj.GetValue<string>('name');
  ServerIPAddress := JSONObj.GetValue<string>('ip_address');
  ServerIPPort := JSONObj.GetValue<Integer>('ip_port');

  ServerJSON := TServerController.UpdateServer(ServerID, ServerName, ServerIPAddress, ServerIPPort);

  if Assigned(ServerJSON) then
  begin
    Response.ContentType := 'application/json';
    Response.Content := ServerJSON.ToString;

    Response.StatusCode := 200;
  end;
end;

procedure TWebModule1.WebFileDispatcher1BeforeDispatch(Sender: TObject;
  const AFileName: string; Request: TWebRequest; Response: TWebResponse;
  var Handled: Boolean);
var
  D1, D2: TDateTime;
begin
  Handled := False;
  if SameFileName(ExtractFileName(AFileName), 'serverfunctions.js') then
    if not FileExists(AFileName) or (FileAge(AFileName, D1) and FileAge(WebApplicationFileName, D2) and (D1 < D2)) then
    begin
      DSProxyGenerator1.TargetDirectory := ExtractFilePath(AFileName);
      DSProxyGenerator1.TargetUnitName := ExtractFileName(AFileName);
      DSProxyGenerator1.Write;
    end;
end;

procedure TWebModule1.WebModuleCreate(Sender: TObject);
begin
  DSServerMetaDataProvider1.Server := DSServer;
  DSHTTPWebDispatcher1.Server := DSServer;
  if DSServer.Started then
  begin
    DSHTTPWebDispatcher1.DbxContext := DSServer.DbxContext;
    DSHTTPWebDispatcher1.Start;
  end;
end;

initialization
finalization
  Web.WebReq.FreeWebModules;

end.

