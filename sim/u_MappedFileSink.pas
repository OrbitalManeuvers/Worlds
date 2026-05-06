unit u_MappedFileSink;

{
  u_MappedFileSink — Memory-mapped file sink and reader for TSimEvent streams.

  SECURITY NOTE: Callers are responsible for sanitising file paths that originate
  from user input. This unit does not perform path traversal validation; it passes
  the supplied path directly to the Windows CreateFile API.

  TMappedFileSink  — ISimEventConsumer subscriber that records the full TSimEvent
                     stream into a chunked, pre-allocated memory-mapped backing file.
  TMappedFileLog   — IEventLog reader that provides indexed read-only access to a
                     backing file written by TMappedFileSink. Safe for concurrent
                     use while a live TMappedFileSink is writing to the same file.
}

interface

uses
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  u_SimDiagnosticsIntf,
  u_EventSinkIntf;

type
  /// <summary>
  ///   File header written at offset 0 of every .simlog backing file.
  ///   Magic lets any reader cheaply verify it has the right file type.
  ///   Version allows future readers to detect and handle older formats.
  ///   EventCount is the live write cursor — updated after every Consume call
  ///   so a concurrent read-only mapping can determine how many complete event
  ///   records are present without relying on file size (which includes padding).
  /// </summary>
  TSimLogHeader = record
    Magic:      Cardinal;  // file identity guard: $534C4F47 ('SLOG')
    Version:    Word;      // file format version, currently 1
    EventCount: Int64;     // writer updates this after every Consume call
  end;

  PSimLogHeader = ^TSimLogHeader;

  PSimEvent = ^TSimEvent;

  // -------------------------------------------------------------------------
  // TMappedFileSink
  // -------------------------------------------------------------------------

  /// <summary>
  ///   Implements ISimEventConsumer and subscribes to TSimDiagnosticsHub to
  ///   record the full TSimEvent stream into a memory-mapped file using chunked
  ///   pre-allocation. The caller passes a complete file path; the sink is
  ///   agnostic about naming conventions, directory structure, and file extension.
  /// </summary>
  TMappedFileSink = class(TInterfacedObject, ISimEventConsumer)
  private
    fFilePath:       string;
    fFileHandle:     THandle;      // CreateFile result
    fMappingHandle:  THandle;      // CreateFileMapping result
    fMapView:        Pointer;      // MapViewOfFile result — current chunk
    fHeaderView:     Pointer;      // mapped base pointer used for header writes (same mapping as fMapView)
    fNextIndex:      Int64;        // next write slot (absolute, across all chunks)
    fChunkBase:      Int64;        // absolute index of first event in current chunk
    fChunkCapacity:  Integer;      // actual events per chunk (rounded up for alignment)
    fChunkBytes:     Int64;        // actual bytes per chunk (multiple of allocation granularity)
    fHeaderBytes:    Integer;      // SizeOf(TSimLogHeader) — base offset for all event writes
    fFileHeader:     TSimLogHeader; // written at offset 0; EventCount updated after every Consume

    procedure ExtendAndRemap;
  public
    constructor Create(const AFilePath: string; AChunkEvents: Integer = 1000000);
    destructor Destroy; override;

    { ISimEventConsumer }
    procedure Consume(const Event: TSimEvent);

    { Diagnostics / inspection }
    function EventCount: Int64;
    function FilePath: string;
  end;

  // -------------------------------------------------------------------------
  // TMappedFileLog
  // -------------------------------------------------------------------------

  /// <summary>
  ///   Implements IEventLog against a .simlog backing file, providing indexed
  ///   read-only access to TSimEvent records for debug views and tooling.
  ///   Can be used concurrently with a live TMappedFileSink writing to the
  ///   same file.
  ///
  ///   KEY CONSTRAINT: Always use Count (sourced from header.EventCount) as the
  ///   upper bound for reads. Reading beyond Count into the pre-allocated region
  ///   returns zero-filled memory, not valid events.
  /// </summary>
  TMappedFileLog = class(TInterfacedObject, IEventLog)
  private
    fFilePath:      string;
    fFileHandle:    THandle;
    fMappingHandle: THandle;
    fView:          Pointer;
    fHeaderBytes:   Integer;
    fMappedSize:    Int64;
  public
    constructor Create(const AFilePath: string);
    destructor Destroy; override;

    { IEventLog }
    { TODO: remove when IEventLog is cleaned up }
    procedure Subscribe(const aHandler: TNotifyEvent);
    { TODO: remove when IEventLog is cleaned up }
    procedure Unsubscribe(const aHandler: TNotifyEvent);
    function GetCount: Integer;
    function GetEvent(aIndex: Integer): TSimEvent;

    { Inspection }
    function Header: TSimLogHeader;

    property Count: Integer read GetCount;
    property Events[aIndex: Integer]: TSimEvent read GetEvent;
  end;

