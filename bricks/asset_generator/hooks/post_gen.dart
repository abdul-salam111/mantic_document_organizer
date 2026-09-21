
import 'package:mason/mason.dart';

void run(HookContext context) {
  final imagesCount = context.vars['images_count'] as int;
  final iconsCount = context.vars['icons_count'] as int;
  
  context.logger.info('');
  context.logger.success('✓ Generated asset constants successfully!');
  context.logger.info('');
  context.logger.info('📁 Files created:');
  context.logger.info('  • lib/core/constants/app_images.dart ($imagesCount images)');
  context.logger.info('  • lib/core/constants/app_icons.dart ($iconsCount icons)');
  context.logger.info('');
  context.logger.info('💡 Usage example:');
  context.logger.info('  Image.asset(AppImages.appLogo)');
  context.logger.info('  Image.asset(AppIcons.homeIcon)');
  context.logger.info('');
  context.logger.info('🔄 To update after adding new assets, run:');
  context.logger.info('  mason make asset_generator');
}