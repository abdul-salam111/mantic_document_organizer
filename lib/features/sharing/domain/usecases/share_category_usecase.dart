import '../../../../core/shared/shared_exports.dart';
import '../../../categories/domain/entities/category_item.dart';
import '../../../categories/domain/repositories/category_repository.dart';
import '../entities/space_entity.dart';
import '../entities/space_role.dart';
import 'sharing_usecases.dart';

/// Turns a plain local category into a shared one: creates its dedicated
/// backend Space + the one category inside it (see
/// docs/space_sharing_ux_plan.txt), then writes the resulting `spaceId`
/// back onto the local category with `myRole = owner`. The only intended
/// caller of [CreateSpaceUsecase]/[CreateSpaceCategoryUsecase] -- every
/// other path onto a shared space goes through joining one that already
/// exists, never creating a second one for the same category (see the UX
/// plan's "no duplicate spaces" rule).
///
/// Lives in the sharing feature (not categories) because it depends on
/// [Result]/[Usecase] -- categories' own domain layer is kept pure Dart
/// with no dependency on core/shared at all (see
/// test/architecture/clean_architecture_test.dart), so this orchestration
/// can't live there even though it mutates a [CategoryItem].
class ShareCategoryUsecase
    implements
        Usecase<CategoryItem, ({String token, CategoryItem category})> {
  final CreateSpaceUsecase _createSpace;
  final CreateSpaceCategoryUsecase _createSpaceCategory;
  final ICategoryRepository _categoryRepository;

  ShareCategoryUsecase(
    this._createSpace,
    this._createSpaceCategory,
    this._categoryRepository,
  );

  @override
  Future<Result<CategoryItem>> call(
    ({String token, CategoryItem category}) params,
  ) async {
    final spaceResult = await _createSpace((
      token: params.token,
      name: params.category.name,
    ));
    if (spaceResult case Failure(:final error)) return Failure(error);
    final space = (spaceResult as Success<SpaceEntity>).value;

    final categoryResult = await _createSpaceCategory((
      token: params.token,
      spaceId: space.id,
      name: params.category.name,
      iconKey: params.category.iconKey,
      color: params.category.colorValue?.toRadixString(16),
    ));
    if (categoryResult case Failure(:final error)) return Failure(error);

    final shared = params.category.copyWith(
      spaceId: space.id,
      myRole: SpaceRole.owner.value,
    );
    await _categoryRepository.updateCategory(params.category.id, shared);
    return Success(shared);
  }
}
