{-------------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: SynHighlighterBat.pas, released 2000-04-18.
The Original Code is based on the dmBatSyn.pas file from the
mwEdit component suite by Martin Waldenburg and other developers, the Initial
Author of this file is David H. Muir.
Unicode translation by Ma�l H�rz.
All Rights Reserved.

Contributors to the SynEdit and mwEdit projects are listed in the
Contributors.txt file.

Alternatively, the contents of this file may be used under the terms of the
GNU General Public License Version 2 or later (the "GPL"), in which case
the provisions of the GPL are applicable instead of those above.
If you wish to allow use of your version of this file only under the terms
of the GPL and not to allow others to use your version of this file
under the MPL, indicate your decision by deleting the provisions above and
replace them with the notice and other provisions required by the GPL.
If you do not delete the provisions above, a recipient may use your version
of this file under either the MPL or the GPL.

$Id: SynHighlighterBat.pas,v 1.14.2.6 2008/09/14 16:24:59 maelh Exp $

You may retrieve the latest version of this file at the SynEdit home page,
located at http://SynEdit.SourceForge.net

Known Issues:
-------------------------------------------------------------------------------}
{
@abstract(Provides a MS-DOS Batch file highlighter for SynEdit)
@author(David Muir <dhm@dmsoftware.co.uk>)
@created(Late 1999)
@lastmod(May 19, 2000)
The SynHighlighterBat unit provides SynEdit with a MS-DOS Batch file (.bat) highlighter.
The highlighter supports the formatting of keywords and parameters (batch file arguments).
}

unit SynEdit32.Highlighter.Bat;

{$I SynEdit.inc}

interface

uses
  Graphics,
  SynEdit32.Types,
  SynEdit32.Highlighter,
  SynEdit32.Unicode,
  SysUtils,
  Classes;

type
  TtkTokenKind = (tkComment, tkIdentifier, tkKey, tkNull, tkNumber, tkSpace,
    tkUnknown, tkVariable);

  PIdentFuncTableFunc = ^TIdentFuncTableFunc;
  TIdentFuncTableFunc = function (Index: Integer): TtkTokenKind of object;

type
  TSynEdit32HighlighterBat = class(TSynEdit32CustomHighlighter)
  private
    FIdentFuncTable: array[0..24] of TIdentFuncTableFunc;
    FTokenID: TtkTokenKind;
    FCommentAttri: TSynEdit32HighlighterAttributes;
    FIdentifierAttri: TSynEdit32HighlighterAttributes;
    FKeyAttri: TSynEdit32HighlighterAttributes;
    FNumberAttri: TSynEdit32HighlighterAttributes;
    FSpaceAttri: TSynEdit32HighlighterAttributes;
    FVariableAttri: TSynEdit32HighlighterAttributes;
    function AltFunc(Index: Integer): TtkTokenKind;
    function FuncCall(Index: Integer): TtkTokenKind;
    function FuncCd(Index: Integer): TtkTokenKind;
    function FuncCls(Index: Integer): TtkTokenKind;
    function FuncCopy(Index: Integer): TtkTokenKind;
    function FuncDel(Index: Integer): TtkTokenKind;
    function FuncDo(Index: Integer): TtkTokenKind;
    function FuncEcho(Index: Integer): TtkTokenKind;
    function FuncErrorlevel(Index: Integer): TtkTokenKind;
    function FuncExist(Index: Integer): TtkTokenKind;
    function FuncFor(Index: Integer): TtkTokenKind;
    function FuncGoto(Index: Integer): TtkTokenKind;
    function FuncIf(Index: Integer): TtkTokenKind;
    function FuncIn(Index: Integer): TtkTokenKind;
    function FuncNot(Index: Integer): TtkTokenKind;
    function FuncOff(Index: Integer): TtkTokenKind;
    function FuncOn(Index: Integer): TtkTokenKind;
    function FuncPause(Index: Integer): TtkTokenKind;
    function FuncSet(Index: Integer): TtkTokenKind;
    function FuncShift(Index: Integer): TtkTokenKind;
    function FuncStart(Index: Integer): TtkTokenKind;
    function FuncTitle(Index: Integer): TtkTokenKind;
    function HashKey(Str: PWideChar): Cardinal;
    function IdentKind(MayBe: PWideChar): TtkTokenKind;
    procedure InitIdent;
    procedure VariableProc;
    procedure CRProc;
    procedure CommentProc;
    procedure IdentProc;
    procedure LFProc;
    procedure NullProc;
    procedure NumberProc;
    procedure REMCommentProc;
    procedure SpaceProc;
    procedure UnknownProc;
  protected
    function GetSampleSource: UnicodeString; override;
    function IsFilterStored: Boolean; override;
  public
    class function GetLanguageName: string; override;
    class function GetFriendlyLanguageName: UnicodeString; override;
  public
    constructor Create(AOwner: TComponent); override;        
    function GetDefaultAttribute(Index: integer): TSynEdit32HighlighterAttributes;
      override;
    function GetTokenID: TtkTokenKind;
    function GetTokenAttribute: TSynEdit32HighlighterAttributes; override;
    function GetTokenKind: integer; override;
    procedure Next; override;
  published
    property CommentAttri: TSynEdit32HighlighterAttributes read FCommentAttri
      write FCommentAttri;
    property IdentifierAttri: TSynEdit32HighlighterAttributes read FIdentifierAttri
      write FIdentifierAttri;
    property KeyAttri: TSynEdit32HighlighterAttributes read FKeyAttri write FKeyAttri;
    property NumberAttri: TSynEdit32HighlighterAttributes read FNumberAttri
      write FNumberAttri;
    property SpaceAttri: TSynEdit32HighlighterAttributes read FSpaceAttri
      write FSpaceAttri;
    property VariableAttri: TSynEdit32HighlighterAttributes read FVariableAttri
      write FVariableAttri;
  end;

