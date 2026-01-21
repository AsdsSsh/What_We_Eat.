import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _prefsKey = 'deviceUniqueId';

Future<String> getOrCreateDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  final cached = prefs.getString(_prefsKey);
  if (cached != null && cached.isNotEmpty) return cached;

  final plugin = DeviceInfoPlugin();
  String? hardwareId;
    if (Platform.isAndroid) {
    final info = await plugin.androidInfo;
    hardwareId =
        (info.id.isNotEmpty == true ? info.id : null) ??
        (info.fingerprint.isNotEmpty == true ? info.fingerprint : null);
  } else if (Platform.isIOS) {
    final info = await plugin.iosInfo;
    hardwareId = info.identifierForVendor;
  }
  //  如果没有获得硬件标识，则生成一个随机 UUID
  // 这里后续可能需要提醒用户无法获取硬件 ID 的情况 ， 并且请求用户注册.提示其如果不注册则数据可能会丢失
  final generated = hardwareId?.isNotEmpty == true ? hardwareId! : const Uuid().v4();
  await prefs.setString(_prefsKey, generated);
  return generated;
}