/// Representa la entidad pura del dominio de un Anime en la aplicación.
///
/// Es agnóstica de frameworks (Flutter), bases de datos y orígenes de datos externos.
class AnimeEntity {
  final int malId;
  final String title;
  final String imageUrl;
  final int? year;
  final int? episodes;
  final int? members;
  final double? score;
  final String? synopsis;
  final List<String> genres;
  final String? trailerYoutubeId;

  const AnimeEntity({
    required this.malId,
    required this.title,
    required this.imageUrl,
    this.year,
    this.episodes,
    this.members,
    this.score,
    this.synopsis,
    this.genres = const [],
    this.trailerYoutubeId,
  });
}
