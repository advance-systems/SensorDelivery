unit uFramePagamentoPix;

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes,
  System.NetEncoding, System.JSON, System.Net.URLClient,
  System.Net.HttpClient, System.Net.HttpClientComponent,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Objects,
  FMX.Layouts, FMX.StdCtrls, FMX.Memo, FMX.ScrollBox,
  FMX.Controls.Presentation, FMX.Platform;

type
  TfraPagamentoPix = class(TFrame)
  private
    FFundo, FTopo, FCardQr, FCardCodigo, FBtnCopiar,
      FBtnContinuar: TRectangle;
    FScroll: TVertScrollBox;
    FConteudo, FAreaQr: TLayout;
    FTitulo, FSubtitulo, FPedido, FValor, FInstrucao,
      FCopiarTexto, FContinuarTexto, FStatusPagamento: TLabel;
    FQrImage: TImage;
    FCodigoMemo: TMemo;
    FCodigoPix: string;
    FPedidoId: string;
    FSegundosRestantes: Integer;
    FConsultando: Boolean;
    FCancelado: Boolean;
    FTimer: TTimer;
    FOnContinuar: TNotifyEvent;
    FOnCancelado: TNotifyEvent;
    function CriarRotulo(const AParent: TFmxObject; const ATexto: string;
      const AX, AY, ALargura, AAltura, ATamanho: Single;
      const ACor: TAlphaColor; const ANegrito: Boolean = False): TLabel;
    procedure MontarTela;
    procedure CarregarImagemQr(const ABase64: string);
    procedure CopiarClick(Sender: TObject);
    procedure ContinuarClick(Sender: TObject);
    procedure TimerStatus(Sender: TObject);
    procedure ConsultarStatus;
    procedure AtualizarTextoEspera;
    procedure FrameResize(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure Exibir(const APedidoId, ACodigoPix, AQRCodeBase64: string;
      const AValor: Currency; const ANumeroPedido: Integer);
    property OnContinuar: TNotifyEvent read FOnContinuar write FOnContinuar;
    property OnCancelado: TNotifyEvent read FOnCancelado write FOnCancelado;
  end;

implementation

uses
  uMensagemMobile, uApiConfig;

constructor TfraPagamentoPix.Create(AOwner: TComponent);
begin
  inherited;
  Width := 390;
  Height := 760;
  OnResize := FrameResize;
  MontarTela;
  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := 2000;
  FTimer.OnTimer := TimerStatus;
end;

function TfraPagamentoPix.CriarRotulo(const AParent: TFmxObject;
  const ATexto: string; const AX, AY, ALargura, AAltura, ATamanho: Single;
  const ACor: TAlphaColor; const ANegrito: Boolean): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := AParent;
  Result.Position.Point := PointF(AX, AY);
  Result.Width := ALargura;
  Result.Height := AAltura;
  Result.Text := ATexto;
  Result.StyledSettings := [];
  Result.TextSettings.Font.Family := 'Manrope';
  Result.TextSettings.Font.Size := ATamanho;
  Result.TextSettings.FontColor := ACor;
  if ANegrito then
    Result.TextSettings.Font.Style := [TFontStyle.fsBold];
  Result.HitTest := False;
end;

procedure TfraPagamentoPix.MontarTela;
begin
  FFundo := TRectangle.Create(Self);
  FFundo.Parent := Self;
  FFundo.Align := TAlignLayout.Client;
  FFundo.Fill.Color := $FFF7F7FA;
  FFundo.Stroke.Kind := TBrushKind.None;

  FTopo := TRectangle.Create(Self);
  FTopo.Parent := FFundo;
  FTopo.Align := TAlignLayout.Top;
  FTopo.Height := 92;
  FTopo.Fill.Color := $FFFFFFFF;
  FTopo.Stroke.Kind := TBrushKind.None;
  FTitulo := CriarRotulo(FTopo, 'Pagamento PIX', 20, 15, 350, 32,
    22, $FF202332, True);
  FSubtitulo := CriarRotulo(FTopo,
    'Escaneie o QR Code ou copie o código abaixo', 20, 49, 350, 24,
    11, $FF7B8190);

  FScroll := TVertScrollBox.Create(Self);
  FScroll.Parent := FFundo;
  FScroll.Align := TAlignLayout.Client;
  FScroll.ShowScrollBars := False;

  FConteudo := TLayout.Create(Self);
  FConteudo.Parent := FScroll;
  FConteudo.Align := TAlignLayout.Top;
  FConteudo.Height := 690;

  FPedido := CriarRotulo(FConteudo, 'Pedido', 20, 18, 170, 24,
    12, $FF7B8190);
  FValor := CriarRotulo(FConteudo, 'R$ 0,00', 190, 12, 180, 32,
    21, $FFFF4B0A, True);
  FValor.TextSettings.HorzAlign := TTextAlign.Trailing;

  FCardQr := TRectangle.Create(Self);
  FCardQr.Parent := FConteudo;
  FCardQr.Position.Point := PointF(20, 56);
  FCardQr.Width := 350;
  FCardQr.Height := 300;
  FCardQr.Anchors := [TAnchorKind.akLeft, TAnchorKind.akTop, TAnchorKind.akRight];
  FCardQr.Fill.Color := $FFFFFFFF;
  FCardQr.Stroke.Color := $FFE7E8ED;
  FCardQr.XRadius := 14;
  FCardQr.YRadius := 14;

  FAreaQr := TLayout.Create(Self);
  FAreaQr.Parent := FCardQr;
  FAreaQr.Align := TAlignLayout.Client;
  FAreaQr.Margins.Rect := RectF(14, 14, 14, 14);

  FQrImage := TImage.Create(Self);
  FQrImage.Parent := FAreaQr;
  FQrImage.Align := TAlignLayout.Center;
  FQrImage.Width := 264;
  FQrImage.Height := 264;
  FQrImage.WrapMode := TImageWrapMode.Fit;
  FQrImage.HitTest := False;

  FInstrucao := CriarRotulo(FConteudo,
    'PIX copia e cola', 20, 376, 350, 22, 12, $FF202332, True);

  FCardCodigo := TRectangle.Create(Self);
  FCardCodigo.Parent := FConteudo;
  FCardCodigo.Position.Point := PointF(20, 403);
  FCardCodigo.Width := 350;
  FCardCodigo.Height := 92;
  FCardCodigo.Anchors := [TAnchorKind.akLeft, TAnchorKind.akTop,
    TAnchorKind.akRight];
  FCardCodigo.Fill.Color := $FFFFFFFF;
  FCardCodigo.Stroke.Color := $FFE1E3E8;
  FCardCodigo.XRadius := 10;
  FCardCodigo.YRadius := 10;

  FCodigoMemo := TMemo.Create(Self);
  FCodigoMemo.Parent := FCardCodigo;
  FCodigoMemo.Align := TAlignLayout.Client;
  FCodigoMemo.Margins.Rect := RectF(10, 6, 10, 6);
  FCodigoMemo.ReadOnly := True;
  FCodigoMemo.WordWrap := True;
  FCodigoMemo.StyledSettings := [];
  FCodigoMemo.TextSettings.Font.Family := 'Manrope';
  FCodigoMemo.TextSettings.Font.Size := 10;
  FCodigoMemo.TextSettings.FontColor := $FF3A3E49;

  FBtnCopiar := TRectangle.Create(Self);
  FBtnCopiar.Parent := FConteudo;
  FBtnCopiar.Position.Point := PointF(20, 511);
  FBtnCopiar.Width := 350;
  FBtnCopiar.Height := 48;
  FBtnCopiar.Anchors := [TAnchorKind.akLeft, TAnchorKind.akTop,
    TAnchorKind.akRight];
  FBtnCopiar.Fill.Color := $FFFFF0EA;
  FBtnCopiar.Stroke.Color := $FFFF4B0A;
  FBtnCopiar.XRadius := 10;
  FBtnCopiar.YRadius := 10;
  FBtnCopiar.OnClick := CopiarClick;
  FCopiarTexto := CriarRotulo(FBtnCopiar, 'Copiar código PIX', 0, 0,
    350, 48, 13, $FFFF4B0A, True);
  FCopiarTexto.Align := TAlignLayout.Client;
  FCopiarTexto.TextSettings.HorzAlign := TTextAlign.Center;
  FCopiarTexto.TextSettings.VertAlign := TTextAlign.Center;

  FStatusPagamento := CriarRotulo(FConteudo,
    'Aguardando confirmação do pagamento', 20, 570, 350, 28,
    12, $FFFF8A00, True);
  FStatusPagamento.Anchors := [TAnchorKind.akLeft, TAnchorKind.akTop,
    TAnchorKind.akRight];
  FStatusPagamento.TextSettings.HorzAlign := TTextAlign.Center;
  FStatusPagamento.TextSettings.VertAlign := TTextAlign.Center;

  FBtnContinuar := TRectangle.Create(Self);
  FBtnContinuar.Parent := FConteudo;
  FBtnContinuar.Position.Point := PointF(20, 610);
  FBtnContinuar.Width := 350;
  FBtnContinuar.Height := 52;
  FBtnContinuar.Anchors := [TAnchorKind.akLeft, TAnchorKind.akTop,
    TAnchorKind.akRight];
  FBtnContinuar.Fill.Color := $FFFF4B0A;
  FBtnContinuar.Stroke.Kind := TBrushKind.None;
  FBtnContinuar.XRadius := 11;
  FBtnContinuar.YRadius := 11;
  FBtnContinuar.OnClick := ContinuarClick;
  FContinuarTexto := CriarRotulo(FBtnContinuar, 'Acompanhar pedido', 0, 0,
    350, 52, 14, $FFFFFFFF, True);
  FContinuarTexto.Align := TAlignLayout.Client;
  FContinuarTexto.TextSettings.HorzAlign := TTextAlign.Center;
  FContinuarTexto.TextSettings.VertAlign := TTextAlign.Center;
  FBtnContinuar.Visible := False;
end;

procedure TfraPagamentoPix.CarregarImagemQr(const ABase64: string);
var
  LBase64: string;
  LSeparador: Integer;
  LBytes: TBytes;
  LStream: TBytesStream;
begin
  FQrImage.Bitmap.SetSize(0, 0);
  LBase64 := ABase64.Trim;
  LSeparador := LBase64.IndexOf(',');
  if LSeparador >= 0 then
    LBase64 := LBase64.Substring(LSeparador + 1);
  if LBase64.IsEmpty then
    Exit;

  LBytes := TNetEncoding.Base64.DecodeStringToBytes(LBase64);
  LStream := TBytesStream.Create(LBytes);
  try
    FQrImage.Bitmap.LoadFromStream(LStream);
  finally
    LStream.Free;
  end;
end;

procedure TfraPagamentoPix.Exibir(const APedidoId, ACodigoPix,
  AQRCodeBase64: string;
  const AValor: Currency; const ANumeroPedido: Integer);
begin
  FPedidoId := APedidoId;
  FCodigoPix := ACodigoPix;
  FCodigoMemo.Text := FCodigoPix;
  FPedido.Text := Format('Pedido #%d', [ANumeroPedido]);
  FValor.Text := FormatFloat('R$ #,##0.00', AValor);
  CarregarImagemQr(AQRCodeBase64);
  FScroll.ViewportPosition := PointF(0, 0);
  FSegundosRestantes := 300;
  FCancelado := False;
  FConsultando := False;
  FBtnContinuar.Visible := False;
  FBtnContinuar.Fill.Color := $FFFF4B0A;
  FContinuarTexto.Text := 'Acompanhar pedido';
  AtualizarTextoEspera;
  FTimer.Enabled := True;
  ConsultarStatus;
end;

procedure TfraPagamentoPix.CopiarClick(Sender: TObject);
var
  LClipboard: IFMXClipboardService;
begin
  if FCodigoPix.IsEmpty then
    Exit;
  if TPlatformServices.Current.SupportsPlatformService(
    IFMXClipboardService,
    LClipboard
  ) then
  begin
    LClipboard.SetClipboard(FCodigoPix);
    TMensagemMobile.Exibir('Código PIX copiado.', tmSucesso);
  end
  else
    TMensagemMobile.Exibir('Não foi possível acessar a área de transferência.',
      tmErro);
end;

procedure TfraPagamentoPix.ContinuarClick(Sender: TObject);
begin
  FTimer.Enabled := False;
  if FCancelado then
  begin
    if Assigned(FOnCancelado) then
      FOnCancelado(Self);
  end
  else if Assigned(FOnContinuar) then
    FOnContinuar(Self);
end;

procedure TfraPagamentoPix.AtualizarTextoEspera;
begin
  FStatusPagamento.Text := Format(
    'Aguardando confirmação do PIX  %d:%.2d',
    [FSegundosRestantes div 60, FSegundosRestantes mod 60]
  );
  FStatusPagamento.TextSettings.FontColor := $FFFF8A00;
end;

procedure TfraPagamentoPix.ConsultarStatus;
var
  LHTTP: TNetHTTPClient;
  LResposta: IHTTPResponse;
  LJSON, LPagamento: TJSONObject;
  LSituacao: string;
begin
  if FConsultando or FPedidoId.Trim.IsEmpty then
    Exit;

  FConsultando := True;
  LHTTP := TNetHTTPClient.Create(nil);
  LJSON := nil;
  try
    try
      LHTTP.Accept := 'application/json';
      LHTTP.ConnectionTimeout := 3000;
      LHTTP.ResponseTimeout := 8000;
      LResposta := LHTTP.Get(
        TApiConfig.Url('/api/pedidos/') + FPedidoId + '/pagamento-pix'
      );
      if LResposta.StatusCode <> 200 then
        Exit;

      LJSON := TJSONObject.ParseJSONValue(
        LResposta.ContentAsString(TEncoding.UTF8)
      ) as TJSONObject;
      if not Assigned(LJSON) then
        Exit;

      LPagamento := LJSON.GetValue<TJSONObject>('pagamento');
      if not Assigned(LPagamento) then
        Exit;

      LSituacao := LPagamento.GetValue<string>('situacao', '');
      FSegundosRestantes := LPagamento.GetValue<Integer>(
        'segundosRestantes', FSegundosRestantes
      );

      if SameText(LSituacao, 'PAGO') then
      begin
        FTimer.Enabled := False;
        FCancelado := False;
        FStatusPagamento.Text := 'PIX confirmado! Pedido enviado para a loja.';
        FStatusPagamento.TextSettings.FontColor := $FF1FAD66;
        FBtnContinuar.Visible := True;
        FBtnContinuar.Fill.Color := $FF1FAD66;
        FContinuarTexto.Text := 'Acompanhar pedido';
      end
      else if SameText(LSituacao, 'CANCELADO') then
      begin
        FTimer.Enabled := False;
        FCancelado := True;
        FStatusPagamento.Text := 'Tempo esgotado. O pedido foi cancelado.';
        FStatusPagamento.TextSettings.FontColor := $FFE5484D;
        FBtnContinuar.Visible := True;
        FBtnContinuar.Fill.Color := $FF59606F;
        FContinuarTexto.Text := 'Voltar ao início';
      end
      else
        AtualizarTextoEspera;
    except
      on E: Exception do
      begin
        { Mantém a tela aguardando. A próxima consulta tenta novamente. }
      end;
    end;
  finally
    LJSON.Free;
    LHTTP.Free;
    FConsultando := False;
  end;
end;

procedure TfraPagamentoPix.TimerStatus(Sender: TObject);
begin
  if FSegundosRestantes > 2 then
    Dec(FSegundosRestantes, 2)
  else
    FSegundosRestantes := 0;
  AtualizarTextoEspera;
  ConsultarStatus;
end;

procedure TfraPagamentoPix.FrameResize(Sender: TObject);
begin
  if not Assigned(FCardQr) then
    Exit;
  FCardQr.Width := Width - 40;
  FCardCodigo.Width := Width - 40;
  FBtnCopiar.Width := Width - 40;
  FBtnContinuar.Width := Width - 40;
  FSubtitulo.Width := Width - 40;
  FValor.Width := Width - 210;
  FStatusPagamento.Width := Width - 40;
end;

end.
