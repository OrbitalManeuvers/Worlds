unit u_SessionFileSink;

{
  u_SessionFileSink — Memory-mapped file sink and reader for TSessionEvent streams.

  TSessionFileSink — ISessionEventConsumer that records the session event stream
                     into a chunked, pre-allocated memory-mapped backing file.
  TSessionFileLog  — ISessionEventLog reader that provides indexed read-only access
                     to a backing file written by TSessionFileSink. Safe for
                     concurrent use while a live TSessionFileSink is writing.
}

interface

uses
  Winapi.Windows,
  System.SysUtils,
  u_SessionEventTypes;

const
  SESSION_LOG_SIGNATURE = $53455654; // 'SEVT'
  SESSION_LOG_VERSION   = 1;

type
  TSessionLogHeader = record
    Signature: Cardinal;
    Version: Word;
    EventCount: Integer;
  end;

  PSessionLogHeader = ^TSessionLogHeader;
  PSessionEvent = ^TSessionEvent;

  // -------------------------------------------------------------------------
  // TSessionFileSink
  // -------------------------------------------------------------------------

  TSessionFileSink = class(TInterfacedObject, ISessionEventConsumer)
  private
    fFilePath: string;
    fFileHandle: THandle;
    fMappingHandle: THandle;
    fMapView: Pointer;
    fHeaderView: Pointer;
    fNextIndex: Integer;
    fChunkStartIndex: Integer;
    fChunkCapacity: Integer;
    fChunkBytes: Int64;
    fHeaderBytes: Integer;

    procedure ExtendAndRemap;
  public
    constructor Create(const AFilePath: string; AChunkEvents: Integer = 1000000);
    destructor Destroy; override;

    { ISessionEventConsumer }
    procedure Consume(const Event: TSessionEvent);

    function EventCount: Integer;
    property FilePath: string read fFilePath;
  end;

  // -------------------------------------------------------------------------
  // TSessionFileLog
  // -------------------------------------------------------------------------

  TSessionFileLog = class(TInterfacedObject, ISessionEventLog)
  private
    fFilePath: string;
    fFileHandle: THandle;
    fMappingHandle: THandle;
    fView: Pointer;
    fHeaderBytes: Integer;
    fMappedSize: Int64;
  public
    constructor Create(const AFilePath: string);
    destructor Destroy; override;

    { ISessionEventLog }
    function GetCount: Integer;
    function GetEvent(aIndex: Integer): TSessionEvent;

    function Header: TSessionLogHeader;

    property Count: Integer read GetCount;
    property Events[aIndex: Integer]: TSessionEvent read GetEvent;
  end;

function StandardSessionLogHeader: TSessionLogHeader;

implementation

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function GetFileSize64(AFileHandle: THandle): Int64;
begin
  if not GetFileSizeEx(AFileHandle, Result) then
    RaiseLastOSError;
end;

procedure SeekFileBegin64(AFileHandle: THandle; AOffset: Int64);
var
  offsetParts: Int64Rec;
  highPart: Longint;
begin
  offsetParts := Int64Rec(AOffset);
  highPart := offsetParts.Hi;
  if (SetFilePointer(AFileHandle, Longint(offsetParts.Lo), @highPart, FILE_BEGIN) = DWORD($FFFFFFFF))
     and (GetLastError <> NO_ERROR) then
    RaiseLastOSError;
end;

function StandardSessionLogHeader: TSessionLogHeader;
begin
  Result := Default(TSessionLogHeader);
  Result.Signature := SESSION_LOG_SIGNATURE;
  Result.Version := SESSION_LOG_VERSION;
end;

// ---------------------------------------------------------------------------
// TSessionFileSink
// ---------------------------------------------------------------------------

constructor TSessionFileSink.Create(const AFilePath: string; AChunkEvents: Integer);
var
  sysInfo: TSystemInfo;
  grain: Int64;
  recSize: Int64;
  li: Int64Rec;
