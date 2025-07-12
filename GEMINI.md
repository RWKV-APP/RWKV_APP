## 状态管理

- 整个项目在使用 riverpods 管理状态
- 下面是对 riverpods 的封装, 用于原子化状态管理

```dart
/// Generates a [StateProvider] initialized to the specified value.
StateProvider<V> qs<V>(V v) => StateProvider<V>((_) => v);

/// Generates a [Provider] using the provided createFn.
Provider<V> qp<V>(V Function(Ref<V> ref) createFn) => Provider<V>(createFn);

extension HaloProviderListenable<V> on ProviderListenable<V> {
  /// Reads the current value using shorthand `q`.
  V get q => rc.read(this);
}

extension HaloStateProvider<V> on StateProvider<V> {
  /// Reads the current state using shorthand `q`.
  V get q => rc.read(this);

  /// Sets the state to [value].
  set q(V value) {
    rc.read(notifier).state = value;
  }
}
```

## rwkv_mobile_flutter

- `rwkv_mobile_flutter` 是这个项目的 LLM inference 引擎
