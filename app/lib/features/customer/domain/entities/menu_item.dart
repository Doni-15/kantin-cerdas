class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.stallId,
    required this.stallName,
    required this.block,
    required this.price,
    required this.waitTime,
    required this.description,
    required this.category,
    this.available = true,
  });

  final String id;
  final String name;

  final String stallId;
  final String stallName;
  final String block;

  final int price;

  final String waitTime;
  final String description;
  final String category;

  final bool available;
}