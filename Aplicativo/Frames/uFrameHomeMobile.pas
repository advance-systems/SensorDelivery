unit uFrameHomeMobile;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Diagnostics,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Layouts, FMX.Controls.Presentation, FMX.Edit, System.JSON,
  System.Net.HttpClient, System.Net.URLClient, System.Net.HttpClientComponent,
  uFrameProdutoMobile, uCarrinhoModel;

type
  TProdutoSelecionadoEvent = procedure(
    Sender: TObject;
    const AProdutoId: string
  ) of object;

  TPizzaSelecionadaEvent = procedure(
    Sender: TObject;
    const AProdutoId: string;
    const AVariacaoId: string;
    const AVariacaoNome: string;
    const APreco: Currency
  ) of object;

  TfraHomeMobile = class(TFrame)
    rctFundo: TRectangle;
    rctVerCarrinho: TRectangle;
    lblIconeCarrinho: TLabel;
    lblVerCarrinho: TLabel;
    lblQuantidadeCarrinho: TLabel;
    rctTopoHome: TRectangle;
    lytTopoInterno: TLayout;
    lytMenu: TLayout;
    lytNotificacao: TLayout;
    lytLogo: TLayout;
    lblMenu: TLabel;
    lblSino: TLabel;
    cirNotificacao: TCircle;
    imgLogoHome: TImage;
    lytSaudacao: TLayout;
    lytTextoSaudacao: TLayout;
    lblOla: TLabel;
    lblPergunta: TLabel;
    lytStatusLoja: TLayout;
    rctStatusLoja: TRectangle;
    lblStatusLoja: TLabel;
    lblHorarioLoja: TLabel;
    lblNotificacao: TLabel;
    rctBusca: TRectangle;
    lblIconeBusca: TLabel;
    edtBusca: TEdit;
    lytCategorias: TLayout;
    lblTituloCategorias: TLabel;
    lblVerTodasCategorias: TLabel;
    hsbCategorias: THorzScrollBox;
    lytMaisPedidos: TLayout;
    lblTituloMaisPedidos: TLabel;
    lblVerTodosProdutos: TLabel;
    lytProdutos: TLayout;
    vsbConteudo: TVertScrollBox;
    lytEspacoFinal: TLayout;
    procedure rctVerCarrinhoClick(Sender: TObject);
    procedure CategoriaClick(Sender: TObject);
  private
    FOnProdutoSelecionado: TProdutoSelecionadoEvent;
    FOnPizzaSelecionada: TPizzaSelecionadaEvent;
    FOnAbrirCarrinho: TNotifyEvent;

    FCardapioCarregado: Boolean;
    FPreCargaEmAndamento: Boolean;
    FJSONCategoriasCache: string;
    FJSONProdutosCache: string;
    FCategoriaSelecionada: string;
    FCardCategoriaPressionado: TRectangle;
    FToqueCategoriaInicio: TPointF;
    FToqueCategoriaInicioHorario: Int64;

    procedure CarregarProdutosAPI;
    procedure ProdutoClick(Sender: TObject; const AProdutoId: string);
    procedure AdicionarProdutoClick(Sender: TObject; const AProdutoId: string);
    procedure CarregarVariacoesPizza(
      const AProdutoId: string;
      var AIndiceVisual: Integer);
    procedure CarregarImagemCategoriaAsync(const AImagem: TImage;
      const AURL: string);
    procedure CriarCategorias;
    procedure CategoriaMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure CategoriaMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
  public
    procedure CarregarCardapio;
    procedure PreCarregarCardapio;
    procedure AtualizarCardapio;
    procedure AtualizarCarrinho;

    property OnProdutoSelecionado: TProdutoSelecionadoEvent
      read FOnProdutoSelecionado
      write FOnProdutoSelecionado;

    property OnPizzaSelecionada: TPizzaSelecionadaEvent
      read FOnPizzaSelecionada
      write FOnPizzaSelecionada;

    property OnAbrirCarrinho: TNotifyEvent
      read FOnAbrirCarrinho
      write FOnAbrirCarrinho;

    constructor Create(AOwner: TComponent); override;
  end;

implementation

{$R *.fmx}

uses uEmpresaApp, uApiConfig, uCursorCamposMobile;

