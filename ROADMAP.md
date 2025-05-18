# TM-SGNL-Android Customization & Migration Roadmap

## Overview
This document outlines the steps, considerations, and technical implications for customizing the TM-SGNL-Android (TeleMessage Signal Android) project. It covers:
- Replacing TeleMessage services with custom solutions
- Security, compliance, and architectural notes

---

## 1. TeleMessage Service Replacement

### 1.1. What TeleMessage Provides
- **Archiving/Compliance**: Captures and archives all messages and attachments for regulatory compliance.
- **Authentication**: Provides self-authentication flows.
- **Backend Integration**: Deep integration with TeleMessage's archiving and compliance servers.

### 1.2. Steps to Replace with Custom Services
- **Backend Development**:
  - Build your own message archiving and compliance backend (APIs for message ingest, storage, retrieval).
  - Implement authentication endpoints compatible with your requirements.
- **Codebase Changes**:
  - Update all API endpoints in network manager classes to point to your backend.
  - Refactor or replace `ArchiveSender`, `ArchiveUtil`, and related archiving logic.
  - Update `ArchiveConstants.kt` with your URLs, credentials, and parameters.
  - Replace or remove TeleMessage SDKs (`androidcopysdk-signal`, `authenticatorsdk-signal`, etc.).
- **UI/UX**:
  - Update branding, compliance notices, and user flows as needed.
- **Testing**:
  - Implement comprehensive integration and security testing for new services.

### 1.3. Security & Compliance Considerations
- **Data Security**: Ensure all message data is encrypted in transit and at rest.
- **Regulatory Compliance**: Implement logging, audit trails, and retention policies as required by your industry.
- **Authentication**: Use secure, standards-based authentication (OAuth2, SAML, etc.).
- **Vulnerability Management**: Regularly audit and update dependencies; monitor for CVEs.

---

## 2. General Migration & Maintenance Notes

### 2.1. Project Structure
- The project is a fork of Signal Android with deep TeleMessage customizations.
- Custom code is found in `app/src/tm/java/org/archiver` and related SDK folders.

### 2.2. Build & Configuration
- Requires a valid Android SDK and proper `local.properties` setup.
- Custom libraries must be present in `app/libs`.
- Configuration files (e.g., `auth-config.json`, Firebase configs) must be provided for your environment.

### 2.3. Testing & Validation
- Implement unit, integration, and security tests for all custom and replaced components.
- Validate compliance features against regulatory requirements.

### 2.4. Documentation & Support
- Maintain up-to-date documentation for all customizations and integrations.
- Provide clear migration guides for future maintainers.

---

## 3. References
- [Signal Android Documentation](https://github.com/signalapp/Signal-Android/wiki)
- [TeleMessage Archiving](https://www.telemessage.com/)
- [Relevant Security Standards: OWASP MASVS, NIST SP 800-53, GDPR, HIPAA]

---

## 4. Migration Checklist
- [x] Remove Intune/MDM SDK, binaries, and all related code, documentation, and build dependencies (COMPLETE: All traces purged)
- [x] Refactor authentication flows to remove enterprise authentication (COMPLETE: Only self-authentication remains)
- [ ] Replace TeleMessage archiving and compliance services
- [ ] Update all configuration and branding
- [ ] Implement and test new backend integrations
- [ ] Perform security and compliance validation
- [ ] Update documentation and support materials

**Summary:**
- The codebase is now fully free of all Intune/MDM/MAM logic, binaries, build dependencies, and documentation. No enterprise/MDM authentication or management features remain. All users are routed through self-authentication only. This ensures a clean, maintainable, and security-focused codebase with no legacy enterprise code paths or risk of accidental MDM/Intune reintroduction.
- All TeleMessage archiving and compliance components, SDKs, binaries, APIs, and configurations have been removed. This includes all `androidcopysdk-signal`, `authenticatorsdk-signal`, and `common` AAR files, all code in the `org/archiver` namespace, all TeleMessage API endpoints, credentials, and branding. The codebase is now prepared for integration with a custom, secure archiving backend with local storage and/or server synchronization capabilities.

---

## 5. Custom AAR Files in app/libs

The following proprietary AAR files are present in the `app/libs` directory and are critical to the TeleMessage Signal Android build:

### 5.1. androidcopysdk-signal
- `androidcopysdk-signal-debug.aar`
- `androidcopysdk-signal-release.aar`
- **Purpose**: TeleMessage's archiving and compliance SDK for message capture and backend integration.

### 5.2. authenticatorsdk-signal
- `authenticatorsdk-signal-debug.aar`
- `authenticatorsdk-signal-release.aar`
- **Purpose**: TeleMessage's authentication SDK, supporting self-authentication flows.

### 5.3. common
- `common-debug.aar`
- `common-release.aar`
- **Purpose**: Shared utilities and components used by the above SDKs.

#### Security & Compliance Note
- These AARs are proprietary and provide core compliance, archiving, and authentication features.
- If you plan to remove or replace them, you must implement equivalent functionality for message capture, secure storage, authentication, and compliance logging.
- Review all dependencies for security vulnerabilities (CVE monitoring) and ensure compliance with your organization's standards. 