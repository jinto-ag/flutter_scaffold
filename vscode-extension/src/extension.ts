import * as vscode from 'vscode';
import * as fs from 'fs';
import { execSync } from 'child_process';

const KNOWN_PLACEHOLDERS = new Set([
    // Core names
    'projectName',
    'featureName',
    'FeatureName',
    'FEATURE_NAME',
    'PASCAL_NAME',
    'PASCAL_FEATURE_NAME',
    // Model-related
    'MODEL_NAME',
    'PASCAL_MODEL_NAME',
    // Screen-related
    'screenName',
    'PASCAL_SCREEN_NAME',
    // Fields & data
    'FIELDS',
    'FIELD_NAMES',
    'FIELDS_WITH_OPTIONAL',
    'COPY_FIELDS',
    'JSON_FIELDS',
    'FROM_JSON_FIELDS',
    // Logic markers
    'HAS_FIELDS',
    'HAS_ENTITY',
    'HAS_PARAMS',
    // Feature/Component names
    'REPOSITORY_NAME',
    'PASCAL_REPOSITORY_NAME',
    'USECASE_NAME',
    'PASCAL_USECASE_NAME',
    'USECASE_DESCRIPTION',
    'RETURN_TYPE',
    'ENTITY_NAME',
    'PASCAL_ENTITY_NAME',
]);

// Regex to capture the content inside {{ }}. 
// Optimized for single-line usage mostly, but supports newlines if VS Code range allows.
const PLACEHOLDER_REGEX = /\{\{([\s\S]*?)\}\}/g;
const SHADOW_HEADER_LINES = 1;

let diagnosticCollection: vscode.DiagnosticCollection;

// Decoration types for template syntax highlighting
const bracketDecorationType = vscode.window.createTextEditorDecorationType({
    color: '#FF6B6B',
    fontWeight: 'bold',
});

const keywordDecorationType = vscode.window.createTextEditorDecorationType({
    color: '#C678DD',
    fontWeight: 'bold',
});

const variableDecorationType = vscode.window.createTextEditorDecorationType({
    color: '#61AFEF',
    fontStyle: 'italic',
});

export function activate(context: vscode.ExtensionContext) {
    console.log('Flutter Scaffold Template extension activated');

    diagnosticCollection = vscode.languages.createDiagnosticCollection('flutter-scaffold-template');
    context.subscriptions.push(diagnosticCollection);

    vscode.workspace.textDocuments.forEach(validateDocument);

    const shadowProvider = new ShadowDocumentProvider();

    // Listeners
    context.subscriptions.push(
        vscode.workspace.onDidOpenTextDocument(validateDocument),
        vscode.workspace.onDidChangeTextDocument((e) => {
            validateDocument(e.document);
            // Update decorations for the active editor
            const editor = vscode.window.activeTextEditor;
            if (editor && editor.document === e.document && isTemplateFile(e.document)) {
                updateDecorations(editor);
            }
        }),
        vscode.workspace.onDidSaveTextDocument(validateDocument),

        vscode.workspace.onDidCloseTextDocument((doc) => {
            if (isTemplateFile(doc)) {
                shadowProvider.deleteShadowFile(doc);
            }
        }),

        // Editor change listeners for decorations
        vscode.window.onDidChangeActiveTextEditor((editor) => {
            if (editor && isTemplateFile(editor.document)) {
                updateDecorations(editor);
            }
        })
    );

    // Apply decorations to currently active editor
    if (vscode.window.activeTextEditor && isTemplateFile(vscode.window.activeTextEditor.document)) {
        updateDecorations(vscode.window.activeTextEditor);
    }

    context.subscriptions.push(
        vscode.languages.registerHoverProvider('dart-template', {
            async provideHover(document, position, token) {
                const templateHover = provideTemplateHover(document, position);
                if (templateHover) return templateHover;
                return shadowProvider.provideHover(document, position, token);
            }
        }),
    );

    context.subscriptions.push(
        vscode.languages.registerCompletionItemProvider(
            'dart-template',
            {
                async provideCompletionItems(document, position, token, context) {
                    const templateItems = provideTemplatePlaceholderCompletions(document, position);
                    const dartItems = await shadowProvider.provideCompletionItems(document, position, token, context);

                    if (!dartItems) return templateItems;

                    const items = Array.isArray(dartItems) ? dartItems : dartItems.items;
                    // prioritizing template items
                    return [...templateItems, ...items];
                },
            },
            '.',
            '{',
            ' ', // Trigger on space too
            'i', 'e', // Trigger on logic start chars
        ),
    );

    context.subscriptions.push(
        vscode.languages.registerDefinitionProvider('dart-template', shadowProvider)
    );

    context.subscriptions.push(
        vscode.languages.registerDocumentFormattingEditProvider('dart-template', {
            provideDocumentFormattingEdits(document: vscode.TextDocument): vscode.TextEdit[] {
                return formatTemplate(document);
            }
        })
    );
}

