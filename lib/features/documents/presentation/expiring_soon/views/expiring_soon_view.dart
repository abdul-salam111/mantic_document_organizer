import 'package:mantic_doc_org/core/utils/persist_action.dart';
import 'package:flutter/material.dart';

import '../../../../../core/di/di_exports.dart';
import '../../../../../core/localization/localization_exports.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';
import '../../../../../routes/routes_exports.dart';
import '../../../../home/home_exports.dart';
import '../viewmodels/expiring_soon_viewmodel.dart';

/// Destination for tapping the weekly expiry digest notification (see
/// ExpiryDigestListener) — same list-tile presentation as Trash/Favorites,
/// just scoped to documents due within
/// ExpiryNotificationService.digestWindowDays.
class ExpiringSoonView extends StatelessWidget {
  const ExpiringSoonView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<ExpiringSoonViewModel>(),
      child: Consumer<ExpiringSoonViewModel>(
        builder: (context, vm, _) {
          final documents = vm.documents;
          return Scaffold(
            appBar: CustomAppBar(
              title: AppLocalizations.of(context).expiringSoonTitle,
            ),
            body: SafeArea(
              child: documents.isEmpty
                  ? EmptyStateWidget(
                      icon: Iconsax.timer_1,
                      title: AppLocalizations.of(
                        context,
                      ).expiringSoonEmptyTitle,
                      subtitle: AppLocalizations.of(
                        context,
                      ).expiringSoonEmptySubtitle,
                    )
                  : StaggeredReveal(
                      itemCount: documents.length,
                      builder: (context, reveal) => ListView.separated(
                        padding: const .fromLTRB(10, 10, 10, 20),
                        itemCount: documents.length,
                        separatorBuilder: (context, index) => heightBox(10),
                        itemBuilder: (context, index) {
                          final document = documents[index];
                          return StaggeredRevealItem(
                            reveal: reveal,
                            itemCount: documents.length,
                            index: index,
                            child: DocumentListTile(
                              document: document,
                              accentColor: categoryIconColor(
                                context,
                                document.category,
                              ),
                              onTap: () => AppNavigator.pushNamed(
                                RouteNames.documentViewer,
                                extra: document,
                              ),
                              onToggleFavorite: () => persistAction(
                                context,
                                () => vm.toggleFavorite(document),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
