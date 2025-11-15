import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Accessibility Helper
/// Provides utilities for improving app accessibility
class AccessibilityHelper {
  /// Create semantic label for button
  static String buttonLabel(String text, {String? hint}) {
    if (hint != null) {
      return '$text. $hint';
    }
    return '$text. Botón';
  }

  /// Create semantic label for text field
  static String textFieldLabel(String label, {bool required = false}) {
    if (required) {
      return '$label. Campo requerido';
    }
    return '$label. Campo de texto';
  }

  /// Create semantic label for image
  static String imageLabel(String description) {
    return 'Imagen. $description';
  }

  /// Create semantic label for progress indicator
  static String progressLabel(int progress, {String? action}) {
    if (action != null) {
      return '$action. Progreso: $progress porciento';
    }
    return 'Progreso: $progress porciento';
  }

  /// Create semantic label for list item
  static String listItemLabel(String title, {int? position, int? total}) {
    if (position != null && total != null) {
      return '$title. Elemento $position de $total';
    }
    return title;
  }

  /// Announce message to screen reader
  static void announce(BuildContext context, String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Check if screen reader is enabled
  static bool isScreenReaderEnabled(BuildContext context) {
    return MediaQuery.of(context).accessibleNavigation;
  }
}

/// Accessible Button Widget
/// Button with built-in accessibility support
class AccessibleButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final bool isLoading;
  final String? semanticHint;

  const AccessibleButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
    this.isLoading = false,
    this.semanticHint,
  });

  @override
  Widget build(BuildContext context) {
    final semanticLabel = AccessibilityHelper.buttonLabel(
      label,
      hint: semanticHint,
    );

    Widget button;

    if (icon != null) {
      button = ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(label),
        style: color != null
            ? ElevatedButton.styleFrom(backgroundColor: color)
            : null,
      );
    } else {
      button = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: color != null
            ? ElevatedButton.styleFrom(backgroundColor: color)
            : null,
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      );
    }

    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: !isLoading && onPressed != null,
      child: ExcludeSemantics(
        child: button,
      ),
    );
  }
}

/// Accessible Text Field Widget
/// TextField with built-in accessibility support
class AccessibleTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final bool required;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final IconData? prefixIcon;

  const AccessibleTextField({
    super.key,
    required this.label,
    this.controller,
    this.required = false,
    this.obscureText = false,
    this.keyboardType,
    this.hint,
    this.errorText,
    this.onChanged,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final semanticLabel = AccessibilityHelper.textFieldLabel(
      label,
      required: required,
    );

    return Semantics(
      label: semanticLabel,
      textField: true,
      child: ExcludeSemantics(
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label + (required ? ' *' : ''),
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            border: const OutlineInputBorder(),
          ),
        ),
      ),
    );
  }
}

/// Accessible Image Widget
/// Image with built-in accessibility support
class AccessibleImage extends StatelessWidget {
  final ImageProvider image;
  final String semanticLabel;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const AccessibleImage({
    super.key,
    required this.image,
    required this.semanticLabel,
    this.width,
    this.height,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AccessibilityHelper.imageLabel(semanticLabel),
      image: true,
      child: ExcludeSemantics(
        child: Image(
          image: image,
          width: width,
          height: height,
          fit: fit,
          semanticLabel: semanticLabel,
        ),
      ),
    );
  }
}

/// Accessible Progress Indicator Widget
/// Progress indicator with built-in accessibility support
class AccessibleProgressIndicator extends StatelessWidget {
  final double? value; // 0.0 to 1.0, null for indeterminate
  final String? label;

  const AccessibleProgressIndicator({
    super.key,
    this.value,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final progress = value != null ? (value! * 100).toInt() : 0;
    final semanticLabel = AccessibilityHelper.progressLabel(
      progress,
      action: label,
    );

    return Semantics(
      label: semanticLabel,
      value: value != null ? '$progress%' : 'En progreso',
      child: ExcludeSemantics(
        child: LinearProgressIndicator(value: value),
      ),
    );
  }
}

/// Accessible List Tile Widget
/// ListTile with built-in accessibility support
class AccessibleListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final VoidCallback? onTap;
  final int? position;
  final int? total;

  const AccessibleListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.onTap,
    this.position,
    this.total,
  });

  @override
  Widget build(BuildContext context) {
    final semanticLabel = AccessibilityHelper.listItemLabel(
      title,
      position: position,
      total: total,
    );

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: ExcludeSemantics(
        child: ListTile(
          leading: leadingIcon != null ? Icon(leadingIcon) : null,
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle) : null,
          onTap: onTap,
        ),
      ),
    );
  }
}

/// Accessible Icon Button Widget
/// IconButton with built-in accessibility support
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AccessibilityHelper.buttonLabel(label),
      button: true,
      enabled: onPressed != null,
      child: ExcludeSemantics(
        child: IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          color: color,
          tooltip: label,
        ),
      ),
    );
  }
}

/// Accessible Card Widget
/// Card with semantic grouping
class AccessibleCard extends StatelessWidget {
  final String semanticLabel;
  final Widget child;
  final VoidCallback? onTap;

  const AccessibleCard({
    super.key,
    required this.semanticLabel,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      container: true,
      button: onTap != null,
      child: Card(
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                child: child,
              )
            : child,
      ),
    );
  }
}
