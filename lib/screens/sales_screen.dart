import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mysoul/models/perfume.dart';
import 'package:mysoul/services/firestore_service.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String? _selectedPerfumeId;

  /// perfumeId -> quantity
  final Map<String, int> _selectedPerfumes = {};

  List<Perfume> _perfumes = [];
  bool _isLoading = false;
  bool _isLoadingPerfumes = true;

  @override
  void initState() {
    super.initState();
    _loadPerfumes();
  }

  Future<void> _loadPerfumes() async {
    try {
      final firestoreService =
      Provider.of<FirestoreService>(context, listen: false);
      _perfumes = await firestoreService.getPerfumesForDropdown();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading perfumes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoadingPerfumes = false);
    }
  }

  /// ➕ Add perfume to sale list
  void _addPerfumeToSale() {
    if (_selectedPerfumeId == null) return;

    final perfume =
    _perfumes.firstWhere((p) => p.id == _selectedPerfumeId);

    if (perfume.quantity <=
        (_selectedPerfumes[_selectedPerfumeId!] ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough stock available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _selectedPerfumes[_selectedPerfumeId!] =
          (_selectedPerfumes[_selectedPerfumeId!] ?? 0) + 1;
      _selectedPerfumeId = null;
    });
  }

  /// ❌ Remove one quantity
  void _removePerfume(String perfumeId) {
    setState(() {
      if (_selectedPerfumes[perfumeId]! > 1) {
        _selectedPerfumes[perfumeId] =
            _selectedPerfumes[perfumeId]! - 1;
      } else {
        _selectedPerfumes.remove(perfumeId);
      }
    });
  }

  /// ✅ Submit sale (REAL Firebase reduction)
  Future<void> _submitSale() async {
    if (_selectedPerfumes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one perfume'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firestoreService =
      Provider.of<FirestoreService>(context, listen: false);

      for (final entry in _selectedPerfumes.entries) {
        await firestoreService.decrementQuantityBy(
          entry.key,
          entry.value,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sale recorded successfully'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _selectedPerfumes.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error recording sale: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Record a Sale',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            /// 🔽 Dropdown
            if (_isLoadingPerfumes)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<String>(
                value: _selectedPerfumeId,
                decoration: const InputDecoration(
                  labelText: 'Select Perfume',
                  border: OutlineInputBorder(),
                ),
                items: _perfumes.map((perfume) {
                  final isOutOfStock = perfume.quantity <= 0;
                  return DropdownMenuItem<String>(
                    value: perfume.id,
                    enabled: !isOutOfStock,
                    child: Text(
                      '${perfume.name} (${perfume.quantity})',
                      style: TextStyle(
                        color:
                        isOutOfStock ? Colors.grey : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedPerfumeId = value);
                },
              ),

            const SizedBox(height: 12),

            /// ➕ Add button
            ElevatedButton.icon(
              onPressed: _addPerfumeToSale,
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            ),

            const SizedBox(height: 30),

            /// 🛒 Selected products list
            const Text(
              'Selected Products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            if (_selectedPerfumes.isEmpty)
              const Text(
                'No products added',
                style: TextStyle(color: Colors.grey),
              )
            else
              Column(
                children: _selectedPerfumes.entries.map((entry) {
                  final perfume = _perfumes
                      .firstWhere((p) => p.id == entry.key);

                  return Card(
                    child: ListTile(
                      title: Text(perfume.name),
                      subtitle: Text('Quantity: ${entry.value}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle,
                            color: Colors.red),
                        onPressed: () =>
                            _removePerfume(entry.key),
                      ),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 30),

            /// ✅ Submit sale
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitSale,
                style: ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                  'Submit Sale',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
