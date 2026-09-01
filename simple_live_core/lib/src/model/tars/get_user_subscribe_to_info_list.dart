import 'package:tars_dart/tars/codec/tars_displayer.dart';
import 'package:tars_dart/tars/codec/tars_input_stream.dart';
import 'package:tars_dart/tars/codec/tars_output_stream.dart';
import 'package:tars_dart/tars/codec/tars_struct.dart';

import 'huya_user_id.dart';

class GetUserSubscribeToInfoListReq extends TarsStruct {
  HuyaUserId tId = HuyaUserId();
  int iPageIndex = 0;

  @override
  void readFrom(TarsInputStream input) {
    tId = input.read(tId, 0, false);
    iPageIndex = input.read(iPageIndex, 1, false);
  }

  @override
  void writeTo(TarsOutputStream output) {
    output.write(tId, 0);
    output.write(iPageIndex, 1);
  }

  @override
  TarsStruct deepCopy() => GetUserSubscribeToInfoListReq()
    ..tId = tId
    ..iPageIndex = iPageIndex;

  @override
  void displayAsString(StringBuffer sb, int level) {
    final display = TarsDisplayer(sb, level: level);
    display.DisplayTarsStruct(tId, 'tId');
    display.DisplayInt(iPageIndex, 'iPageIndex');
  }
}

class GetUserSubscribeToInfoListRsp extends TarsStruct {
  String sMessage = '';
  List<UserSubscribeToInfo> vItems = [UserSubscribeToInfo()];
  int iTotal = 0;
  int iPageSize = 0;
  int iPageIndex = 0;

  @override
  void readFrom(TarsInputStream input) {
    sMessage = input.read(sMessage, 0, false);
    vItems = input.readList(vItems, 1, false);
    iTotal = input.read(iTotal, 2, false);
    iPageSize = input.read(iPageSize, 3, false);
    iPageIndex = input.read(iPageIndex, 4, false);
  }

  @override
  void writeTo(TarsOutputStream output) {
    output.write(sMessage, 0);
    output.write(vItems, 1);
    output.write(iTotal, 2);
    output.write(iPageSize, 3);
    output.write(iPageIndex, 4);
  }

  @override
  TarsStruct deepCopy() => GetUserSubscribeToInfoListRsp()
    ..sMessage = sMessage
    ..vItems = vItems
    ..iTotal = iTotal
    ..iPageSize = iPageSize
    ..iPageIndex = iPageIndex;

  @override
  void displayAsString(StringBuffer sb, int level) {
    final display = TarsDisplayer(sb, level: level);
    display.DisplayString(sMessage, 'sMessage');
    display.DisplayInt(iTotal, 'iTotal');
    display.DisplayInt(iPageSize, 'iPageSize');
    display.DisplayInt(iPageIndex, 'iPageIndex');
  }
}

class UserSubscribeToInfo extends TarsStruct {
  int lUid = 0;
  int lYYId = 0;
  String sNick = '';
  String sPrivateHost = '';
  String sAvatar = '';
  int iRoomId = 0;
  String sVideoCaptureUrl = '';

  @override
  void readFrom(TarsInputStream input) {
    lUid = input.read(lUid, 0, false);
    lYYId = input.read(lYYId, 1, false);
    sNick = input.read(sNick, 2, false);
    sPrivateHost = input.read(sPrivateHost, 3, false);
    sAvatar = input.read(sAvatar, 4, false);
    iRoomId = input.read(iRoomId, 5, false);
    sVideoCaptureUrl = input.read(sVideoCaptureUrl, 13, false);
  }

  @override
  void writeTo(TarsOutputStream output) {
    output.write(lUid, 0);
    output.write(lYYId, 1);
    output.write(sNick, 2);
    output.write(sPrivateHost, 3);
    output.write(sAvatar, 4);
    output.write(iRoomId, 5);
    output.write(sVideoCaptureUrl, 13);
  }

  @override
  TarsStruct deepCopy() => UserSubscribeToInfo()
    ..lUid = lUid
    ..lYYId = lYYId
    ..sNick = sNick
    ..sPrivateHost = sPrivateHost
    ..sAvatar = sAvatar
    ..iRoomId = iRoomId
    ..sVideoCaptureUrl = sVideoCaptureUrl;

  @override
  void displayAsString(StringBuffer sb, int level) {
    final display = TarsDisplayer(sb, level: level);
    display.DisplayInt(lUid, 'lUid');
    display.DisplayString(sNick, 'sNick');
    display.DisplayString(sAvatar, 'sAvatar');
    display.DisplayInt(iRoomId, 'iRoomId');
  }
}
