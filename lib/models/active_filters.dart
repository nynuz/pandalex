class ActiveFilters {
  final List<String> categoria;

  ActiveFilters({
    required this.categoria,
  });

  ActiveFilters copyWith({
    List<String>? categoria,
  }) {
    return ActiveFilters(
      categoria: categoria ?? this.categoria,
    );
  }

  bool get isEmpty => categoria.isEmpty;
  
  int get totalCount => categoria.length;
}