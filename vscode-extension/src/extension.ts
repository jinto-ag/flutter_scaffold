import * as vscode from 'vscode';
import * as fs from 'fs';
import { execSync } from 'child_process';

const KNOWN_PLACEHOLDERS = new Set([
    'projectName',
    'featureName',
    'FeatureName',
]);

// Regex to capture the content inside {{ }}. 
// Optimized for single-line usage mostly, but supports newlines if VS Code range allows.
const PLACEHOLDER_REGEX = /\{\{([\s\S]*?)\}\}/g;
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
    const placeholderDescriptions: Record<string, string> = {
        projectName: 'Project name',
        featureName: 'Feature name (snake_case)',
        FeatureName: 'Feature name (PascalCase)',
        'if ': 'If condition - {{if variableName}}',
        'else if ': 'Else if condition - {{else if variableName}}',
        'else': 'Else block - {{else}}',
        'endif': 'End if block - {{endif}}'
    };

    // Context-aware suggestions
    const contentSinceOpen = linePrefix.substring(lastOpen + 2).trim();
    
    if (contentSinceOpen === '') {
        // At start of placeholder - suggest all options
        for (const [name, description] of Object.entries(placeholderDescriptions)) {
            const item = new vscode.CompletionItem(name, vscode.CompletionItemKind.Keyword);
            item.detail = 'Template Directive';
            item.documentation = description;
            item.insertText = name;
            items.push(item);
        }
    } else if (contentSinceOpen.startsWith('if ') || contentSinceOpen.startsWith('else if ') || contentSinceOpen === 'else') {
        // After conditional logic - suggest endif
        const endifItem = new vscode.CompletionItem('endif', vscode.CompletionItemKind.Keyword);
        endifItem.detail = 'Template Directive';
        endifItem.documentation = 'End if block - {{endif}}';
        endifItem.insertText = 'endif';
        items.push(endifItem);
    }

    return items;
}

function formatTemplate(document: vscode.TextDocument): vscode.TextEdit[] {
    const text = document.getText();
    const placeholders: { original: string, uuid: string }[] = [];

    let tempText = text.replace(PLACEHOLDER_REGEX, (match) => {
        const uuid = 'TEMPLATE_PH_' + Math.random().toString(36).substring(2, 10).toUpperCase();
        placeholders.push({ original: match, uuid });
        return `/* ${uuid} */`;
    });

    try {
        const output = execSync('dart format --output=show', {
            input: tempText,
            encoding: 'utf-8',
            timeout: 3000
        });

        let formattedText = output.toString();

        placeholders.forEach(p => {
            const escapedUuid = p.uuid.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
            const regex = new RegExp(`\/\\*\\s*${escapedUuid}\\s*\\*\/`, 'g');
            formattedText = formattedText.replace(regex, p.original);
        });

        const fullRange = new vscode.Range(document.positionAt(0), document.positionAt(text.length));
        return [vscode.TextEdit.replace(fullRange, formattedText)];

    } catch (e) {
        return [];
    }
}
