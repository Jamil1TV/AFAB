import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

@immutable
class CustomerInvoiceLinkDto {
  const CustomerInvoiceLinkDto({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.amount,
    required this.status,
    required this.orderDate,
    required this.description,
    this.paymentMethod,
    this.invoiceNumber,
    this.createdAt,
  });

  final String id;
  final String orderNumber;
  final String customerId;
  final Decimal amount;
  final String status;
  final String orderDate;
  final String description;
  final String? paymentMethod;
  final String? invoiceNumber;
  final DateTime? createdAt;

  factory CustomerInvoiceLinkDto.fromJson(Map<String, dynamic> json) {
    return CustomerInvoiceLinkDto(
      id: (json['id'] ?? '').toString(),
      orderNumber: (json['orderNumber'] ?? '').toString(),
      customerId: (json['customerId'] ?? '').toString(),
      amount: MoneyFormatter.parseDecimal(json['amount']),
      status: (json['status'] ?? 'DRAFT').toString().toUpperCase(),
      orderDate: (json['orderDate'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      paymentMethod: json['paymentMethod']?.toString(),
      invoiceNumber: json['invoiceNumber']?.toString(),
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}

@immutable
class CustomerDto {
  const CustomerDto({
    required this.id,
    required this.customerCode,
    required this.businessId,
    required this.name,
    this.companyName,
    this.email,
    this.phone,
    required this.group,
    required this.status,
    required this.totalRevenue,
    required this.invoicedAmount,
    required this.outstandingBalance,
    required this.ordersCount,
    this.lastActivityDate,
    this.address,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.orders = const [],
  });

  final String id;
  final String customerCode;
  final String businessId;
  final String name;
  final String? companyName;
  final String? email;
  final String? phone;
  final String group;
  final String status;
  final Decimal totalRevenue;
  final Decimal invoicedAmount;
  final Decimal outstandingBalance;
  final int ordersCount;
  final String? lastActivityDate;
  final String? address;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<CustomerInvoiceLinkDto> orders;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'C';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  factory CustomerDto.fromJson(Map<String, dynamic> json) {
    final rawOrders = json['orders'] as List<dynamic>? ?? const [];
    return CustomerDto(
      id: (json['id'] ?? '').toString(),
      customerCode: (json['customerCode'] ?? '').toString(),
      businessId: (json['businessId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      companyName: json['companyName']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      group: (json['group'] ?? 'Standard').toString(),
      status: (json['status'] ?? 'Active').toString(),
      totalRevenue: MoneyFormatter.parseDecimal(json['totalRevenue']),
      invoicedAmount: MoneyFormatter.parseDecimal(json['invoicedAmount']),
      outstandingBalance: MoneyFormatter.parseDecimal(
        json['outstandingBalance'],
      ),
      ordersCount: (json['ordersCount'] as num?)?.toInt() ?? 0,
      lastActivityDate: json['lastActivityDate']?.toString(),
      address: json['address']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] is String
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      orders: rawOrders
          .whereType<Map<String, dynamic>>()
          .map(CustomerInvoiceLinkDto.fromJson)
          .toList(),
    );
  }
}

@immutable
class CustomerPageDto {
  const CustomerPageDto({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.pageNumber,
    required this.pageSize,
  });

  final List<CustomerDto> content;
  final int totalElements;
  final int totalPages;
  final int pageNumber;
  final int pageSize;

  factory CustomerPageDto.fromJson(Map<String, dynamic> json) {
    final list = json['content'] as List<dynamic>? ?? const [];
    return CustomerPageDto(
      content: list
          .whereType<Map<String, dynamic>>()
          .map(CustomerDto.fromJson)
          .toList(),
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 0,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
    );
  }
}

@immutable
class CustomerOverviewDonutDto {
  const CustomerOverviewDonutDto({
    required this.activeCount,
    required this.activePct,
    required this.inactiveCount,
    required this.inactivePct,
    required this.newCount,
    required this.newPct,
  });

  final int activeCount;
  final double activePct;
  final int inactiveCount;
  final double inactivePct;
  final int newCount;
  final double newPct;

  factory CustomerOverviewDonutDto.fromJson(Map<String, dynamic> json) {
    return CustomerOverviewDonutDto(
      activeCount: (json['activeCount'] as num?)?.toInt() ?? 0,
      activePct: (json['activePct'] as num?)?.toDouble() ?? 0.0,
      inactiveCount: (json['inactiveCount'] as num?)?.toInt() ?? 0,
      inactivePct: (json['inactivePct'] as num?)?.toDouble() ?? 0.0,
      newCount: (json['newCount'] as num?)?.toInt() ?? 0,
      newPct: (json['newPct'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

@immutable
class CustomerTopItemDto {
  const CustomerTopItemDto({
    required this.id,
    required this.customerCode,
    required this.name,
    this.email,
    required this.revenue,
    required this.ordersCount,
    this.avatarColor,
  });

  final String id;
  final String customerCode;
  final String name;
  final String? email;
  final Decimal revenue;
  final int ordersCount;
  final String? avatarColor;

  factory CustomerTopItemDto.fromJson(Map<String, dynamic> json) {
    return CustomerTopItemDto(
      id: (json['id'] ?? '').toString(),
      customerCode: (json['customerCode'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: json['email']?.toString(),
      revenue: MoneyFormatter.parseDecimal(json['revenue']),
      ordersCount: (json['ordersCount'] as num?)?.toInt() ?? 0,
      avatarColor: json['avatarColor']?.toString(),
    );
  }
}

@immutable
class CustomerActivityItemDto {
  const CustomerActivityItemDto({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.type,
    required this.description,
    required this.amount,
    required this.timestamp,
  });

  final String id;
  final String customerId;
  final String customerName;
  final String type;
  final String description;
  final Decimal amount;
  final String timestamp;

  factory CustomerActivityItemDto.fromJson(Map<String, dynamic> json) {
    return CustomerActivityItemDto(
      id: (json['id'] ?? '').toString(),
      customerId: (json['customerId'] ?? '').toString(),
      customerName: (json['customerName'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      amount: MoneyFormatter.parseDecimal(json['amount']),
      timestamp: (json['timestamp'] ?? '').toString(),
    );
  }
}

@immutable
class CustomerSummaryDto {
  const CustomerSummaryDto({
    required this.totalCustomers,
    required this.totalCustomersChangePct,
    required this.newCustomers,
    required this.newCustomersChangePct,
    required this.totalRevenue,
    required this.totalRevenueChangePct,
    required this.avgRevenuePerCustomer,
    required this.avgRevenueChangePct,
    required this.repeatCustomersPct,
    required this.repeatCustomersChangePct,
    required this.currency,
    required this.overviewDonut,
    required this.topCustomers,
    required this.recentActivity,
  });

  final int totalCustomers;
  final double totalCustomersChangePct;
  final int newCustomers;
  final double newCustomersChangePct;
  final Decimal totalRevenue;
  final double totalRevenueChangePct;
  final Decimal avgRevenuePerCustomer;
  final double avgRevenueChangePct;
  final double repeatCustomersPct;
  final double repeatCustomersChangePct;
  final String currency;
  final CustomerOverviewDonutDto overviewDonut;
  final List<CustomerTopItemDto> topCustomers;
  final List<CustomerActivityItemDto> recentActivity;

  factory CustomerSummaryDto.fromJson(Map<String, dynamic> json) {
    final topRaw = json['topCustomers'] as List<dynamic>? ?? const [];
    final actRaw = json['recentActivity'] as List<dynamic>? ?? const [];
    final donutRaw = json['overviewDonut'] as Map<String, dynamic>?;
    return CustomerSummaryDto(
      totalCustomers: (json['totalCustomers'] as num?)?.toInt() ?? 0,
      totalCustomersChangePct:
          (json['totalCustomersChangePct'] as num?)?.toDouble() ?? 0.0,
      newCustomers: (json['newCustomers'] as num?)?.toInt() ?? 0,
      newCustomersChangePct:
          (json['newCustomersChangePct'] as num?)?.toDouble() ?? 0.0,
      totalRevenue: MoneyFormatter.parseDecimal(json['totalRevenue']),
      totalRevenueChangePct:
          (json['totalRevenueChangePct'] as num?)?.toDouble() ?? 0.0,
      avgRevenuePerCustomer: MoneyFormatter.parseDecimal(
        json['avgRevenuePerCustomer'],
      ),
      avgRevenueChangePct:
          (json['avgRevenueChangePct'] as num?)?.toDouble() ?? 0.0,
      repeatCustomersPct:
          (json['repeatCustomersPct'] as num?)?.toDouble() ?? 0.0,
      repeatCustomersChangePct:
          (json['repeatCustomersChangePct'] as num?)?.toDouble() ?? 0.0,
      currency: (json['currency'] ?? 'USD').toString(),
      overviewDonut: CustomerOverviewDonutDto.fromJson(donutRaw ?? const {}),
      topCustomers: topRaw
          .whereType<Map<String, dynamic>>()
          .map(CustomerTopItemDto.fromJson)
          .toList(),
      recentActivity: actRaw
          .whereType<Map<String, dynamic>>()
          .map(CustomerActivityItemDto.fromJson)
          .toList(),
    );
  }
}

@immutable
class CustomerMutationRequest {
  const CustomerMutationRequest({
    required this.name,
    this.companyName,
    this.email,
    this.customerCode,
    this.phone,
    this.group = 'Standard',
    this.status = 'Active',
    this.address,
    this.notes,
  });

  final String name;
  final String? companyName;
  final String? email;
  final String? customerCode;
  final String? phone;
  final String group;
  final String status;
  final String? address;
  final String? notes;

  Map<String, dynamic> toJson() {
    String? clean(String? value) {
      if (value == null) return null;
      final t = value.trim();
      return t.isEmpty ? null : t;
    }

    return {
      'name': name.trim(),
      'companyName': clean(companyName),
      'email': clean(email),
      'customerCode': clean(customerCode),
      'phone': clean(phone),
      'group': group,
      'status': status,
      'address': clean(address),
      'notes': clean(notes),
    };
  }
}