implementation

function GetFileSize64(AFileHandle: THandle): Int64;
var
  size: Int64;
begin
  if not GetFileSizeEx(AFileHandle, size) then
    RaiseLastOSError;
  Result := size;
end;

procedure SeekFileBegin64(AFileHandle: THandle; AOffset: Int64);
var
  offsetParts: Int64Rec;
  highPart: Longint;
  lowPart: DWORD;
begin
  offsetParts := Int64Rec(AOffset);
  highPart := offsetParts.Hi;
  lowPart := SetFilePointer(AFileHandle, Longint(offsetParts.Lo), @highPart, FILE_BEGIN);
  if (lowPart = DWORD($FFFFFFFF)) and (GetLastError <> NO_ERROR) then
    RaiseLastOSError;
end;

{ TMappedFileSink }

constructor TMappedFileSink.Create(const AFilePath: string; AChunkEvents: Integer);
var
  sysInfo:   TSystemInfo;
  grain:     Int64;
  recSize:   Int64;
  li:        Int64Rec;
begin
  inherited Create;

  // Initialize fields.
  fFilePath      := AFilePath;
  fNextIndex     := 0;
  fChunkBase     := 0;
  fFileHandle    := INVALID_HANDLE_VALUE;
  fMappingHandle := 0;
  fMapView       := nil;
  fHeaderView    := nil;

  // Compute aligned chunk geometry.
  fHeaderBytes := SizeOf(TSimLogHeader);
  GetSystemInfo(sysInfo);
  grain   := sysInfo.dwAllocationGranularity;
  recSize := SizeOf(TSimEvent);
  fChunkBytes := ((Int64(fHeaderBytes) + Int64(AChunkEvents) * recSize + grain - 1) div grain) * grain;

  // Number of whole events that fit after the header.
  fChunkCapacity := (fChunkBytes - fHeaderBytes) div recSize;

  try
    // Create backing file; fail if it already exists.
    // Caller is responsible for ensuring the path does not already exist.
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

    // Pre-allocate the first chunk.
    SeekFileBegin64(fFileHandle, fChunkBytes);
    if not SetEndOfFile(fFileHandle) then
      RaiseLastOSError;

    // Create writable mapping for the initial file size.
    li := Int64Rec(fChunkBytes);
    fMappingHandle := CreateFileMapping(fFileHandle, nil, PAGE_READWRITE, li.Hi, li.Lo, nil);
    if fMappingHandle = 0 then
      RaiseLastOSError;

    fMapView := MapViewOfFile(fMappingHandle, FILE_MAP_WRITE, 0, 0, fChunkBytes);
    if fMapView = nil then
      RaiseLastOSError;

    // Initialize file header at offset 0.
    fFileHeader.Magic      := $534C4F47;  // 'SLOG'
    fFileHeader.Version    := 1;
    fFileHeader.EventCount := 0;
    PSimLogHeader(fMapView)^ := fFileHeader;
    fHeaderView := fMapView;  // header lives at offset 0 of the current mapping

  except
    // Exception guard: close any already-opened handles, then re-raise.
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

destructor TMappedFileSink.Destroy;
var
  finalBytes: Int64;
begin
  // fHeaderView shares the same mapping as fMapView.
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

  // Truncate to the exact logical payload: header + written events.
  if fFileHandle <> INVALID_HANDLE_VALUE then
  begin
    finalBytes  := fHeaderBytes + fNextIndex * SizeOf(TSimEvent);
    SeekFileBegin64(fFileHandle, finalBytes);
    SetEndOfFile(fFileHandle);
    CloseHandle(fFileHandle);
    fFileHandle := INVALID_HANDLE_VALUE;
  end;

  inherited;
end;

procedure TMappedFileSink.Consume(const Event: TSimEvent);
var
  dest: PSimEvent;
  absoluteOffset: NativeInt;
begin
  // Grow when the current chunk is full.
  if (fNextIndex - fChunkBase) >= fChunkCapacity then
    ExtendAndRemap;

  // fMapView is mapped from offset 0; event N lives at header + N*recordSize.
  absoluteOffset := fHeaderBytes + fNextIndex * SizeOf(TSimEvent);
  dest := PSimEvent(PByte(fMapView) + absoluteOffset);

  // Preserve SessionId/Sequence stamped by the diagnostics hub.
  dest^ := Event;

  Inc(fNextIndex);

  // Keep header.EventCount as the live logical cursor.
  PSimLogHeader(fHeaderView)^.EventCount := fNextIndex;
