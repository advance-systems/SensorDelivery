unit uFrameProdutoMobile;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  System.UITypes,
  System.Diagnostics,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Objects,
  FMX.StdCtrls,
  FMX.Layouts,
  FMX.Graphics, FMX.Controls.Presentation,
  System.Net.URLClient, System.Net.HttpClient;

type
  TProdutoMobileClickEvent = procedure(
    Sender: TObject;
    const AProdutoId: string
  ) of object;

  TfraProdutoMobile = class(TFrame)
    rctFundo: TRectangle;
    imgProduto: TImage;
    lytInfo: TLayout;
    lblNome: TLabel;
    lblDescricao: TLabel;
    rctImagem: TRectangle;
    lblAPartir: TLabel;
    lblPreco: TLabel;
    rctAdicionar: TRectangle;
    lblAdicionar: TLabel;

    procedure rctFundoClick(Sender: TObject);
    procedure rctAdicionarClick(Sender: TObject);
    procedure rctFundoMouseEnter(Sender: TObject);
    procedure rctFundoMouseLeave(Sender: TObject);
  private
    FProdutoId: string;
    FDescricao: string;
    FPreco: Currency;
    FOnProdutoClick: TProdutoMobileClickEvent;
    FOnAdicionarClick: TProdutoMobileClickEvent;
    FVariacaoId: string;
    FVariacaoNome: string;
    FVariacaoPreco: Currency;
    FControlePressionado: TControl;
    FToqueInicio: TPointF;
    FToqueInicioHorario: Int64;

    procedure AtualizarVisual;
    procedure CarregarImagemAsync(const AURL: string);
    procedure ToqueMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure ToqueMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
  public
    property VariacaoId: string
      read FVariacaoId
      write FVariacaoId;

    property VariacaoNome: string
      read FVariacaoNome
      write FVariacaoNome;

    property VariacaoPreco: Currency
      read FVariacaoPreco
      write FVariacaoPreco;

    constructor Create(AOwner: TComponent); override;

    procedure Preencher(
      const AProdutoId: string;
      const ANome: string;
      const ADescricao: string;
      const APreco: Currency;
      const AImagemURL: string
    );

//    procedure CarregarImagem(const AURL: string);

    property ProdutoId: string read FProdutoId;

    property OnProdutoClick: TProdutoMobileClickEvent
      read FOnProdutoClick
      write FOnProdutoClick;

    property OnAdicionarClick: TProdutoMobileClickEvent
      read FOnAdicionarClick
      write FOnAdicionarClick;
  end;

implementation

{$R *.fmx}

uses uApiConfig;

constructor TfraProdutoMobile.Create(AOwner: TComponent);
begin
  inherited;

  FProdutoId := '';
  FDescricao := '';
  FPreco := 0;
  FControlePressionado := nil;

  rctFundo.OnClick := nil;
  rctFundo.OnMouseDown := ToqueMouseDown;
  rctFundo.OnMouseUp := ToqueMouseUp;
  rctAdicionar.OnClick := nil;
  rctAdicionar.OnMouseDown := ToqueMouseDown;
  rctAdicionar.OnMouseUp := ToqueMouseUp;

  imgProduto.WrapMode := TImageWrapMode.Fit;
  imgProduto.Visible := False;

  AtualizarVisual;
end;

procedure TfraProdutoMobile.Preencher(
  const AProdutoId: string;
  const ANome: string;
  const ADescricao: string;
  const APreco: Currency;
  const AImagemURL: string);
begin
  FProdutoId := AProdutoId;
  FDescricao := ADescricao;
  FPreco := APreco;

  lblNome.Text := ANome;
  lblDescricao.Text := ADescricao;

  lblPreco.Text :=
    FormatFloat(
      '"R$ " #,##0.00',
      APreco
    );

  CarregarImagemAsync(AImagemURL);
end;

procedure TfraProdutoMobile.ToqueMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if not (Sender is TControl) then
    Exit;
  FControlePressionado := TControl(Sender);
  FToqueInicio := PointF(X, Y);
  FToqueInicioHorario := TStopwatch.GetTimeStamp;
end;

procedure TfraProdutoMobile.ToqueMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
const
  TOLERANCIA_MOVIMENTO = 12;
  TEMPO_MINIMO_MS = 50;
var
  LDuracaoMS: Int64;
begin
  try
    LDuracaoMS := ((TStopwatch.GetTimeStamp - FToqueInicioHorario) * 1000)
      div TStopwatch.Frequency;
    if (Sender <> FControlePressionado) or
       (Abs(X - FToqueInicio.X) > TOLERANCIA_MOVIMENTO) or
       (Abs(Y - FToqueInicio.Y) > TOLERANCIA_MOVIMENTO) or
       (LDuracaoMS < TEMPO_MINIMO_MS) then
      Exit;

    if Sender = rctAdicionar then
      rctAdicionarClick(Sender)
    else if Sender = rctFundo then
      rctFundoClick(Sender);
  finally
    FControlePressionado := nil;
  end;
end;

procedure TfraProdutoMobile.CarregarImagemAsync(const AURL: string);
var
  LURL: string;
begin
  imgProduto.Bitmap.Clear(TAlphaColors.Null);
  imgProduto.Visible := False;

  LURL := AURL.Trim;
  if LURL.IsEmpty then
    Exit;
  if LURL.StartsWith('/') then
    LURL := TApiConfig.Url(LURL);

  TThread.CreateAnonymousThread(
    procedure
    var
      LHTTP: THTTPClient;
      LResposta: IHTTPResponse;
      LConteudo: TMemoryStream;
    begin
      LHTTP := THTTPClient.Create;
      LConteudo := TMemoryStream.Create;
      try
        try
          LHTTP.ConnectionTimeout := 4000;
          LHTTP.ResponseTimeout := 7000;
          LResposta := LHTTP.Get(LURL, LConteudo);
          if (LResposta.StatusCode >= 200) and
             (LResposta.StatusCode < 300) then
          begin
            TThread.Synchronize(nil,
              procedure
              begin
                if not (csDestroying in ComponentState) then
                begin
                  LConteudo.Position := 0;
                  imgProduto.Bitmap.LoadFromStream(LConteudo);
                  imgProduto.Visible := True;
                  imgProduto.BringToFront;
                end;
              end);
          end;
        except
          { O card permanece disponível mesmo se a imagem falhar. }
        end;
      finally
        LConteudo.Free;
        LHTTP.Free;
      end;
    end).Start;
end;

procedure TfraProdutoMobile.AtualizarVisual;
begin
  rctFundo.Fill.Color := $FFFFFFFF;
  rctFundo.Stroke.Kind := TBrushKind.Solid;
  rctFundo.Stroke.Color := $FFE6E6E6;
  rctFundo.Stroke.Thickness := 1;

  rctFundo.XRadius := 18;
  rctFundo.YRadius := 18;
end;

procedure TfraProdutoMobile.rctFundoMouseEnter(
  Sender: TObject);
begin
  rctFundo.Fill.Color := $FFFFFAF7;
end;

procedure TfraProdutoMobile.rctFundoMouseLeave(
  Sender: TObject);
begin
  AtualizarVisual;
end;

procedure TfraProdutoMobile.rctFundoClick(Sender: TObject);
begin
  if Assigned(FOnProdutoClick) then
    FOnProdutoClick(
      Self,
      FProdutoId
    );
end;

procedure TfraProdutoMobile.rctAdicionarClick(Sender: TObject);
begin
  if Assigned(FOnAdicionarClick) then
    FOnAdicionarClick(
      Self,
      FProdutoId
    );
end;

end.
