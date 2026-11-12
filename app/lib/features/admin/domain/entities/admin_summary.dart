/// Jumlah dari server; data yang belum tersedia tidak berarti nol.
class AdminSummary {
  AdminSummary({
    required this.users,
    required this.stalls,
    required this.openStalls,
    required this.pendingApplications,
    required this.activeOrders,
  }) {
    if (users < 0 ||
        stalls < 0 ||
        openStalls < 0 ||
        pendingApplications < 0 ||
        activeOrders < 0 ||
        openStalls > stalls) {
      throw ArgumentError('Ringkasan admin tidak valid.');
    }
  }

  final int users;
  final int stalls;
  final int openStalls;
  final int pendingApplications;
  final int activeOrders;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdminSummary &&
          other.users == users &&
          other.stalls == stalls &&
          other.openStalls == openStalls &&
          other.pendingApplications == pendingApplications &&
          other.activeOrders == activeOrders);

  @override
  int get hashCode =>
      Object.hash(users, stalls, openStalls, pendingApplications, activeOrders);
}