end;

procedure TMappedFileSink.ExtendAndRemap;
var
  newFileSize: Int64;
begin
  // Drop current mapping before extending/remapping.
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

  // Advance chunk base to the first index of the next chunk.
  Inc(fChunkBase, fChunkCapacity);

  // Reserve one additional chunk beyond the existing logical span.
  newFileSize := fHeaderBytes + (fChunkBase * SizeOf(TSimEvent)) + fChunkBytes;

  // Extend file to the requested size.
  SeekFileBegin64(fFileHandle, newFileSize);
  if not SetEndOfFile(fFileHandle) then
    RaiseLastOSError;

  // Recreate mapping over current file size.
  fMappingHandle := CreateFileMapping(fFileHandle, nil, PAGE_READWRITE, 0, 0, nil);
  if fMappingHandle = 0 then
    RaiseLastOSError;

  // Map from offset 0 to avoid allocation-granularity offset constraints.
  fMapView := MapViewOfFile(fMappingHandle, FILE_MAP_WRITE, 0, 0, 0);
  if fMapView = nil then
    RaiseLastOSError;

  fHeaderView := fMapView;
end;

function TMappedFileSink.EventCount: Int64;
begin
  Result := fNextIndex;
end;

function TMappedFileSink.FilePath: string;
begin
  Result := fFilePath;
end;

{ TMappedFileLog }

constructor TMappedFileLog.Create(const AFilePath: string);
begin
  inherited Create;

  if AFilePath = '' then
    raise EOSError.Create('TMappedFileLog: file path must not be empty');

  fFilePath    := AFilePath;
  fHeaderBytes := SizeOf(TSimLogHeader);
  fFileHandle  := INVALID_HANDLE_VALUE;
  fMappingHandle := 0;
  fView        := nil;
  fMappedSize  := 0;

  try
    // Open existing file read-only; allow concurrent writer access.
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

    // Create read-only mapping for the current file size.
    fMappingHandle := CreateFileMapping(fFileHandle, nil, PAGE_READONLY, 0, 0, nil);
    if fMappingHandle = 0 then
      RaiseLastOSError;

    fView := MapViewOfFile(fMappingHandle, FILE_MAP_READ, 0, 0, 0);
    if fView = nil then
      RaiseLastOSError;

    // Track mapped size so GetCount can detect growth and remap.
    fMappedSize := GetFileSize64(fFileHandle);

  except
    // Clean up any handles opened before failure, then re-raise.
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

destructor TMappedFileLog.Destroy;
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

procedure TMappedFileLog.Subscribe(const aHandler: TNotifyEvent);
begin
  { TODO: remove when IEventLog is cleaned up }
end;

procedure TMappedFileLog.Unsubscribe(const aHandler: TNotifyEvent);
begin
  { TODO: remove when IEventLog is cleaned up }
end;

function TMappedFileLog.GetCount: Integer;
var
  eventCount: Int64;
  requiredSize: Int64;
begin
  // Read live EventCount from header at offset 0.
  eventCount := PSimLogHeader(fView)^.EventCount;

  // Remap-on-growth when writer extends beyond current view.
  requiredSize := fHeaderBytes + eventCount * SizeOf(TSimEvent);
  if requiredSize > fMappedSize then
  begin
    // Release stale view and mapping handle.
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

    // Recreate read-only mapping for the new file size.
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

    // Refresh tracked mapped size.
    fMappedSize := GetFileSize64(fFileHandle);

    // Re-read EventCount from the refreshed view.
    eventCount := PSimLogHeader(fView)^.EventCount;
  end;

  Result := eventCount;
end;

function TMappedFileLog.GetEvent(aIndex: Integer): TSimEvent;
begin
  // Count is called here so the view is current before reading.
  if (aIndex < 0) or (aIndex >= GetCount) then
    raise ERangeError.CreateFmt(
      'TMappedFileLog.GetEvent: index %d is out of bounds (Count = %d)',
      [aIndex, GetCount]);

  // Direct pointer read at header + N*recordSize.
  Result := PSimEvent(PByte(fView) + fHeaderBytes + aIndex * SizeOf(TSimEvent))^;
end;

function TMappedFileLog.Header: TSimLogHeader;
begin
  Result := PSimLogHeader(fView)^;
end;

end.
