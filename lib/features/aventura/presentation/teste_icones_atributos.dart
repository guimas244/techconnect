import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:remixicon/remixicon.dart';

class TesteIconesAtributos extends StatelessWidget {
  const TesteIconesAtributos({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Material Symbols'),
        Row(
          children: const [
            Icon(MaterialSymbolsIcons.favorite, color: Colors.red, size: 32),
            SizedBox(width: 16),
            Icon(MaterialSymbolsIcons.favorite, color: Colors.red, size: 32),
            SizedBox(width: 16),
            Icon(MaterialSymbolsIcons.favorite, color: Colors.red, size: 32),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Font Awesome Flutter'),
        Row(
          children: const [
            FaIcon(FontAwesomeIcons.solidHeart, color: Colors.red, size: 32),
            SizedBox(width: 16),
            FaIcon(FontAwesomeIcons.solidHeart, color: Colors.red, size: 32),
            SizedBox(width: 16),
            FaIcon(FontAwesomeIcons.solidHeart, color: Colors.red, size: 32),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Remix Icon'),
        Row(
          children: const [
            Icon(Remix.heart_fill, color: Colors.red, size: 32),
            SizedBox(width: 16),
            Icon(Remix.heart_fill, color: Colors.red, size: 32),
            SizedBox(width: 16),
            Icon(Remix.heart_fill, color: Colors.red, size: 32),
          ],
        ),
      ],
    );
  }
}
