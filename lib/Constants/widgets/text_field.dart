// ignore_for_file: must_be_immutable

import 'package:rideshare/Constants/styles/colors.dart';
import 'package:rideshare/Constants/styles/styles.dart';
import 'package:flutter/material.dart';

class TextFieldForm extends StatelessWidget {
  String text;
  TextEditingController controller;
  TextCapitalization capitalization;
  TextInputType textInputType;
  TextInputAction textInputAction;

  TextFieldForm({
    Key? key,
    required this.text,
    required this.controller,
    required this.capitalization,
    required this.textInputType,
    required this.textInputAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: textInputType,
      textInputAction: textInputAction,
      textCapitalization: capitalization,
      decoration: InputDecoration(
          enabledBorder: StylesConst.textBorder,
          focusedBorder: StylesConst.textBorder,
          fillColor: ColorsConst.grey100,
          filled: true,
          label: Text(text),
          labelStyle: StylesConst.labelStyle,
          hintStyle: StylesConst.hintStyle),
      style: const TextStyle(fontSize: 17.0),
    );
  }
}