export function deactivate() {
    if (diagnosticCollection) {
        diagnosticCollection.dispose();
    }
}

class ShadowDocumentProvider implements vscode.HoverProvider, vscode.CompletionItemProvider, vscode.DefinitionProvider {

    private getShadowUri(document: vscode.Uri): vscode.Uri {
        return vscode.Uri.file(document.fsPath + '.__analysis__.dart');
    }

    deleteShadowFile(document: vscode.TextDocument) {
        const shadowPath = this.getShadowUri(document.uri).fsPath;
        try {
            if (fs.existsSync(shadowPath)) {
                fs.unlinkSync(shadowPath);
            }
        } catch (e) {
            console.error('Failed to delete shadow file', e);
        }
    }

    private updateShadowFile(document: vscode.TextDocument) {
        const text = document.getText();
        const ignores = '// ignore_for_file: uri_does_not_exist, undefined_class, undefined_function, undefined_identifier, UNUSED_IMPORT, dead_code\n';

        // Replace ALL {{...}} content with block comments
        const sanitized = ignores + text.replace(/\{\{([\s\S]*?)\}\}/g, '/* {{$1}} */');

        const shadowPath = this.getShadowUri(document.uri).fsPath;
        try {
            fs.writeFileSync(shadowPath, sanitized);
        } catch (e) {
            console.error('Failed to write shadow file', e);
        }
    }

    private mapRangeFromShadow(range: vscode.Range | undefined): vscode.Range | undefined {
        if (!range) return undefined;
        if (range.start.line < SHADOW_HEADER_LINES) return range;
        return new vscode.Range(
            range.start.translate(-SHADOW_HEADER_LINES, 0),
            range.end.translate(-SHADOW_HEADER_LINES, 0)
        );
    }

    private mapLocationFromShadow(location: vscode.Location): vscode.Location {
        if (location.uri.path.endsWith('.__analysis__.dart')) {
            const templatePath = location.uri.fsPath.replace('.__analysis__.dart', '');
            const templateUri = vscode.Uri.file(templatePath);
            const range = this.mapRangeFromShadow(location.range);
            return new vscode.Location(templateUri, range || location.range);
        }
        return location;
    }

    async provideHover(document: vscode.TextDocument, position: vscode.Position, token: vscode.CancellationToken): Promise<vscode.Hover | undefined> {
        this.updateShadowFile(document);
        const shadowUri = this.getShadowUri(document.uri);
        const shadowPos = position.translate(SHADOW_HEADER_LINES, 0);

        try {
            const hovers = await vscode.commands.executeCommand<vscode.Hover[]>(
                'vscode.executeHoverProvider',
                shadowUri,
                shadowPos
            );

            if (hovers && hovers.length > 0) {
                const hover = hovers[0];
                if (hover.range) {
                    hover.range = this.mapRangeFromShadow(hover.range);
                }
                return hover;
            }
        } catch (e) {
            // ignore
        }
        return undefined;
    }

