import 'package:flutter/foundation.dart';

import '../../../core/services/services_exports.dart';

class HomeViewModel extends ChangeNotifier {
  String get userName {
    final user = SessionController.instance.userDetails;
    if (user.name?.isNotEmpty == true) return user.name!;
    return user.email ?? 'there';
  }
}
