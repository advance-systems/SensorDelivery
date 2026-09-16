unit uFrameItemCarrinho;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Objects, FMX.Controls.Presentation, uCarrinhoModel;

type
  TItemCarrinhoEvent = procedure(
    Sender: TObject;
    AItem: TItemCarrinho
  ) of object;

  TfraItemCarrinho = class(TFrame)
    lytConteudo: TLayout;
    rctFundo: TRectangle;
    lblProduto: TLabel;
    lblDetalhes: TLabel;
    lblValor: TLabel;
    btnMenos: TCornerButton;
    lblQuantidade: TLabel;
    btnMais: TCornerButton;
    btnRemover: TCornerButton;
  private
    FItem: TItemCarrinho;

    FOnRemover: TItemCarrinhoEvent;
    FOnQuantidadeAlterada: TItemCarrinhoEvent;

    FCard: TRectangle;
    FLayoutCabecalho: TLayout;
    FLayoutConteudo: TLayout;
    FLayoutRodape: TLayout;

    FCirculoImagem: TCircle;
    FLabelImagem: TLabel;

    FLabelProduto: TLabel;
    FLabelTamanho: TLabel;
    FLabelSaboresTitulo: TLabel;
    FLabelSabores: TLabel;
    FLabelBorda: TLabel;

    FRetanguloObservacao: TRectangle;
    FLabelObservacaoTitulo: TLabel;
    FLabelObservacao: TLabel;

    FBotaoMenos: TRectangle;
    FLabelMenos: TLabel;
    FLabelQuantidade: TLabel;
    FBotaoMais: TRectangle;
    FLabelMais: TLabel;

    FLabelValorUnitario: TLabel;
    FLabelValorTotal: TLabel;

    FBotaoRemover: TRectangle;
    FLabelRemover: TLabel;

    procedure ConstruirInterface;

    function CriarLabel(
      const AParent: TFmxObject;
      const AName: string;
      const ATexto: string;
      const ATamanhoFonte: Single;
      const ACor: TAlphaColor;
      const ANegrito: Boolean = False
    ): TLabel;

    function TextoSabores: string;
    function TextoBorda: string;

    procedure BotaoMenosClick(Sender: TObject);
    procedure BotaoMaisClick(Sender: TObject);
    procedure BotaoRemoverClick(Sender: TObject);

    procedure AtualizarAltura;

  public
    constructor Create(AOwner: TComponent); override;

    procedure CarregarItem(AItem: TItemCarrinho);
    procedure Atualizar;

    property Item: TItemCarrinho
      read FItem;

    property OnRemover: TItemCarrinhoEvent
      read FOnRemover
      write FOnRemover;

    property OnQuantidadeAlterada: TItemCarrinhoEvent
      read FOnQuantidadeAlterada
      write FOnQuantidadeAlterada;
  end;

implementation

{$R *.fmx}

{ TfraItemCarrinho }

constructor TfraItemCarrinho.Create(AOwner: TComponent);
begin
  inherited;

  Width := 390;
  Height := 260;

  ConstruirInterface;
end;

function TfraItemCarrinho.CriarLabel(
  const AParent: TFmxObject;
  const AName: string;
  const ATexto: string;
  const ATamanhoFonte: Single;
  const ACor: TAlphaColor;
  const ANegrito: Boolean): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := AParent;
  Result.Name := AName;
  Result.Text := ATexto;
  Result.TextSettings.Font.Size := ATamanhoFonte;
  Result.TextSettings.FontColor := ACor;
  Result.TextSettings.HorzAlign := TTextAlign.Leading;
  Result.TextSettings.VertAlign := TTextAlign.Center;
  Result.TextSettings.WordWrap := False;
  Result.HitTest := False;

  if ANegrito then
    Result.TextSettings.Font.Style := [TFontStyle.fsBold];
end;