    async provideCompletionItems(document: vscode.TextDocument, position: vscode.Position, token: vscode.CancellationToken, context: vscode.CompletionContext): Promise<vscode.CompletionList | vscode.CompletionItem[] | undefined> {
        this.updateShadowFile(document);
        const shadowUri = this.getShadowUri(document.uri);
        const shadowPos = position.translate(SHADOW_HEADER_LINES, 0);

        try {
            const list = await vscode.commands.executeCommand<vscode.CompletionList>(
                'vscode.executeCompletionItemProvider',
                shadowUri,
                shadowPos,
                context.triggerCharacter
            );

            if (!list) return undefined;

            const items = list.items.map(item => {
                if (item.range) {
                    if (item.range instanceof vscode.Range) {
                        item.range = this.mapRangeFromShadow(item.range);
                    } else {
                        item.range = {
                            inserting: this.mapRangeFromShadow(item.range.inserting)!,
                            replacing: this.mapRangeFromShadow(item.range.replacing)!
                        };
                    }
                }
                return item;
            });

            list.items = items;
            return list;

        } catch (e) {
            return undefined;
        }
    }

    async provideDefinition(document: vscode.TextDocument, position: vscode.Position, token: vscode.CancellationToken): Promise<vscode.Definition | vscode.DefinitionLink[] | undefined> {
        this.updateShadowFile(document);
        const shadowUri = this.getShadowUri(document.uri);
        const shadowPos = position.translate(SHADOW_HEADER_LINES, 0);

        try {
            const result = await vscode.commands.executeCommand<vscode.Definition | vscode.DefinitionLink[]>(
                'vscode.executeDefinitionProvider',
                shadowUri,
                shadowPos
            );

            if (!result) return undefined;

            if (Array.isArray(result)) {
                if (result.length === 0) return result;
                if ('targetUri' in result[0]) {
                    return (result as vscode.DefinitionLink[]).map(link => {
                        if (link.targetUri.path.endsWith('.__analysis__.dart')) {
                            const templatePath = link.targetUri.fsPath.replace('.__analysis__.dart', '');
                            link.targetUri = vscode.Uri.file(templatePath);
                            link.targetRange = this.mapRangeFromShadow(link.targetRange)!;
                            link.targetSelectionRange = this.mapRangeFromShadow(link.targetSelectionRange);
                        }
                        return link;
                    });
                } else {
                    return (result as vscode.Location[]).map(loc => this.mapLocationFromShadow(loc));
                }
            } else {
                return this.mapLocationFromShadow(result as vscode.Location);
            }
        } catch (e) {
            return undefined;
        }
    }
}

function isTemplateFile(document: vscode.TextDocument): boolean {
    return document.languageId === 'dart-template' || document.languageId === 'shell-template';
}

// Global regex reset helper unused, but we reset in loops
function validateDocument(document: vscode.TextDocument) {
    if (!isTemplateFile(document)) {
        return;
    }
    const config = vscode.workspace.getConfiguration('flutterScaffoldTemplate');
    if (!config.get('enableLinting', true)) {
        diagnosticCollection.delete(document.uri);
        return;
    }

    const diagnostics: vscode.Diagnostic[] = [];
    const text = document.getText();

    // Validate conditional nesting
    if (config.get('placeholderValidation', true)) {
        diagnostics.push(...validateConditionalNesting(document));

        let match;
        PLACEHOLDER_REGEX.lastIndex = 0;

        while ((match = PLACEHOLDER_REGEX.exec(text)) !== null) {
            const content = match[1].trim();

            // Logic check: if starts with logic keywords, Ignore entire block
            if (/^(if\s+[a-zA-Z0-9_]+|else\s+if\s+[a-zA-Z0-9_]+|else|endif)(\s|$)/.test(content)) {
                continue;
            }

            const parts = content.split(/\s+/);
            const name = parts[0];

            // Only validate if it looks like a variable name (alphanumeric)
            // and is NOT a logic keyword matching strict check above
            if (name && /^[a-zA-Z][a-zA-Z0-9_]*$/.test(name)) {
                if (!KNOWN_PLACEHOLDERS.has(name)) {
                    // One final check: complex expressions
                    if (parts.length > 1) {
                        // e.g. {{ someFunc(arg) }} - skip validation
                        continue;
                    }

                    const startPos = document.positionAt(match.index);
                    const endPos = document.positionAt(match.index + match[0].length);
                    const range = new vscode.Range(startPos, endPos);

                    const diagnostic = new vscode.Diagnostic(
                        range,
                        `Unknown placeholder: '${name}'.`,
                        vscode.DiagnosticSeverity.Warning,
                    );
                    diagnostic.source = 'flutter-scaffold-template';
                    diagnostic.code = 'unknown-placeholder';
                    diagnostics.push(diagnostic);
                }
            }
        }
    }

    diagnosticCollection.set(document.uri, diagnostics);
}

