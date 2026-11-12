part of 'simulation.dart';

class SimulationAuthRepository implements AuthRepository {
  SimulationAuthRepository(this.store);
  final SimulationStore store;
  int _revision = 0;
  void _checkSession(int revision, int epoch) {
    if (revision != _revision || epoch != store._sessionEpoch) {
      throw const AuthOperationSupersededFailure();
    }
  }

  @override
  Future<User> login({
    required String identifier,
    required String password,
  }) async {
    final revision = ++_revision;
    final epoch = store._sessionEpoch;
    if (store.latency > Duration.zero) {
      await Future<void>.delayed(store.latency);
    }
    return store.atomic(() {
      _checkSession(revision, epoch);
      final normalized = identifier.trim().toLowerCase();
      final matches = store
          .table('users')
          .values
          .map((value) => unpackUser(asJson(value)))
          .where(
            (user) =>
                user.username.toLowerCase() == normalized ||
                user.email.toLowerCase() == normalized,
          );
      if (matches.isEmpty) throw const AuthInvalidCredentialsFailure();
      final user = matches.first;
      if (store.table('passwords')[user.id] != password) {
        throw const AuthInvalidCredentialsFailure();
      }
      if (!user.isActive) throw const AuthAccountDisabledFailure();
      store._data['session'] = user.id;
      store._sessionEpoch++;
      return user;
    });
  }

  @override
  Future<bool> isEmailAvailable({required String email}) async {
    final normalized = email.trim().toLowerCase();
    final users = store.table('users').values.map((e) => unpackUser(asJson(e)));
    return !users.any((u) => u.email.toLowerCase() == normalized);
  }

  @override
  Future<User> register({
    required String name,
    required String username,
    required String email,
    required String password,
    Uint8List? avatarBytes,
  }) => store.atomic(() {
    final users = store.table('users').values.map((e) => unpackUser(asJson(e)));
    if (users.any((u) => u.username.toLowerCase() == username.toLowerCase())) {
      throw const AuthUsernameTakenFailure();
    }
    if (users.any((u) => u.email.toLowerCase() == email.toLowerCase())) {
      throw const AuthEmailTakenFailure();
    }
    final userId = store.nextId('customer');
    String? avatarUrl;
    if (avatarBytes != null && avatarBytes.isNotEmpty) {
      final validated = ImageSecurityValidator.validateAndPrepare(
        bytes: avatarBytes,
        actorId: userId,
        category: MediaUploadCategory.profileAvatar,
      );
      avatarUrl =
          'https://cdn.kantincerdas.ac.id/media/${validated.category.slug}/${validated.safeFileName}';
    }
    final user = User(
      id: userId,
      username: username,
      email: email,
      name: name,
      role: UserRole.customer,
      isActive: true,
      avatarUrl: avatarUrl,
    );
    store.table('users')[user.id] = packUser(user);
    store.table('passwords')[user.id] = password;
    store.table('userVersions')[user.id] = 1;
    return user;
  });

  @override
  Future<User?> restoreSession() async {
    final revision = ++_revision;
    final epoch = store._sessionEpoch;
    if (store.latency > Duration.zero) {
      await Future<void>.delayed(store.latency);
    }
    await store._queue;
    _checkSession(revision, epoch);
    store.readGuard();
    final user = store.sessionUser;
    if (user != null && !user.isActive) {
      await store.atomic(() {
        _checkSession(revision, epoch);
        store._data['session'] = null;
        store._sessionEpoch++;
      });
      throw const AuthAccountDisabledFailure();
    }
    return user;
  }

  @override
  Future<void> logout() {
    ++_revision;
    return store.signOut();
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final actor = await store.begin();
    await store.atomic(() {
      store.check(actor);
      if (store.table('passwords')[actor.$1] != currentPassword) {
        throw const AuthInvalidCurrentPasswordFailure();
      }
      store.table('passwords')[actor.$1] = newPassword;
    });
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    if (store.latency > Duration.zero) {
      await Future<void>.delayed(store.latency);
    }
    store
        .readGuard(); // Simulates acknowledgement only. No email or reset link.
  }

  @override
  Future<User> updateProfileAvatar({required String? avatarUrl}) async {
    final safeUrl = ImageSecurityValidator.normalizeSafeImageUrl(
      avatarUrl,
      fieldName: 'avatar_url',
    );
    final actor = await store.begin();
    return store.atomic(() {
      store.check(actor);
      final current = unpackUser(asJson(store.table('users')[actor.$1]));
      final updated = current.copyWith(
        avatarUrl: safeUrl,
        clearAvatarUrl: safeUrl == null,
      );
      store.table('users')[actor.$1] = packUser(updated);
      store.table('userVersions')[actor.$1] =
          ((store.table('userVersions')[actor.$1] as int?) ?? 1) + 1;
      return updated;
    });
  }
}