constructor TfraHomeMobile.Create(AOwner: TComponent);
begin
  inherited;

  FCardapioCarregado := False;
  FPreCargaEmAndamento := False;
  FJSONCategoriasCache := '';
  FJSONProdutosCache := '';
  FCategoriaSelecionada := '';
  FCardCategoriaPressionado := nil;
  rctVerCarrinho.Visible := False;
  TCursorCamposMobile.Aplicar(Self, Self);
  vsbConteudo.ViewportPosition := PointF(0, 0);
end;

procedure TfraHomeMobile.CarregarProdutosAPI;
const
  ALTURA_CARD = 226;
  ESPACO_Y = 10;
var
  LHTTP: TNetHTTPClient;
  LResposta: IHTTPResponse;
  LJSON: TJSONObject;
  LProdutos: TJSONArray;
  LProdutoJSON: TJSONObject;
  LProduto: TfraProdutoMobile;

  I: Integer;

  LIndiceVisual: Integer;
  LId: string;
  LNome: string;
  LDescricao: string;
  LPrecoTexto: string;
  LPreco: Currency;
  LImagemURL: string;
  LCategoriaId: string;

  LFS: TFormatSettings;
begin
  { Limpa os produtos existentes }
  while lytProdutos.ChildrenCount > 0 do
    lytProdutos.Children[0].Free;

  lytProdutos.Height := 0;

  LJSON := nil;
  LHTTP := TNetHTTPClient.Create(nil);
  try
    LHTTP.ConnectionTimeout := 5000;
    LHTTP.ResponseTimeout := 10000;

    try
      if not FJSONProdutosCache.IsEmpty then
      begin
        LJSON := TJSONObject.ParseJSONValue(FJSONProdutosCache) as TJSONObject;
        FJSONProdutosCache := '';
      end
      else
      begin
      LResposta :=
        LHTTP.Get(
          TApiConfig.Url('/api/produtos?empresaId=') + TEmpresaApp.Id
        );

      if LResposta.StatusCode <> 200 then
        raise Exception.CreateFmt(
          'Erro ao carregar produtos. API retornou %d.',
          [LResposta.StatusCode]
        );

      LJSON :=
        TJSONObject.ParseJSONValue(
          LResposta.ContentAsString(TEncoding.UTF8)
        ) as TJSONObject;
      end;

      if not Assigned(LJSON) then
        raise Exception.Create(
          'A API retornou um JSON inválido.'
        );

      try
        LProdutos :=
          LJSON.GetValue<TJSONArray>('produtos');

        if not Assigned(LProdutos) then
          Exit;

        LFS := TFormatSettings.Create;
        LFS.DecimalSeparator := '.';

        LIndiceVisual := 0;
        for I := 0 to LProdutos.Count - 1 do
        begin
          LProdutoJSON :=
            LProdutos.Items[I] as TJSONObject;

          LId :=
            LProdutoJSON.GetValue<string>('id', '');

          LCategoriaId :=
            LProdutoJSON.GetValue<string>('categoria_id', '');

          if (not FCategoriaSelecionada.IsEmpty) and
             (not SameText(LCategoriaId, FCategoriaSelecionada)) then
            Continue;

          LNome :=
            LProdutoJSON.GetValue<string>('nome', '');

          LDescricao :=
            LProdutoJSON.GetValue<string>('descricao', '');

          LPrecoTexto :=
            LProdutoJSON.GetValue<string>('preco', '0');

          if not TryStrToCurr(
            LPrecoTexto,
            LPreco,
            LFS
          ) then
            LPreco := 0;

          LImagemURL :=
            LProdutoJSON.GetValue<string>(
            'imagem_url',
            ''
          );

          if SameText(LNome, 'Pizza') then
          begin
            CarregarVariacoesPizza(
              LId,
              LIndiceVisual
            );

            Continue;
          end;

          LProduto :=
            TfraProdutoMobile.Create(nil);

          LProduto.Name := '';
          LProduto.Parent := lytProdutos;

          LProduto.Align := TAlignLayout.None;

          LProduto.Position.X := 0;
          LProduto.Position.Y :=
            LIndiceVisual * (ALTURA_CARD + ESPACO_Y);

          LProduto.Width :=
            lytProdutos.Width;

          LProduto.Height := ALTURA_CARD;

          LProduto.Preencher(
            LId,
            LNome,
            LDescricao,
            LPreco,
            LImagemURL
          );

          LProduto.OnProdutoClick :=
            ProdutoClick;

          LProduto.OnAdicionarClick :=
            AdicionarProdutoClick;

          Inc(LIndiceVisual);
        end;

        if LIndiceVisual > 0 then
          lytProdutos.Height :=
            (LIndiceVisual * ALTURA_CARD) +
            ((LIndiceVisual - 1) * ESPACO_Y)
        else
          lytProdutos.Height := 0;

        lytMaisPedidos.Height := 38 + lytProdutos.Height + 20;

        lytEspacoFinal.Position.Y := lytMaisPedidos.Position.Y + lytMaisPedidos.Height;
      finally
        LJSON.Free;
      end;

    except
      on E: Exception do
      begin
        // A tela principal mantém o estado atual se esta carga falhar.
      end;
    end;

  finally
    LHTTP.Free;
  end;
