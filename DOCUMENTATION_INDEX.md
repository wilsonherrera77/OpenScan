# Lumara Frontend Architecture - Complete Documentation Index

Generated: November 1, 2025  
Framework: Flutter 3.x  
Project: Lumara Scan (OpenScan) - Indigenous Communities Document Digitization  
Version: 5.6.1 (Phase 2: Session Tracking + Review Workflow + CSV Export)

---

## Documentation Files

### 1. **ARCHITECTURE_MAP.md** (Comprehensive)
**Size:** 1,018 lines | 51 KB  
**Best for:** In-depth understanding of the entire architecture

**Contents:**
- Complete screens inventory (17 screens by user role)
- All providers with state details and data flows
- Repository documentation (4 repositories)
- Services documentation (12+ services)
- Data flow diagrams (ASCII) for:
  - Authentication flow
  - Document upload flow (anti-duplicate system)
  - Assignment workflow (multi-user)
  - Session tracking (Phase 2)
- Complete features implementation status matrix
- Navigation flow diagram
- Component relationship map
- API endpoints reference (15+ endpoints)
- Security considerations
- Performance optimizations
- Dependencies reference
- Completeness assessment (what's done, what's partial, what's missing)

**Use when:** You need detailed technical information about a specific component or flow.

---

### 2. **ARCHITECTURE_SUMMARY.md** (Quick Reference)
**Size:** 302 lines | 9.1 KB  
**Best for:** Quick lookups and getting oriented

**Contents:**
- Quick stats (17 screens, 3 providers, 4 repos, 12+ services)
- Architecture layers overview
- Key features by category
- Screen map by user role
- Data flow summary (simple version)
- Critical files reference table
- API integration quick reference
- State management strategy
- Performance optimizations table
- Security features table
- Testing checklist
- Common tasks (how-to guide)
- Next steps / Phase 3 ideas

**Use when:** You need a quick answer or overview of a feature.

---

### 3. **ARCHITECTURE_VISUAL.txt** (Diagrams & Charts)
**Size:** 324 lines | 25 KB  
**Best for:** Visual understanding of structure and flow

**Contents:**
- Application flow diagram (ASCII art)
- Presentation layer organization diagram
- Data flow: Upload flow (complete diagram with all services)
- Data layer repositories diagram
- Services layer organization
- State management diagram
- Role-based routing diagram
- Entity relationship model
- Offline support architecture diagram
- Core features matrix (with status indicators)

**Use when:** You need to understand the structure visually or present to others.

---

### 4. **CLAUDE.md** (Project Configuration)
**Size:** 51 KB  
**For:** Claude Code AI assistant configuration

**Contains:** Advanced instructions for Claude Code v2.0.31, including subagent usage patterns, context management strategies, and enterprise development workflows.

---

## File Navigation Guide

### If you want to know about...

**Screens & Navigation:**
- ARCHITECTURE_MAP.md § 1 (Screens by role)
- ARCHITECTURE_SUMMARY.md § "Screen Map by User Role"
- ARCHITECTURE_VISUAL.txt § "Application Flow" + "Role-Based Routing"

**State Management:**
- ARCHITECTURE_MAP.md § 2 (Providers)
- ARCHITECTURE_SUMMARY.md § "Architecture Layers"
- ARCHITECTURE_VISUAL.txt § "State Management"

**Document Upload:**
- ARCHITECTURE_MAP.md § 5.2 (Upload data flow)
- ARCHITECTURE_VISUAL.txt § "Data Flow: Upload"

**Assignment Workflow:**
- ARCHITECTURE_MAP.md § 5.3 (Assignment workflow)
- ARCHITECTURE_SUMMARY.md § "Assignment Workflow"

**API Endpoints:**
- ARCHITECTURE_MAP.md § 16 (API endpoints)
- ARCHITECTURE_SUMMARY.md § "API Integration"

**Offline Support:**
- ARCHITECTURE_MAP.md § 8 (Component relationship)
- ARCHITECTURE_VISUAL.txt § "Offline Support Architecture"

**Features Status:**
- ARCHITECTURE_MAP.md § 6 (Features matrix)
- ARCHITECTURE_VISUAL.txt § "Core Features Matrix"

**Security:**
- ARCHITECTURE_MAP.md § 15 (Security considerations)
- ARCHITECTURE_SUMMARY.md § "Security Features"

**Performance:**
- ARCHITECTURE_MAP.md § 16 (Performance optimizations)
- ARCHITECTURE_SUMMARY.md § "Performance Optimizations"

---

## Quick Stats

| Metric | Value | Location |
|--------|-------|----------|
| Screens | 17 | MAP § 1, SUMMARY § Overview |
| Providers | 3 | MAP § 2, SUMMARY § Architecture |
| Repositories | 4 | MAP § 3, VISUAL § Data Layer |
| Services | 12+ | MAP § 4, VISUAL § Services Layer |
| Routes | 20+ | MAP § 7, VISUAL § App Flow |
| User Roles | 4 | MAP § 6.1, VISUAL § Role-Based Routing |
| API Endpoints | 15+ | MAP § 16, SUMMARY § API Integration |
| Features Complete | 25+ | MAP § 6, VISUAL § Features Matrix |

---

## Architecture Layers Quick Reference

```
Presentation Layer (17 screens + 3 providers)
        ↓
Domain Layer (8 entities)
        ↓
Data Layer (4 repositories + 2 data sources)
        ↓
Services Layer (12+ services)
        ↓
Backend API (Django REST Framework)
```

---

## Key Features Quick Matrix

| Feature | Status | Location |
|---------|--------|----------|
| JWT Authentication | ✅ Complete | MAP § 6.1 |
| RBAC (4 roles) | ✅ Complete | MAP § 6.1 |
| Document Upload | ✅ Complete | MAP § 6.2 |
| Anti-Duplicate Check | ✅ Complete | MAP § 6.2, VISUAL § Upload Flow |
| Hybrid OCR | ✅ Complete | MAP § 6.3 |
| Assignment Management | ✅ Complete | MAP § 6.4 |
| Review Workflow | ✅ Phase 2 | MAP § 6.5 |
| Session Tracking | ✅ Phase 2 | MAP § 6.8 |
| CSV Export | ✅ Phase 2 | MAP § 6.6 |
| Gap Analysis | ✅ Complete | MAP § 6.7 |
| Offline-First Sync | ✅ Complete | MAP § 6.8 |
| Image Optimization | ✅ Phase 2 | MAP § 6.2 |
| Push Notifications | ❌ Phase 3 | MAP § 6.8 |
| Full-text Search | ❌ Phase 3 | MAP § 6.8 |

---

## Documentation Quality

- **Completeness:** 95% (covers main features, documented known limitations)
- **Accuracy:** High (extracted from actual codebase)
- **Maintainability:** Medium (requires update when major changes occur)
- **Update Frequency:** As needed (last updated: Nov 1, 2025)

---

## How to Use This Documentation

### For New Team Members:
1. Read: ARCHITECTURE_SUMMARY.md (quick orientation)
2. Watch: ARCHITECTURE_VISUAL.txt (understand structure)
3. Deep dive: ARCHITECTURE_MAP.md (specific component)

### For Code Review:
1. Reference: ARCHITECTURE_SUMMARY.md (architecture compliance)
2. Check: ARCHITECTURE_MAP.md § 6 (feature requirements)
3. Verify: API endpoints against ARCHITECTURE_MAP.md § 16

### For Bug Fixing:
1. Locate: Component in ARCHITECTURE_VISUAL.txt
2. Find: Data flow in ARCHITECTURE_MAP.md § 5
3. Check: Dependencies in ARCHITECTURE_MAP.md § 14

### For New Features:
1. Check: Current status in ARCHITECTURE_MAP.md § 6
2. Review: Similar features in components
3. Plan: Using sections § 7-15 of ARCHITECTURE_MAP.md

---

## Important Concepts

### Multi-User System (4 Roles)
- ADMIN: Team management, assignment creation, system config
- DIGITALIZADOR: Document capture, personal assignments
- REVISOR: Quality review, approval/rejection
- VIEWER: Read-only analytics and reporting

See: ARCHITECTURE_VISUAL.txt § "Role-Based Routing"

### Anti-Duplicate System
Unique feature preventing duplicate document uploads before capturing:
1. Select person + document type
2. Check backend if document exists
3. If exists + high quality → Skip capture
4. If exists + low quality → Option to replace
5. If not exists → Proceed to capture

See: ARCHITECTURE_MAP.md § 5.2

### Hybrid OCR Strategy
Cost-effective approach to text extraction:
1. Try local OCR (Google ML Kit) first [fast, free]
2. If confidence < 70%, fallback to cloud OCR (OpenAI)
3. Result: 70% cost reduction vs cloud-only

See: ARCHITECTURE_MAP.md § 4.3, VISUAL § "Upload Flow"

### Offline-First Architecture
Works without internet:
1. Capture documents
2. Queue uploads to SQLite
3. Background sync when online (every 15 minutes)
4. Automatic retry with exponential backoff

See: ARCHITECTURE_VISUAL.txt § "Offline Support Architecture"

---

## Troubleshooting Guide

### Finding where something is implemented:
1. Search for component name in ARCHITECTURE_VISUAL.txt
2. Check ARCHITECTURE_MAP.md § 1-4 for the file location
3. Reference data flow in ARCHITECTURE_MAP.md § 5

### Understanding a user flow:
1. Start from screen in ARCHITECTURE_MAP.md § 1
2. Follow navigation in ARCHITECTURE_MAP.md § 7
3. See data flow in ARCHITECTURE_MAP.md § 5

### API integration questions:
1. Check endpoint in ARCHITECTURE_MAP.md § 16
2. Find repository in ARCHITECTURE_MAP.md § 3
3. Trace to provider in ARCHITECTURE_MAP.md § 2

### Performance issues:
1. Check service in ARCHITECTURE_MAP.md § 4
2. Review optimization in ARCHITECTURE_MAP.md § 16
3. Check state management in ARCHITECTURE_VISUAL.txt

---

## Version Information

- **App Version:** 5.6.1
- **Phase:** Phase 2 (Session Tracking + Review Workflow + CSV Export)
- **Flutter Version:** 3.x
- **Dart Version:** 3.5.3+
- **Documentation Version:** 1.0
- **Last Updated:** November 1, 2025

---

## Next Steps (Phase 3)

Phase 3 planned features (not yet implemented):
- Push notifications for assignment updates
- Advanced full-text search across documents
- Batch OCR processing queue optimization
- Document versioning and change tracking
- Complete audit trail and logging
- ML-based quality automation
- Real-time performance dashboards

See: ARCHITECTURE_SUMMARY.md § "Next Steps"

---

## Feedback & Updates

To update this documentation:
1. Update relevant code files
2. Regenerate documentation sections using Claude Code
3. Update version date in header
4. Commit with message: "docs: update architecture documentation"

---

**For more information, see the corresponding detailed sections in the referenced documentation files.**

Happy coding! 🚀

