import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import '../providers/cart_provider.dart'; 

// --- MODEL DATA ---
class User {
  final int? id;
  final String email;
  String password;
  String? name;

  User({this.id, required this.email, required this.password, this.name});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'email': email, 'password': password};
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
    );
  }
}

class Restaurant {
  final int? id;
  final int userId;
  final String name;
  final String? description;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? openingTime;
  final String? closingTime;
  List<MenuItem> menuItems = [];
  List<RestaurantImage> images = [];

  Restaurant({
    this.id,
    required this.userId,
    required this.name,
    this.description,
    this.address,
    this.latitude,
    this.longitude,
    this.openingTime,
    this.closingTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'openingTime': openingTime,
      'closingTime': closingTime,
    };
  }

  factory Restaurant.fromMap(Map<String, dynamic> map) {
    return Restaurant(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
      description: map['description'],
      address: map['address'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      openingTime: map['openingTime'],
      closingTime: map['closingTime'],
    );
  }
}

class MenuItem {
  final int? id;
  final int restaurantId;
  final String itemName;
  final int price;
  final String? description;

  MenuItem(
      {this.id,
      required this.restaurantId,
      required this.itemName,
      required this.price,
      this.description});
  Map<String, dynamic> toMap() => {
        'id': id,
        'restaurantId': restaurantId,
        'itemName': itemName,
        'price': price,
        'description': description
      };
  factory MenuItem.fromMap(Map<String, dynamic> map) => MenuItem(
      id: map['id'],
      restaurantId: map['restaurantId'],
      itemName: map['itemName'],
      price: map['price'],
      description: map['description']);
}

class RestaurantImage {
  final int? id;
  final int restaurantId;
  final String imagePath;

  RestaurantImage(
      {this.id, required this.restaurantId, required this.imagePath});
  Map<String, dynamic> toMap() =>
      {'id': id, 'restaurantId': restaurantId, 'imagePath': imagePath};
  factory RestaurantImage.fromMap(Map<String, dynamic> map) => RestaurantImage(
      id: map['id'],
      restaurantId: map['restaurantId'],
      imagePath: map['imagePath']);
}

class Order {
  final int? id;
  final int restaurantId;
  final String tableNumber;
  final String? notes;
  final String paymentMethod;
  final double totalPrice;
  final DateTime orderTimestamp;
  String status;

  Order({
    this.id,
    required this.restaurantId,
    required this.tableNumber,
    this.notes,
    required this.paymentMethod,
    required this.totalPrice,
    required this.orderTimestamp,
    this.status = 'Pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'tableNumber': tableNumber,
      'notes': notes,
      'paymentMethod': paymentMethod,
      'totalPrice': totalPrice,
      'orderTimestamp': orderTimestamp.toIso8601String(),
      'status': status,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      restaurantId: map['restaurantId'],
      tableNumber: map['tableNumber'],
      notes: map['notes'],
      paymentMethod: map['paymentMethod'],
      totalPrice: map['totalPrice'],
      orderTimestamp: DateTime.parse(map['orderTimestamp']),
      status: map['status'],
    );
  }
}

class OrderItem {
  final int? id;
  final int orderId;
  final int menuItemId;
  final String itemName;
  final int itemPrice;
  final int quantity;