class SimulationImagePickerPort implements ImagePickerPort {
  SimulationImagePickerPort(this.store);
  final SimulationStore store;

  /// Valid 1x1 PNG binary (67 bytes) for deterministic simulation tests.
  static final Uint8List validSamplePngBytes = Uint8List.fromList(const <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 dimensions
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89,
    0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, // IDAT chunk
    0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01,
    0x0D, 0x0A, 0x2D, 0xB4,
    0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, // IEND chunk
    0xAE, 0x42, 0x60, 0x82,
  ]);

  @override
  Future<RawPickedImage?> pickImage(ImagePickSource source) async {
    if (store.latency > Duration.zero) {
      await Future<void>.delayed(store.latency);
    }
    return RawPickedImage(bytes: validSamplePngBytes);
  }
}

class SimulationMediaUploadRepository implements MediaUploadRepository {
  SimulationMediaUploadRepository(this.store);
  final SimulationStore store;

  @override
  bool get isConfigured => true;

  @override
  Future<String> uploadImage(ValidatedUploadImage image) async {
    await store.begin();
    if (!ImageSecurityValidator.isSafeGeneratedFileName(image.safeFileName)) {
      throw const MediaInvalidImageFailure(
        MediaValidationReason.invalidActorId,
      );
    }
    return 'https://cdn.kantincerdas.ac.id/media/${image.category.slug}/${image.safeFileName}';
  }
}

CustomerCatalog simulationCatalog(SimulationStore store) {
  final owners = store
      .table('stalls')
      .values
      .map((e) => unpackOwnerStall(asJson(e)))
      .toList();
  final all = <MenuItem>[];
  final stalls = <Stall>[];
  for (final s in owners) {
    final menus = store
        .table('menus')
        .values
        .map((e) => unpackOwnerMenu(asJson(e)))
        .where((m) => m.stallId == s.id)
        .map(
          (m) => MenuItem(
            id: m.id,
            name: m.name,
            stallId: s.id,
            stallName: s.name,
            block: s.block,
            price: m.priceIdr,
            waitTime: '${s.prepTimeMin} menit',
            description: m.description,
            category: switch (m.category) {
              OwnerMenuCategory.rice => 'Nasi',
              OwnerMenuCategory.noodles => 'Mi',
              OwnerMenuCategory.drinks => 'Minuman',
              OwnerMenuCategory.snacks => 'Camilan',
              OwnerMenuCategory.other => 'Lainnya',
            },
            available: m.isAvailable,
            imageUrl: m.imageUrl,
          ),
        )
        .toList();
    all.addAll(menus);
    stalls.add(
      Stall(
        id: s.id,
        name: s.name,
        block: s.block,
        waitTime: '${s.prepTimeMin} menit',
        description: s.description,
        menus: menus,
        isOpen: s.isOpen,
        imageUrl: s.imageUrl,
      ),
    );
  }
  return CustomerCatalog(menus: all, stalls: stalls);
}

class SimulationCatalogRepository implements CustomerCatalogRepository {
  SimulationCatalogRepository(this.store);
  final SimulationStore store;
  @override
  Future<CustomerCatalog> getCatalog() async {
    await store.begin(UserRole.customer);
    store.readGuard();
    return store.empty
        ? CustomerCatalog(menus: [], stalls: [])
        : simulationCatalog(store);
  }
}

class SimulationAssistantRepository implements CustomerAssistantRepository {
  SimulationAssistantRepository(this.store);
  final SimulationStore store;
  @override
  Future<AssistantReply> recommend(String message) async {
    final actor = await store.begin(UserRole.customer);
    store.readGuard();
    final saved = store.table('preferences')[actor.$1];
    final prefs = saved == null
        ? null
        : unpackFoodPreferencesSnapshot(asJson(saved)).preferences;
    final catalog = simulationCatalog(store);
    final menus = catalog.menus
        .where(
          (m) =>
              catalog.canOrder(m.id) &&
              (prefs?.maxBudgetIdr == null ||
                  m.price <= prefs!.maxBudgetIdr!) &&
              (prefs?.vegetarian != true ||
                  m.description.contains('vegetarian')) &&
              !(prefs?.avoidIngredients.any(
                    (s) => '${m.name} ${m.description}'.toLowerCase().contains(
                      s.toLowerCase(),
                    ),
                  ) ??
                  false),
        )
        .take(3)
        .toList();
    return AssistantReply(
      message:
          'SIMULASI: pilihan berdasarkan katalog dan preferensi uji, bukan AI nyata. '
          'Informasi bahan terbatas; konfirmasi bahan/alergi kepada pemilik stan.',
      menus: store.empty ? [] : menus,
    );
  }
}
