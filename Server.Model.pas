unit Server.Model;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, Videos.Model;

type
  TServer = class
  private
    FID: TGUID;
    FName: string;
    FIPAddress: string;
    FIPPort: Integer;
    FVideoList: TObjectList<TVideo>;
  public
    property ID: TGUID read FID write FID;
    property Name: string read FName write FName;
    property IPAddress: string read FIPAddress write FIPAddress;
    property IPPort: Integer read FIPPort write FIPPort;
    property VideoList: TObjectList<TVideo> read FVideoList write FVideoList;
  end;

var
  ServerList: TList<TServer>;

implementation

initialization
  ServerList := TList<TServer>.Create;

finalization
  ServerList.Free;

end.
