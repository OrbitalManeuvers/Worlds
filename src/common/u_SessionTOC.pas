unit u_SessionTOC;

interface

uses System.Generics.Collections;

type
  TSessionTOCSegment = record
    SegmentIndex: Integer;

    FirstSequence: Integer;
    LastSequence: Integer;

    FirstDayNumber: Integer;
    FirstDayTick: Integer;
    LastDayNumber: Integer;
    LastDayTick: Integer;

    SavedStartEventIndex: Integer;
    SavedEventCount: Integer;
  end;

  TSessionTOC = class
  private
    fSegments: TList<TSessionTOCSegment>;
    function GetCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    procedure AddSegment(const aSegment: TSessionTOCSegment);
    function ToArray: TArray<TSessionTOCSegment>;

    function LoadFromFile(const aFileName: string): Boolean;
    procedure SaveToFile(const aFileName: string);

    property Count: Integer read GetCount;
  end;

implementation

uses System.SysUtils, System.JSON, System.IOUtils;

const
  SESSION_TOC_VERSION = 1;

  KEY_VERSION = 'version';
  KEY_SEGMENTS = 'segments';

  KEY_SEGMENT_INDEX = 'segmentIndex';
  KEY_FIRST_SEQUENCE = 'firstSequence';
  KEY_LAST_SEQUENCE = 'lastSequence';

  KEY_FIRST_DAY_NUMBER = 'firstDayNumber';
  KEY_FIRST_DAY_TICK = 'firstDayTick';
  KEY_LAST_DAY_NUMBER = 'lastDayNumber';
  KEY_LAST_DAY_TICK = 'lastDayTick';

  KEY_SAVED_START_EVENT_INDEX = 'savedStartEventIndex';
  KEY_SAVED_EVENT_COUNT = 'savedEventCount';

{ TSessionTOC }

constructor TSessionTOC.Create;
begin
  inherited;
  fSegments := TList<TSessionTOCSegment>.Create;
end;

destructor TSessionTOC.Destroy;
begin
  fSegments.Free;
  inherited;
end;

procedure TSessionTOC.Clear;
begin
  fSegments.Clear;
end;

procedure TSessionTOC.AddSegment(const aSegment: TSessionTOCSegment);
begin
  fSegments.Add(aSegment);
end;

function TSessionTOC.GetCount: Integer;
begin
  Result := fSegments.Count;
end;

function TSessionTOC.ToArray: TArray<TSessionTOCSegment>;
begin
  Result := fSegments.ToArray;
end;

function TSessionTOC.LoadFromFile(const aFileName: string): Boolean;
begin
  Clear;
  Result := False;

  if not TFile.Exists(aFileName) then
    Exit;

  var root := TJSONObject.ParseJSONValue(TFile.ReadAllText(aFileName, TEncoding.UTF8)) as TJSONObject;
  try
    if not Assigned(root) then
      Exit;

    var jsonSegments: TJSONArray;
    if not root.TryGetValue<TJSONArray>(KEY_SEGMENTS, jsonSegments) then
      Exit;

    for var index := 0 to jsonSegments.Count - 1 do
    begin
      var jsonSegment := jsonSegments.Items[index] as TJSONObject;
      if not Assigned(jsonSegment) then
        Continue;

      var segment := Default(TSessionTOCSegment);
      jsonSegment.TryGetValue<Integer>(KEY_SEGMENT_INDEX, segment.SegmentIndex);
      jsonSegment.TryGetValue<Integer>(KEY_FIRST_SEQUENCE, segment.FirstSequence);
      jsonSegment.TryGetValue<Integer>(KEY_LAST_SEQUENCE, segment.LastSequence);

      jsonSegment.TryGetValue<Integer>(KEY_FIRST_DAY_NUMBER, segment.FirstDayNumber);
      jsonSegment.TryGetValue<Integer>(KEY_FIRST_DAY_TICK, segment.FirstDayTick);
      jsonSegment.TryGetValue<Integer>(KEY_LAST_DAY_NUMBER, segment.LastDayNumber);
      jsonSegment.TryGetValue<Integer>(KEY_LAST_DAY_TICK, segment.LastDayTick);

      jsonSegment.TryGetValue<Integer>(KEY_SAVED_START_EVENT_INDEX, segment.SavedStartEventIndex);
      jsonSegment.TryGetValue<Integer>(KEY_SAVED_EVENT_COUNT, segment.SavedEventCount);

      AddSegment(segment);
    end;

    Result := True;
  finally
    root.Free;
  end;
end;

procedure TSessionTOC.SaveToFile(const aFileName: string);
begin
  Assert(not aFileName.Trim.IsEmpty);

  var root := TJSONObject.Create;
  try
    root.AddPair(KEY_VERSION, TJSONNumber.Create(SESSION_TOC_VERSION));

    var jsonSegments := TJSONArray.Create;
    for var segment in fSegments do
    begin
      var jsonSegment := TJSONObject.Create;
      jsonSegment.AddPair(KEY_SEGMENT_INDEX, TJSONNumber.Create(segment.SegmentIndex));
      jsonSegment.AddPair(KEY_FIRST_SEQUENCE, TJSONNumber.Create(segment.FirstSequence));
      jsonSegment.AddPair(KEY_LAST_SEQUENCE, TJSONNumber.Create(segment.LastSequence));

      jsonSegment.AddPair(KEY_FIRST_DAY_NUMBER, TJSONNumber.Create(segment.FirstDayNumber));
      jsonSegment.AddPair(KEY_FIRST_DAY_TICK, TJSONNumber.Create(segment.FirstDayTick));
      jsonSegment.AddPair(KEY_LAST_DAY_NUMBER, TJSONNumber.Create(segment.LastDayNumber));
      jsonSegment.AddPair(KEY_LAST_DAY_TICK, TJSONNumber.Create(segment.LastDayTick));

      jsonSegment.AddPair(KEY_SAVED_START_EVENT_INDEX, TJSONNumber.Create(segment.SavedStartEventIndex));
      jsonSegment.AddPair(KEY_SAVED_EVENT_COUNT, TJSONNumber.Create(segment.SavedEventCount));

      jsonSegments.AddElement(jsonSegment);
    end;

    root.AddPair(KEY_SEGMENTS, jsonSegments);

    var folder := TPath.GetDirectoryName(aFileName);
    if (folder <> '') and not TDirectory.Exists(folder) then
      TDirectory.CreateDirectory(folder);

    TFile.WriteAllText(aFileName, root.Format(4), TEncoding.UTF8);
  finally
    root.Free;
  end;
end;

end.
