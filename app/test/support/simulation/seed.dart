part of 'simulation.dart';

Json simulationSeed() {
  final users = <User>[
    const User(
      id: 'customer-1',
      username: 'pelanggan',
      email: 'pelanggan@example.test',
      name: 'Alya Simulasi',
      role: UserRole.customer,
      isActive: true,
    ),
    const User(
      id: 'customer-2',
      username: 'pelanggan2',
      email: 'pelanggan2@example.test',
      name: 'Bima Simulasi',
      role: UserRole.customer,
      isActive: true,
    ),
    const User(
      id: 'owner-1',
      username: 'pemilik',
      email: 'pemilik@example.test',
      name: 'Citra Simulasi',
      role: UserRole.owner,
      isActive: true,
    ),
    const User(
      id: 'owner-2',
      username: 'pemilik2',
      email: 'pemilik2@example.test',
      name: 'Damar Simulasi',
      role: UserRole.owner,
      isActive: true,
    ),
    const User(
      id: 'owner-3',
      username: 'pemilik3',
      email: 'pemilik3@example.test',
      name: 'Eka Simulasi',
      role: UserRole.owner,
      isActive: true,
    ),
    const User(
      id: 'admin-1',
      username: 'admin',
      email: 'admin@example.test',
      name: 'Admin Simulasi',
      role: UserRole.admin,
      isActive: true,
    ),
  ];
  final stalls = List.generate(
    3,
    (i) => OwnerStall(
      id: 'stall-${i + 1}',
      ownerId: 'owner-${i + 1}',
      name: ['Dapur Nusantara', 'Warung Mie Kampus', 'Kedai Segar'][i],
      block: 'Blok ${['A', 'B', 'C'][i]}',
      description: 'Stan fiktif untuk simulasi KantinCerdas.',
      isOpen: i != 2,
      prepTimeMin: 10 + i * 5,
      version: 1,
    ),
  );
  final names = [
    'Nasi Ayam',
    'Nasi Sayur',
    'Es Teh',
    'Tahu Goreng',
    'Nasi Telur',
  ];
  final menus = <OwnerMenu>[];
  for (var i = 0; i < 3; i++) {
    for (var j = 0; j < names.length; j++) {
      menus.add(
        OwnerMenu(
          id: 'menu-$i-$j',
          stallId: stalls[i].id,
          name: names[j],
          description: j == 1
              ? 'Sayur, nasi; vegetarian.'
              : 'Menu contoh. Tanyakan bahan kepada pemilik stan.',
          category: j == 2
              ? OwnerMenuCategory.drinks
              : j == 3
              ? OwnerMenuCategory.snacks
              : OwnerMenuCategory.rice,
          priceIdr: [15000, 12000, 5000, 8000, 13000][j] + i * 1000,
          isAvailable: j != 4,
          version: 1,
        ),
      );
    }
  }
  final now = DateTime.utc(2026, 10, 28, 3);
  final orders = List.generate(8, (i) {
    final status = OrderStatus.values[i % OrderStatus.values.length];
    final menu = menus[i % 4];
    return OrderRecord(
      id: 'order-seed-$i',
      orderNumber: 'SIM-${100 + i}',
      customerId: i == 7 ? 'customer-2' : 'customer-1',
      customerName: i == 7 ? 'Bima Simulasi' : 'Alya Simulasi',
      stallId: menu.stallId,
      stallName: stalls.first.name,
      items: [
        OrderLine(
          menuId: menu.id,
          name: menu.name,
          quantity: 1,
          unitPriceIdr: menu.priceIdr,
          note: '',
        ),
      ],
      status: status,
      paymentStatus: status == OrderStatus.completed
          ? OrderPaymentStatus.paid
          : status == OrderStatus.rejected || status == OrderStatus.cancelled
          ? OrderPaymentStatus.notCharged
          : OrderPaymentStatus.unpaid,
      totalPriceIdr: menu.priceIdr,
      note: '',
      createdAt: now.subtract(Duration(hours: i)),
      updatedAt: now,
      version: 1,
      rejectionReason: status == OrderStatus.rejected
          ? 'Bahan habis (simulasi).'
          : null,
    );
  });
  final application = CanteenApplication(
    id: 'application-seed',
    applicantId: 'customer-2',
    name: 'Kedai Bima',
    description: 'Pengajuan fiktif untuk mencoba keputusan admin.',
    location: 'Blok D',
    phone: '081234567890',
    status: CanteenApplicationStatus.submitted,
    createdAt: now,
    version: 1,
  );
  return {
    'schema': 1,
    'revision': 1,
    'sequence': 1000,
    'session': null,
    'users': {for (final u in users) u.id: packUser(u)},
    'passwords': {for (final u in users) u.id: 'Simulasi123!'},
    'userVersions': {for (final u in users) u.id: 1},
    'stalls': {for (final s in stalls) s.id: packOwnerStall(s)},
    'menus': {for (final m in menus) m.id: packOwnerMenu(m)},
    'orders': {for (final o in orders) o.id: packOrderRecord(o)},
    'applications': {application.id: packCanteenApplication(application)},
    'preferences': <String, dynamic>{},
    'receipts': <String, dynamic>{},
    'journals': <String, dynamic>{},
  };
}
