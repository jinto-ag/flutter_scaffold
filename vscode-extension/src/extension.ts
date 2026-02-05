import * as vscode from 'vscode';
import * as fs from 'fs';
import { execSync } from 'child_process';

const KNOWN_PLACEHOLDERS = new Set([
    'projectName',
    'featureName',
    'FeatureName',
]);

const PLACEHOLDER_REGEX = /\{\{\s*([a-zA-Z][a-zA-Z0-9_]*)\s*\}\}/g;
// Number of lines added to the top of the shadow file
const SHADOW_HEADER_LINES = 1;

let diagnosticCollection: vscode.DiagnosticCollection;

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
        }),
        vscode.workspace.onDidSaveTextDocument(validateDocument),

        // Clean up shadow files when document is closed
        vscode.workspace.onDidCloseTextDocument((doc) => {
            if (isTemplateFile(doc)) {
                shadowProvider.deleteShadowFile(doc);
            }
        })
    );

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
                    return [...templateItems, ...items];
                },
            },
            '.',
            '{',
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
        const sanitized = ignores + text.replace(/\{\{/g, '  ').replace(/\}\}/g, '  ');

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
            console.error('Shadow hover failed', e);
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
            console.error('Shadow completion failed', e);
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
            console.error('Shadow definition failed', e);
            return undefined;
        }
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

function provideTemplateHover(document: vscode.TextDocument, position: vscode.Position): vscode.Hover | undefined {
    const range = document.getWordRangeAtPosition(position, /\{\{\s*[a-zA-Z][a-zA-Z0-9_]*\s*\}\}/);
    if (!range) return undefined;

    const text = document.getText(range);
    const match = text.match(/\{\{\s*([a-zA-Z][a-zA-Z0-9_]*)\s*\}\}/);
    if (!match) return undefined;

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

function provideTemplatePlaceholderCompletions(document: vscode.TextDocument, position: vscode.Position): vscode.CompletionItem[] {
    const linePrefix = document.lineAt(position).text.substring(0, position.character);
    if (!linePrefix.endsWith('{') && !linePrefix.endsWith('{{')) return [];

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

    let tempText = text.replace(PLACEHOLDER_REGEX, (match, name, offset) => {
        const uuid = 'valid_dart_id_' + Math.random().toString(36).substring(2, 15);
        placeholders.push({ name: `{{${name}}}`, uuid, index: offset });
        return uuid;
    });

    try {
        const output = execSync('dart format --output=show', {
            input: tempText,
            encoding: 'utf-8',
            timeout: 3000
        });

        let formattedText = output.toString();
        placeholders.forEach(p => {
            formattedText = formattedText.replace(p.uuid, p.name);
        });

        const fullRange = new vscode.Range(document.positionAt(0), document.positionAt(text.length));
        return [vscode.TextEdit.replace(fullRange, formattedText)];

    } catch (e) {
        console.error('Formatting failed:', e);
        if (e instanceof Error && !e.message.includes('Could not format')) {
            vscode.window.showErrorMessage('Dart Template formatting failed. Ensure "dart" is in your PATH.');
        }
        return [];
    }
}