implementation

uses
  SynEdit32.StrConst;

const
  KeyWords: array[0..20] of UnicodeString = (
    'call', 'cd', 'cls', 'copy', 'del', 'do', 'echo', 'errorlevel', 'exist', 
    'for', 'goto', 'if', 'in', 'not', 'off', 'on', 'pause', 'set', 'shift', 
    'start', 'title' 
  );

  KeyIndices: array[0..24] of Integer = (
    14, 4, -1, 6, 17, 12, 8, 18, 19, 15, -1, -1, 10, 3, 13, 0, 1, 11, 20, 7, 2, 
    5, -1, 16, 9 
  );

{$Q-}
function TSynEdit32HighlighterBat.HashKey(Str: PWideChar): Cardinal;
begin
  Result := 0;
  while IsIdentChar(Str^) do
  begin
    Result := Result * 869 + Ord(Str^) * 61;
    Inc(Str);
  end;
  Result := Result mod 25;
  FStringLen := Str - FToIdent;
end;
{$Q+}

function TSynEdit32HighlighterBat.IdentKind(MayBe: PWideChar): TtkTokenKind;
var
  Key: Cardinal;
begin
  FToIdent := MayBe;
  Key := HashKey(MayBe);
  if Key <= High(FIdentFuncTable) then
    Result := FIdentFuncTable[Key](KeyIndices[Key])
  else
    Result := tkIdentifier;
end;

procedure TSynEdit32HighlighterBat.InitIdent;
var
  i: Integer;
begin
  for i := Low(FIdentFuncTable) to High(FIdentFuncTable) do
    if KeyIndices[i] = -1 then
      FIdentFuncTable[i] := AltFunc;
      
  FIdentFuncTable[15] := FuncCall;
  FIdentFuncTable[16] := FuncCd;
  FIdentFuncTable[20] := FuncCls;
  FIdentFuncTable[13] := FuncCopy;
  FIdentFuncTable[1] := FuncDel;
  FIdentFuncTable[21] := FuncDo;
  FIdentFuncTable[3] := FuncEcho;
  FIdentFuncTable[19] := FuncErrorlevel;
  FIdentFuncTable[6] := FuncExist;
  FIdentFuncTable[24] := FuncFor;
  FIdentFuncTable[12] := FuncGoto;
  FIdentFuncTable[17] := FuncIf;
  FIdentFuncTable[5] := FuncIn;
  FIdentFuncTable[14] := FuncNot;
  FIdentFuncTable[0] := FuncOff;
  FIdentFuncTable[9] := FuncOn;
  FIdentFuncTable[23] := FuncPause;
  FIdentFuncTable[4] := FuncSet;
  FIdentFuncTable[7] := FuncShift;
  FIdentFuncTable[8] := FuncStart;
  FIdentFuncTable[18] := FuncTitle;