begin
  inherited Create;

  fFilePath := AFilePath;
  fNextIndex := 0;
  fChunkStartIndex := 0;
  fFileHandle := INVALID_HANDLE_VALUE;
  fMappingHandle := 0;
  fMapView := nil;
  fHeaderView := nil;
  fHeaderBytes := SizeOf(TSessionLogHeader);

  // Compute aligned chunk geometry.
  GetSystemInfo(sysInfo);
  grain := sysInfo.dwAllocationGranularity;
  recSize := SizeOf(TSessionEvent);
  fChunkBytes := ((Int64(fHeaderBytes) + Int64(AChunkEvents) * recSize + grain - 1) div grain) * grain;
  fChunkCapacity := (fChunkBytes - fHeaderBytes) div recSize;

  try
    fFileHandle := CreateFile(
      PChar(AFilePath),
      GENERIC_READ or GENERIC_WRITE,
      FILE_SHARE_READ,
      nil,
      CREATE_NEW,
      FILE_ATTRIBUTE_NORMAL or FILE_FLAG_RANDOM_ACCESS,
      0);
    if fFileHandle = INVALID_HANDLE_VALUE then
      RaiseLastOSError;

    // Pre-allocate first chunk.
    SeekFileBegin64(fFileHandle, fChunkBytes);
    if not SetEndOfFile(fFileHandle) then
      RaiseLastOSError;

    li := Int64Rec(fChunkBytes);
    fMappingHandle := CreateFileMapping(fFileHandle, nil, PAGE_READWRITE, li.Hi, li.Lo, nil);
    if fMappingHandle = 0 then
      RaiseLastOSError;

    fMapView := MapViewOfFile(fMappingHandle, FILE_MAP_WRITE, 0, 0, fChunkBytes);
    if fMapView = nil then
      RaiseLastOSError;

    // Write header at offset 0.
    PSessionLogHeader(fMapView)^ := StandardSessionLogHeader;
    fHeaderView := fMapView;

  except
    if fMapView <> nil then
    begin
      UnmapViewOfFile(fMapView);
      fMapView := nil;
    end;
    if fMappingHandle <> 0 then
    begin
      CloseHandle(fMappingHandle);
      fMappingHandle := 0;
    end;
    if fFileHandle <> INVALID_HANDLE_VALUE then
    begin
      CloseHandle(fFileHandle);
      fFileHandle := INVALID_HANDLE_VALUE;
    end;
    raise;
  end;
end;

destructor TSessionFileSink.Destroy;
var
  finalBytes: Int64;
begin
  if fMapView <> nil then
  begin
    FlushViewOfFile(fMapView, 0);
    UnmapViewOfFile(fMapView);
    fMapView := nil;
    fHeaderView := nil;
  end;

  if fMappingHandle <> 0 then
  begin
    CloseHandle(fMappingHandle);
    fMappingHandle := 0;
  end;

  if fFileHandle <> INVALID_HANDLE_VALUE then
  begin
    finalBytes := fHeaderBytes + Int64(fNextIndex) * SizeOf(TSessionEvent);
    SeekFileBegin64(fFileHandle, finalBytes);
    SetEndOfFile(fFileHandle);
    CloseHandle(fFileHandle);
    fFileHandle := INVALID_HANDLE_VALUE;
  end;

  inherited;
end;

procedure TSessionFileSink.Consume(const Event: TSessionEvent);
var
  dest: PSessionEvent;
  offset: Int64;
begin
  if (fNextIndex - fChunkStartIndex) >= fChunkCapacity then
    ExtendAndRemap;

  offset := fHeaderBytes + Int64(fNextIndex) * SizeOf(TSessionEvent);
  dest := PSessionEvent(PByte(fMapView) + offset);
  dest^ := Event;

  Inc(fNextIndex);
  PSessionLogHeader(fHeaderView)^.EventCount := fNextIndex;
end;

procedure TSessionFileSink.ExtendAndRemap;
var
  newFileSize: Int64;
begin
  if fMapView <> nil then
  begin
    UnmapViewOfFile(fMapView);
    fMapView := nil;
  end;
  fHeaderView := nil;

  if fMappingHandle <> 0 then
  begin
    CloseHandle(fMappingHandle);
    fMappingHandle := 0;
  end;

  Inc(fChunkStartIndex, fChunkCapacity);
  newFileSize := fHeaderBytes + (Int64(fChunkStartIndex) * SizeOf(TSessionEvent)) + fChunkBytes;

  SeekFileBegin64(fFileHandle, newFileSize);
  if not SetEndOfFile(fFileHandle) then
    RaiseLastOSError;

  fMappingHandle := CreateFileMapping(fFileHandle, nil, PAGE_READWRITE, 0, 0, nil);
  if fMappingHandle = 0 then
    RaiseLastOSError;

  fMapView := MapViewOfFile(fMappingHandle, FILE_MAP_WRITE, 0, 0, 0);
  if fMapView = nil then
    RaiseLastOSError;

  fHeaderView := fMapView;
