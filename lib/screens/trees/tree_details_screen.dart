import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/tree_provider.dart';
import '../../models/tree.dart';

class TreeDetailsScreen extends StatefulWidget {
  final String treeId;

  const TreeDetailsScreen({super.key, required this.treeId});

  @override
  State<TreeDetailsScreen> createState() => _TreeDetailsScreenState();
}

class _TreeDetailsScreenState extends State<TreeDetailsScreen> {
  late Future<Tree?> _treeFuture;

  @override
  void initState() {
    super.initState();
    _loadTreeDetails();
  }

  void _loadTreeDetails() {
    final treeProvider = Provider.of<TreeProvider>(context, listen: false);
    _treeFuture = treeProvider.getTreeById(widget.treeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).maybePop();
          },
        ),
        title: const Text('Tree Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.push('/trees/${widget.treeId}/edit');
            },
          ),
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              // TODO: Show tree location on map
            },
          ),
        ],
      ),
      body: FutureBuilder<Tree?>(
        future: _treeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading tree details: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final tree = snapshot.data;
          if (tree == null) {
            return const Center(
              child: Text('Tree not found'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (tree.imageUrl.isNotEmpty) ...[
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(tree.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Tree ID', tree.id),
                        const Divider(),
                        _buildInfoRow('Species', tree.species),
                        const Divider(),
                        _buildInfoRow('Local Name', tree.localName),
                        const Divider(),
                        _buildInfoRow('Scientific Name', tree.scientificName),
                        const Divider(),
                        _buildInfoRow('Age (Years)', tree.age.toString()),
                        const Divider(),
                        _buildInfoRow('Height (m)', tree.height.toString()),
                        const Divider(),
                        _buildInfoRow('Girth (cm)', tree.girth.toString()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Location Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Ward', tree.ward),
                        const Divider(),
                        _buildInfoRow('Area', tree.area),
                        const Divider(),
                        _buildInfoRow('Street', tree.street),
                        const Divider(),
                        _buildInfoRow(
                          'Coordinates',
                          '${tree.latitude}, ${tree.longitude}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Health Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Condition', tree.condition),
                        const Divider(),
                        _buildInfoRow('Health Issues', tree.healthIssues ?? 'None'),
                        const Divider(),
                        _buildInfoRow(
                          'Last Inspected',
                          tree.lastInspectionDate?.toString() ?? 'Not available',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Additional Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          'Surveyed By',
                          tree.surveyedBy ?? 'Not available',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'Survey Date',
                          tree.surveyDate?.toString() ?? 'Not available',
                        ),
                        const Divider(),
                        _buildInfoRow('Notes', tree.notes ?? 'No notes available'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/requests/new', extra: {'treeId': widget.treeId});
        },
        child: const Icon(Icons.report_problem),
        tooltip: 'Report Issue',
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}