end;

procedure TfraHomeMobile.ProdutoClick(
  Sender: TObject;
  const AProdutoId: string);
var
  LProduto: TfraProdutoMobile;
begin
  if Sender is TfraProdutoMobile then
  begin
    LProduto := TfraProdutoMobile(Sender);

    if not LProduto.VariacaoId.Trim.IsEmpty then
    begin
      if Assigned(FOnPizzaSelecionada) then
        FOnPizzaSelecionada(
          Self,
          AProdutoId,                 // produto Pizza
          LProduto.VariacaoId,        // tamanho
          LProduto.VariacaoNome,
          LProduto.VariacaoPreco
        );

      Exit;
    end;
  end;

  if Assigned(FOnProdutoSelecionado) then
    FOnProdutoSelecionado(
      Self,
      AProdutoId
    );
end;

procedure TfraHomeMobile.rctVerCarrinhoClick(Sender: TObject);
begin
  if Assigned(FOnAbrirCarrinho) then
    FOnAbrirCarrinho(Self);
end;

procedure TfraHomeMobile.AdicionarProdutoClick(
  Sender: TObject;
  const AProdutoId: string);
begin
  ProdutoClick(
    Sender,
    AProdutoId
  );
end;

procedure TfraHomeMobile.CarregarVariacoesPizza(
  const AProdutoId: string;
  var AIndiceVisual: Integer);
const
  ALTURA_CARD = 226;
  ESPACO_Y = 10;
var
  LHTTP: TNetHTTPClient;
  LResposta: IHTTPResponse;
  LJSON: TJSONObject;
  LVariacoes: TJSONArray;
  LVariacao: TJSONObject;
  LProduto: TfraProdutoMobile;

  I: Integer;
  LId: string;
  LNome: string;
  LPrecoTexto: string;
  LPreco: Currency;
  LFS: TFormatSettings;
begin
  LHTTP := TNetHTTPClient.Create(nil);
  LJSON := nil;

  try
    LHTTP.Accept := 'application/json';

    LResposta := LHTTP.Get(
      TApiConfig.Url('/api/produtos/') +
      AProdutoId +
      '/variacoes?empresaId=' + TEmpresaApp.Id
    );

    if LResposta.StatusCode <> 200 then
      Exit;

    LJSON :=
      TJSONObject.ParseJSONValue(
        LResposta.ContentAsString(TEncoding.UTF8)
      ) as TJSONObject;

    if not Assigned(LJSON) then
      Exit;

    LVariacoes :=
      LJSON.GetValue<TJSONArray>('variacoes');

    if not Assigned(LVariacoes) then
      Exit;

    LFS := TFormatSettings.Create;
    LFS.DecimalSeparator := '.';

    for I := 0 to LVariacoes.Count - 1 do
    begin
      LVariacao :=
        LVariacoes.Items[I] as TJSONObject;

      LId :=
        LVariacao.GetValue<string>(
          'id',
          ''
        );

      LNome :=
        LVariacao.GetValue<string>(
          'nome',
          ''
        );

      LPrecoTexto :=
        LVariacao.GetValue<string>(
          'preco',
          '0'
        );

      if not TryStrToCurr(
        LPrecoTexto,
        LPreco,
        LFS
      ) then
        LPreco := 0;

      LProduto :=
        TfraProdutoMobile.Create(nil);

      LProduto.Name := '';
      LProduto.Parent := lytProdutos;

      LProduto.Align :=
        TAlignLayout.None;

      LProduto.Position.X := 0;

      LProduto.Position.Y :=
        AIndiceVisual *
        (ALTURA_CARD + ESPACO_Y);

      LProduto.Width :=
        lytProdutos.Width;

      LProduto.Height :=
        ALTURA_CARD;

      LProduto.Preencher(
        AProdutoId,
        'Pizza ' + LNome,
        'Escolha os sabores',
        LPreco,
        ''
      );

      LProduto.VariacaoId :=
        LId;

      LProduto.VariacaoNome :=
        LNome;

      LProduto.VariacaoPreco :=
        LPreco;

      LProduto.OnProdutoClick :=
        ProdutoClick;

      LProduto.OnAdicionarClick :=
        AdicionarProdutoClick;

      Inc(AIndiceVisual);
    end;

  finally
    LJSON.Free;
    LHTTP.Free;
  end;
