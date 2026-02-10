/// Model management service.
library;

import '../core/constants.dart';
import '../utils/file_utils.dart';
import '../utils/logger.dart';
import '../utils/string_utils.dart';
import '../utils/templates.dart';
import 'build_runner_service.dart';

/// Information about a model.
class ModelInfo {
  const ModelInfo({
    required this.name,
    required this.path,
    required this.fileCount,
    required this.components,
  });

  final String name;
  final String path;
  final int fileCount;
  final List<String> components;
}

/// Result of model operation.
class ModelResult {
  const ModelResult({required this.filesCreated});

  final int filesCreated;
}

/// Service for managing data models.
class ModelService {
  ModelService({
    ScaffoldLogger? logger,
    FileUtils? fileUtils,
    TemplateRegistry? templates,
    BuildRunnerService? buildRunnerService,
  }) : _logger = logger ?? ScaffoldLogger(),
       _fileUtils = fileUtils ?? const FileUtils(),
       _buildRunnerService = buildRunnerService ?? BuildRunnerService();

  final ScaffoldLogger _logger;
  final FileUtils _fileUtils;
  final BuildRunnerService _buildRunnerService;

  /// Create a TemplateRegistry with context from pubspec.yaml.
  TemplateRegistry _createTemplateRegistry(String projectPath) {
    final pubspecPath = _fileUtils.joinPath(projectPath, 'pubspec.yaml');
    final context = TemplateContext.fromPubspec(pubspecPath);
    return TemplateRegistry(context: context);
  }

  /// Get the models directory path for a feature.
  String _modelsPath(String projectPath, String featureName) =>
      _fileUtils.joinPath(
        _fileUtils.joinPath(
          _fileUtils.joinPath(
            _fileUtils.joinPath(
              _fileUtils.joinPath(projectPath, srcDir),
              'features',
            ),
            featureName,
          ),
          'data',
        ),
        'models',
      );

  /// Get the path to a specific model file.
  String _modelPath(String projectPath, String featureName, String modelName) =>
      '${_modelsPath(projectPath, featureName)}/${modelName}_model.dart';

  /// Check if a feature exists.
  bool featureExists(String projectPath, String featureName) {
    final featurePath = _fileUtils.joinPath(
      projectPath,
      srcDir,
      'features',
      featureName,
    );
    return _fileUtils.directoryExists(featurePath);
  }

  /// Check if a model exists.
  bool modelExists(String projectPath, String featureName, String modelName) {
    return _fileUtils.fileExists(
      _modelPath(projectPath, featureName, modelName),
    );
  }

