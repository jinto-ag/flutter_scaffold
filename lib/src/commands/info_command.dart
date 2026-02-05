/// Info command for displaying project information.
library;

import 'package:args/command_runner.dart';

import '../services/feature_service.dart';
import '../utils/file_utils.dart';
import '../utils/logger.dart';

/// Command to display project features information.
class InfoCommand extends Command<int> {
  InfoCommand({
    ScaffoldLogger? logger,
    FeatureService? featureService,
    FileUtils? fileUtils,
  }) : _logger = logger ?? ScaffoldLogger(),
       _featureService = featureService ?? FeatureService(),
       _fileUtils = fileUtils ?? const FileUtils();

  final ScaffoldLogger _logger;
  final FeatureService _featureService;
  final FileUtils _fileUtils;

  @override
  String get name => 'info';

  @override
  String get description => 'Display project features information';

  @override
  Future<int> run() async {
    final projectPath = _fileUtils.currentDirectory;

    // Check if features directory exists
    final featuresPath = _fileUtils.joinPath(projectPath, 'lib/src/features');
    if (!_fileUtils.directoryExists(featuresPath)) {
      _logger.error('Features directory not found at lib/src/features');
      _logger.info(
        "Run 'flutter_scaffold scaffold' to create the basic structure first",
      );
      return 1;
    }

    _logger.header('Project Features Information');

    final features = _featureService.getFeatureInfos(projectPath);

    if (features.isEmpty) {
      _logger.warn('No features found in lib/src/features');
      _logger.info('');
      _logger.info('To add a feature:');
      _logger.info('  flutter_scaffold add feature <name>');
      return 0;
    }

    _logger.info('Found ${features.length} feature(s):');
    _logger.info('');

    var totalFiles = 0;
    var totalDirs = 0;

    for (final feature in features) {
      totalFiles += feature.fileCount;
      totalDirs += feature.dirCount;

      _logger.info('📁 ${feature.name}');
      _logger.info('   Path: ${feature.path}');
      _logger.info(
        '   Files: ${feature.fileCount} | '
        'Directories: ${feature.dirCount} | '
        'Size: ${feature.size}',
      );

      if (feature.components.isNotEmpty) {
        _logger.info('   Components: ${feature.components.join(', ')}');
      }

      _logger.info('');
    }

    _logger.divider();
    _logger.info('Summary:');
    _logger.info('  Total features: ${features.length}');
    _logger.info('  Total files: $totalFiles');
    _logger.info('  Total directories: $totalDirs');
    _logger.info('');

    _logger.info('Available commands:');
    _logger.info('  flutter_scaffold add feature <name>     - Add new feature');
    _logger.info('  flutter_scaffold remove feature <name>  - Remove feature');
    _logger.info('  flutter_scaffold reset feature <name>   - Reset feature');

    return 0;
  }
}
