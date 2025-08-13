import 'package:flutter/material.dart';
import '../models/pantry_item.dart';
import '../models/pantry_enums.dart';

class PantryItemTile extends StatelessWidget {
  final PantryItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const PantryItemTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final daysUntilExpiry = item.expirationDate.difference(DateTime.now()).inDays;
    final isExpired = daysUntilExpiry < 0;
    final isExpiringSoon = daysUntilExpiry > 0 && daysUntilExpiry <= 7;

    return Dismissible(
      key: Key(item.id ?? item.name),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Item'),
              content: Text('Are you sure you want to delete ${item.name}?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) => onDelete(),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16.0),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: _buildCategoryIcon(),
        title: Text(
          item.name,
          style: TextStyle(
            color: isExpired ? Colors.red : null,
            fontWeight: isExpiringSoon ? FontWeight.bold : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.details != null)
              Text(item.details!),
            Text(
              'Expires: ${_formatDate(item.expirationDate)}',
              style: TextStyle(
                color: isExpired ? Colors.red : (isExpiringSoon ? Colors.orange : null),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.isLowStock)
              const Icon(
                Icons.warning,
                color: Colors.orange,
              ),
            const SizedBox(width: 8),
            Icon(
              _getLocationIcon(),
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIcon() {
    IconData iconData;
    switch (item.category) {
      case FoodCategory.produce:
        iconData = Icons.eco; break;
      case FoodCategory.dairy:
        iconData = Icons.water_drop; break;
      case FoodCategory.grains:
        iconData = Icons.rice_bowl; break;
      case FoodCategory.protein:
        iconData = Icons.restaurant; break;
      case FoodCategory.baking:
        iconData = Icons.cookie; break;
      case FoodCategory.herbsAndSpices:
        iconData = Icons.local_florist; break;
      case FoodCategory.bakery:
        iconData = Icons.bakery_dining; break;
      case FoodCategory.condiments:
        iconData = Icons.room_service; break;
      case FoodCategory.frozenFoods:
        iconData = Icons.ac_unit; break;
      case FoodCategory.beverages:
        iconData = Icons.local_drink; break;
      case FoodCategory.snacks:
        iconData = Icons.fastfood; break;
      case FoodCategory.other:
        iconData = Icons.help_outline; break;
    }

    return CircleAvatar(
      backgroundColor: Colors.grey[200],
      child: Icon(
        iconData,
        color: Colors.grey[600],
      ),
    );
  }

  IconData _getLocationIcon() {
    switch (item.storageLocation) {
      case StorageLocation.pantry:
        return Icons.kitchen;
      case StorageLocation.fridge:
        return Icons.kitchen_outlined;
      case StorageLocation.freezer:
        return Icons.ac_unit;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