end;

function TSessionFileSink.EventCount: Integer;
begin
  Result := fNextIndex;
end;

// ---------------------------------------------------------------------------
// TSessionFileLog
// ---------------------------------------------------------------------------

constructor TSessionFileLog.Create(const AFilePath: string);
begin
  inherited Create;

  if AFilePath = '' then
    raise EOSError.Create('TSessionFileLog: file path must not be empty');

  fFilePath := AFilePath;
  fHeaderBytes := SizeOf(TSessionLogHeader);
  fFileHandle := INVALID_HANDLE_VALUE;
  fMappingHandle := 0;
  fView := nil;
  fMappedSize := 0;

  try
    fFileHandle := CreateFile(
      PChar(AFilePath),
      GENERIC_READ,
      FILE_SHARE_READ or FILE_SHARE_WRITE,
      nil,
      OPEN_EXISTING,
      FILE_ATTRIBUTE_NORMAL or FILE_FLAG_RANDOM_ACCESS,
      0);
    if fFileHandle = INVALID_HANDLE_VALUE then
      RaiseLastOSError;

    fMappingHandle := CreateFileMapping(fFileHandle, nil, PAGE_READONLY, 0, 0, nil);
    if fMappingHandle = 0 then
      RaiseLastOSError;

    fView := MapViewOfFile(fMappingHandle, FILE_MAP_READ, 0, 0, 0);
    if fView = nil then
      RaiseLastOSError;

    fMappedSize := GetFileSize64(fFileHandle);

  except
    if fView <> nil then
    begin
      UnmapViewOfFile(fView);
      fView := nil;
    end;
    if fMappingHandle <> 0 then
    begin
      CloseHandle(fMappingHandle);
      fMappingHandle := 0;
    end;
    if fFileHandle <> INVALID_HANDLE_VALUE then
    begin
      CloseHandle(fFileHandle);
      fFileHandle := INVALID_HANDLE_VALUE;
    end;
    raise;
  end;
end;

destructor TSessionFileLog.Destroy;
begin
  if fView <> nil then
  begin
    UnmapViewOfFile(fView);
    fView := nil;
  end;

  if fMappingHandle <> 0 then
  begin
    CloseHandle(fMappingHandle);
    fMappingHandle := 0;
  end;

  if fFileHandle <> INVALID_HANDLE_VALUE then
  begin
    CloseHandle(fFileHandle);
    fFileHandle := INVALID_HANDLE_VALUE;
  end;

  inherited;
end;

function TSessionFileLog.GetCount: Integer;
var
  eventCount: Integer;
  requiredSize: Int64;
begin
  eventCount := PSessionLogHeader(fView)^.EventCount;

  requiredSize := fHeaderBytes + Int64(eventCount) * SizeOf(TSessionEvent);
  if requiredSize > fMappedSize then
  begin
    if fView <> nil then
    begin
      UnmapViewOfFile(fView);
      fView := nil;
    end;
    if fMappingHandle <> 0 then
    begin
      CloseHandle(fMappingHandle);
      fMappingHandle := 0;
    end;

    fMappingHandle := CreateFileMapping(fFileHandle, nil, PAGE_READONLY, 0, 0, nil);
    if fMappingHandle = 0 then
      RaiseLastOSError;

    fView := MapViewOfFile(fMappingHandle, FILE_MAP_READ, 0, 0, 0);
    if fView = nil then
    begin
      CloseHandle(fMappingHandle);
      fMappingHandle := 0;
      RaiseLastOSError;
    end;

    fMappedSize := GetFileSize64(fFileHandle);
    eventCount := PSessionLogHeader(fView)^.EventCount;
  end;

  Result := eventCount;
end;

function TSessionFileLog.GetEvent(aIndex: Integer): TSessionEvent;
begin
  if (aIndex < 0) or (aIndex >= GetCount) then
    raise ERangeError.CreateFmt(
      'TSessionFileLog.GetEvent: index %d out of bounds (Count = %d)',
      [aIndex, GetCount]);

  Result := PSessionEvent(PByte(fView) + fHeaderBytes + aIndex * SizeOf(TSessionEvent))^;
end;

function TSessionFileLog.Header: TSessionLogHeader;
begin
  Result := PSessionLogHeader(fView)^;
end;

end.
