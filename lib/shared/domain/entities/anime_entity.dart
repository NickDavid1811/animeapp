class AnimeEntity {
  final int malId;
  final String title;
  final String imageUrl;
  final int? year;
  final int? episodes;
  final int? members;

  const AnimeEntity({
    required this.malId,
    required this.title,
    required this.imageUrl,
    this.year,
    this.episodes,
    this.members,
  });
}