  OrderItem({
    this.id,
    required this.orderId,
    required this.menuItemId,
    required this.itemName,
    required this.itemPrice,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'menuItemId': menuItemId,
      'itemName': itemName,
      'itemPrice': itemPrice,
      'quantity': quantity,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'],
      orderId: map['orderId'],
      menuItemId: map['menuItemId'],
      itemName: map['itemName'],
      itemPrice: map['itemPrice'],
      quantity: map['quantity'],
    );
  }
}


// --- KELAS UTAMA DATABASE HELPER ---
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'quliner.db');
    return await openDatabase(
      path,
      version: 1, // Jika Anda melakukan perubahan lagi nanti, naikkan versi ini
      onCreate: _onCreate,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(
        '''CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, email TEXT UNIQUE NOT NULL, password TEXT NOT NULL)''');
    await db.execute(
        '''CREATE TABLE restaurants(id INTEGER PRIMARY KEY AUTOINCREMENT, userId INTEGER NOT NULL, name TEXT NOT NULL, description TEXT, address TEXT, latitude REAL, longitude REAL, openingTime TEXT, closingTime TEXT, FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE)''');
    await db.execute(
        '''CREATE TABLE menu_items(id INTEGER PRIMARY KEY AUTOINCREMENT, restaurantId INTEGER NOT NULL, itemName TEXT NOT NULL, description TEXT, price INTEGER NOT NULL, FOREIGN KEY (restaurantId) REFERENCES restaurants (id) ON DELETE CASCADE)''');
    await db.execute(
        '''CREATE TABLE restaurant_images(id INTEGER PRIMARY KEY AUTOINCREMENT, restaurantId INTEGER NOT NULL, imagePath TEXT NOT NULL, FOREIGN KEY (restaurantId) REFERENCES restaurants (id) ON DELETE CASCADE)''');
    
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        restaurantId INTEGER NOT NULL,
        tableNumber TEXT NOT NULL,
        notes TEXT,
        paymentMethod TEXT NOT NULL,
        totalPrice REAL NOT NULL,
        orderTimestamp TEXT NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY (restaurantId) REFERENCES restaurants (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId INTEGER NOT NULL,
        menuItemId INTEGER NOT NULL,
        itemName TEXT NOT NULL,
        itemPrice INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (orderId) REFERENCES orders (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> registerUser(User user) async {
    final db = await database;
    final existingUser =
        await db.query('users', where: 'email = ?', whereArgs: [user.email]);
    if (existingUser.isNotEmpty) {
      return -1;
    }
    return await db.insert('users', user.toMap());
  }

  Future<User?> loginUser(String email, String password) async {
    final db = await database;
    var res = await db.query('users',
        where: 'email = ? AND password = ?', whereArgs: [email, password]);
    if (res.isNotEmpty) {
      return User.fromMap(res.first);
    }
    return null;
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    var res = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) {
      return User.fromMap(res.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<List<Restaurant>> getRestaurantsForUser(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('restaurants', where: 'userId = ?', whereArgs: [userId]);
    return _mapRestaurantsWithThumbnails(maps);
  }

  Future<List<Restaurant>> getAllRestaurants() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('restaurants');
    return _mapRestaurantsWithThumbnails(maps);
  }

  Future<List<Restaurant>> _mapRestaurantsWithThumbnails(
      List<Map<String, dynamic>> maps) async {
    List<Restaurant> restaurants = [];
    for (var map in maps) {
      final restaurant = Restaurant.fromMap(map);
      final images = await getImages(restaurant.id!);
      if (images.isNotEmpty) {
        restaurant.images.add(images.first);
      }
      restaurants.add(restaurant);
    }
    return restaurants;
  }

  Future<int> deleteRestaurant(int id) async => await (await database)
      .delete('restaurants', where: 'id = ?', whereArgs: [id]);
  Future<List<RestaurantImage>> getImages(int restaurantId) async =>
      (await (await database).query('restaurant_images',
              where: 'restaurantId = ?', whereArgs: [restaurantId]))
          .map((map) => RestaurantImage.fromMap(map))
          .toList();

  Future<Restaurant> getFullRestaurantDetails(int restaurantId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db
        .query('restaurants', where: 'id = ?', whereArgs: [restaurantId]);
    if (maps.isNotEmpty) {
      final restaurant = Restaurant.fromMap(maps.first);
      restaurant.menuItems = (await db.query('menu_items',
              where: 'restaurantId = ?', whereArgs: [restaurantId]))
          .map((map) => MenuItem.fromMap(map))
          .toList();
      restaurant.images = await getImages(restaurantId);
      return restaurant;
    }
    throw Exception('Restaurant with ID $restaurantId not found');
  }

  Future<void> saveRestaurantTransaction(
      {required Restaurant restaurant,
      required List<MenuItem> menuItems,
      required List<RestaurantImage> newImages,
      required bool isEditMode}) async {
    final db = await database;
    await db.transaction((txn) async {
      int restaurantId;
      if (isEditMode) {
        await txn.update('restaurants', restaurant.toMap(),
            where: 'id = ?', whereArgs: [restaurant.id]);
        restaurantId = restaurant.id!;
        await txn.delete('menu_items',
            where: 'restaurantId = ?', whereArgs: [restaurantId]);
      } else {
        restaurantId = await txn.insert('restaurants', restaurant.toMap());
      }

      if (menuItems.isNotEmpty) {
        final menuBatch = txn.batch();
        for (var item in menuItems) {
          menuBatch.insert(
              'menu_items',
              MenuItem(
                      restaurantId: restaurantId,
                      itemName: item.itemName,
                      price: item.price,
                      description: item.description)
                  .toMap());
        }
        await menuBatch.commit(noResult: true);
      }

      if (newImages.isNotEmpty) {
        if (isEditMode) {
          await txn.delete('restaurant_images',
              where: 'restaurantId = ?', whereArgs: [restaurantId]);
        }
        final imageBatch = txn.batch();
        for (var image in newImages) {
          imageBatch.insert(
              'restaurant_images',
              RestaurantImage(
                      restaurantId: restaurantId, imagePath: image.imagePath)
                  .toMap());
        }
        await imageBatch.commit(noResult: true);
      }
    });
  }

  Future<void> insertOrder(Order order, List<CartItem> cartItems) async {
    final db = await database;
    await db.transaction((txn) async {
      final orderId = await txn.insert('orders', order.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);

      for (var cartItem in cartItems) {
        final orderItem = OrderItem(
          orderId: orderId,
          menuItemId: cartItem.menuItem.id!,
          itemName: cartItem.menuItem.itemName,
          itemPrice: cartItem.menuItem.price,
          quantity: cartItem.quantity,
        );
        await txn.insert('order_items', orderItem.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Order>> getOrdersForRestaurant(int restaurantId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'restaurantId = ?',
      whereArgs: [restaurantId],
      orderBy: 'orderTimestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return Order.fromMap(maps[i]);
    });
  }

  Future<List<OrderItem>> getOrderItems(int orderId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'order_items',
      where: 'orderId = ?',
      whereArgs: [orderId],
    );

    return List.generate(maps.length, (i) {
      return OrderItem.fromMap(maps[i]);
    });
  }

Future<void> updateOrderStatus(int orderId, String newStatus) async {
  final db = await database;
  await db.update(
    'orders',
    {'status': newStatus},
    where: 'id = ?',
    whereArgs: [orderId],
  );
}
}