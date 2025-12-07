#!/usr/bin/env python3
"""
Script para convertir Censo_Chia_Consolidado_2025_Principal.csv
al formato esperado por Lumara (persons.csv)
"""

import csv
import sys
from pathlib import Path

def get_required_documents(tipo_ident):
    """
    Determina qué documentos se requieren según el tipo de identificación

    tipo_ident:
    - 1: Registro Civil de Nacimiento
    - 2: Tarjeta de Identidad
    - 3: Cédula de Ciudadanía
    """
    # Todos requieren Registro Civil y EPS
    base_docs = ["REGISTRO_CIVIL", "CERTIFICADO_AFILIACION_EPS"]

    if tipo_ident == "1":  # Registro Civil
        return base_docs
    elif tipo_ident == "2":  # Tarjeta de Identidad
        return ["TARJETA_IDENTIDAD"] + base_docs
    elif tipo_ident == "3":  # Cédula de Ciudadanía
        return ["CEDULA_CIUDADANIA"] + base_docs
    else:
        return base_docs

def clean_name(name):
    """Limpia y capitaliza nombres"""
    if not name or name.strip() == "":
        return ""
    return name.strip().upper()

def convert_census(input_path, output_path):
    """Convierte el censo al formato de Lumara"""

    print(f"📖 Leyendo archivo: {input_path}")

    with open(input_path, 'r', encoding='utf-8') as f_in:
        reader = csv.DictReader(f_in)

        # Leer todos los datos
        rows = list(reader)
        total_rows = len(rows)
        print(f"📊 Total de registros a procesar: {total_rows}")

        # Preparar salida
        output_rows = []
        person_id = 3998  # Empezar desde 3998 como en el original

        for i, row in enumerate(rows, 1):
            try:
                # Extraer campos
                num_doc = row['num_doc'].strip()
                primer_nombre = clean_name(row.get('primer_nombre', ''))
                segun_nombre = clean_name(row.get('segun_nombre', ''))
                primer_apellido = clean_name(row.get('primer_apellido', ''))
                segun_apellido = clean_name(row.get('segun_apellido', ''))
                num_familia = row['num_familia'].strip()
                tipo_ident = row['tipo_ident'].strip()
                fech_naci = row['fech_naci'].strip()

                # Construir nombre completo
                first_name_parts = [primer_nombre, segun_nombre]
                first_name = " ".join([p for p in first_name_parts if p])

                last_name_parts = [primer_apellido, segun_apellido]
                last_name = " ".join([p for p in last_name_parts if p])

                full_name = f"{first_name} {last_name}".strip()

                # Determinar documentos requeridos
                required_docs = get_required_documents(tipo_ident)
                required_docs_str = ",".join(required_docs)
                required_docs_count = len(required_docs)

                # Crear fila de salida
                output_row = {
                    'person_id': str(person_id),
                    'full_name': full_name,
                    'first_name': first_name,
                    'last_name': last_name,
                    'birthdate': fech_naci,
                    'document_number': num_doc,
                    'family_id': num_familia,
                    'required_documents_count': required_docs_count,
                    'required_documents': required_docs_str
                }

                output_rows.append(output_row)
                person_id += 1

                # Progreso cada 500 registros
                if i % 500 == 0 or i == total_rows:
                    print(f"⏳ Procesados: {i}/{total_rows} ({i*100//total_rows}%)")

            except Exception as e:
                print(f"❌ Error en fila {i}: {e}")
                print(f"   Datos: {row}")
                continue

        # Escribir archivo de salida
        print(f"\n📝 Escribiendo archivo: {output_path}")

        with open(output_path, 'w', encoding='utf-8', newline='') as f_out:
            fieldnames = [
                'person_id', 'full_name', 'first_name', 'last_name',
                'birthdate', 'document_number', 'family_id',
                'required_documents_count', 'required_documents'
            ]

            writer = csv.DictWriter(f_out, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(output_rows)

        print(f"\n✅ Conversión completada!")
        print(f"   Total de personas: {len(output_rows)}")
        print(f"   Archivo generado: {output_path}")

        # Estadísticas
        stats = {
            'registro_civil': 0,
            'tarjeta_identidad': 0,
            'cedula_ciudadania': 0
        }

        for row in output_rows:
            docs = row['required_documents']
            if 'CEDULA_CIUDADANIA' in docs:
                stats['cedula_ciudadania'] += 1
            elif 'TARJETA_IDENTIDAD' in docs:
                stats['tarjeta_identidad'] += 1
            else:
                stats['registro_civil'] += 1

        print(f"\n📊 Estadísticas:")
        print(f"   📄 Cédulas de Ciudadanía: {stats['cedula_ciudadania']}")
        print(f"   🎫 Tarjetas de Identidad: {stats['tarjeta_identidad']}")
        print(f"   👶 Registros Civiles: {stats['registro_civil']}")

if __name__ == "__main__":
    # Rutas por defecto
    script_dir = Path(__file__).parent
    project_root = script_dir.parent

    input_file = Path("/home/smt/Escritorio/programacion_proyectos/tejido/Censo_Chia_Consolidado_2025_Principal.csv")
    output_file = project_root / "assets" / "census" / "persons.csv"

    if not input_file.exists():
        print(f"❌ Error: No se encontró el archivo de entrada: {input_file}")
        sys.exit(1)

    # Crear directorio de salida si no existe
    output_file.parent.mkdir(parents=True, exist_ok=True)

    print("═══════════════════════════════════════════════════════")
    print("🔄 CONVERSIÓN DE CENSO PARA LUMARA")
    print("═══════════════════════════════════════════════════════")
    print(f"📥 Entrada: {input_file.name}")
    print(f"📤 Salida: {output_file}")
    print("═══════════════════════════════════════════════════════\n")

    convert_census(input_file, output_file)

    print("\n═══════════════════════════════════════════════════════")
    print("✅ PROCESO COMPLETADO")
    print("═══════════════════════════════════════════════════════")
    print("\n💡 Próximos pasos:")
    print("   1. Recompilar el APK con los datos actualizados")
    print("   2. Instalar en el dispositivo")
    print("   3. Ejecutar Workflow 2 de testing")
