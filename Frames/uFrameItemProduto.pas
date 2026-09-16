unit uFrameItemProduto;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation;

type
  TfraItemProduto = class(TFrame)
    rctFundo: TRectangle;
    lblQuantidade: TLabel;
    lblProduto: TLabel;
    lblComplementos: TLabel;
    lblValor: TLabel;
  private
    { Private declarations }
  public
    procedure Preencher(const AQuantidade: Integer; const AProduto,
      AComplementos: string; const AValor: Currency);
  end;

implementation

{$R *.fmx}

procedure TfraItemProduto.Preencher(
  const AQuantidade: Integer;
  const AProduto: string;
  const AComplementos: string;
  const AValor: Currency);
begin
  lblQuantidade.Text := AQuantidade.ToString + 'x';
  lblProduto.Text := AProduto;
  lblComplementos.Text := AComplementos;
  lblValor.Text := FormatFloat('"R$ " #,##0.00', AValor);
end;

end.
