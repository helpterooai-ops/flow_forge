class SavedMap {
  final String id;
  String name;
  final String jsonData;

  SavedMap({required this.id, required this.name, required this.jsonData});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'jsonData': jsonData,
      };

  factory SavedMap.fromJson(Map<String, dynamic> json) => SavedMap(
        id: json['id'],
        name: json['name'],
        jsonData: json['jsonData'],
      );
}