import 'package:flutter/material.dart';
import 'meal_planner_screen.dart';

// Deprecated: PlanningHomeScreen now directly routes to MealPlannerScreen overview.
class PlanningHomeScreen extends StatelessWidget {
  const PlanningHomeScreen({super.key});
  @override
  Widget build(BuildContext context) => const MealPlannerScreen();
}
