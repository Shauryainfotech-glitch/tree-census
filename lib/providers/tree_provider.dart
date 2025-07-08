import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/tree.dart';
import '../services/tree_service.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';

class TreeProvider extends ChangeNotifier {
  List<Tree> _trees = [];
  List<Tree> _filteredTrees = [];
  Tree? _selectedTree;
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  TreeHealth? _healthFilter;
  String? _wardFilter;
  bool _heritageFilter = false;
  Position? _currentLocation;

  // Getters
  List<Tree> get trees => _filteredTrees;
  List<Tree> get allTrees => _trees;
  Tree? get selectedTree => _selectedTree;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  TreeHealth? get healthFilter => _healthFilter;
  String? get wardFilter => _wardFilter;
  bool get heritageFilter => _heritageFilter;
  Position? get currentLocation => _currentLocation;

  final TreeService _treeService = TreeService();
  final LocationService _locationService = LocationService();

  // Load trees from API or local storage
  Future<void> loadTrees({bool forceRefresh = false}) async {
    _setLoading(true);
    _clearError();

    try {
      final trees = await _treeService.getTrees(forceRefresh: forceRefresh);
      _trees = trees;
      _applyFilters();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load trees: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Search trees by query
  void searchTrees(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  // Filter trees by health status
  void filterByHealth(TreeHealth? health) {
    _healthFilter = health;
    _applyFilters();
  }

  // Filter trees by ward
  void filterByWard(String? ward) {
    _wardFilter = ward;
    _applyFilters();
  }

  // Filter heritage trees
  void filterHeritage(bool heritage) {
    _heritageFilter = heritage;
    _applyFilters();
  }

  // Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _healthFilter = null;
    _wardFilter = null;
    _heritageFilter = false;
    _applyFilters();
  }

  // Apply all active filters
  void _applyFilters() {
    _filteredTrees = _trees.where((tree) {
      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final matchesSearch = tree.species.toLowerCase().contains(_searchQuery) ||
            tree.localName.toLowerCase().contains(_searchQuery) ||
            tree.ward.toLowerCase().contains(_searchQuery) ||
            tree.id.toLowerCase().contains(_searchQuery);
        if (!matchesSearch) return false;
      }

      // Health filter
      if (_healthFilter != null && tree.health != _healthFilter) {
        return false;
      }

      // Ward filter
      if (_wardFilter != null && tree.ward != _wardFilter) {
        return false;
      }

      // Heritage filter
      if (_heritageFilter && !tree.heritage) {
        return false;
      }

      return true;
    }).toList();

    // Sort by distance if location is available
    if (_currentLocation != null) {
      _filteredTrees.sort((a, b) {
        final distanceA = Geolocator.distanceBetween(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          a.lat,
          a.lng,
        );
        final distanceB = Geolocator.distanceBetween(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          b.lat,
          b.lng,
        );
        return distanceA.compareTo(distanceB);
      });
    }

    notifyListeners();
  }

  // Get tree by ID
  Future<Tree?> getTreeById(String id) async {
    try {
      // First check in loaded trees
      final existingTree = _trees.firstWhere(
        (tree) => tree.id == id,
        orElse: () => throw Exception('Tree not found'),
      );
      return existingTree;
    } catch (e) {
      // If not found locally, fetch from API
      try {
        final tree = await _treeService.getTreeById(id);
        return tree;
      } catch (e) {
        _setError('Failed to load tree details: ${e.toString()}');
        return null;
      }
    }
  }

  // Select a tree
  void selectTree(Tree tree) {
    _selectedTree = tree;
    notifyListeners();
  }

  // Clear selected tree
  void clearSelection() {
    _selectedTree = null;
    notifyListeners();
  }

  // Add new tree
  Future<bool> addTree(Tree tree) async {
    _setLoading(true);
    _clearError();

    try {
      final addedTree = await _treeService.addTree(tree);
      _trees.add(addedTree);
      _applyFilters();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add tree: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Update existing tree
  Future<bool> updateTree(Tree tree) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedTree = await _treeService.updateTree(tree);
      final index = _trees.indexWhere((t) => t.id == tree.id);
      if (index != -1) {
        _trees[index] = updatedTree;
        _applyFilters();
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update tree: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Delete tree
  Future<bool> deleteTree(String treeId) async {
    _setLoading(true);
    _clearError();

    try {
      await _treeService.deleteTree(treeId);
      _trees.removeWhere((tree) => tree.id == treeId);
      _applyFilters();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete tree: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Get trees near location
  Future<List<Tree>> getTreesNearLocation(
    double lat,
    double lng,
    double radiusInMeters,
  ) async {
    try {
      final nearbyTrees = await _treeService.getTreesNearLocation(
        lat,
        lng,
        radiusInMeters,
      );
      return nearbyTrees;
    } catch (e) {
      _setError('Failed to load nearby trees: ${e.toString()}');
      return [];
    }
  }

  // Get trees by ward
  Future<List<Tree>> getTreesByWard(String ward) async {
    try {
      final wardTrees = await _treeService.getTreesByWard(ward);
      return wardTrees;
    } catch (e) {
      _setError('Failed to load ward trees: ${e.toString()}');
      return [];
    }
  }

  // Get heritage trees
  Future<List<Tree>> getHeritageTrees() async {
    try {
      final heritageTrees = await _treeService.getHeritageTrees();
      return heritageTrees;
    } catch (e) {
      _setError('Failed to load heritage trees: ${e.toString()}');
      return [];
    }
  }

  // Get current location
  Future<void> getCurrentLocation() async {
    try {
      _currentLocation = await _locationService.getCurrentPosition();
      _applyFilters(); // Re-sort by distance
    } catch (e) {
      debugPrint('Failed to get current location: $e');
    }
  }

  // Calculate distance to tree
  double? getDistanceToTree(Tree tree) {
    if (_currentLocation == null) return null;
    
    return Geolocator.distanceBetween(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      tree.lat,
      tree.lng,
    );
  }

  // Get tree statistics
  Map<String, dynamic> getTreeStatistics() {
    final totalTrees = _trees.length;
    final heritageTrees = _trees.where((tree) => tree.heritage).length;
    final healthyTrees = _trees.where((tree) => tree.health == TreeHealth.healthy).length;
    final diseasedTrees = _trees.where((tree) => tree.health == TreeHealth.diseased).length;
    
    final speciesCount = <String, int>{};
    final wardCount = <String, int>{};
    
    for (final tree in _trees) {
      speciesCount[tree.species] = (speciesCount[tree.species] ?? 0) + 1;
      wardCount[tree.ward] = (wardCount[tree.ward] ?? 0) + 1;
    }

    return {
      'totalTrees': totalTrees,
      'heritageTrees': heritageTrees,
      'healthyTrees': healthyTrees,
      'diseasedTrees': diseasedTrees,
      'healthPercentage': totalTrees > 0 ? (healthyTrees / totalTrees * 100).round() : 0,
      'speciesCount': speciesCount,
      'wardCount': wardCount,
      'mostCommonSpecies': speciesCount.isNotEmpty 
          ? speciesCount.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : 'N/A',
    };
  }

  // Export trees data
  Future<String> exportTreesData({
    String format = 'csv',
    List<String>? fields,
  }) async {
    try {
      return await _treeService.exportTrees(
        trees: _filteredTrees,
        format: format,
        fields: fields,
      );
    } catch (e) {
      _setError('Failed to export data: ${e.toString()}');
      return '';
    }
  }

  // Sync offline data
  Future<void> syncOfflineData() async {
    _setLoading(true);
    _clearError();

    try {
      await _treeService.syncOfflineData();
      await loadTrees(forceRefresh: true);
    } catch (e) {
      _setError('Failed to sync data: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Load demo data for testing
  void loadDemoData() {
    _trees = [
      Tree(
        id: 'TMC001',
        species: 'Mangifera indica',
        localName: 'Mango',
        lat: 19.2183,
        lng: 72.9781,
        height: 15.5,
        girth: 120.0,
        age: 25,
        heritage: false,
        ward: 'Ward 1 - Naupada',
        health: TreeHealth.healthy,
        canopy: 8.5,
        ownership: TreeOwnership.government,
        images: ['tree1_1.jpg', 'tree1_2.jpg'],
        lastSurveyDate: DateTime.now().subtract(const Duration(days: 30)),
        notes: 'Healthy mango tree in good condition',
      ),
      Tree(
        id: 'TMC002',
        species: 'Ficus religiosa',
        localName: 'Peepal',
        lat: 19.2200,
        lng: 72.9800,
        height: 25.0,
        girth: 200.0,
        age: 75,
        heritage: true,
        ward: 'Ward 2 - Kopri',
        health: TreeHealth.healthy,
        canopy: 15.0,
        ownership: TreeOwnership.government,
        images: ['tree2_1.jpg'],
        lastSurveyDate: DateTime.now().subtract(const Duration(days: 15)),
        notes: 'Heritage peepal tree, requires special care',
      ),
      Tree(
        id: 'TMC003',
        species: 'Azadirachta indica',
        localName: 'Neem',
        lat: 19.2150,
        lng: 72.9750,
        height: 12.0,
        girth: 80.0,
        age: 20,
        heritage: false,
        ward: 'Ward 1 - Naupada',
        health: TreeHealth.diseased,
        canopy: 6.0,
        ownership: TreeOwnership.private,
        images: ['tree3_1.jpg'],
        lastSurveyDate: DateTime.now().subtract(const Duration(days: 45)),
        notes: 'Shows signs of pest infestation, needs treatment',
      ),
    ];
    _applyFilters();
  }
}