  /// Add a new model to a feature.
  Future<ModelResult> addModel({
    required String projectPath,
    required String featureName,
    required String modelName,
    List<String> fields = const [],
    bool useJsonSerializable = false,
    bool useFreezed = false,
    bool force = false,
    bool dryRun = false,
  }) async {
    // Normalize names
    final normalizedFeature = normalizeFeatureName(featureName);
    final normalizedModel = normalizeFeatureName(modelName);

    // Check if feature exists
    if (!featureExists(projectPath, normalizedFeature)) {
      throw ModelException(
        "Feature '$normalizedFeature' does not exist. "
        'Please create the feature first.',
      );
    }

    // Check if model exists
    final modelPath = _modelPath(
      projectPath,
      normalizedFeature,
      normalizedModel,
    );
    if (_fileUtils.fileExists(modelPath) && !force) {
      throw ModelException(
        "Model '$normalizedModel' already exists at $modelPath\n"
        'Use --force to overwrite',
      );
    }

    // Create context-aware template registry
    final templates = _createTemplateRegistry(projectPath);

    var filesCreated = 0;

    // Create model file
    _logger.section('Creating model...');

    final templateType = _getModelTemplateType(useJsonSerializable, useFreezed);

    if (useJsonSerializable || useFreezed) {
      _logger.warn(
        'JSON serialization and Freezed templates are not yet implemented',
      );
      _logger.info('Using basic model template instead');
    }

    final specificVariables = {
      'MODEL_NAME': normalizedModel,
      'PASCAL_MODEL_NAME': toPascalCase(normalizedModel),
      'modelName': normalizedModel,
      'pascalModelName': toPascalCase(normalizedModel),
      'FEATURE_NAME': normalizedFeature,
      'PASCAL_FEATURE_NAME': toPascalCase(normalizedFeature),
      // Constructor parameters: required this.fieldName,
      'FIELDS': fields
          .map((field) {
            final parts = field.split(':');
            final name = parts[0].trim();
            return '    required this.$name,';
          })
          .join('\n'),
      // Field declarations: final Type fieldName;
      'FIELD_DECLARATIONS': fields
          .map((field) {
            final parts = field.split(':');
            final name = parts[0].trim();
            final type = parts.length > 1 ? parts[1].trim() : 'dynamic';
            return '  final $type $name;';
          })
          .join('\n'),
      // Just field names for hashCode and toString
      'FIELD_NAMES': fields
          .map((field) => field.split(':').first.trim())
          .join(', '),
      // copyWith parameters: Type? fieldName,
      'FIELDS_WITH_OPTIONAL': fields
          .map((field) {
            final parts = field.split(':');
            final name = parts[0].trim();
            final type = parts.length > 1 ? parts[1].trim() : 'dynamic';
            return '    $type? $name,';
          })
          .join('\n'),
      // copyWith body: fieldName: fieldName ?? this.fieldName,
      'COPY_FIELDS': fields
          .map((field) {
            final parts = field.split(':');
            final name = parts[0].trim();
            return '      $name: $name ?? this.$name,';
          })
          .join('\n'),
      // toJson entries: 'fieldName': fieldName,
      'JSON_FIELDS': fields
          .map((field) {
            final parts = field.split(':');
            final name = parts[0].trim();
            return "      '$name': $name,";
          })
          .join('\n'),
      // fromJson entries: fieldName: json['fieldName'] as Type,
      'FROM_JSON_FIELDS': fields
          .map((field) {
            final parts = field.split(':');
            final name = parts[0].trim();
            final type = parts.length > 1 ? parts[1].trim() : 'dynamic';
            return "      $name: json['$name'] as $type,";
          })
          .join('\n'),
      'HAS_FIELDS': fields.isNotEmpty,
      'FIELD_COUNT': fields.length,
    };

    templates.context.setSpecifics(specificVariables);
    final content = templates.getFeatureTemplate(
      'basic_model',
      normalizedModel,
    );

    if (content == null) {
      throw ModelException('Could not load model template');
    }

    if (dryRun) {
      _logger.would('Create file: ${_fileUtils.basename(modelPath)}');
      _logger.info('Template type: $templateType');
      if (fields.isNotEmpty) {
        _logger.info('Fields: ${fields.join(', ')}');
      }
    } else {
      // Ensure models directory exists
      final modelsDir = _modelsPath(projectPath, normalizedFeature);
      _fileUtils.createDirectory(modelsDir);

      if (_fileUtils.createFile(modelPath, content, force: force)) {
        _logger.created(_fileUtils.basename(modelPath));
        filesCreated++;
      } else {
        _logger.skipped(_fileUtils.basename(modelPath));
      }

      // Run build runner if needed
      if (useJsonSerializable || useFreezed) {
        final buildResult = await _buildRunnerService.runBuildRunner(
          projectPath,
        );
        if (!buildResult.success) {
          _logger.warn('Build runner completed with issues');
        }
      }

      // Run verification
      final verificationResult = await _buildRunnerService.verifyCode(
        projectPath,
      );
      if (!verificationResult.success) {
        _logger.warn('Code verification found issues');
        if (verificationResult.issues.isNotEmpty) {
          for (final issue in verificationResult.issues) {
            _logger.warn('  • $issue');
          }
        }
      }
    }

    _logger.divider();
    _logger.success("Model '$normalizedModel' created!");
    _logger.info('  Files: $filesCreated');
    if (useJsonSerializable) {
      _logger.info('  JSON Serialization: Enabled');
    }
    if (useFreezed) {
      _logger.info('  Freezed: Enabled');
    }
    _logger.info('');
    _logger.info('Model location:');
    _logger.info('  $modelPath');

    return ModelResult(filesCreated: filesCreated);
  }

  /// Get the appropriate template type based on options.
  String _getModelTemplateType(bool useJsonSerializable, bool useFreezed) {
    if (useFreezed) {
      return 'freezed';
    } else if (useJsonSerializable) {
      return 'json_serializable';
    }
    return 'basic';
  }
}

/// Exception thrown for model-related errors.
class ModelException implements Exception {
  const ModelException(this.message);

  final String message;

  @override
  String toString() => 'ModelException: $message';
}
