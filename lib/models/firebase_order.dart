class FirebaseOrder {
  final String? id;
  final String orderId;
  final String status;
  final String orderstatus;
  final String customerName;
  final String? email;
  final String? phone;
  final String? address;
  final String? trackingId;
  final String? designUrl;
  final List<FirebaseOrderProduct> products;
  final String? createdAt;
  final String? updatedAt;

  FirebaseOrder({
    this.id,
    required this.orderId,
    required this.status,
    required this.orderstatus,
    required this.customerName,
    this.email,
    this.phone,
    this.address,
    this.trackingId,
    this.designUrl,
    required this.products,
    this.createdAt,
    this.updatedAt,
  });

  factory FirebaseOrder.fromJson(Map<String, dynamic> json) {
    return FirebaseOrder(
      id: json['id'],
      orderId: json['orderId'] ?? '',
      status: json['status'] ?? 'pending',
      orderstatus: json['orderstatus'] ?? '',
      customerName: json['customerName'] ?? '',
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      trackingId: json['trackingId'],
      designUrl: json['designUrl'],
      products: (json['products'] as List?)
          ?.map((x) => FirebaseOrderProduct.fromJson(x))
          .toList() ?? [],
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'orderId': orderId,
    'status': status,
    'orderstatus': orderstatus,
    'customerName': customerName,
    if (email != null) 'email': email,
    if (phone != null) 'phone': phone,
    if (address != null) 'address': address,
    if (trackingId != null) 'trackingId': trackingId,
    if (designUrl != null) 'designUrl': designUrl,
    'products': products.map((x) => x.toJson()).toList(),
    if (createdAt != null) 'createdAt': createdAt,
    if (updatedAt != null) 'updatedAt': updatedAt,
  };
}

class FirebaseOrderProduct {
  final String details;
  final String image;
  final String orderName;
  final String sku;
  final num salePrice;
  final String productPageUrl;
  final String productCategory;
  final String colour;
  final String size;
  final int qty;
  final String? downloaddesign;

  FirebaseOrderProduct({
    required this.details,
    required this.image,
    required this.orderName,
    required this.sku,
    required this.salePrice,
    required this.productPageUrl,
    required this.productCategory,
    required this.colour,
    required this.size,
    required this.qty,
    this.downloaddesign,
  });

  factory FirebaseOrderProduct.fromJson(Map<String, dynamic> json) {
    return FirebaseOrderProduct(
      details: json['details'] ?? '',
      image: json['image'] ?? '',
      orderName: json['orderName'] ?? '',
      sku: json['sku'] ?? '',
      salePrice: json['sale_price'] ?? 0,
      productPageUrl: json['product_page_url'] ?? '',
      productCategory: json['product_category'] ?? '',
      colour: json['colour'] ?? '',
      size: json['size'] ?? '',
      qty: json['qty'] ?? 1,
      downloaddesign: json['downloaddesign'],
    );
  }

  Map<String, dynamic> toJson() => {
    'details': details,
    'image': image,
    'orderName': orderName,
    'sku': sku,
    'sale_price': salePrice,
    'product_page_url': productPageUrl,
    'product_category': productCategory,
    'colour': colour,
    'size': size,
    'qty': qty,
    if (downloaddesign != null) 'downloaddesign': downloaddesign,
  };
} 