end;

procedure TfraHomeMobile.CarregarCardapio;
begin
  if FCardapioCarregado or FPreCargaEmAndamento then
    Exit;

  CriarCategorias;
  CarregarProdutosAPI;

  FCardapioCarregado := True;

  vsbConteudo.ViewportPosition := PointF(0, 0);
end;

procedure TfraHomeMobile.PreCarregarCardapio;
begin
  if FCardapioCarregado or FPreCargaEmAndamento then
    Exit;

  FPreCargaEmAndamento := True;
  TThread.CreateAnonymousThread(
    procedure
    var
      LHTTP: TNetHTTPClient;
      LResposta: IHTTPResponse;
      LCategoriasJSON, LProdutosJSON: string;
    begin
      LCategoriasJSON := '';
      LProdutosJSON := '';
      LHTTP := TNetHTTPClient.Create(nil);
      try
        try
          LHTTP.ConnectionTimeout := 4000;
          LHTTP.ResponseTimeout := 8000;
          LResposta := LHTTP.Get(
            TApiConfig.Url('/api/produtos/categorias/lista?empresaId=') +
            TEmpresaApp.Id
          );
          if LResposta.StatusCode = 200 then
            LCategoriasJSON := LResposta.ContentAsString(TEncoding.UTF8);

          LResposta := LHTTP.Get(
            TApiConfig.Url('/api/produtos?empresaId=') + TEmpresaApp.Id
          );
          if LResposta.StatusCode = 200 then
            LProdutosJSON := LResposta.ContentAsString(TEncoding.UTF8);
        except
          { Uma carga normal será tentada depois, caso a pré-carga falhe. }
        end;
      finally
        LHTTP.Free;
      end;

      TThread.Queue(nil,
        procedure
        begin
          if csDestroying in ComponentState then
            Exit;
          FJSONCategoriasCache := LCategoriasJSON;
          FJSONProdutosCache := LProdutosJSON;
          FPreCargaEmAndamento := False;
          FCardapioCarregado := False;
          CarregarCardapio;
        end
      );
    end
  ).Start;
end;

procedure TfraHomeMobile.AtualizarCardapio;
begin
  FCardapioCarregado := False;

  CarregarCardapio;
end;

procedure TfraHomeMobile.AtualizarCarrinho;
var
  LQuantidade: Integer;
begin
  LQuantidade :=
    TCarrinho.Instancia.QuantidadeItens;

  { O resumo agora pertence à uPrincipal }
  rctVerCarrinho.Visible := False;

  if LQuantidade = 1 then
    lblQuantidadeCarrinho.Text := '1 item'
  else
    lblQuantidadeCarrinho.Text :=
      LQuantidade.ToString + ' itens';
end;