function validateConditionalNesting(document: vscode.TextDocument): vscode.Diagnostic[] {
    const diagnostics: vscode.Diagnostic[] = [];
    const text = document.getText();
    const lines = text.split('\n');
    const stack: Array<{ type: string, line: number }> = [];

    const ifRegex = /^\s*\{\{\s*if\s+([a-zA-Z0-9_]+)\s*\}\}\s*$/;
    const elIfRegex = /^\s*\{\{\s*else\s+if\s+([a-zA-Z0-9_]+)\s*\}\}\s*$/;
    const elseRegex = /^\s*\{\{\s*else\s*\}\}\s*$/;
    const endifRegex = /^\s*\{\{\s*endif\s*\}\}\s*$/;

    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];

        if (ifRegex.test(line)) {
            stack.push({ type: 'if', line: i });
        } else if (elIfRegex.test(line) || elseRegex.test(line)) {
            if (stack.length === 0) {
                const startPos = new vscode.Position(i, 0);
                const endPos = new vscode.Position(i, line.length);
                const range = new vscode.Range(startPos, endPos);

                diagnostics.push(new vscode.Diagnostic(
                    range,
                    'Unmatched else/else if - no corresponding if block',
                    vscode.DiagnosticSeverity.Error,
                ));
            }
        } else if (endifRegex.test(line)) {
            if (stack.length === 0) {
                const startPos = new vscode.Position(i, 0);
                const endPos = new vscode.Position(i, line.length);
                const range = new vscode.Range(startPos, endPos);

                diagnostics.push(new vscode.Diagnostic(
                    range,
                    'Unmatched endif - no corresponding if block',
                    vscode.DiagnosticSeverity.Error,
                ));
            } else {
                stack.pop();
            }
        }
    }

    // Check for unclosed if blocks
    stack.forEach(item => {
        const line = lines[item.line];
        const startPos = new vscode.Position(item.line, 0);
        const endPos = new vscode.Position(item.line, line.length);
        const range = new vscode.Range(startPos, endPos);

        diagnostics.push(new vscode.Diagnostic(
            range,
            'Unclosed if block - missing endif',
            vscode.DiagnosticSeverity.Error,
        ));
    });

    diagnostics.forEach(diagnostic => {
        diagnostic.source = 'flutter-scaffold-template';
        diagnostic.code = 'conditional-nesting';
    });

    return diagnostics;
}

function provideTemplateHover(document: vscode.TextDocument, position: vscode.Position): vscode.Hover | undefined {
    // We use a simpler regex for hover detection at cursor
    const range = document.getWordRangeAtPosition(position, /\{\{.*?\}\}/);
    if (!range) return undefined;

    const text = document.getText(range);
    const contentMatch = text.match(/\{\{([\s\S]*?)\}\}/);
    if (!contentMatch) return undefined;

    const content = contentMatch[1].trim();

    // Explicit logic check
    if (/^(if\s+[a-zA-Z0-9_]+|else\s+if\s+[a-zA-Z0-9_]+|else|endif)(\s|$)/.test(content)) {
        return new vscode.Hover('**Template Logic**: Control flow directive', range);
    }

    const parts = content.split(/\s+/);
    const placeholderName = parts[0];

    const descriptions: Record<string, string> = {
        projectName: 'The Flutter project name from pubspec.yaml (snake_case)',
        featureName: 'The feature name in snake_case (e.g., my_feature)',
        FeatureName: 'The feature name in PascalCase (e.g., MyFeature)',
    };

    const description = descriptions[placeholderName] || 'Template placeholder';
    const contents = new vscode.MarkdownString();

    if (KNOWN_PLACEHOLDERS.has(placeholderName)) {
        contents.appendMarkdown(`**Placeholder:** \`${placeholderName}\`\n\n${description}`);
    } else {
        contents.appendMarkdown(`**Placeholder:** \`${placeholderName}\`\n\n⚠️ *Unknown placeholder*`);
    }

    return new vscode.Hover(contents, range);
}

