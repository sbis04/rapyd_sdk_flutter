// To parse this JSON data, do
//
//     final customer = customerFromJson(jsonString);

import 'dart:convert';

import 'status.dart';

class Customer {
  Customer({
    required this.status,
    required this.data,
  });

  final Status status;
  final CustomerData data;

  factory Customer.fromRawJson(String str) =>
      Customer.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        status: Status.fromJson(json["status"]),
        data: CustomerData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status.toJson(),
        "data": data.toJson(),
      };
}

class CustomerData {
  CustomerData({
    required this.id,
    required this.name,
    required this.defaultPaymentMethod,
    required this.description,
    required this.email,
    required this.invoicePrefix,
    required this.createdAt,
    required this.businessVatId,
    required this.ewallet,
  });

  final String id;
  final String name;
  final String? defaultPaymentMethod;
  final String? description;
  final String email;
  final String? invoicePrefix;
  final int createdAt;
  final String? businessVatId;
  final String? ewallet;

  factory CustomerData.fromRawJson(String str) =>
      CustomerData.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory CustomerData.fromJson(Map<String, dynamic> json) => CustomerData(
        id: json["id"],
        name: json["name"],
        defaultPaymentMethod: json["default_payment_method"],
        description: json["description"],
        email: json["email"],
        invoicePrefix: json["invoice_prefix"],
        createdAt: json["created_at"],
        businessVatId: json["business_vat_id"],
        ewallet: json["ewallet"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "default_payment_method": defaultPaymentMethod,
        "description": description,
        "email": email,
        "invoice_prefix": invoicePrefix,
        "created_at": createdAt,
        "business_vat_id": businessVatId,
        "ewallet": ewallet,
      };
}
