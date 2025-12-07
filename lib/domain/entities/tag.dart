/// Tag entity from Tejido-ngx
class Tag {
  final int id;
  final String name;
  final String color;
  final String textColor;

  Tag({
    required this.id,
    required this.name,
    required this.color,
    required this.textColor,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as int,
      name: json['name'] as String,
      color: json['color'] as String? ?? '#a6cee3',
      textColor: json['text_color'] as String? ?? '#000000',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'text_color': textColor,
    };
  }

  @override
  String toString() => 'Tag(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tag &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
