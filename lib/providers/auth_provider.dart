import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/storage/firebase_storage.dart';
import '../core/storage/secure_storage.dart';
import '../core/storage/hive_storage.dart';
import '../models/user_model.dart';
import '../core/utils/logger.dart';
import '../services/notification_service.dart';

// ---------------------------------------------------------------------------
// Top-level providers — must live here, outside every class
// ---------------------------------------------------------------------------

/// The current user's UID, or null when signed out.
/// Downstream providers watch this to scope their Firestore reads/writes.
final currentUidProvider = StateProvider<String?>((ref) {
  return FirebaseAuth.instance.currentUser?.uid;
});

/// A ready-to-use FirestoreStorage scoped to the current user.
/// Returns null when no user is signed in — providers must guard against this.
final firestoreStorageProvider = Provider<FirestoreStorage?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return null;
  return FirestoreStorage(uid);
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(secureStorageProvider),
    ref.read(hiveStorageProvider),
    ref.read(notificationServiceProvider),
    ref,
  );
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserModel? user;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserModel? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AuthNotifier extends StateNotifier<AuthState> {
  final SecureStorage _secureStorage;
  final HiveStorage _hiveStorage;
  final NotificationService _notificationService;
  final Ref _ref;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthNotifier(
      this._secureStorage,
      this._hiveStorage,
      this._notificationService,
      this._ref,
      ) : super(const AuthState()) {
    _auth.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        // Sync UID into the top-level provider so firestoreStorageProvider
        // and any downstream provider rebuild immediately.
        _ref.read(currentUidProvider.notifier).state = firebaseUser.uid;

        // Serve cached user immediately so UI unblocks on cold start.
        final cached = await _hiveStorage.getUser();
        if (cached != null) {
          state = state.copyWith(isAuthenticated: true, user: cached);
        }

        // Refresh from Firestore in background; update state + cache if changed.
        final fresh = await _fetchUserModel(firebaseUser);
        state = state.copyWith(isAuthenticated: true, user: fresh);

        await _saveToken(firebaseUser);
        _notificationService.initialize();
      } else {
        _ref.read(currentUidProvider.notifier).state = null;
        state = state.copyWith(isAuthenticated: false, user: null);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Sign up — creates the Firestore anchor document
  // ---------------------------------------------------------------------------
  Future<void> signUp(String email, String password, String displayName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(displayName);

      await _firestore.collection('users').doc(user.uid).set({
        'email': email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'onboardingComplete': false,
      });

      // authStateChanges fires and rehydrates state — nothing extra needed.
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _getFirebaseErrorMessage(e.code));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Sign in
  // ---------------------------------------------------------------------------
  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final userModel = await _fetchUserModel(credential.user!);
      state = state.copyWith(isLoading: false, isAuthenticated: true, user: userModel);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _getFirebaseErrorMessage(e.code));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Google sign-in — upserts the anchor doc so new Google users get one too
  // ---------------------------------------------------------------------------
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      // merge: true — only writes fields that don't already exist,
      // so onboardingComplete is preserved on subsequent sign-ins.
      await _firestore.collection('users').doc(user.uid).set(
        {
          'email': user.email ?? '',
          'displayName': user.displayName ?? '',
          'photoUrl': user.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'onboardingComplete': false,
        },
        SetOptions(merge: true),
      );

      final userModel = await _fetchUserModel(user);
      state = state.copyWith(isLoading: false, isAuthenticated: true, user: userModel);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _getFirebaseErrorMessage(e.code));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Sign out
  // ---------------------------------------------------------------------------
  Future<void> signOut() async {
    try {
      await _hiveStorage.clearUser();
      await _secureStorage.clearAll();
      await GoogleSignIn().signOut();
      await _auth.signOut();
      // currentUidProvider is cleared by the authStateChanges listener above.
      state = const AuthState(isAuthenticated: false);
    } catch (e) {
      AppLogger.error('Sign out error', e);
    }
  }

  // ---------------------------------------------------------------------------
  // Mark onboarding complete
  // ---------------------------------------------------------------------------
  Future<void> completeOnboarding() async {
    final uid = state.user?.uid;
    if (uid == null) return;
    try {
      await _firestore.collection('users').doc(uid).update({'onboardingComplete': true});
      final updated = state.user!.copyWith(onboardingComplete: true);
      state = state.copyWith(user: updated);
      await _hiveStorage.saveUser(updated);
    } catch (e) {
      AppLogger.error('completeOnboarding error', e);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<UserModel> _fetchUserModel(User firebaseUser) async {
    try {
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final user = UserModel(
          uid: firebaseUser.uid,
          email: data['email'] as String? ?? firebaseUser.email ?? '',
          displayName: data['displayName'] as String? ?? firebaseUser.displayName,
          photoUrl: data['photoUrl'] as String? ?? firebaseUser.photoURL,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          onboardingComplete: data['onboardingComplete'] as bool? ?? false,
        );
        await _hiveStorage.saveUser(user);
        return user;
      }
    } catch (e) {
      AppLogger.error('_fetchUserModel error', e);
      final cached = await _hiveStorage.getUser();
      if (cached != null) return cached;
    }

    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      createdAt: DateTime.now(),
      onboardingComplete: false,
    );
  }

  Future<void> _saveToken(User user) async {
    final token = await user.getIdToken();
    if (token != null) {
      await _secureStorage.saveAuthToken(token);
      await _secureStorage.saveUserId(user.uid);
      await _secureStorage.saveUserEmail(user.email ?? '');
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'Authentication error. Please try again.';
    }
  }
}