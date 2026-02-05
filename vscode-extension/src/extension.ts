import * as vscode from 'vscode';
import { execSync } from 'child_process';

// Known placeholders in flutter_scaffold templates
const KNOWN_PLACEHOLDERS = new Set([
    'projectName',
    'featureName',
    'FeatureName',
]);

// Placeholder pattern
const PLACEHOLDER_REGEX = /\{\{([a-zA-Z][a-zA-Z0-9_]*)\}\}/g;

let diagnosticCollection: vscode.DiagnosticCollection;

export function activate(context: vscode.ExtensionContext) {
    console.log('Flutter Scaffold Template extension activated');

    // Create diagnostic collection for linting
    diagnosticCollection = vscode.languages.createDiagnosticCollection('flutter-scaffold-template');
    context.subscriptions.push(diagnosticCollection);

    // Register document change listener for linting
    context.subscriptions.push(
        vscode.workspace.onDidOpenTextDocument(validateDocument),
        vscode.workspace.onDidChangeTextDocument((e) => validateDocument(e.document)),
        vscode.workspace.onDidSaveTextDocument(validateDocument),
    );

    // Validate all open documents
    vscode.workspace.textDocuments.forEach(validateDocument);

    // Register hover provider for placeholders
    context.subscriptions.push(
        vscode.languages.registerHoverProvider('dart-template', {
            provideHover(document, position) {
                return provideTemplateHover(document, position);
            },
        }),
    );

    // Register completion provider for placeholders
    context.subscriptions.push(
        vscode.languages.registerCompletionItemProvider(
            'dart-template',
            {
                provideCompletionItems(document, position) {
                    return provideTemplatePlaceholderCompletions(document, position);
                },
            },
            '{', // Trigger on opening brace
        ),
    );

    // Register document formatting provider
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

function isTemplateFile(document: vscode.TextDocument): boolean {
    return document.languageId === 'dart-template' || document.languageId === 'shell-template';
}

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

    // Validate placeholder names
    if (config.get('placeholderValidation', true)) {
        let match;
        while ((match = PLACEHOLDER_REGEX.exec(text)) !== null) {
            const placeholderName = match[1];
            if (!KNOWN_PLACEHOLDERS.has(placeholderName)) {
                const startPos = document.positionAt(match.index);
                const endPos = document.positionAt(match.index + match[0].length);
                const range = new vscode.Range(startPos, endPos);

                const diagnostic = new vscode.Diagnostic(
                    range,
                    `Unknown placeholder: '${placeholderName}'. Known placeholders: ${Array.from(KNOWN_PLACEHOLDERS).join(', ')}`,
                    vscode.DiagnosticSeverity.Warning,
                );
                diagnostic.source = 'flutter-scaffold-template';
                diagnostic.code = 'unknown-placeholder';
                diagnostics.push(diagnostic);
            }
        }
    }

    diagnosticCollection.set(document.uri, diagnostics);
}

function provideTemplateHover(
    document: vscode.TextDocument,
    position: vscode.Position,
): vscode.Hover | undefined {
    const range = document.getWordRangeAtPosition(position, /\{\{[a-zA-Z][a-zA-Z0-9_]*\}\}/);
    if (!range) {
        return undefined;
    }

    const text = document.getText(range);
    const match = text.match(/\{\{([a-zA-Z][a-zA-Z0-9_]*)\}\}/);
    if (!match) {
        return undefined;
    }

    const placeholderName = match[1];
    const descriptions: Record<string, string> = {
        projectName: 'The Flutter project name from pubspec.yaml (snake_case)',
        featureName: 'The feature name in snake_case (e.g., my_feature)',
        FeatureName: 'The feature name in PascalCase (e.g., MyFeature)',
    };

    const description = descriptions[placeholderName] || 'Template placeholder';
    const contents = new vscode.MarkdownString();
    contents.appendMarkdown(`**Placeholder:** \`${placeholderName}\`\n\n`);
    contents.appendMarkdown(description);

    if (!KNOWN_PLACEHOLDERS.has(placeholderName)) {
        contents.appendMarkdown('\n\n⚠️ *Unknown placeholder*');
    }

    return new vscode.Hover(contents, range);
}

function provideTemplatePlaceholderCompletions(
    document: vscode.TextDocument,
    position: vscode.Position,
): vscode.CompletionItem[] {
    const linePrefix = document.lineAt(position).text.substring(0, position.character);

    // Check if we're inside a placeholder
    if (!linePrefix.endsWith('{') && !linePrefix.endsWith('{{')) {
        return [];
    }

    const items: vscode.CompletionItem[] = [];

    const placeholderDescriptions: Record<string, string> = {
        projectName: 'Project name from pubspec.yaml',
        featureName: 'Feature name in snake_case',
        FeatureName: 'Feature name in PascalCase',
    };

    for (const [name, description] of Object.entries(placeholderDescriptions)) {
        const item = new vscode.CompletionItem(name, vscode.CompletionItemKind.Variable);
        item.detail = 'Template Placeholder';
        item.documentation = description;

        // Insert the full placeholder if user typed single {
        if (linePrefix.endsWith('{{')) {
            item.insertText = `${name}}}`;
        } else {
            item.insertText = `{${name}}}`;
        }

        items.push(item);
    }

    return items;
}

function formatTemplate(document: vscode.TextDocument): vscode.TextEdit[] {
    const text = document.getText();
    const placeholders: { name: string, uuid: string, index: number }[] = [];

    // Replace placeholders with distinct temporary identifiers that are valid Dart identifiers
    // Using a prefix 'valid_dart_id_' + random string to avoid collisions
    let tempText = text.replace(PLACEHOLDER_REGEX, (match, name, offset) => {
        const uuid = 'valid_dart_id_' + Math.random().toString(36).substring(2, 15);
        placeholders.push({ name: match, uuid, index: offset });
        return uuid;
    });

    try {
        // Run dart format on the temp text
        const output = execSync('dart format --output=show', {
            input: tempText,
            encoding: 'utf-8',
            timeout: 3000 // 3s timeout
        });

        let formattedText = output.toString();

        // Restore placeholders
        placeholders.forEach(p => {
            // Replace UUIDs back with placeholders
            formattedText = formattedText.replace(p.uuid, p.name);
        });

        const fullRange = new vscode.Range(
            document.positionAt(0),
            document.positionAt(text.length)
        );

        return [vscode.TextEdit.replace(fullRange, formattedText)];

    } catch (e) {
        console.error('Formatting failed:', e);
        // Only show error message if it's not just a syntax error in the template that caused format to fail
        if (e instanceof Error && !e.message.includes('Could not format')) {
            vscode.window.showErrorMessage('Dart Template formatting failed. Ensure "dart" is in your PATH.');
        }
        return [];
    }
}
