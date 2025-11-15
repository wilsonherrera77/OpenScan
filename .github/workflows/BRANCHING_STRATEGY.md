# Branching Strategy

## Branches
- `baseline-clean` - Main branch (protegido)
- `feature/*` - Features (desde baseline-clean)
- `hotfix/*` - Hotfixes críticos

## Workflow
1. Crear feature branch: `git checkout -b feature/nombre`
2. Desarrollar + commits frecuentes
3. Testing completo
4. Merge a baseline-clean
5. Tag: `git tag vX.X.X-feature-name`

## Protección
- NO commits directos a baseline-clean
- Testing E2E obligatorio antes de merge
- Commits descriptivos (feat:, fix:, docs:, etc.)
