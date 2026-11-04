/// Providers for the organization selection.
///
/// Lives in `core/` rather than in a feature because both the auth feature
/// (which must clear it on logout) and the organization feature (which reads
/// and changes it) need the same instance, and features must not import each
/// other. `TenantStore.shared` is the one object; this only exposes it to
/// Riverpod and gives tests an override point.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tenant_store.dart';

final tenantStoreProvider = Provider<TenantStore>((ref) => TenantStore.shared);
