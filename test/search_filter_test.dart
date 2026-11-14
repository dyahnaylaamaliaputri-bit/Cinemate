// test/search_filter_test.dart
// Unit tests untuk Epic Pencarian & Filter Multi-Kriteria (SRC — PB 11 / PB-051 s.d. PB-055)

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:cinemate/controllers/search_controller.dart';
import 'package:cinemate/models/movie_model.dart';
import 'package:cinemate/models/cinema_model.dart';
import 'package:cinemate/models/fnb_item_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Epic Pencarian & Filter Multi-Kriteria (SRC — PB 11)', () {
    late AppSearchController controller;

    final mockMovies = [
      const MovieModel(
        id: 1,
        title: 'Deadpool & Wolverine',
        overview: 'Wade Wilson and Logan team up in action-packed adventure.',
        voteAverage: 8.2,
        voteCount: 4500,
        popularity: 350.0,
        genreIds: [28, 35, 878], // Action, Comedy, Sci-Fi
      ),
      const MovieModel(
        id: 2,
        title: 'Inside Out 2',
        overview: 'Riley navigates new emotions in animated adventure.',
        voteAverage: 7.9,
        voteCount: 3800,
        popularity: 280.0,
        genreIds: [16, 35, 10751], // Animation, Comedy, Family
      ),
      const MovieModel(
        id: 3,
        title: 'A Quiet Place: Day One',
        overview: 'Survive monsters in horror thriller setting.',
        voteAverage: 6.8,
        voteCount: 2100,
        popularity: 190.0,
        genreIds: [27, 878, 53], // Horror, Sci-Fi, Thriller
      ),
      const MovieModel(
        id: 4,
        title: 'Sekawan Limo',
        overview: 'Komedi horor pendakian gunung di Jawa.',
        voteAverage: 7.1,
        voteCount: 890,
        popularity: 120.0,
        genreIds: [35, 27], // Comedy, Horror
      ),
    ];

    final mockCinemas = [
      const CinemaModel(
        id: 'c1',
        name: 'Cinemate Plaza Grand Indonesia',
        address: 'Jl. MH Thamrin No. 1',
        city: 'Jakarta',
        latitude: -6.1950,
        longitude: 106.8230,
        distanceKm: 2.5,
      ),
      const CinemaModel(
        id: 'c2',
        name: 'Bintang Cinema Depok',
        address: 'Jl. Margonda Raya No. 50',
        city: 'Depok',
        latitude: -6.3728,
        longitude: 106.8327,
        distanceKm: 18.2,
      ),
      const CinemaModel(
        id: 'c3',
        name: 'Cinemate Paris Van Java',
        address: 'Jl. Sukajadi No. 137',
        city: 'Bandung',
        latitude: -6.8893,
        longitude: 107.5962,
        distanceKm: 140.0,
      ),
    ];

    final mockFnb = [
      const FnbItemModel(
        id: 'f1',
        name: 'Popcorn Caramel Jumbo',
        description: 'Popcorn renyah manis lezat',
        price: 45000,
        category: 'snack',
      ),
      const FnbItemModel(
        id: 'f2',
        name: 'Coca Cola Zero Regular',
        description: 'Minuman bersoda segar dingin',
        price: 25000,
        category: 'drink',
      ),
      const FnbItemModel(
        id: 'f3',
        name: 'Combo Puas Berdua',
        description: '2 Popcorn Large + 2 Minuman Dingin',
        price: 85000,
        category: 'combo',
      ),
      const FnbItemModel(
        id: 'f4',
        name: 'Hot Dog Spesial',
        description: 'Sosis sapi dengan saus mustard mayo',
        price: 38000,
        category: 'food',
      ),
    ];

    setUp(() {
      Get.testMode = true;
      controller = AppSearchController();
      controller.allMovies.assignAll(mockMovies);
      controller.allCinemas.assignAll(mockCinemas);
      controller.allFnb.assignAll(mockFnb);
      controller.searchHistory.clear();
      controller.resetFilters();
    });

    tearDown(() {
      controller.onClose();
    });

    // ─────────────────────────────────────────────────────────────────────────
    // PB-051: Pencarian Multi-Entitas dengan Debounce
    // ─────────────────────────────────────────────────────────────────────────
    test('PB-051: Search finds matches across Movies, Cinemas, and F&B simultaneously', () {
      // Cari kata kunci 'deadpool'
      controller.searchQuery.value = 'deadpool';
      controller.performSearch();

      expect(controller.hasSearched.value, isTrue);
      expect(controller.filteredMovies.length, equals(1));
      expect(controller.filteredMovies.first.title, contains('Deadpool'));
      expect(controller.filteredCinemas, isEmpty);
      expect(controller.filteredFnb, isEmpty);
      expect(controller.totalResultCount, equals(1));

      // Cari kata kunci 'popcorn' (harus mencocokkan menu F&B)
      controller.searchQuery.value = 'popcorn';
      controller.performSearch();

      expect(controller.filteredFnb.length, equals(2)); // Popcorn Caramel & Combo Puas Berdua
      expect(controller.filteredMovies, isEmpty);

      // Cari kata kunci 'depok' (harus mencocokkan bioskop)
      controller.searchQuery.value = 'depok';
      controller.performSearch();

      expect(controller.filteredCinemas.length, equals(1));
      expect(controller.filteredCinemas.first.name, equals('Bintang Cinema Depok'));
      expect(controller.filteredMovies, isEmpty);
      expect(controller.filteredFnb, isEmpty);
    });

    test('PB-051: Search is case-insensitive and matches descriptions/overviews', () {
      // Overview film Inside Out 2: 'Riley navigates new emotions'
      controller.searchQuery.value = 'EMOTIONS';
      controller.performSearch();

      expect(controller.filteredMovies.length, equals(1));
      expect(controller.filteredMovies.first.title, equals('Inside Out 2'));

      // Description F&B: 'sosis sapi'
      controller.searchQuery.value = 'sosis';
      controller.performSearch();

      expect(controller.filteredFnb.length, equals(1));
      expect(controller.filteredFnb.first.name, equals('Hot Dog Spesial'));
    });

    test('PB-051: Clearing search resets results and search query', () {
      controller.searchQuery.value = 'deadpool';
      controller.performSearch();
      expect(controller.totalResultCount, greaterThan(0));

      controller.clearSearch();
      expect(controller.searchQuery.value, isEmpty);
      expect(controller.searchInput.text, isEmpty);
      expect(controller.hasSearched.value, isFalse);
      expect(controller.filteredMovies, isEmpty);
      expect(controller.filteredCinemas, isEmpty);
      expect(controller.filteredFnb, isEmpty);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // PB-052: Filter Pencarian Multi-Kriteria
    // ─────────────────────────────────────────────────────────────────────────
    test('PB-052: Filter by Entity Type narrows down result to specific category', () {
      controller.searchQuery.value = ''; // Tanpa query, tapi filter entitas aktif
      controller.setEntity(SearchEntityType.movie);

      expect(controller.filteredMovies.length, equals(mockMovies.length));
      expect(controller.filteredCinemas, isEmpty);
      expect(controller.filteredFnb, isEmpty);

      controller.setEntity(SearchEntityType.fnb);
      expect(controller.filteredMovies, isEmpty);
      expect(controller.filteredCinemas, isEmpty);
      expect(controller.filteredFnb.length, equals(mockFnb.length));
    });

    test('PB-052: Filter by Genre filters movies accurately', () {
      controller.setEntity(SearchEntityType.movie);
      controller.setGenre('Animation');

      expect(controller.filteredMovies.length, equals(1));
      expect(controller.filteredMovies.first.title, equals('Inside Out 2'));

      // Ubah genre ke Comedy (Deadpool, Inside Out 2, Sekawan Limo)
      controller.setGenre('Comedy');
      expect(controller.filteredMovies.length, equals(3));
    });

    test('PB-052: Filter by High Rating (>= 7.0) excludes movies below 7.0', () {
      controller.setEntity(SearchEntityType.movie);
      controller.toggleHighRating();

      expect(controller.isHighRatingOnly.value, isTrue);
      // Mock movies rating >= 7.0: Deadpool (8.2), Inside Out 2 (7.9), Sekawan Limo (7.1)
      // A Quiet Place (6.8) harus tereksklusi
      expect(controller.filteredMovies.length, equals(3));
      for (final m in controller.filteredMovies) {
        expect(m.voteAverage, greaterThanOrEqualTo(7.0));
      }
    });

    test('PB-052: Filter by Max Price filters F&B items budget', () {
      controller.setEntity(SearchEntityType.fnb);
      controller.setMaxPrice(40000);

      // Max price 40.000: Coca Cola (25.000), Hot Dog (38.000)
      expect(controller.filteredFnb.length, equals(2));
      for (final item in controller.filteredFnb) {
        expect(item.price, lessThanOrEqualTo(40000));
      }
    });

    test('PB-052: Filter by City filters cinema locations', () {
      controller.setEntity(SearchEntityType.cinema);
      controller.setCity('Depok');

      expect(controller.filteredCinemas.length, equals(1));
      expect(controller.filteredCinemas.first.city, equals('Depok'));

      controller.setCity('Semua Kota');
      expect(controller.filteredCinemas.length, equals(mockCinemas.length));
    });

    test('PB-052: resetFilters restores all default criteria', () {
      controller.setEntity(SearchEntityType.movie);
      controller.setGenre('Horror');
      controller.toggleHighRating();
      controller.setMaxPrice(50000);
      controller.setCity('Bandung');
      controller.setSortOption(SearchSortOption.ratingDesc);

      expect(controller.hasActiveFilters, isTrue);
      expect(controller.activeFilterCount, greaterThan(3));

      controller.resetFilters();

      expect(controller.selectedEntity.value, equals(SearchEntityType.all));
      expect(controller.selectedGenre.value, isNull);
      expect(controller.isHighRatingOnly.value, isFalse);
      expect(controller.maxPrice.value, isNull);
      expect(controller.selectedCity.value, isNull);
      expect(controller.selectedSort.value, equals(SearchSortOption.relevance));
      expect(controller.hasActiveFilters, isFalse);
      expect(controller.activeFilterCount, equals(0));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // PB-053: Pengurutan Hasil Pencarian
    // ─────────────────────────────────────────────────────────────────────────
    test('PB-053: Sorting movies by Rating Descending orders highest rating first', () {
      controller.setEntity(SearchEntityType.movie);
      controller.setSortOption(SearchSortOption.ratingDesc);

      expect(controller.filteredMovies.length, equals(4));
      expect(controller.filteredMovies[0].voteAverage, equals(8.2)); // Deadpool
      expect(controller.filteredMovies[1].voteAverage, equals(7.9)); // Inside Out 2
      expect(controller.filteredMovies[2].voteAverage, equals(7.1)); // Sekawan Limo
      expect(controller.filteredMovies[3].voteAverage, equals(6.8)); // A Quiet Place
    });

    test('PB-053: Sorting F&B by Price Ascending orders cheapest first', () {
      controller.setEntity(SearchEntityType.fnb);
      controller.setSortOption(SearchSortOption.priceAsc);

      expect(controller.filteredFnb.length, equals(4));
      expect(controller.filteredFnb[0].price, equals(25000)); // Coca Cola
      expect(controller.filteredFnb[1].price, equals(38000)); // Hot Dog
      expect(controller.filteredFnb[2].price, equals(45000)); // Popcorn
      expect(controller.filteredFnb[3].price, equals(85000)); // Combo
    });

    test('PB-053: Sorting Cinemas by Distance Ascending orders closest first', () {
      controller.setEntity(SearchEntityType.cinema);
      controller.setSortOption(SearchSortOption.distanceAsc);

      expect(controller.filteredCinemas.length, equals(3));
      expect(controller.filteredCinemas[0].distanceKm, equals(2.5)); // GI
      expect(controller.filteredCinemas[1].distanceKm, equals(18.2)); // Depok
      expect(controller.filteredCinemas[2].distanceKm, equals(140.0)); // PVJ
    });

    test('PB-053: Sorting by Name Ascending orders alphabetically', () {
      controller.setEntity(SearchEntityType.movie);
      controller.setSortOption(SearchSortOption.nameAsc);

      expect(controller.filteredMovies.first.title, startsWith('A Quiet Place'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // PB-054: Riwayat Pencarian Terakhir (Maksimal 5 item)
    // ─────────────────────────────────────────────────────────────────────────
    test('PB-054: addSearchHistory stores up to 5 unique recent searches with LIFO order', () {
      controller.clearAllHistory();
      expect(controller.searchHistory, isEmpty);

      controller.addSearchHistory('Avatar');
      controller.addSearchHistory('Spider-Man');
      controller.addSearchHistory('Batman');
      controller.addSearchHistory('Joker');
      controller.addSearchHistory('Oppenheimer');

      expect(controller.searchHistory.length, equals(5));
      expect(controller.searchHistory.first, equals('Oppenheimer'));

      // Tambahkan item ke-6 -> item terlama (Avatar) harus terbuang
      controller.addSearchHistory('Inception');
      expect(controller.searchHistory.length, equals(5));
      expect(controller.searchHistory.first, equals('Inception'));
      expect(controller.searchHistory.contains('Avatar'), isFalse);

      // Tambahkan item yang sudah ada ('Batman') -> harus pindah ke paling depan tanpa duplikasi
      controller.addSearchHistory('Batman');
      expect(controller.searchHistory.length, equals(5));
      expect(controller.searchHistory.first, equals('Batman'));
      expect(controller.searchHistory.where((q) => q == 'Batman').length, equals(1));
    });

    test('PB-054: removeHistoryItem removes specific search and clearAllHistory wipes list', () {
      controller.clearAllHistory();
      controller.addSearchHistory('Film A');
      controller.addSearchHistory('Film B');
      controller.addSearchHistory('Film C');

      controller.removeHistoryItem('Film B');
      expect(controller.searchHistory.length, equals(2));
      expect(controller.searchHistory.contains('Film B'), isFalse);

      controller.clearAllHistory();
      expect(controller.searchHistory, isEmpty);
    });

    test('PB-054: selectHistoryItem sets query and triggers search', () {
      controller.selectHistoryItem('deadpool');
      expect(controller.searchInput.text, equals('deadpool'));
      expect(controller.searchQuery.value, equals('deadpool'));
      expect(controller.hasSearched.value, isTrue);
      expect(controller.filteredMovies.length, equals(1));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // PB-055: State Kosong & Loading
    // ─────────────────────────────────────────────────────────────────────────
    test('PB-055: isEmptyResult is true only when query yielded no results', () {
      expect(controller.isEmptyResult, isFalse);

      // Cari query yang tidak ada
      controller.searchQuery.value = 'xyz123randomnonexistent';
      controller.performSearch();

      expect(controller.hasSearched.value, isTrue);
      expect(controller.totalResultCount, equals(0));
      expect(controller.isEmptyResult, isTrue);
    });
  });
}