procedure TfraItemCarrinho.ConstruirInterface;
begin
  btnRemover.OnClick := BotaoRemoverClick;
  btnMenos.OnClick := BotaoMenosClick;
  btnMais.OnClick := BotaoMaisClick;

  lblRemover.HitTest := False;
  lblMenos.HitTest := False;
  lblQuantidade.HitTest := False;
  lblMais.HitTest := False;

  lblQuantidade.Text := '1';
  rctObservacao.Visible := False;
end;

procedure TfraItemCarrinho.CarregarItem(AItem: TItemCarrinho);
begin
  FItem := AItem;
  Atualizar;
end;

function TfraItemCarrinho.TextoSabores: string;
var
  I: Integer;
begin
  Result := '';

  if not Assigned(FItem) then
    Exit;

  for I := 0 to FItem.Sabores.Count - 1 do
  begin
    if Result <> '' then
      Result := Result + ' • ';

    Result := Result + FItem.Sabores[I].Descricao;
  end;

  if Result = '' then
    Result := 'Nenhum sabor informado';
end;

function TfraItemCarrinho.TextoBorda: string;
begin
  Result := '';

  if not Assigned(FItem) then
    Exit;

  if FItem.BordaDescricao = '' then
    Result := 'Borda: sem borda'
  else if FItem.ValorBorda > 0 then
    Result :=
      'Borda: ' +
      FItem.BordaDescricao +
      '  +' +
      FormatFloat('R$ #,##0.00', FItem.ValorBorda)
  else
    Result := 'Borda: ' + FItem.BordaDescricao;
end;

procedure TfraItemCarrinho.Atualizar;
begin
  if not Assigned(FItem) then
  begin
    Visible := False;
    Exit;
  end;

  Visible := True;

  FLabelProduto.Text :=
    FItem.ProdutoDescricao;

  FLabelTamanho.Text :=
    FItem.TamanhoDescricao +
    ' • ' +
    FItem.Sabores.Count.ToString +
    ' sabor(es)';

  FLabelSabores.Text :=
    TextoSabores;

  FLabelBorda.Text :=
    TextoBorda;

  FLabelValorUnitario.Text :=
    'Valor unitário: ' +
    FormatFloat(
      'R$ #,##0.00',
      FItem.ValorUnitario
    );

  FLabelQuantidade.Text :=
    FItem.Quantidade.ToString;

  FLabelValorTotal.Text :=
    FormatFloat(
      'R$ #,##0.00',
      FItem.ValorTotal
    );

  FLabelObservacao.Text :=
    Trim(FItem.Observacao);

  FRetanguloObservacao.Visible :=
    Trim(FItem.Observacao) <> '';

  AtualizarAltura;
end;

procedure TfraItemCarrinho.AtualizarAltura;
begin
  if FRetanguloObservacao.Visible then
  begin
    Height := 316;
    FCard.Height := Height - 8;
  end
  else
  begin
    Height := 250;
    FCard.Height := Height - 8;
  end;
end;

procedure TfraItemCarrinho.BotaoMenosClick(Sender: TObject);
begin
  if not Assigned(FItem) then
    Exit;

  if FItem.Quantidade > 1 then
  begin
    Dec(FItem.Quantidade);
    Atualizar;

    if Assigned(FOnQuantidadeAlterada) then
      FOnQuantidadeAlterada(Self, FItem);
  end;
end;

procedure TfraItemCarrinho.BotaoMaisClick(Sender: TObject);
begin
  if not Assigned(FItem) then
    Exit;

  Inc(FItem.Quantidade);
  Atualizar;

  if Assigned(FOnQuantidadeAlterada) then
    FOnQuantidadeAlterada(Self, FItem);
end;

procedure TfraItemCarrinho.BotaoRemoverClick(Sender: TObject);
begin
  if not Assigned(FItem) then
    Exit;

  if Assigned(FOnRemover) then
    FOnRemover(Self, FItem);
end;

end.
