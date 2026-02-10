# Security Policy

## Supported Versions

| Version | Supported          |
|---------|-------------------|
| 0.1.x  | ✅ Current        |

## Reporting a Vulnerability

The flutter_scaffold team and community take security bugs seriously. We appreciate your efforts to responsibly disclose your findings.

### How to Report

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please send an email to: **security@flutter_scaffold.dev**

This email is monitored by the core team who will respond within 48 hours.

### What to Include

Please include the following information in your report:

- **Type of issue** (e.g., buffer overflow, SQL injection, cross-site scripting, etc.)
- **Full paths** of source file(s) related to the manifestation of the issue
- **Location of the affected source code** (tag/branch/commit or direct URL)
- **Special configuration** required to reproduce the issue
- **Step-by-step instructions** to reproduce the issue
- **Proof-of-concept or exploit code** (if possible)
- **Impact** of the issue, including how an attacker might exploit it

### Response Timeline

- **Initial response**: Within 48 hours
- **Detailed response**: Within 7 days
- **Resolution**: As soon as feasible, based on complexity

### Security Measures

flutter_scaffold takes several security measures:

1. **No Remote Code Execution**: The CLI tool operates locally and doesn't execute remote code
2. **Sandboxed Operations**: File operations are restricted to specified project directories
3. **Dependency Verification**: All dependencies are verified through pub.dev
4. **Input Validation**: All user inputs are validated and sanitized
5. **No Network Access**: The tool doesn't make unsolicited network requests

### Best Practices for Users

To stay secure:

1. **Install from trusted sources only**:
   ```bash
   dart pub global activate flutter_scaffold
   ```

2. **Verify checksums** when downloading binaries
3. **Keep your version updated** to get security patches
4. **Review generated code** before running it in production
5. **Use project-specific configurations** to avoid exposing sensitive data

### Security Changelog

We will maintain a security changelog for all security fixes:

#### Version 0.1.0-beta
- No security issues reported

## Recognition

We want to thank security researchers for helping keep flutter_scaffold and our users safe. We'll acknowledge your contribution (with your permission) in our security changelog.

## Disclosure Policy

- We will publicly disclose vulnerabilities within 90 days of receipt
- Complex vulnerabilities may require additional time
- We'll coordinate disclosure if other projects are affected
- We'll provide CVEs for significant vulnerabilities

## Additional Resources

- [GitHub Security Best Practices](https://docs.github.com/en/code-security)
- [OWASP Secure Coding Practices](https://owasp.org/www-project-secure-coding-practices-quick-reference-guide/)
- [Dart Security Guidelines](https://dart.dev/guides/server/security)

---
*Last updated: February 10, 2026*