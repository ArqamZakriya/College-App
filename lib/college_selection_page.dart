import 'package:flutter/material.dart';

class SearchableDropdown extends StatelessWidget {
  final TextEditingController controller;
  final List<String> items;
  final String hint;
  final IconData icon;
  final Function(String) onSelected;
  final Size size;

  const SearchableDropdown({
    super.key,
    required this.controller,
    required this.items,
    required this.hint,
    required this.icon,
    required this.onSelected,
    required this.size,
  });

  void _showSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SearchModal(
        items: items,
        onSelected: (value) {
          controller.text = value;
          onSelected(value);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSearch(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A237E).withOpacity(0.1),
              const Color(0xFF121212).withOpacity(0.05),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A237E).withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          enabled: false,
          style: TextStyle(
            fontSize: size.width * 0.04,
            color: const Color(0xFF121212),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: const Color(0xFF121212).withOpacity(0.5),
              fontSize: size.width * 0.04,
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF1A237E),
              size: size.width * 0.06,
            ),
            suffixIcon: Icon(
              Icons.arrow_drop_down,
              color: const Color(0xFF1A237E),
              size: size.width * 0.06,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide(
                color: const Color(0xFF1A237E).withOpacity(0.1),
                width: 1,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide(
                color: const Color(0xFF1A237E).withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchModal extends StatefulWidget {
  final List<String> items;
  final Function(String) onSelected;

  const _SearchModal({
    required this.items,
    required this.onSelected,
  });

  @override
  _SearchModalState createState() => _SearchModalState();
}

class _SearchModalState extends State<_SearchModal> {
  final TextEditingController _searchController = TextEditingController();
  List<String> filteredItems = [];

  @override
  void initState() {
    super.initState();
    filteredItems = widget.items;
  }

  void _filterItems(String query) {
    setState(() {
      filteredItems = widget.items
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterItems,
              decoration: const InputDecoration(
                hintText: 'Search College',
                border: InputBorder.none,
                icon: Icon(Icons.search),
              ),
              autofocus: true,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(filteredItems[index]),
                  onTap: () => widget.onSelected(filteredItems[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}