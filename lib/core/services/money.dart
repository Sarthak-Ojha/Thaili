/// Immutable precision money value object stored in integer paisa/cents to eliminate floating point issues.
class Money implements Comparable<Money> {
  final int paisa;

  const Money._(this.paisa);

  factory Money.fromPaisa(int paisa) => Money._(paisa);

  factory Money.fromDouble(double amount) {
    return Money._((amount * 100).round());
  }

  factory Money.zero() => const Money._(0);

  double toDouble() => paisa / 100.0;

  Money operator +(Money other) => Money._(paisa + other.paisa);
  Money operator -(Money other) => Money._(paisa - other.paisa);
  Money operator *(num factor) => Money._((paisa * factor).round());

  bool get isNegative => paisa < 0;
  bool get isZero => paisa == 0;
  bool get isPositive => paisa > 0;

  @override
  int compareTo(Money other) => paisa.compareTo(other.paisa);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money && runtimeType == other.runtimeType && paisa == other.paisa;

  @override
  int get hashCode => paisa.hashCode;

  @override
  String toString() => toDouble().toStringAsFixed(2);
}
