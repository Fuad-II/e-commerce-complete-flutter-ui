import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shop/models/product_model.dart';

class CmsScreen extends StatefulWidget {
  const CmsScreen({super.key});

  @override
  State<CmsScreen> createState() => _CmsScreenState();
}

class _CmsScreenState extends State<CmsScreen> {
  List<ProductModel> _currentProducts =
      List<ProductModel>.of(demoPopularProducts);
  bool _isLoading = false;

  void _loadDemo() {
    setState(() {
      _currentProducts = demoPopularProducts;
      _isLoading = false;
    });
  }

  void _flush() {
    setState(() {
      _currentProducts = [];
      _isLoading = false;
    });
  }

  Future<void> _uploadJson() async {
    setState(() => _isLoading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (!mounted || result == null) return;

      final bytes = result.files.single.bytes;
      if (bytes == null) {
        throw const FormatException('The selected file could not be read.');
      }
      final loaded = productModelFromJson(utf8.decode(bytes));
      setState(() {
        _currentProducts = loaded;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loaded ${loaded.length} products.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load catalog: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FlutterShop CMS')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _loadDemo,
                  icon: const Icon(Icons.star),
                  label: const Text('Load Demo Data'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _flush,
                  icon: const Icon(Icons.delete),
                  label: const Text('Flush (Clear)'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _uploadJson,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload JSON Catalog'),
                ),
              ],
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Products loaded: ${_currentProducts.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: _currentProducts.isEmpty
                ? const Center(
                    child: Text(
                        'No products — upload a catalog or load demo data.'),
                  )
                : ListView.separated(
                    itemCount: _currentProducts.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final product = _currentProducts[index];
                      return ListTile(
                        title: Text(product.title),
                        subtitle: Text(product.brandName),
                        trailing: Text('\$${product.price.toStringAsFixed(2)}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
