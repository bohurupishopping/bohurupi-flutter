class WooOrder {
  final int id;
  final int parentId;
  final String number;
  final String orderKey;
  final String createdVia;
  final String version;
  final String status;
  final String currency;
  final String dateCreated;
  final String dateCreatedGmt;
  final String dateModified;
  final String dateModifiedGmt;
  final String discountTotal;
  final String discountTax;
  final String shippingTotal;
  final String shippingTax;
  final String cartTax;
  final String total;
  final String totalTax;
  final bool pricesIncludeTax;
  final int customerId;
  final String customerIpAddress;
  final String customerUserAgent;
  final String customerNote;
  final WooOrderAddress billing;
  final WooOrderAddress shipping;
  final String paymentMethod;
  final String paymentMethodTitle;
  final String? transactionId;
  final List<WooOrderMetaData> metaData;
  final List<WooOrderLineItem> lineItems;
  final List<WooOrderNote>? notes;

  WooOrder({
    required this.id,
    required this.parentId,
    required this.number,
    required this.orderKey,
    required this.createdVia,
    required this.version,
    required this.status,
    required this.currency,
    required this.dateCreated,
    required this.dateCreatedGmt,
    required this.dateModified,
    required this.dateModifiedGmt,
    required this.discountTotal,
    required this.discountTax,
    required this.shippingTotal,
    required this.shippingTax,
    required this.cartTax,
    required this.total,
    required this.totalTax,
    required this.pricesIncludeTax,
    required this.customerId,
    required this.customerIpAddress,
    required this.customerUserAgent,
    required this.customerNote,
    required this.billing,
    required this.shipping,
    required this.paymentMethod,
    required this.paymentMethodTitle,
    this.transactionId,
    required this.metaData,
    required this.lineItems,
    this.notes,
  });

  factory WooOrder.fromJson(Map<String, dynamic> json) {
    return WooOrder(
      id: json['id'] ?? 0,
      parentId: json['parent_id'] ?? 0,
      number: json['number'] ?? '',
      orderKey: json['order_key'] ?? '',
      createdVia: json['created_via'] ?? '',
      version: json['version'] ?? '',
      status: json['status'] ?? '',
      currency: json['currency'] ?? '',
      dateCreated: json['date_created'] ?? '',
      dateCreatedGmt: json['date_created_gmt'] ?? '',
      dateModified: json['date_modified'] ?? '',
      dateModifiedGmt: json['date_modified_gmt'] ?? '',
      discountTotal: json['discount_total'] ?? '0',
      discountTax: json['discount_tax'] ?? '0',
      shippingTotal: json['shipping_total'] ?? '0',
      shippingTax: json['shipping_tax'] ?? '0',
      cartTax: json['cart_tax'] ?? '0',
      total: json['total'] ?? '0',
      totalTax: json['total_tax'] ?? '0',
      pricesIncludeTax: json['prices_include_tax'] ?? false,
      customerId: json['customer_id'] ?? 0,
      customerIpAddress: json['customer_ip_address'] ?? '',
      customerUserAgent: json['customer_user_agent'] ?? '',
      customerNote: json['customer_note'] ?? '',
      billing: WooOrderAddress.fromJson(json['billing'] ?? {}),
      shipping: WooOrderAddress.fromJson(json['shipping'] ?? {}),
      paymentMethod: json['payment_method'] ?? '',
      paymentMethodTitle: json['payment_method_title'] ?? '',
      transactionId: json['transaction_id'],
      metaData: (json['meta_data'] as List?)
          ?.map((x) => WooOrderMetaData.fromJson(x))
          .toList() ?? [],
      lineItems: (json['line_items'] as List?)
          ?.map((x) => WooOrderLineItem.fromJson(x))
          .toList() ?? [],
      notes: (json['notes'] as List?)
          ?.map((x) => WooOrderNote.fromJson(x))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'parent_id': parentId,
    'number': number,
    'order_key': orderKey,
    'created_via': createdVia,
    'version': version,
    'status': status,
    'currency': currency,
    'date_created': dateCreated,
    'date_created_gmt': dateCreatedGmt,
    'date_modified': dateModified,
    'date_modified_gmt': dateModifiedGmt,
    'discount_total': discountTotal,
    'discount_tax': discountTax,
    'shipping_total': shippingTotal,
    'shipping_tax': shippingTax,
    'cart_tax': cartTax,
    'total': total,
    'total_tax': totalTax,
    'prices_include_tax': pricesIncludeTax,
    'customer_id': customerId,
    'customer_ip_address': customerIpAddress,
    'customer_user_agent': customerUserAgent,
    'customer_note': customerNote,
    'billing': billing.toJson(),
    'shipping': shipping.toJson(),
    'payment_method': paymentMethod,
    'payment_method_title': paymentMethodTitle,
    'transaction_id': transactionId,
    'meta_data': metaData.map((x) => x.toJson()).toList(),
    'line_items': lineItems.map((x) => x.toJson()).toList(),
    if (notes != null) 'notes': notes!.map((x) => x.toJson()).toList(),
  };
}

class WooOrderAddress {
  final String firstName;
  final String lastName;
  final String company;
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String postcode;
  final String country;
  final String? email;
  final String? phone;

  WooOrderAddress({
    required this.firstName,
    required this.lastName,
    required this.company,
    required this.address1,
    required this.address2,
    required this.city,
    required this.state,
    required this.postcode,
    required this.country,
    this.email,
    this.phone,
  });

  factory WooOrderAddress.fromJson(Map<String, dynamic> json) {
    return WooOrderAddress(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      company: json['company'] ?? '',
      address1: json['address_1'] ?? '',
      address2: json['address_2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postcode: json['postcode'] ?? '',
      country: json['country'] ?? '',
      email: json['email'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'company': company,
    'address_1': address1,
    'address_2': address2,
    'city': city,
    'state': state,
    'postcode': postcode,
    'country': country,
    if (email != null) 'email': email,
    if (phone != null) 'phone': phone,
  };
}

class WooOrderMetaData {
  final int id;
  final String key;
  final String value;
  final String displayKey;
  final String displayValue;

  WooOrderMetaData({
    required this.id,
    required this.key,
    required this.value,
    required this.displayKey,
    required this.displayValue,
  });

  factory WooOrderMetaData.fromJson(Map<String, dynamic> json) {
    return WooOrderMetaData(
      id: json['id'] ?? 0,
      key: json['key'] ?? '',
      value: json['value']?.toString() ?? '',
      displayKey: json['display_key'] ?? '',
      displayValue: json['display_value'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'key': key,
    'value': value,
    'display_key': displayKey,
    'display_value': displayValue,
  };
}

class WooOrderLineItem {
  final int id;
  final String name;
  final int productId;
  final int variationId;
  final int quantity;
  final String taxClass;
  final String subtotal;
  final String subtotalTax;
  final String total;
  final String totalTax;
  final List<WooOrderTax> taxes;
  final List<WooOrderMetaData> metaData;
  final String sku;
  final double price;

  WooOrderLineItem({
    required this.id,
    required this.name,
    required this.productId,
    required this.variationId,
    required this.quantity,
    required this.taxClass,
    required this.subtotal,
    required this.subtotalTax,
    required this.total,
    required this.totalTax,
    required this.taxes,
    required this.metaData,
    required this.sku,
    required this.price,
  });

  factory WooOrderLineItem.fromJson(Map<String, dynamic> json) {
    return WooOrderLineItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      productId: json['product_id'] ?? 0,
      variationId: json['variation_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      taxClass: json['tax_class'] ?? '',
      subtotal: json['subtotal'] ?? '0',
      subtotalTax: json['subtotal_tax'] ?? '0',
      total: json['total'] ?? '0',
      totalTax: json['total_tax'] ?? '0',
      taxes: (json['taxes'] as List?)
          ?.map((x) => WooOrderTax.fromJson(x))
          .toList() ?? [],
      metaData: (json['meta_data'] as List?)
          ?.map((x) => WooOrderMetaData.fromJson(x))
          .toList() ?? [],
      sku: json['sku'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'product_id': productId,
    'variation_id': variationId,
    'quantity': quantity,
    'tax_class': taxClass,
    'subtotal': subtotal,
    'subtotal_tax': subtotalTax,
    'total': total,
    'total_tax': totalTax,
    'taxes': taxes.map((x) => x.toJson()).toList(),
    'meta_data': metaData.map((x) => x.toJson()).toList(),
    'sku': sku,
    'price': price,
  };
}

class WooOrderTax {
  final int id;
  final String total;
  final String subtotal;

  WooOrderTax({
    required this.id,
    required this.total,
    required this.subtotal,
  });

  factory WooOrderTax.fromJson(Map<String, dynamic> json) {
    return WooOrderTax(
      id: json['id'] ?? 0,
      total: json['total'] ?? '0',
      subtotal: json['subtotal'] ?? '0',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'total': total,
    'subtotal': subtotal,
  };
}

class WooOrderNote {
  final int id;
  final String author;
  final String dateCreated;
  final String dateCreatedGmt;
  final String note;
  final bool customerNote;

  WooOrderNote({
    required this.id,
    required this.author,
    required this.dateCreated,
    required this.dateCreatedGmt,
    required this.note,
    required this.customerNote,
  });

  factory WooOrderNote.fromJson(Map<String, dynamic> json) {
    return WooOrderNote(
      id: json['id'] ?? 0,
      author: json['author'] ?? '',
      dateCreated: json['date_created'] ?? '',
      dateCreatedGmt: json['date_created_gmt'] ?? '',
      note: json['note'] ?? '',
      customerNote: json['customer_note'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'author': author,
    'date_created': dateCreated,
    'date_created_gmt': dateCreatedGmt,
    'note': note,
    'customer_note': customerNote,
  };
} 