enum AttachmentType { image, file }

class AttachmentItem {
  final String path;
  final AttachmentType type;

  const AttachmentItem({required this.path, required this.type});
}

class AttachmentSelection {
  final List<AttachmentItem> items;
  final bool scanFailed;
  final bool galleryFailed;
  final bool skippedImages;
  const AttachmentSelection({
    this.items = const [],
    this.scanFailed = false,
    this.galleryFailed = false,
    this.skippedImages = false,
  });
}
