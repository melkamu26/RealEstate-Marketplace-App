import 'package:flutter/material.dart';
import '../models/property.dart';
import '../services/property_service.dart';

class FavoriteButton extends StatefulWidget {
  final Property property;

  const FavoriteButton({super.key, required this.property});

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool loading = false;
  bool isFav = false;

  @override
  void initState() {
    super.initState();
    checkFav();
  }

  Future<void> checkFav() async {
    final service = PropertyService();

    final snap = await service.favRef.doc(widget.property.propertyId).get();
    setState(() {
      isFav = snap.exists;
    });
  }

  Future<void> toggle() async {
    final service = PropertyService();
    setState(() => loading = true);

    final id = widget.property.propertyId;

    if (isFav) {
      await service.favRef.doc(id).delete();
    } else {
      await service.favRef.doc(id).set(widget.property.toMap());
    }

    setState(() {
      isFav = !isFav;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: loading ? null : toggle,
      icon: Icon(
        Icons.favorite,
        color: isFav ? Colors.red : Colors.grey,
        size: 26,
      ),
    );
  }
}