import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/home_remote_datasource.dart';
import '../../data/datasources/home_local_datasource.dart';
import '../../data/repositories/home_repository.dart';
import '../../domain/entities/home_entities.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/errors/failures.dart';

// ── Infrastructure providers ──────────────────────────────────────────────────
final homeRemoteDatasourceProvider = Provider<HomeRemoteDatasource>((ref) {
  return HomeRemoteDatasource(ref.read(dioClientProvider).dio);
});

final homeLocalDatasourceProvider = Provider<HomeLocalDatasource>((ref) {
  return HomeLocalDatasource();
});

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(
    ref.read(homeRemoteDatasourceProvider),
    ref.read(homeLocalDatasourceProvider),
  );
});

// ── State ─────────────────────────────────────────────────────────────────────
enum HomeLoadStatus { initial, loading, success, error }

class HomeState {
  final HomeLoadStatus status;
  final HomeData? data;
  final Failure? failure;
  final bool isRefreshing; // background refresh without blanking the UI

  const HomeState({
    this.status = HomeLoadStatus.initial,
    this.data,
    this.failure,
    this.isRefreshing = false,
  });

  bool get hasData => data != null;

  HomeState copyWith({
    HomeLoadStatus? status,
    HomeData? data,
    Failure? failure,
    bool? isRefreshing,
    bool clearFailure = false,
  }) =>
      HomeState(
        status:       status       ?? this.status,
        data:         data         ?? this.data,
        failure:      clearFailure ? null : failure ?? this.failure,
        isRefreshing: isRefreshing ?? this.isRefreshing,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class HomeNotifier extends StateNotifier<HomeState> {
  final HomeRepository _repo;

  HomeNotifier(this._repo) : super(const HomeState()) {
    load();
  }

  /// Initial load — shows skeletons until data arrives.
  Future<void> load() async {
    state = state.copyWith(status: HomeLoadStatus.loading);
    final result = await _repo.getHomeData();
    if (result.isSuccess) {
      state = state.copyWith(
          status: HomeLoadStatus.success,
          data:   result.requireData,
          clearFailure: true);
    } else {
      state = state.copyWith(
          status:  HomeLoadStatus.error,
          failure: result.failure);
    }
  }

  /// Pull-to-refresh — keeps showing existing data while fetching.
  Future<void> refresh() async {
    if (state.isRefreshing) return;
    state = state.copyWith(isRefreshing: true, clearFailure: true);
    final result = await _repo.getHomeData(forceRefresh: true);
    if (result.isSuccess) {
      state = state.copyWith(
          status:       HomeLoadStatus.success,
          data:         result.requireData,
          isRefreshing: false,
          clearFailure: true);
    } else {
      // On refresh failure, keep old data visible.
      state = state.copyWith(
          isRefreshing: false,
          failure:      result.failure);
    }
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(ref.read(homeRepositoryProvider));
});

// ── Convenience selectors ─────────────────────────────────────────────────────
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(homeProvider).data?.unreadNotifications ?? 0;
});
