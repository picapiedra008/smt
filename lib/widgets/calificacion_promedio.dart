import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalificacionPromedio extends StatelessWidget {
  final String restaurantId;
  final double? size;
  final Color? color;
  final bool showDetails;

  const CalificacionPromedio({
    super.key,
    required this.restaurantId,
    this.size = 18,
    this.color = Colors.amber,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .snapshots(),
      builder: (context, snapshot) {
        // Manejar estados
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }

        if (snapshot.hasError) {
          return _buildError(snapshot.error.toString());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildNoData();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final averageRate = (data['average_rate'] as num?)?.toDouble() ?? 0.0;


        return _buildRatingDisplay(averageRate);
      },
    );
  }

  Widget _buildLoading() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          color: color?.withOpacity(0.5),
          size: size,
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 20,
          height: size,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ],
    );
  }

  Widget _buildError(String error) {
    debugPrint('Error en CalificacionPromedio: $error');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_border,
          color: Colors.grey,
          size: size,
        ),
        const SizedBox(width: 4),
        Text(
          "-",
          style: TextStyle(
            fontSize: size! * 0.8,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildNoData() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_border,
          color: Colors.grey,
          size: size,
        ),
        const SizedBox(width: 4),
        Text(
          "-",
          style: TextStyle(
            fontSize: size! * 0.8,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingDisplay(double averageRate) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              color: averageRate > 0 ? color : Colors.grey,
              size: size,
            ),
            const SizedBox(width: 4),
            Text(
              averageRate > 0 ? averageRate.toStringAsFixed(1) : "-",
              style: TextStyle(
                fontSize: size! * 0.8,
                fontWeight: FontWeight.w500,
                color: averageRate > 0 ? Colors.black87 : Colors.grey,
              ),
            ),
          ],
        ),
        
      ],
    );
  }
}