procedure TfraHomeMobile.CriarCategorias;

  procedure AdicionarCategoria(
    const ATexto: string;
    const AId: string;
    const AImagemUrl: string;
    const AX: Single);
  var
    LCard: TRectangle;
    LIcone: TLabel;
    LImagem: TImage;
    LTexto: TLabel;
    LURLImagem: string;
  begin
    LCard := TRectangle.Create(hsbCategorias);
    LCard.Parent := hsbCategorias;

    LCard.Name := '';
    LCard.TagString := AId;

    LCard.Position.X := AX;
    LCard.Position.Y := 4;
    if Length(ATexto) > 18 then
      LCard.Width := 144
    else
      LCard.Width := 88;
    LCard.Height := 124;

    LCard.Fill.Color := $FFFFFFFF;
    LCard.Stroke.Kind := TBrushKind.Solid;
    LCard.Stroke.Color := $FFE8E8E8;
    LCard.Stroke.Thickness := 1;

    LCard.XRadius := 14;
    LCard.YRadius := 14;

    LCard.HitTest := True;
    { No celular, OnClick também podia disparar durante o início de uma
      rolagem horizontal. A seleção é confirmada somente ao soltar o dedo. }
    LCard.OnMouseDown := CategoriaMouseDown;
    LCard.OnMouseUp := CategoriaMouseUp;

    LURLImagem := AImagemUrl.Trim;
    if not LURLImagem.IsEmpty then
    begin
      if LURLImagem.StartsWith('/') then
        LURLImagem := TApiConfig.Url(LURLImagem);

      LImagem := TImage.Create(LCard);
      LImagem.Parent := LCard;
      LImagem.Align := TAlignLayout.Top;
      LImagem.Height := 54;
      LImagem.Margins.Rect := RectF(7, 5, 7, 1);
      LImagem.WrapMode := TImageWrapMode.Fit;
      LImagem.HitTest := False;
      CarregarImagemCategoriaAsync(LImagem, LURLImagem);
    end
    else
    begin
      LIcone := TLabel.Create(LCard);
      LIcone.Parent := LCard;
      LIcone.Align := TAlignLayout.Top;
      LIcone.Height := 54;

      if AId.IsEmpty then
        LIcone.Text := '✦'
      else if not ATexto.IsEmpty then
        LIcone.Text := UpperCase(Copy(ATexto, 1, 1))
      else
        LIcone.Text := '•';

      LIcone.TextSettings.Font.Size := 23;
      LIcone.TextSettings.HorzAlign := TTextAlign.Center;
      LIcone.TextSettings.VertAlign := TTextAlign.Center;
      LIcone.HitTest := False;
    end;

    LTexto := TLabel.Create(LCard);
    LTexto.Parent := LCard;

    LTexto.Align := TAlignLayout.Client;
    LTexto.Text := ATexto;
    LTexto.WordWrap := True;

    if Length(ATexto) > 18 then
      LTexto.TextSettings.Font.Size := 10
    else
      LTexto.TextSettings.Font.Size := 9;
    LTexto.TextSettings.Font.Style :=
      [TFontStyle.fsBold];

    LTexto.TextSettings.FontColor :=
      $FF202124;

    LTexto.TextSettings.HorzAlign :=
      TTextAlign.Center;

    LTexto.TextSettings.VertAlign :=
      TTextAlign.Center;

    LTexto.HitTest := False;

    if SameText(AId, FCategoriaSelecionada) then
    begin
      LCard.Fill.Color := $FFFFFAF7;
      LCard.Stroke.Color := $FFFF4B0A;
      LCard.Stroke.Thickness := 1.5;

      LTexto.TextSettings.FontColor :=
        $FFFF4B0A;
    end;
  end;

var
  LHTTP: TNetHTTPClient;
  LResposta: IHTTPResponse;
  LValor: TJSONValue;
  LJSON, LCategoria: TJSONObject;
  LCategorias: TJSONArray;
  I: Integer;
  LX: Single;
  LId, LNome, LImagemUrl: string;
begin
  while hsbCategorias.Content.ChildrenCount > 0 do
    hsbCategorias.Content.Children[0].Free;

  LX := 0;
  AdicionarCategoria('Todos', '', '', LX);
  LX := LX + 98;

  LHTTP := TNetHTTPClient.Create(nil);
  LValor := nil;
  try
    LHTTP.ConnectionTimeout := 5000;
    LHTTP.ResponseTimeout := 10000;
    try
      if not FJSONCategoriasCache.IsEmpty then
      begin
        LValor := TJSONObject.ParseJSONValue(FJSONCategoriasCache);
        FJSONCategoriasCache := '';
      end
      else
      begin
      LResposta := LHTTP.Get(
        TApiConfig.Url('/api/produtos/categorias/lista?empresaId=') +
        TEmpresaApp.Id
      );
      if LResposta.StatusCode <> 200 then
        Exit;

      LValor := TJSONObject.ParseJSONValue(
        LResposta.ContentAsString(TEncoding.UTF8)
      );
      end;
      if not (LValor is TJSONObject) then
        Exit;

      LJSON := TJSONObject(LValor);
      LCategorias := LJSON.GetValue<TJSONArray>('categorias');
      if not Assigned(LCategorias) then
        Exit;

      for I := 0 to LCategorias.Count - 1 do
        if LCategorias.Items[I] is TJSONObject then
        begin
          LCategoria := TJSONObject(LCategorias.Items[I]);
          LId := LCategoria.GetValue<string>('id', '');
          LNome := LCategoria.GetValue<string>('nome', '');
          LImagemUrl := LCategoria.GetValue<string>('imagem_url', '');
          if (not LId.IsEmpty) and (not LNome.IsEmpty) then
          begin
            AdicionarCategoria(LNome, LId, LImagemUrl, LX);
            if Length(LNome) > 18 then
              LX := LX + 154
            else
              LX := LX + 98;
          end;
        end;
    except
      { Mantém a opção Todos caso a lista de categorias não possa ser carregada. }
    end;
  finally
    LValor.Free;
    LHTTP.Free;
  end;