function provideTemplatePlaceholderCompletions(document: vscode.TextDocument, position: vscode.Position): vscode.CompletionItem[] {
    const linePrefix = document.lineAt(position).text.substring(0, position.character);

    // Check if we are inside {{ ... }}
    const lastOpen = linePrefix.lastIndexOf('{{');
    const lastClose = linePrefix.lastIndexOf('}}');

    // Not inside a block
    if (lastOpen === -1 || lastOpen < lastClose) {
        return [];
    }

    const items: vscode.CompletionItem[] = [];

    // Snippets

    const ifSnippet = new vscode.CompletionItem('if', vscode.CompletionItemKind.Snippet);
    ifSnippet.detail = 'Template Logic';
    ifSnippet.documentation = 'Insert conditional block';
    ifSnippet.insertText = new vscode.SnippetString('if ${1:condition} }}\n$0\n{{ endif');
    items.push(ifSnippet);

    const ifElseSnippet = new vscode.CompletionItem('ifelse', vscode.CompletionItemKind.Snippet);
    ifElseSnippet.detail = 'Template Logic';
    ifElseSnippet.documentation = 'Insert if-else block';
    ifElseSnippet.insertText = new vscode.SnippetString('if ${1:condition} }}\n$2\n{{ else }}\n$0\n{{ endif');
    items.push(ifElseSnippet);

    const placeholderDescriptions: Record<string, string> = {
        // Core names
        projectName: 'Project name from pubspec.yaml',
        featureName: 'Feature name (snake_case)',
        FeatureName: 'Feature name (PascalCase)',
        FEATURE_NAME: 'Feature name (UPPER_SNAKE_CASE)',
        PASCAL_NAME: 'Entity/Feature name in PascalCase',
        PASCAL_FEATURE_NAME: 'Feature name in PascalCase',
        // Model-related
        MODEL_NAME: 'Model name (snake_case)',
        PASCAL_MODEL_NAME: 'Model name (PascalCase)',
        // Screen-related
        screenName: 'Screen name (snake_case)',
        PASCAL_SCREEN_NAME: 'Screen name (PascalCase)',
        // Fields & data
        FIELDS: 'List of model fields',
        FIELD_NAMES: 'Comma-separated field names',
        FIELDS_WITH_OPTIONAL: 'Fields marked as optional',
        COPY_FIELDS: 'Fields for copyWith method',
        JSON_FIELDS: 'Fields for JSON serialization',
        FROM_JSON_FIELDS: 'Fields for JSON deserialization',
        // Logic markers
        HAS_FIELDS: 'Boolean - true if model has fields',
        HAS_ENTITY: 'Boolean - true if feature has an entity',
        HAS_PARAMS: 'Boolean - true if use case has parameters',
        // Component names
        REPOSITORY_NAME: 'Repository name (snake_case)',
        PASCAL_REPOSITORY_NAME: 'Repository name (PascalCase)',
        USECASE_NAME: 'Use case name (snake_case)',
        PASCAL_USECASE_NAME: 'Use case name (PascalCase)',
        USECASE_DESCRIPTION: 'Description of the use case',
        RETURN_TYPE: 'Return type of the use case',
        ENTITY_NAME: 'Entity name (snake_case)',
        PASCAL_ENTITY_NAME: 'Entity name (PascalCase)',
    };

    const keywords = ['if', 'else', 'else if', 'endif', 'true', 'false'];

    // Context-aware suggestions
    const contentSinceOpen = linePrefix.substring(lastOpen + 2).trimStart();

    if (contentSinceOpen === '') {
        // At start of placeholder - suggest all options
        for (const [name, description] of Object.entries(placeholderDescriptions)) {
            const item = new vscode.CompletionItem(name, vscode.CompletionItemKind.Variable);
            item.detail = 'Template Variable';
            item.documentation = description;
            item.insertText = name;
            items.push(item);
        }
    } else {
        // We are typing something - suggest keywords too if applicable
        // Simple heuristic: if it looks like start of expression
        const currentWord = contentSinceOpen.split(/\s+/).pop() || '';

        if (['if', 'else', 'endif'].some(k => k.startsWith(currentWord))) {
            // Add keyword completions logic if needed, but snippets usually cover 'if'
            // Let's add 'endif' and 'else' manually as keywords
            if ('endif'.startsWith(currentWord)) {
                items.push(new vscode.CompletionItem('endif', vscode.CompletionItemKind.Keyword));
            }
            if ('else'.startsWith(currentWord)) {
                items.push(new vscode.CompletionItem('else', vscode.CompletionItemKind.Keyword));
            }
        }
    }

    return items;
}

