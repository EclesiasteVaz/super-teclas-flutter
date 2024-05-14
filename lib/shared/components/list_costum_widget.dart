// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:super_teclas/shared/helpers/costum_list.dart';

class ListCustomWidget extends StatelessWidget {
  ListCustomWidget({
    super.key,
    required this.child,
  });
  Widget child;
  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: CustomScrollBehavior(),
      child: child,
    );
  }
}
