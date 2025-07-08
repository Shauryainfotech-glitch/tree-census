import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../models/tree.dart';
import '../utils/constants.dart';

class TreeService {
  final String _baseUrl = AppConstants.baseUrl;
  late Box<Tree> _treeBox;

  TreeService() {
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    try {
      _treeBox = await Hive.openBox<Tree>(AppConstants.treesBox);
    } catch (e) {
      print('Error initializing Hive: $e');
    }
  }

  // Get all trees
  Future<List<Tree>> getTrees({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _treeBox.isNotEmpty) {
        // Return cached data if available
        return _treeBox.values.toList();
      }

      final response = await http.get(
        Uri.parse('$_baseUrl${ApiEndpoints.trees}'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> treesJson = data['trees'] ?? [];
        
        final trees = treesJson.map((json) => Tree.fromJson(json)).toList();
        
        // Cache the data
        await _cacheTreesLocally(trees);
        
        return trees;
      } else {
        throw Exception('Failed to load trees: ${response.statusCode}');
      }
    } catch (e) {
      // Return cached data if network fails
      if (_treeBox.isNotEmpty) {
        return _treeBox.values.toList();
      }
      throw Exception('Failed to load trees: $e');
    }
  }

  // Get tree by ID
  Future<Tree> getTreeById(String id) async {
    try {
      // Check cache first
      final cachedTree = _treeBox.get(id);
      if (cachedTree != null) {
        return cachedTree;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl${ApiEndpoints.treeById.replaceAll('{id}', id)}'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tree = Tree.fromJson(data['tree']);
        
        // Cache the tree
        await _treeBox.put(tree.id, tree);
        
        return tree;
      } else {
        throw Exception('Tree not found');
      }
    } catch (e) {
      throw Exception('Failed to load tree: $e');
    }
  }

  // Search trees
  Future<List<Tree>> searchTrees({
    String? query,
    TreeHealth? health,
    String? ward,
    bool? heritage,
    double? lat,
    double? lng,
    double? radius,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }
      if (health != null) {
        queryParams['health'] = health.toString().split('.').last;
      }
      if (ward != null) {
        queryParams['ward'] = ward;
      }
      if (heritage != null) {
        queryParams['heritage'] = heritage.toString();
      }
      if (lat != null && lng != null) {
        queryParams['lat'] = lat.toString();
        queryParams['lng'] = lng.toString();
      }
      if (radius != null) {
        queryParams['radius'] = radius.toString();
      }

      final uri = Uri.parse('$_baseUrl${ApiEndpoints.treeSearch}')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> treesJson = data['trees'] ?? [];
        
        return treesJson.map((json) => Tree.fromJson(json)).toList();
      } else {
        throw Exception('Search failed: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to local search if network fails
      return _searchTreesLocally(
        query: query,
        health: health,
        ward: ward,
        heritage: heritage,
      );
    }
  }

  // Get trees near location
  Future<List<Tree>> getTreesNearLocation(
    double lat,
    double lng,
    double radiusInMeters,
  ) async {
    try {
      final queryParams = {
        'lat': lat.toString(),
        'lng': lng.toString(),
        'radius': radiusInMeters.toString(),
      };

      final uri = Uri.parse('$_baseUrl${ApiEndpoints.trees}/nearby')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> treesJson = data['trees'] ?? [];
        
        return treesJson.map((json) => Tree.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get nearby trees: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get nearby trees: $e');
    }
  }

  // Get trees by ward
  Future<List<Tree>> getTreesByWard(String ward) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiEndpoints.treesByWard.replaceAll('{ward}', ward)}'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> treesJson = data['trees'] ?? [];
        