function formatTemplate(document: vscode.TextDocument): vscode.TextEdit[] {
    const text = document.getText();
    const os = require('os');
    const path = require('path');
    const tempDir = os.tmpdir();

    let formattedText: string;

    // Step 1: Try full-file formatting (works for most templates)
    const fullFormatResult = tryFullFileFormat(text, tempDir, path);
    if (fullFormatResult.success) {
        formattedText = fullFormatResult.text;
    } else {
        // Step 2: Fall back to zone-based formatting for templates with structural breaks
        formattedText = formatByZones(text, tempDir, path);
    }

    // Step 3: Normalize template syntax (always applied)
    formattedText = normalizeTemplateSyntax(formattedText);

    const fullRange = new vscode.Range(document.positionAt(0), document.positionAt(text.length));
    return [vscode.TextEdit.replace(fullRange, formattedText)];
}

/**
 * Normalize template syntax:
 * - Clean up whitespace inside {{ }} blocks
 * - Normalize control line formatting
 * - Remove excessive blank lines
 */
function normalizeTemplateSyntax(text: string): string {
    let result = text;

    // 1. Normalize whitespace inside {{ }} blocks
    // {{ if  HAS_FIELDS  }} -> {{if HAS_FIELDS}}
    result = result.replace(/\{\{\s*([^}]+?)\s*\}\}/g, (match, content) => {
        // Normalize internal whitespace: multiple spaces/tabs become single space
        const normalized = content.trim().replace(/\s+/g, ' ');
        return `{{${normalized}}}`;
    });

    // 2. Ensure control lines are on their own line without leading/trailing whitespace
    // Lines that are ONLY a control block should be trimmed
    const lines = result.split('\n');
    const processedLines = lines.map(line => {
        // Check if line is only a control block (with optional whitespace)
        const controlOnlyMatch = line.match(/^\s*(\{\{(?:if\s+[a-zA-Z0-9_]+|else\s+if\s+[a-zA-Z0-9_]+|else|endif)\}\})\s*$/);
        if (controlOnlyMatch) {
            // Keep leading whitespace (user's original indentation), trim trailing
            return line.replace(/\s+$/, '');
        }
        return line;
    });

    // 3. Remove excessive blank lines (more than 1 consecutive blank line)
    const collapsedLines: string[] = [];
    let consecutiveBlankCount = 0;

    for (const line of processedLines) {
        if (line.trim() === '') {
            consecutiveBlankCount++;
            if (consecutiveBlankCount <= 1) {
                collapsedLines.push(line);
            }
        } else {
            consecutiveBlankCount = 0;
            collapsedLines.push(line);
        }
    }

    // 4. Remove leading/trailing blank lines
    while (collapsedLines.length > 0 && collapsedLines[0].trim() === '') {
        collapsedLines.shift();
    }
    while (collapsedLines.length > 0 && collapsedLines[collapsedLines.length - 1].trim() === '') {
        collapsedLines.pop();
    }

    // Ensure file ends with a newline
    result = collapsedLines.join('\n');
    if (!result.endsWith('\n')) {
        result += '\n';
    }

    return result;
}

/**
 * Try to format the entire file by converting template syntax to valid Dart.
 * Returns success if dart format completes without parse errors.
 */
