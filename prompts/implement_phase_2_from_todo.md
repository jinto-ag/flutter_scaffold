# **Project Context**

You are implementing **Phase 2: Advanced Scaffolding & Architecture** features for the Flutter Scaffold CLI - a production-grade Dart CLI tool that generates Flutter projects with Clean Architecture. The project has a robust foundation with comprehensive safety features (backup, sandbox, history), template engine, and CLI infrastructure already completed in Phase 1.

### **Current Architecture Overview**

- **Entry Point**: `/bin/flutter_scaffold.dart` using CommandRunner pattern
- **Services**: 12 core services in `/lib/src/services/` including FeatureService, ModelService, ScaffoldService
- **Templates**: Advanced template engine with conditional logic in `/lib/src/templates/`
- **Structure**: Clean architecture with core/features/routing/shared organization
- **Safety**: BackupService, SandboxService, HistoryService, GitService fully implemented

### **Phase 2 Implementation Tasks**

#### **1. Data Layer Generation (High Priority)**

Implement complete data layer scaffolding for Clean Architecture:

**1.1 Repository Implementation Templates**

- Create `/lib/src/templates/feature/repository_impl.dart.template`
- Generate concrete repository implementations with error handling
- Include method signatures from repository interface templates
- Add dependency injection for datasources
- Support async/await patterns with proper error propagation

**1.2 Datasource Templates**

- Create `/lib/src/templates/feature/datasource.dart.template`
- Generate remote and local datasource interfaces
- Include HTTP client integration for remote datasources
- Add local storage abstraction (SharedPreferences, Hive, etc.)
- Support API endpoint configuration and authentication headers

**1.3 Mapper Templates**

- Create `/lib/src/templates/feature/mapper.dart.template`
- Generate entity ↔ DTO transformation classes
- Include JSON serialization/deserialization logic
- Add null safety and type conversion handling
- Support nested object mapping and list transformations

#### **2. Component Generation Commands**

Extend CLI with granular component generation:

**2.1 UseCase Command**

- Implement `AddUsecaseCommand` in `/lib/src/commands/`
- Create `/lib/src/templates/feature/usecase.dart.template`
- Generate use case classes with parameter validation
- Include Result/Either pattern for error handling
- Add repository integration and business logic scaffolding

**2.2 Repository Command**

- Implement `AddRepositoryCommand` for repository generation
- Generate both interface and implementation files
- Include datasource dependency injection
- Add method signature templates with proper typing
- Support CRUD operations and custom business methods

**2.3 Enhanced Model Command**

- Extend existing ModelService with json_serializable support
- Add `--json-serializable` flag for automatic annotation generation
- Include `fromJson`/`toJson` method templates
- Support nested models and enum serialization
- Add build_runner integration for code generation

#### **3. State Management Expansion**

Add Bloc/Cubit support alongside existing Riverpod:

**3.1 Bloc Templates**

- Create `/lib/src/templates/feature/bloc.dart.template`
- Generate Bloc classes with event and state classes
- Include proper event handling and state transitions
- Add error states and loading states
- Support dependency injection for repositories

**3.2 Cubit Templates**

- Create `/lib/src/templates/feature/cubit.dart.template`
- Generate simpler Cubit classes for straightforward state management
- Include state mutation methods with proper typing
- Add error handling and initial state setup

**3.3 Provider Integration**

- Update existing provider templates to support multiple state management options
- Add conditional template rendering based on configuration
- Include proper provider registration and DI setup

### **Implementation Guidelines**

#### **Code Quality Standards**

- Follow existing code style (analyze `analysis_options.yaml`)
- Use null safety throughout (Dart 3+)
- Implement proper error handling with custom exceptions
- Add comprehensive documentation comments
- Follow Clean Architecture principles strictly

#### **Template Engine Usage**

- Use existing template variables: `{{FEATURE_NAME}}`, `{{PASCAL_NAME}}`, etc.
- Implement conditional logic with `{{if}}...{{else}}...{{endif}}`
- Add new template variables as needed (e.g., `{{STATE_MANAGEMENT}}`)
- Ensure templates are context-aware and configurable

#### **Service Integration**

- Extend existing services (FeatureService, ModelService) rather than creating new ones
- Use established patterns for file operations and validation
- Integrate with safety services (Backup, Sandbox, History)
- Follow GitService patterns for auto-committing changes

#### **CLI Experience**

- Maintain existing CLI patterns (verbose flags, dry-run support)
- Add proper command validation and error messages
- Include progress indicators for multi-file operations
- Support interactive mode integration

### **Testing Requirements**

#### **Unit Tests**

- Test all new command implementations
- Verify template generation with various inputs
- Test service integration and error scenarios
- Mock external dependencies (HTTP clients, file systems)

#### **Integration Tests**

- Test complete workflows (e.g., `add repository` with `add usecase`)
- Verify generated code compiles and runs correctly
- Test template variable substitution and conditional logic
- Validate Clean Architecture layer separation

#### **E2E Tests**

- Extend existing E2E test suite (`scripts/e2e_test.dart`)
- Add test steps for new commands and features
- Test flag combinations and configuration options
- Verify integration with existing safety features

### **Configuration & Customization**

#### **CLI Flags**

- Add `--state-management` flag (riverpod, bloc, cubit)
- Include `--include-datasources` flag for data layer generation
- Support `--json-serializable` flag for model enhancement
- Add `--repository-type` flag (crud, custom)

#### **Template Configuration**

- Update `flutter_scaffold.yaml` schema for new options
- Support custom template paths for new components
- Add state management preference configuration
- Include datasource type configuration (http, local, both)

### **Quality Assurance Checklist**

#### **Before Completion**

- [ ] All templates generate valid, compilable Dart code
- [ ] Commands integrate properly with existing CLI infrastructure
- [ ] Error handling covers all failure scenarios
- [ ] Template variables work correctly in all contexts
- [ ] Generated code follows established patterns and conventions
- [ ] All tests pass with comprehensive coverage
- [ ] Documentation is updated for new commands and features
- [ ] E2E tests verify complete workflows

#### **Code Review Points**

- Clean Architecture layer separation is maintained
- Dependency injection is properly implemented
- Error handling follows existing patterns
- Template logic is efficient and maintainable
- CLI experience is consistent with existing commands
- Safety features (backup, sandbox, history) work correctly

### **Success Metrics**

- All Phase 2 TODO items are completed and tested
- Generated Flutter projects compile and run without errors
- CLI commands work seamlessly with existing infrastructure
- Template engine handles all new features correctly
- Test coverage meets or exceeds existing standards
- Code quality passes all linting and analysis rules

This prompt provides a comprehensive roadmap for implementing Phase 2 features while maintaining the high quality and architectural standards established in Phase 1.