end;

procedure TfraHomeMobile.CarregarImagemCategoriaAsync(const AImagem: TImage;
  const AURL: string);
begin
  TThread.CreateAnonymousThread(
    procedure
    var
      LHTTP: TNetHTTPClient;
      LResposta: IHTTPResponse;
      LConteudo: TMemoryStream;
    begin
      LHTTP := TNetHTTPClient.Create(nil);
      LConteudo := TMemoryStream.Create;
      try
        try
          LHTTP.ConnectionTimeout := 3000;
          LHTTP.ResponseTimeout := 5000;
          LResposta := LHTTP.Get(AURL, LConteudo);
          if (LResposta.StatusCode >= 200) and
             (LResposta.StatusCode < 300) then
          begin
            LConteudo.Position := 0;
            TThread.Synchronize(nil,
              procedure
              begin
                if Assigned(AImagem) and
                   not (csDestroying in AImagem.ComponentState) then
                begin
                  LConteudo.Position := 0;
                  AImagem.Bitmap.LoadFromStream(LConteudo);
                end;
              end
            );
          end;
        except
          { A categoria permanece utilizável mesmo sem a miniatura. }
        end;
      finally
        LConteudo.Free;
        LHTTP.Free;
      end;
    end
  ).Start;
end;

procedure TfraHomeMobile.CategoriaClick(
  Sender: TObject);
var
  I: Integer;
  LCard: TRectangle;
  LTexto: TLabel;
begin
  for I := 0 to
    hsbCategorias.Content.ChildrenCount - 1 do
  begin
    if hsbCategorias.Content.Children[I]
      is TRectangle then
    begin
      LCard :=
        TRectangle(
          hsbCategorias.Content.Children[I]
        );

      LCard.Fill.Color := $FFFFFFFF;
      LCard.Stroke.Color := $FFE8E8E8;
      LCard.Stroke.Thickness := 1;

      if (LCard.ChildrenCount > 1) and
         (LCard.Children[1] is TLabel) then
      begin
        LTexto := TLabel(LCard.Children[1]);

        LTexto.TextSettings.FontColor :=
          $FF202124;
      end;
    end;
  end;

  if Sender is TRectangle then
  begin
    LCard := TRectangle(Sender);
    FCategoriaSelecionada := LCard.TagString;

    LCard.Fill.Color := $FFFFFAF7;
    LCard.Stroke.Color := $FFFF4B0A;
    LCard.Stroke.Thickness := 1.5;

    if (LCard.ChildrenCount > 1) and
       (LCard.Children[1] is TLabel) then
    begin
      LTexto := TLabel(LCard.Children[1]);

      LTexto.TextSettings.FontColor :=
        $FFFF4B0A;
    end;

    CarregarProdutosAPI;
  end;
end;

procedure TfraHomeMobile.CategoriaMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if not (Sender is TRectangle) then
    Exit;

  FCardCategoriaPressionado := TRectangle(Sender);
  FToqueCategoriaInicio := PointF(X, Y);
  FToqueCategoriaInicioHorario := TStopwatch.GetTimeStamp;
end;

procedure TfraHomeMobile.CategoriaMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
const
  TOLERANCIA_TOQUE = 8;
  TEMPO_MINIMO_MS = 50;
var
  LDuracaoMS: Int64;
begin
  try
    LDuracaoMS := ((TStopwatch.GetTimeStamp - FToqueCategoriaInicioHorario) * 1000)
      div TStopwatch.Frequency;
    if (Sender <> FCardCategoriaPressionado) or
       (Abs(X - FToqueCategoriaInicio.X) > TOLERANCIA_TOQUE) or
       (Abs(Y - FToqueCategoriaInicio.Y) > TOLERANCIA_TOQUE) or
       (LDuracaoMS < TEMPO_MINIMO_MS) then
      Exit;

    CategoriaClick(Sender);
  finally
    FCardCategoriaPressionado := nil;
  end;
end;

end.
