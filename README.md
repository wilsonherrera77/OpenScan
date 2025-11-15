# Lumara - Sistema Documental Inteligente para Resguardos Indígenas

**Versión**: v6.3.9+85  
**Estado**: Baseline estable, en implementación de mejoras críticas

## Quick Start
```bash
# Backend
cd paperless-ngx && docker-compose up -d

# App
flutter pub get
flutter build apk --release
```

## Testing
```bash
./scripts/test_apk_before_release.sh build/app/outputs/flutter-apk/app-release.apk
```

## Documentación
Ver [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)

## Desarrollo
Ver [CLAUDE.md](CLAUDE.md) - Instrucciones completas + Anti-retroceso
