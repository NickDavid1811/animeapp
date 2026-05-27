import 'package:flutter/material.dart';
import 'package:animeapp/shared/domain/entities/anime_entity.dart';
import 'package:animeapp/feature/anime_list/presentation/widgets/anime_detail_bottom_sheet.dart';
import 'package:animeapp/feature/anime_list/presentation/widgets/anime_detail_dialog.dart';

class AnimeDetailHelper {
  static void showDetail(BuildContext context, AnimeEntity anime) {
    // Si la pantalla es ancha (Desktop/Web/Tablet)
    if (MediaQuery.of(context).size.width >= 600) {
      showDialog(
        context: context,
        builder: (context) => AnimeDetailDialog(anime: anime),
      );
    } else {
      // Si la pantalla es pequeña (Móvil)
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => AnimeDetailBottomSheet(anime: anime),
      );
    }
  }
}
