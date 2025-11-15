class Slide {
  final String imageUrl;
  final String? title;
  final String? description;

  Slide({
    required this.imageUrl,
    this.title,
    this.description,
  });
}

final slideList = [
  Slide(
    imageUrl: 'assets/home.jpg',
    title: '1. Inicio de Sesión',
    description: 'Ingresa tus credenciales de Paperless:\n'
        '• Usuario: admin (o tu usuario)\n'
        '• Contraseña: tu contraseña\n'
        '• URL del Servidor: http://192.168.40.17:8001\n\n'
        '⚠️ IMPORTANTE: Asegúrate de estar conectado a la misma WiFi que el servidor Paperless.',
  ),
  Slide(
    imageUrl: 'assets/view_doc_01.jpg',
    title: '2. Capturar Documentos',
    description: 'Toca el botón + (cyan) en la esquina inferior derecha:\n'
        '• Normal Scan: Captura con cámara y recorta automáticamente\n'
        '• From Gallery: Selecciona fotos existentes\n'
        '• QR Code: Escanea códigos QR\n\n'
        '📸 La app recortará automáticamente cada foto para reducir el tamaño del archivo.',
  ),
  Slide(
    imageUrl: 'assets/view_doc_02.jpg',
    title: '3. Editar y Recortar',
    description: 'Después de capturar:\n'
        '• Aparecerá pantalla de recorte (azul/cyan)\n'
        '• Ajusta los bordes arrastrando las esquinas\n'
        '• Rota la imagen si es necesario\n'
        '• Haz zoom para mayor precisión\n'
        '• Toca ✓ para guardar o X para cancelar\n\n'
        'Si cancelas, se guardará la imagen original.',
  ),
  Slide(
    imageUrl: 'assets/view_doc_03.jpg',
    title: '4. Organizar Documentos',
    description: 'En la pantalla principal:\n'
        '• Tus documentos aparecen en tarjetas\n'
        '• Toca una tarjeta para ver/editar\n'
        '• Mantén presionado para opciones:\n'
        '  - Renombrar\n'
        '  - Compartir\n'
        '  - Eliminar\n'
        '• Arrastra hacia abajo para refrescar',
  ),
  Slide(
    imageUrl: 'assets/view_doc_05.jpg',
    title: '5. Sincronización',
    description: 'Sincroniza con Paperless:\n'
        '• Toca el icono de sincronización (nube) en la barra superior\n'
        '• O activa sincronización automática cada 15 min\n'
        '• Diagnóstico de red: Toca icono network_check\n\n'
        '✅ Verifica que el diagnóstico muestre:\n'
        '  - Internet: Conectado\n'
        '  - Servidor alcanzable: Sí\n'
        '  - Latencia: [X] ms',
  ),
  Slide(
    imageUrl: 'assets/view_doc_04.jpg',
    title: '6. Verificar en Paperless',
    description: 'En tu navegador:\n'
        '• Abre http://192.168.40.17:8001\n'
        '• Inicia sesión en Paperless\n'
        '• Ve a "Documentos"\n'
        '• Verás tus documentos sincronizados\n\n'
        '📊 La app mostrará estadísticas:\n'
        '  - Total de documentos\n'
        '  - PDF (50%), TXT (25%), JPEG (25%)\n'
        '  - Etiquetas y tipos',
  ),
];
