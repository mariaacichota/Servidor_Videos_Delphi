unit Server.Testes;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TServidorDelphiTestes = class
  public
    [Test]
    procedure TestFindServerByID;
  end;

implementation

uses
  Server.Model, System.SysUtils, Server.Controller;

{ TServidorDelphiTestes }

procedure TServidorDelphiTestes.TestFindServerByID;
var
  ServerID: TGUID;
  Server: TServer;
begin
  ServerID := StringToGUID('{BF9EADEA-3F71-4008-97BD-A192AB797307}');
  Server := TServerController.FindServerByID(ServerID);
  Assert.IsNotNull(Server, 'Server should not be null');
  Assert.AreEqual(ServerID, Server.ID, 'Server ID should match');
end;

initialization
  TDUnitX.RegisterTestFixture(TServidorDelphiTestes);

end.
