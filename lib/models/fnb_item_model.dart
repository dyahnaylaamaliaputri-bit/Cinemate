// lib/models/fnb_item_model.dart
// Model untuk item menu Makanan & Minuman (F&B) bioskop (PB-026)

class FnbItemModel {
  final String id;
  final String name;
  final String description;
  final int price;
  final String category; // 'snack', 'drink', 'combo', 'food'
  final String? imageUrl;
  final bool isAvailable;

  const FnbItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    this.isAvailable = true,
  });

  factory FnbItemModel.fromJson(Map<String, dynamic> json) {
    return FnbItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Item F&B',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      category: json['category']?.toString().toLowerCase() ?? 'snack',
      imageUrl: json['image_url']?.toString(),
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      if (imageUrl != null) 'image_url': imageUrl,
      'is_available': isAvailable,
    };
  }

  FnbItemModel copyWith({
    String? id,
    String? name,
    String? description,
    int? price,
    String? category,
    String? imageUrl,
    bool? isAvailable,
  }) {
    return FnbItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  /// Format harga dalam Rupiah (contoh: "Rp 35.000")
  String get formattedPrice {
    final str = price.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count == 3 && i > 0) {
        buffer.write('.');
        count = 0;
      }
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  /// Label kategori yang rapi untuk ditampilkan di UI
  String get categoryLabel {
    switch (category.toLowerCase()) {
      case 'drink':
        return 'Minuman';
      case 'combo':
        return 'Paket Combo';
      case 'food':
        return 'Makanan Berat';
      case 'snack':
      default:
        return 'Snack & Camilan';
    }
  }

  /// Data seed default jika offline dan Hive cache belum tersedia
  static List<FnbItemModel> get seedItems => const [
        FnbItemModel(
          id: 'fnb-popcorn-reg',
          name: 'Popcorn Regular',
          description:
              'Popcorn butter klasik ukuran regular dengan rasa gurih mentega renyah.',
          price: 35000,
          category: 'snack',
        ),
        FnbItemModel(
          id: 'fnb-popcorn-lrg',
          name: 'Popcorn Large',
          description:
              'Popcorn butter ukuran besar, cocok dinikmati berdua saat menonton.',
          price: 50000,
          category: 'snack',
        ),
        FnbItemModel(
          id: 'fnb-popcorn-caramel',
          name: 'Caramel Popcorn Deluxe',
          description:
              'Popcorn renyah berbalut karamel manis gurih khas bioskop.',
          price: 55000,
          category: 'snack',
        ),
        FnbItemModel(
          id: 'fnb-nachos',
          name: 'Nachos Cheese Supreme',
          description:
              'Keripik jagung nachos renyah disajikan dengan saus keju hangat gurih.',
          price: 45000,
          category: 'snack',
        ),
        FnbItemModel(
          id: 'fnb-coke-reg',
          name: 'Coca-Cola Regular',
          description: 'Minuman soda dingin segar 400ml pelepas dahaga.',
          price: 25000,
          category: 'drink',
        ),
        FnbItemModel(
          id: 'fnb-coke-lrg',
          name: 'Coca-Cola Large',
          description: 'Minuman soda dingin segar ukuran jumbo 600ml.',
          price: 35000,
          category: 'drink',
        ),
        FnbItemModel(
          id: 'fnb-lemon-tea',
          name: 'Iced Lemon Tea Jumbo',
          description:
              'Teh lemon segar dingin dengan perasan lemon asli ukuran jumbo 600ml.',
          price: 28000,
          category: 'drink',
        ),
        FnbItemModel(
          id: 'fnb-mineral',
          name: 'Air Mineral 600ml',
          description: 'Air mineral murni dingin dan menyegarkan.',
          price: 15000,
          category: 'drink',
        ),
        FnbItemModel(
          id: 'fnb-combo-1',
          name: 'Combo Solo 1',
          description: 'Paket hemat 1 Popcorn Regular + 1 Coca-Cola Regular.',
          price: 55000,
          category: 'combo',
        ),
        FnbItemModel(
          id: 'fnb-combo-2',
          name: 'Combo Duo Seru 2',
          description:
              'Paket seru berdua: 1 Popcorn Large + 2 Coca-Cola Regular.',
          price: 95000,
          category: 'combo',
        ),
        FnbItemModel(
          id: 'fnb-hotdog',
          name: 'Classic Beef Hot Dog',
          description:
              'Roti lembut dengan sosis sapi panggang premium, mustard, dan saus tomat.',
          price: 40000,
          category: 'food',
        ),
        FnbItemModel(
          id: 'fnb-pretzel',
          name: 'Warm Salted Pretzel',
          description:
              'Kue pretzel hangat gurih disajikan dengan saus keju cheddar leleh.',
          price: 38000,
          category: 'food',
        ),
      ];
}