        return treesJson.map((json) => Tree.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get ward trees: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get ward trees: $e');
    }
  }

  // Get heritage trees
  Future<List<Tree>> getHeritageTrees() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiEndpoints.heritageTree}'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> treesJson = data['trees'] ?? [];
        
        return treesJson.map((json) => Tree.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get heritage trees: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get heritage trees: $e');
    }
  }

  // Add new tree
  Future<Tree> addTree(Tree tree) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl${ApiEndpoints.trees}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(tree.toJson()),
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final newTree = Tree.fromJson(data['tree']);
        
        // Cache the new tree
        await _treeBox.put(newTree.id, newTree);
        
        return newTree;
      } else {
        throw Exception('Failed to add tree: ${response.statusCode}');
      }
    } catch (e) {
      // Store offline for later sync
      await _storeOfflineAction('add', tree);
      throw Exception('Failed to add tree: $e');
    }
  }

  // Update existing tree
  Future<Tree> updateTree(Tree tree) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl${ApiEndpoints.treeById.replaceAll('{id}', tree.id)}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(tree.toJson()),
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedTree = Tree.fromJson(data['tree']);
        
        // Update cache
        await _treeBox.put(updatedTree.id, updatedTree);
        
        return updatedTree;
      } else {
        throw Exception('Failed to update tree: ${response.statusCode}');
      }
    } catch (e) {
      // Store offline for later sync
      await _storeOfflineAction('update', tree);
      throw Exception('Failed to update tree: $e');
    }
  }

  // Delete tree
  Future<void> deleteTree(String treeId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl${ApiEndpoints.treeById.replaceAll('{id}', treeId)}'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        // Remove from cache
        await _treeBox.delete(treeId);
      } else {
        throw Exception('Failed to delete tree: ${response.statusCode}');
      }
    } catch (e) {
      // Store offline for later sync
      await _storeOfflineAction('delete', Tree(
        id: treeId,
        species: '',
        localName: '',
        lat: 0,
        lng: 0,
        height: 0,
        girth: 0,
        age: 0,
        heritage: false,
        ward: '',
        health: TreeHealth.healthy,
        canopy: 0,
        ownership: TreeOwnership.government,
      ));
      throw Exception('Failed to delete tree: $e');
    }
  }

  // Upload tree images
  Future<List<String>> uploadTreeImages(String treeId, List<File> images) async {
    try {
      final uploadedUrls = <String>[];

      for (final image in images) {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$_baseUrl${ApiEndpoints.fileUpload}'),
        );

        request.fields['treeId'] = treeId;
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );

        final response = await request.send().timeout(AppConstants.uploadTimeout);
        
        if (response.statusCode == 200) {
          final responseData = await response.stream.bytesToString();
          final data = jsonDecode(responseData);
          uploadedUrls.add(data['url']);
        } else {
          throw Exception('Failed to upload image: ${response.statusCode}');
        }
      }

      return uploadedUrls;
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }

  // Export trees data
  Future<String> exportTrees({
    required List<Tree> trees,
    String format = 'csv',
    List<String>? fields,
  }) async {
    try {
      if (format.toLowerCase() == 'csv') {
        return _exportToCSV(trees, fields);
      } else if (format.toLowerCase() == 'json') {
        return _exportToJSON(trees, fields);
      } else {
        throw Exception('Unsupported export format: $format');
      }
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  // Sync offline data
  Future<void> syncOfflineData() async {
    try {
      final offlineBox = await Hive.openBox('offline_actions');
      final actions = offlineBox.values.toList();

      for (final action in actions) {
        try {
          final actionData = Map<String, dynamic>.from(action);
          final actionType = actionData['type'];
          final treeData = actionData['tree'];
          final tree = Tree.fromJson(treeData);

          switch (actionType) {
            case 'add':
              await addTree(tree);
              break;
            case 'update':
              await updateTree(tree);
              break;
            case 'delete':
              await deleteTree(tree.id);
              break;
          }

          // Remove synced action
          await offlineBox.delete(action.key);
        } catch (e) {
          print('Failed to sync action: $e');
        }
      }
    } catch (e) {
      throw Exception('Failed to sync offline data: $e');
    }
  }

  // Private helper methods

  Future<void> _cacheTreesLocally(List<Tree> trees) async {
    try {
      await _treeBox.clear();
      for (final tree in trees) {
        await _treeBox.put(tree.id, tree);
      }
    } catch (e) {
      print('Error caching trees: $e');
    }
  }

  List<Tree> _searchTreesLocally({
    String? query,
    TreeHealth? health,
    String? ward,
    bool? heritage,
  }) {
    final allTrees = _treeBox.values.toList();
    
    return allTrees.where((tree) {
      if (query != null && query.isNotEmpty) {
        final searchQuery = query.toLowerCase();
        final matchesQuery = tree.species.toLowerCase().contains(searchQuery) ||
            tree.localName.toLowerCase().contains(searchQuery) ||
            tree.ward.toLowerCase().contains(searchQuery) ||
            tree.id.toLowerCase().contains(searchQuery);
        if (!matchesQuery) return false;
      }

      if (health != null && tree.health != health) {
        return false;
      }

      if (ward != null && tree.ward != ward) {
        return false;
      }

      if (heritage != null && tree.heritage != heritage) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void> _storeOfflineAction(String type, Tree tree) async {
    try {
      final offlineBox = await Hive.openBox('offline_actions');
      final actionId = DateTime.now().millisecondsSinceEpoch.toString();
      
      await offlineBox.put(actionId, {
        'type': type,
        'tree': tree.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error storing offline action: $e');
    }
  }

  String _exportToCSV(List<Tree> trees, List<String>? fields) {
    final selectedFields = fields ?? [
      'id', 'species', 'localName', 'lat', 'lng', 'height', 'girth', 
      'age', 'heritage', 'ward', 'health', 'canopy', 'ownership'
    ];

    final csvLines = <String>[];
    
    // Header
    csvLines.add(selectedFields.join(','));
    
    // Data rows
    for (final tree in trees) {
      final row = selectedFields.map((field) {
        switch (field) {
          case 'id':
            return tree.id;
          case 'species':
            return tree.species;
          case 'localName':
            return tree.localName;
          case 'lat':
            return tree.lat.toString();
          case 'lng':
            return tree.lng.toString();
          case 'height':
            return tree.height.toString();
          case 'girth':
            return tree.girth.toString();
          case 'age':
            return tree.age.toString();
          case 'heritage':
            return tree.heritage.toString();
          case 'ward':
            return tree.ward;
          case 'health':
            return tree.health.displayName;
          case 'canopy':
            return tree.canopy.toString();
          case 'ownership':
            return tree.ownership.displayName;
          default:
            return '';
        }
      }).join(',');
      
      csvLines.add(row);
    }
    
    return csvLines.join('\n');
  }

  String _exportToJSON(List<Tree> trees, List<String>? fields) {
    if (fields == null) {
      return jsonEncode(trees.map((tree) => tree.toJson()).toList());
    }

    final filteredTrees = trees.map((tree) {
      final treeJson = tree.toJson();
      final filteredJson = <String, dynamic>{};
      
      for (final field in fields) {
        if (treeJson.containsKey(field)) {
          filteredJson[field] = treeJson[field];
        }
      }
      
      return filteredJson;
    }).toList();

    return jsonEncode(filteredTrees);
  }
}
