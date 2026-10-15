import '../../../documents/domain/entities/document_item.dart';

enum ReadinessGroup {
  identity('id_card'),
  address('electricity_gas'),
  birth(null),
  health('medical'),
  finance('bank');

  final String? categoryId;
  const ReadinessGroup(this.categoryId);
}

class ReadinessPreferences {
  final Set<ReadinessGroup> excluded;
  final Map<ReadinessGroup, String> links;
  ReadinessPreferences({Set<ReadinessGroup> excluded = const {}, Map<ReadinessGroup, String> links = const {}})
      : excluded = Set.unmodifiable(excluded), links = Map.unmodifiable(links);
}

class ReadinessItem {
  final ReadinessGroup group;
  final bool excluded;
  final DocumentItem? document;
  const ReadinessItem(this.group, this.excluded, this.document);
  bool get complete => !excluded && document != null;
}

/// Deliberately conservative. Broad categories and incidental OCR mentions do
/// not prove document type. A user-confirmed link also works for unnamed scans.
List<ReadinessItem> evaluateReadiness(List<DocumentItem> documents, ReadinessPreferences preferences) {
  final active = documents.where((d) => !d.isTrashed && d.filePaths.isNotEmpty).toList();
  return [for (final group in ReadinessGroup.values)
    ReadinessItem(group, preferences.excluded.contains(group), _match(group, active, preferences.links[group]))];
}

DocumentItem? _match(ReadinessGroup group, List<DocumentItem> documents, String? linkedId) {
  if (linkedId != null) {
    // Retain the link while trashed so restoring the original restores progress.
    for (final document in documents) {
      if (document.id == linkedId) return document;
    }
    return null;
  }
  for (final document in documents) {
    if (group == .identity && {'id_card', 'passports', 'driving_license'}.contains(document.categoryId)) return document;
    final labels = [document.title, ...document.tags].map((text) => text.trim().toLowerCase().replaceAll('-', ' ')).toSet();
    final phrases = switch (group) {
      ReadinessGroup.identity => ['passport', 'national id', 'identity card', 'جواز سفر', 'بطاقة الهوية', 'passeport', 'pasaporte'],
      ReadinessGroup.address => ['utility bill', 'electricity bill', 'gas bill', 'water bill', 'tenancy agreement', 'proof of address', 'إثبات العنوان', 'فاتورة الكهرباء', 'justificatif de domicile', 'comprobante de domicilio'],
      ReadinessGroup.birth => ['birth certificate', 'birth record', 'شهادة ميلاد', 'acte de naissance', 'certificado de nacimiento'],
      ReadinessGroup.health => ['vaccination record', 'medical report', 'medical summary', 'health record', 'تقرير طبي', 'سجل التطعيم', 'rapport médical', 'carnet de vaccination', 'informe médico', 'registro de vacunación'],
      ReadinessGroup.finance => ['bank statement', 'account statement', 'account certificate', 'كشف حساب', 'relevé bancaire', 'estado de cuenta', 'certificado bancario'],
    };
    if (phrases.any(labels.contains)) return document;
  }
  return null;
}
