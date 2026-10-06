const String uncategorizedCategoryId = 'uncategorized';
String generateLocalId() => DateTime.now().microsecondsSinceEpoch.toString();
const Set<String> _imagePathExtensions = {
  'png',
  'jpg',
  'jpeg',
  'gif',
  'bmp',
  'webp',
  'heic',
  'heif',
  'tif',
  'tiff',
};

bool isImagePath(String path) {
  final dot = path.lastIndexOf('.');
  if (dot == -1) return false;
  return _imagePathExtensions.contains(path.substring(dot + 1).toLowerCase());
}

bool isPdfPath(String path) => path.toLowerCase().endsWith('.pdf');

enum DocumentSort { newest, oldest, nameAz }

class DocumentItem {
  final String id;
  final String title;
  final String category;
  final String categoryId;
  final String iconKey;
  final List<String> tags;
  final bool isFavorite;
  final List<String> filePaths;
  final DateTime createdAt;
  final bool isExpirable;
  final DateTime? expiryDate;
  final String description;
  final String ocrText;
  final DateTime? deletedAt;

  DocumentItem({
    required this.id,
    required this.title,
    required this.category,
    required this.categoryId,
    required this.iconKey,
    required this.createdAt,
    List<String> tags = const [],
    this.isFavorite = false,
    List<String> filePaths = const [],
    this.isExpirable = false,
    this.expiryDate,
    this.description = '',
    this.ocrText = '',
    this.deletedAt,
  }) : tags = List.unmodifiable(tags),
       filePaths = List.unmodifiable(filePaths);

  bool get isTrashed => deletedAt != null;

  DocumentItem copyWith({
    String? title,
    String? category,
    String? categoryId,
    String? iconKey,
    bool? isFavorite,
    String? description,
    String? ocrText,
    List<String>? filePaths,
  }) => DocumentItem(
    id: id,
    title: title ?? this.title,
    category: category ?? this.category,
    categoryId: categoryId ?? this.categoryId,
    iconKey: iconKey ?? this.iconKey,
    createdAt: createdAt,
    tags: tags,
    isFavorite: isFavorite ?? this.isFavorite,
    filePaths: filePaths ?? this.filePaths,
    isExpirable: isExpirable,
    expiryDate: expiryDate,
    description: description ?? this.description,
    ocrText: ocrText ?? this.ocrText,
    deletedAt: deletedAt,
  );
  DocumentItem markDeleted(DateTime deletedAt) => DocumentItem(
    id: id,
    title: title,
    category: category,
    categoryId: categoryId,
    iconKey: iconKey,
    createdAt: createdAt,
    tags: tags,
    isFavorite: isFavorite,
    filePaths: filePaths,
    isExpirable: isExpirable,
    expiryDate: expiryDate,
    description: description,
    ocrText: ocrText,
    deletedAt: deletedAt,
  );
  DocumentItem restored() => DocumentItem(
    id: id,
    title: title,
    category: category,
    categoryId: categoryId,
    iconKey: iconKey,
    createdAt: createdAt,
    tags: tags,
    isFavorite: isFavorite,
    filePaths: filePaths,
    isExpirable: isExpirable,
    expiryDate: expiryDate,
    description: description,
    ocrText: ocrText,
    deletedAt: null,
  );
}

extension DocumentListSorting on List<DocumentItem> {
  List<DocumentItem> sortedBy(DocumentSort sort) {
    final sorted = List<DocumentItem>.of(this);
    switch (sort) {
      case DocumentSort.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case DocumentSort.oldest:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case DocumentSort.nameAz:
        sorted.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    }
    return sorted;
  }
}
