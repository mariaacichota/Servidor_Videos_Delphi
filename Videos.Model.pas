unit Videos.Model;

interface

uses
  System.SysUtils;

type
  TVideo = class
  private
    FID: TGUID;
    FDescription: string;
    FContent: TBytes;
    FDataInclusao: TDate;

  public
    property ID: TGUID read FID write FID;
    property Description: string read FDescription write FDescription;
    property Content: TBytes read FContent write FContent;
    property DataInclusao: TDate read FDataInclusao write FDataInclusao;
  end;

implementation

end.