end;

function TSynEdit32HighlighterBat.AltFunc(Index: Integer): TtkTokenKind;
begin
  Result := tkIdentifier
end;

function TSynEdit32HighlighterBat.FuncCall(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterBat.FuncCd(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterBat.FuncCls(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterBat.FuncCopy(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterBat.FuncDel(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterBat.FuncDo(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterBat.FuncEcho(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterBat.FuncErrorlevel(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterBat.FuncExist(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterBat.FuncFor(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterBat.FuncGoto(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterBat.FuncIf(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterBat.FuncIn(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterBat.FuncNot(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterBat.FuncOff(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterBat.FuncOn(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterBat.FuncPause(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterBat.FuncSet(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterBat.FuncShift(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterBat.FuncStart(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynEdit32HighlighterBat.FuncTitle(Index: Integer): TtkTokenKind;
begin
  if IsCurrentToken(KeyWords[Index]) then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

constructor TSynEdit32HighlighterBat.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FCaseSensitive := False;

  FCommentAttri := TSynEdit32HighlighterAttributes.Create(SYNS_AttrComment, SYNS_FriendlyAttrComment);
  FCommentAttri.Style := [fsItalic];
  FCommentAttri.Foreground := clNavy;
  AddAttribute(FCommentAttri);
  FIdentifierAttri := TSynEdit32HighlighterAttributes.Create(SYNS_AttrIdentifier, SYNS_FriendlyAttrIdentifier);
  AddAttribute(FIdentifierAttri);
  FKeyAttri := TSynEdit32HighlighterAttributes.Create(SYNS_AttrKey, SYNS_FriendlyAttrKey);
  FKeyAttri.Style := [fsBold];
  AddAttribute(FKeyAttri);
  FNumberAttri := TSynEdit32HighlighterAttributes.Create(SYNS_AttrNumber, SYNS_FriendlyAttrNumber);
  FNumberAttri.Foreground := clBlue;
  AddAttribute(FNumberAttri);
  FSpaceAttri := TSynEdit32HighlighterAttributes.Create(SYNS_AttrSpace, SYNS_FriendlyAttrSpace);
  AddAttribute(FSpaceAttri);
  FVariableAttri := TSynEdit32HighlighterAttributes.Create(SYNS_AttrVariable, SYNS_FriendlyAttrVariable);
  FVariableAttri.Foreground := clGreen;
  AddAttribute(FVariableAttri);
  SetAttributesOnChange(DefHighlightChange);
  InitIdent;
  fDefaultFilter := SYNS_FilterBatch;
end;

procedure TSynEdit32HighlighterBat.VariableProc;

  function IsVarChar: Boolean;
  begin
    case FLine[FRun] of
      '_', '0'..'9', 'A'..'Z', 'a'..'z':
        Result := True;
      else
        Result := False;
    end;
  end;

begin
  FTokenID := tkVariable;
  repeat
    Inc(FRun);
  until not IsVarChar;
  if FLine[FRun] = '%' then
    Inc(FRun);
end;

procedure TSynEdit32HighlighterBat.CRProc;
begin
  FTokenID := tkSpace;
  Inc(FRun);
  if (FLine[FRun] = #10) then Inc(FRun);
end;

procedure TSynEdit32HighlighterBat.CommentProc;
begin
  FTokenID := tkIdentifier;
  Inc(FRun);
  if FLine[FRun] = ':' then begin
    FTokenID := tkComment;
    repeat
      Inc(FRun);
    until IsLineEnd(FRun);
  end;
end;

procedure TSynEdit32HighlighterBat.IdentProc;
begin
  FTokenID := IdentKind((FLine + FRun));
  Inc(FRun, FStringLen);
  while IsIdentChar(FLine[FRun]) do Inc(FRun);
end;

procedure TSynEdit32HighlighterBat.LFProc;
begin
  FTokenID := tkSpace;
  Inc(FRun);
end;

procedure TSynEdit32HighlighterBat.NullProc;
begin
  FTokenID := tkNull;
  Inc(FRun);
end;

procedure TSynEdit32HighlighterBat.NumberProc;
begin
  FTokenID := tkNumber;
  repeat
    Inc(FRun);
  until not CharInSet(FLine[FRun], ['0'..'9', '.']);
end;

procedure TSynEdit32HighlighterBat.REMCommentProc;
begin
  if CharInSet(FLine[FRun + 1], ['E', 'e']) and
    CharInSet(FLine[FRun + 2], ['M', 'm']) and
    (FLine[FRun + 3] < #33) then
  begin
    FTokenID := tkComment;
    Inc(FRun, 3);
    while (FLine[FRun] <> #0) do begin
      case FLine[FRun] of
        #10, #13: break;
      end; { case }
      Inc(FRun);
    end; { while }
  end
  else
  begin
    FTokenID := tkIdentifier;
    IdentProc;
  end;
end;

procedure TSynEdit32HighlighterBat.SpaceProc;
begin
  FTokenID := tkSpace;
  repeat
    Inc(FRun);
  until (FLine[FRun] > #32) or IsLineEnd(FRun);
end;

procedure TSynEdit32HighlighterBat.UnknownProc;
begin
  Inc(FRun);
  FTokenID := tkUnknown;
end;

procedure TSynEdit32HighlighterBat.Next;
begin
  fTokenPos := FRun;

  case FLine[FRun] of
    '%': VariableProc;
    #13: CRProc;
    ':': CommentProc;
    'A'..'Q', 'S'..'Z', 'a'..'q', 's'..'z', '_': IdentProc;
    #10: LFProc;
    #0: NullProc;
    '0'..'9': NumberProc;
    'R', 'r': REMCommentProc;
    #1..#9, #11, #12, #14..#32: SpaceProc;
    else
      UnknownProc;
  end;
  inherited;
end;

function TSynEdit32HighlighterBat.GetDefaultAttribute(Index: integer): TSynEdit32HighlighterAttributes;
begin
  case Index of
    SYN_ATTR_COMMENT: Result := FCommentAttri;
    SYN_ATTR_IDENTIFIER: Result := FIdentifierAttri;
    SYN_ATTR_KEYWORD: Result := FKeyAttri;
    SYN_ATTR_WHITESPACE: Result := FSpaceAttri;
  else
    Result := nil;
  end;
end;

function TSynEdit32HighlighterBat.GetTokenAttribute: TSynEdit32HighlighterAttributes;
begin
  case FTokenID of
    tkComment: Result := FCommentAttri;
    tkIdentifier: Result := FIdentifierAttri;
    tkKey: Result := FKeyAttri;
    tkNumber: Result := FNumberAttri;
    tkSpace: Result := FSpaceAttri;
    tkUnknown: Result := FIdentifierAttri;
    tkVariable: Result := FVariableAttri;
    else Result := nil;
  end;
end;

function TSynEdit32HighlighterBat.GetTokenID: TtkTokenKind;
begin
  Result := FTokenID;
end;

function TSynEdit32HighlighterBat.GetTokenKind: integer;
begin
  Result := Ord(FTokenID);
end;

function TSynEdit32HighlighterBat.IsFilterStored: Boolean;
begin
  Result := fDefaultFilter <> SYNS_FilterBatch;
end;

class function TSynEdit32HighlighterBat.GetLanguageName: string;
begin
  Result := SYNS_LangBatch;
end;

function TSynEdit32HighlighterBat.GetSampleSource: UnicodeString;
begin
  Result := 'rem MS-DOS batch file'#13#10 +
            'rem'#13#10 +
            '@echo off'#13#10 +
            'cls'#13#10 +
            'echo The command line is: %1 %2 %3 %4 %5'#13#10 +
            'rem'#13#10 +
            'rem now wait for the user ...'#13#10 +
            'pause'#13#10 +
            'copy c:\*.pas d:\'#13#10 +
            'if errorlevel 1 echo Error in copy action!';
end;

class function TSynEdit32HighlighterBat.GetFriendlyLanguageName: UnicodeString;
begin
  Result := SYNS_FriendlyLangBatch;
end;

initialization
  RegisterPlaceableHighlighter(TSynEdit32HighlighterBat);
end.
