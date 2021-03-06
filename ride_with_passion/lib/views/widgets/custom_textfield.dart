import 'package:flutter/material.dart';
import 'package:ride_with_passion/styles.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final String errorText;
  final bool obscure;
  final TextInputType keyboardType;
  final Function(String) validator;
  final FocusNode focusNode;

  final TextInputAction textInputAction;
  final TextEditingController textEditingController;

  final Function(String) onChanged;
  final Function(String) onSubmit;
  final int minLines;
  const CustomTextField({
    Key key,
    this.hint,
    this.label,
    this.onChanged,
    this.minLines,
    this.errorText,
    this.textEditingController,
    this.obscure = false,
    this.validator,
    this.keyboardType,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.onSubmit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: TextFormField(
              keyboardType: keyboardType,
              controller: textEditingController,
              obscureText: obscure,
              style: medium20sp,
              focusNode: focusNode,
              textInputAction: textInputAction,
              minLines: minLines,
              maxLines: minLines ?? 1,
              onChanged: onChanged,
              onFieldSubmitted: onSubmit,
              validator: validator,
              decoration: InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                hintText: hint,
                labelText: label,
                labelStyle: TextStyle(color: Colors.grey[300]),
                hintStyle: medium18sp,
                errorMaxLines: 2,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40.0),
                  borderSide: BorderSide(color: Colors.grey[800]),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40.0),
                  borderSide: BorderSide(color: Colors.grey[800]),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                  borderRadius: BorderRadius.circular(40.0),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                  borderRadius: BorderRadius.circular(40.0),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