function tryFullFileFormat(text: string, tempDir: string, path: any): { success: boolean; text: string } {
    const lines = text.split('\n');
    const controlLines: { index: number; original: string; marker: string }[] = [];
    const placeholderMap = new Map<string, string>(); // Map template var to placeholder
    let controlCounter = 0;
    let placeholderCounter = 0;

    // Regex for control block lines
    const controlLineRegex = /^\s*\{\{(if\s+|else\s*if\s+|else|endif)/;

    // Process each line
    const processedLines = lines.map((line, idx) => {
        if (controlLineRegex.test(line)) {
            const marker = `__CTRL_${controlCounter++}__`;
            controlLines.push({ index: idx, original: line, marker });
            // Use a valid Dart statement that can exist anywhere
            return `/* ${marker} */`;
        }

        // Replace {{ ... }} with valid identifiers
        // IMPORTANT: Same template variable must get same placeholder!
        return line.replace(PLACEHOLDER_REGEX, (match) => {
            if (!placeholderMap.has(match)) {
                placeholderMap.set(match, `Tmpl${placeholderCounter++}Placeholder`);
            }
            return placeholderMap.get(match)!;
        });
    });

    const tempText = processedLines.join('\n');
    const tempFile = path.join(tempDir, `format_full_${Date.now()}.dart`);

    try {
        fs.writeFileSync(tempFile, tempText, 'utf-8');

        // Try dart format - capture stderr to detect parse errors
        execSync(`dart format "${tempFile}" 2>&1`, {
            encoding: 'utf-8',
            timeout: 10000,
        });

        let formattedText = fs.readFileSync(tempFile, 'utf-8');

        // Check if the formatted text still contains our markers (parse was successful)
        const hasAllMarkers = controlLines.every(ctrl => formattedText.includes(ctrl.marker));
        if (!hasAllMarkers) {
            return { success: false, text: '' };
        }

        // Restore control lines - comments might have moved
        controlLines.forEach(ctrl => {
            // Match the formatted comment with flexible whitespace
            const markerPattern = new RegExp(`(\\/\\*\\s*${ctrl.marker}\\s*\\*\\/)`, 'g');
            formattedText = formattedText.replace(markerPattern, () => {
                return ctrl.original.trim();
            });
        });

        // Restore template placeholders
        placeholderMap.forEach((placeholder, original) => {
            formattedText = formattedText.split(placeholder).join(original);
        });

        return { success: true, text: formattedText };
    } catch (e: any) {
        // Parse error or format error - fall back to zone-based
        return { success: false, text: '' };
    } finally {
        try {
            if (fs.existsSync(tempFile)) {
                fs.unlinkSync(tempFile);
            }
        } catch { /* ignore */ }
    }
}

/**
 * Format by zones - splits the template into zones separated by control lines.
 * Each zone is formatted independently if it's valid Dart.
 */
function formatByZones(text: string, tempDir: string, path: any): string {
    const lines = text.split('\n');
    const controlLineRegex = /^\s*\{\{(if\s+|else\s*if\s+|else|endif)/;

    // Identify zones
    interface Zone {
        type: 'code' | 'control';
        lines: string[];
        startIndex: number;
    }

    const zones: Zone[] = [];
    let currentZone: Zone | null = null;

    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        const isControl = controlLineRegex.test(line);

        if (isControl) {
            // End current code zone if any
            if (currentZone && currentZone.type === 'code') {
                zones.push(currentZone);
                currentZone = null;
            }
            // Each control line is its own zone
            zones.push({
                type: 'control',
                lines: [line],
                startIndex: i
            });
        } else {
            // Code line - add to current code zone or create new one
            if (!currentZone || currentZone.type !== 'code') {
                currentZone = {
                    type: 'code',
                    lines: [],
                    startIndex: i
                };
            }
            currentZone.lines.push(line);
        }
    }

    // Push final zone
    if (currentZone) {
        zones.push(currentZone);
    }

    // Format each code zone
    const formattedZones = zones.map(zone => {
        if (zone.type === 'control') {
            // Keep leading whitespace (user's original indentation), trim trailing
            return zone.lines[0].replace(/\s+$/, '');
        }

        // Try to format the code zone
        const formattedCode = tryFormatCodeZone(zone.lines, tempDir, path);
        return formattedCode;
    });

    return formattedZones.join('\n');
}

/**
 * Try to format a code zone. Returns formatted code or original if formatting fails.
 */
function tryFormatCodeZone(lines: string[], tempDir: string, path: any): string {
    if (lines.length === 0) {
        return '';
    }

    // Skip zones that are just whitespace
    const nonEmptyLines = lines.filter(l => l.trim().length > 0);
    if (nonEmptyLines.length === 0) {
        return lines.join('\n');
    }

    // Replace placeholders with valid identifiers
    // IMPORTANT: Same template variable must get same placeholder!
    const placeholderMap = new Map<string, string>();
    let placeholderCounter = 0;

    const processedLines = lines.map(line => {
        return line.replace(PLACEHOLDER_REGEX, (match) => {
            if (!placeholderMap.has(match)) {
                placeholderMap.set(match, `Tmpl${placeholderCounter++}Placeholder`);
            }
            return placeholderMap.get(match)!;
        });
    });

    const tempText = processedLines.join('\n');
    const tempFile = path.join(tempDir, `format_zone_${Date.now()}.dart`);

    try {
        fs.writeFileSync(tempFile, tempText, 'utf-8');

        execSync(`dart format "${tempFile}" 2>&1`, {
            encoding: 'utf-8',
            timeout: 5000,
        });

        let formattedText = fs.readFileSync(tempFile, 'utf-8');

        // Restore placeholders
        placeholderMap.forEach((placeholder, original) => {
            formattedText = formattedText.split(placeholder).join(original);
        });

        // Remove trailing newline that dart format adds
        formattedText = formattedText.replace(/\n$/, '');

        return formattedText;
    } catch {
        // Formatting failed - return original with placeholders restored
        let originalText = lines.join('\n');
        return originalText;
    } finally {
        try {
            if (fs.existsSync(tempFile)) {
                fs.unlinkSync(tempFile);
            }
        } catch { /* ignore */ }
    }
}


// Update decorations for template syntax highlighting
function updateDecorations(editor: vscode.TextEditor): void {
    const text = editor.document.getText();

    const bracketRanges: vscode.Range[] = [];
    const keywordRanges: vscode.Range[] = [];
    const variableRanges: vscode.Range[] = [];

    // Match all {{ ... }} blocks
    const templateRegex = /\{\{([\s\S]*?)\}\}/g;
    let match;

    while ((match = templateRegex.exec(text)) !== null) {
        const startPos = editor.document.positionAt(match.index);
        const endPos = editor.document.positionAt(match.index + match[0].length);

        // Highlight {{ and }}
        const openBracketEnd = editor.document.positionAt(match.index + 2);
        bracketRanges.push(new vscode.Range(startPos, openBracketEnd));

        const closeBracketStart = editor.document.positionAt(match.index + match[0].length - 2);
        bracketRanges.push(new vscode.Range(closeBracketStart, endPos));

        // Highlight content between brackets
        const content = match[1];
        const contentStart = match.index + 2;

        // Check for keywords
        const keywordMatch = content.match(/^\s*(if|else\s+if|else|endif)\b/);
        if (keywordMatch) {
            const kwStart = contentStart + content.indexOf(keywordMatch[1]);
            const kwEnd = kwStart + keywordMatch[1].length;
            keywordRanges.push(new vscode.Range(
                editor.document.positionAt(kwStart),
                editor.document.positionAt(kwEnd)
            ));
        }

        // Highlight variable names
        const varRegex = /\b([a-zA-Z_][a-zA-Z0-9_]*)\b/g;
        let varMatch;
        while ((varMatch = varRegex.exec(content)) !== null) {
            // Skip keywords
            if (['if', 'else', 'endif', 'true', 'false', 'null'].includes(varMatch[1])) {
                continue;
            }
            const varStart = contentStart + varMatch.index;
            const varEnd = varStart + varMatch[1].length;
            variableRanges.push(new vscode.Range(
                editor.document.positionAt(varStart),
                editor.document.positionAt(varEnd)
            ));
        }
    }

    editor.setDecorations(bracketDecorationType, bracketRanges);
    editor.setDecorations(keywordDecorationType, keywordRanges);
    editor.setDecorations(variableDecorationType, variableRanges);
}
