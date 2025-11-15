import 'package:flutter/material.dart';
import '../../domain/entities/tag.dart';

/// Multi-select tag selector widget
/// Allows digitizer to choose which tags to apply to document
class TagSelector extends StatefulWidget {
  final List<Tag> availableTags;
  final List<int> selectedTagIds;
  final Function(List<int>) onTagsChanged;
  final bool enabled;

  const TagSelector({
    Key? key,
    required this.availableTags,
    required this.selectedTagIds,
    required this.onTagsChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  late Set<int> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set<int>.from(widget.selectedTagIds);
  }

  @override
  void didUpdateWidget(TagSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTagIds != oldWidget.selectedTagIds) {
      setState(() {
        _selectedIds = Set<int>.from(widget.selectedTagIds);
      });
    }
  }

  void _toggleTag(int tagId) {
    if (!widget.enabled) return;

    setState(() {
      if (_selectedIds.contains(tagId)) {
        _selectedIds.remove(tagId);
      } else {
        _selectedIds.add(tagId);
      }
    });

    widget.onTagsChanged(_selectedIds.toList());
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.blue.shade200;
    }
  }

  Color _parseTextColor(String hex) {
    try {
      return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.availableTags.isEmpty) {
      return Card(
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: const [
              Icon(Icons.warning_amber, color: Colors.orange),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No hay etiquetas disponibles. Verifica la conexión con Paperless.',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected tags summary
        if (_selectedIds.isNotEmpty) ...[
          Text(
            '${_selectedIds.length} etiqueta(s) seleccionada(s):',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedIds.map((tagId) {
              final tag = widget.availableTags.firstWhere(
                (t) => t.id == tagId,
                orElse: () => Tag(
                  id: tagId,
                  name: 'Tag $tagId',
                  color: '#a6cee3',
                  textColor: '#000000',
                ),
              );
              return Chip(
                label: Text(
                  tag.name,
                  style: TextStyle(
                    color: _parseTextColor(tag.textColor),
                    fontSize: 12,
                  ),
                ),
                backgroundColor: _parseColor(tag.color),
                deleteIcon: Icon(
                  Icons.close,
                  size: 16,
                  color: _parseTextColor(tag.textColor),
                ),
                onDeleted: widget.enabled ? () => _toggleTag(tagId) : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Available tags list
        Container(
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: widget.availableTags.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final tag = widget.availableTags[index];
              final isSelected = _selectedIds.contains(tag.id);

              return ListTile(
                enabled: widget.enabled,
                leading: Checkbox(
                  value: isSelected,
                  onChanged: widget.enabled
                      ? (_) => _toggleTag(tag.id)
                      : null,
                ),
                title: Text(
                  tag.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _parseColor(tag.color),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                ),
                onTap: widget.enabled ? () => _toggleTag(tag.id) : null,
              );
            },
          ),
        ),
      ],
    );
  }
}
