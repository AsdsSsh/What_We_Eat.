import 'package:flutter/material.dart';



/// description: 原材料
/// @param type  原材料种类
class RawMaterial {
  String id;
  String name;
  String type;
  Icon icon;

  RawMaterial({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
  });
}

