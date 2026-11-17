import 'package:flutter/material.dart';

abstract class CentralRuntime {
  bool get canConnect;
  String get platform;
  Future<String> ownPeerId();
  Future<String> linkedEndpoint();
  Future<void> link(
      {required String url,
      required String token,
      required String deviceId,
      required String name});
  Future<void> unlink();
  void listenPresence(void Function(List<String>, List<String>) listener);
  void queryPresence(List<String> ids);
  Future<void> connectTo(BuildContext context, String id);
  void dispose();
}
