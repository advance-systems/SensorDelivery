unit uTelefoneDispositivo;

interface

type
  TTelefoneObtidoProc = reference to procedure(const ATelefone: string);

  TTelefoneDispositivo = class
  private
    class function Formatar(const AValor: string): string; static;
  public
    class procedure Obter(const ACallback: TTelefoneObtidoProc); static;
  end;

implementation

uses
  System.SysUtils, System.Types
{$IFDEF ANDROID}
  , System.Permissions, Androidapi.Helpers, Androidapi.JNI.JavaTypes,
  Androidapi.JNI.Os, Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNI.Telephony
{$ENDIF}
  ;

class function TTelefoneDispositivo.Formatar(const AValor:string):string;
var
  C:Char;
  Digitos:string;
begin
  Digitos:='';
  for C in AValor do
    if CharInSet(C,['0'..'9']) then Digitos:=Digitos+C;

  if ((Length(Digitos)=12) or (Length(Digitos)=13))
    and Digitos.StartsWith('55') then Delete(Digitos,1,2);

  case Length(Digitos) of
    11: Result:=Format('(%s) %s-%s',[
      Copy(Digitos,1,2),Copy(Digitos,3,5),Copy(Digitos,8,4)]);
    10: Result:=Format('(%s) %s-%s',[
      Copy(Digitos,1,2),Copy(Digitos,3,4),Copy(Digitos,7,4)]);
  else
    Result:=Digitos;
  end;
end;

{$IFDEF ANDROID}
function LerTelefoneAndroid:string;
var
  Servico:JObject;
  GerenciadorAssinatura:JSubscriptionManager;
  GerenciadorTelefone:JTelephonyManager;
  Numero:JString;
  IdAssinatura:Integer;
begin
  Result:='';
  try
    Numero:=nil;
    if TOSVersion.Check(13) then begin
      Servico:=TAndroidHelper.Context.getSystemService(
        TJContext.JavaClass.TELEPHONY_SUBSCRIPTION_SERVICE);
      if Assigned(Servico) then begin
        GerenciadorAssinatura:=TJSubscriptionManager.Wrap(Servico);
        IdAssinatura:=TJSubscriptionManager.JavaClass.getDefaultSubscriptionId;
        if TJSubscriptionManager.JavaClass.isValidSubscriptionId(IdAssinatura) then
          Numero:=GerenciadorAssinatura.getPhoneNumber(IdAssinatura);
      end;
    end;

    if not Assigned(Numero) or JStringToString(Numero).Trim.IsEmpty then begin
      Servico:=TAndroidHelper.Context.getSystemService(
        TJContext.JavaClass.TELEPHONY_SERVICE);
      if Assigned(Servico) then begin
        GerenciadorTelefone:=TJTelephonyManager.Wrap(Servico);
        Numero:=GerenciadorTelefone.getLine1Number;
      end;
    end;
    if Assigned(Numero) then Result:=JStringToString(Numero);
  except
    Result:='';
  end;
end;
{$ENDIF}

class procedure TTelefoneDispositivo.Obter(const ACallback:TTelefoneObtidoProc);
{$IFDEF ANDROID}
var
  Permissao:string;
{$ENDIF}
begin
  if not Assigned(ACallback) then Exit;
{$IFDEF ANDROID}
  Permissao:=JStringToString(TJManifest_permission.JavaClass.READ_PHONE_NUMBERS);
  PermissionsService.RequestPermissions([Permissao],
    procedure(const APermissions:TClassicStringDynArray;
      const AGrantResults:TClassicPermissionStatusDynArray)
    var
      Telefone:string;
    begin
      Telefone:='';
      if (Length(AGrantResults)>0)
        and (AGrantResults[0]=TPermissionStatus.Granted) then
        Telefone:=Formatar(LerTelefoneAndroid);
      ACallback(Telefone);
    end);
{$ELSE}
  ACallback('');
{$ENDIF}
end;

end.
