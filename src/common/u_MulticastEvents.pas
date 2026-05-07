unit u_MulticastEvents;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  // Generic multicast event manager for method pointers
  // Maintains a list of subscribers and provides notification with custom invocation logic
  TMulticastEvent<T> = class
  private
    fSubscribers: TList<T>;
    function IndexOf(const AHandler: T): Integer;
    function GetCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Subscribe(const AHandler: T);
    procedure Unsubscribe(const AHandler: T);
    procedure Clear;
    procedure Notify(const AInvoker: TProc<T>);

    property Count: Integer read GetCount;
  end;

implementation

{ TMulticastEvent<T> }

constructor TMulticastEvent<T>.Create;
begin
  inherited Create;
  fSubscribers := TList<T>.Create;
end;

destructor TMulticastEvent<T>.Destroy;
begin
  fSubscribers.Free;
  inherited;
end;

function TMulticastEvent<T>.GetCount: Integer;
begin
  Result := fSubscribers.Count;
end;

function TMulticastEvent<T>.IndexOf(const AHandler: T): Integer;
var
  I: Integer;
  AMethod: TMethod absolute AHandler;
  ExistingHandler: T;
  ExistingMethod: TMethod absolute ExistingHandler;
begin
  // Compare method pointers by Code and Data to detect duplicates
  for I := 0 to fSubscribers.Count - 1 do
  begin
    ExistingHandler := fSubscribers[I];
    if (AMethod.Code = ExistingMethod.Code) and (AMethod.Data = ExistingMethod.Data) then
      Exit(I);
  end;

  Result := -1;
end;

procedure TMulticastEvent<T>.Subscribe(const AHandler: T);
var
  AMethod: TMethod absolute AHandler;
begin
  if Assigned(AMethod.Code) and (IndexOf(AHandler) = -1) then
    fSubscribers.Add(AHandler);
end;

procedure TMulticastEvent<T>.Unsubscribe(const AHandler: T);
var
  Index: Integer;
  AMethod: TMethod absolute AHandler;
begin
  if Assigned(AMethod.Code) then
  begin
    Index := IndexOf(AHandler);
    if Index > -1 then
      fSubscribers.Delete(Index);
  end;
end;

procedure TMulticastEvent<T>.Clear;
begin
  fSubscribers.Clear;
end;

procedure TMulticastEvent<T>.Notify(const AInvoker: TProc<T>);
var
  Handlers: TArray<T>;
  Handler: T;
begin
  // Snapshot the list to allow modifications during notification
  Handlers := fSubscribers.ToArray;
  for Handler in Handlers do
    AInvoker(Handler);
end;

end.
