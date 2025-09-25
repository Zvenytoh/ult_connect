import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  String _selectedCategory = 'Nourriture';
  List<Map<String, dynamic>> _inventory = [];

  final List<String> _categories = ['Nourriture', 'Eau', 'Outil', 'Médicament'];

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('inventory');
    if (data != null) {
      setState(() {
        _inventory = List<Map<String, dynamic>>.from(jsonDecode(data));
      });
    }
  }

  Future<void> _saveInventory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('inventory', jsonEncode(_inventory));
  }

  void _addItem() {
    final name = _nameController.text.trim();
    final qty = int.tryParse(_qtyController.text.trim());

    if (name.isNotEmpty && qty != null && qty > 0) {
      setState(() {
        _inventory.add({
          "name": name,
          "qty": qty,
          "category": _selectedCategory,
          "priority": false,
        });
        _nameController.clear();
        _qtyController.clear();
      });
      _saveInventory();
    }
  }

  void _removeItem(int index) {
    setState(() {
      _inventory.removeAt(index);
    });
    _saveInventory();
  }

  void _increaseQty(int index) {
    setState(() {
      _inventory[index]["qty"]++;
    });
    _saveInventory();
  }

  void _decreaseQty(int index) {
    setState(() {
      if (_inventory[index]["qty"] > 1) {
        _inventory[index]["qty"]--;
      } else {
        _inventory.removeAt(index);
      }
    });
    _saveInventory();
  }

  void _togglePriority(int index) {
    setState(() {
      _inventory[index]["priority"] = !_inventory[index]["priority"];
    });
    _saveInventory();
  }

  Color _getItemColor(Map<String, dynamic> item) {
    if (item["priority"]) return Colors.amber[300]!;
    if (item["qty"] < 3) return Colors.red[100]!;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventaire"),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _inventory.clear();
              });
              _saveInventory();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Formulaire d'ajout
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Nom",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Qté",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedCategory,
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addItem,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 20),

            Expanded(
              child: _inventory.isEmpty
                  ? const Center(
                      child: Text(
                        "Aucune ressource pour l'instant",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _inventory.length,
                      itemBuilder: (context, index) {
                        final item = _inventory[index];
                        return Card(
                          color: _getItemColor(item),
                          child: ListTile(
                            title: Text(item["name"]),
                            subtitle: Text(
                                "Qté: ${item["qty"]} | Catégorie: ${item["category"]}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    item["priority"]
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () => _togglePriority(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove,
                                      color: Colors.red),
                                  onPressed: () => _decreaseQty(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add,
                                      color: Colors.green),
                                  onPressed: () => _increaseQty(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.black54),
                                  onPressed: () => _removeItem(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
