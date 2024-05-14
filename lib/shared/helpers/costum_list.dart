import 'package:flutter/material.dart';

class CustomScrollBehavior extends MaterialScrollBehavior {
  // Sobrescreve o método responsável pelo efeito de esticar.
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child; // Retorna apenas o child para remover o efeito.
  }
}
