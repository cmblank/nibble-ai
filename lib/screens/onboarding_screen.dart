import 'package:flutter/material.dart';
import '../utils/profile_storage.dart';

class CookingProfileOnboarding extends StatefulWidget {
  final VoidCallback onFinish;
  final Map<String, dynamic>? initialData;

  const CookingProfileOnboarding({
    super.key,
    required this.onFinish,
    this.initialData,
  });

  @override
  State<CookingProfileOnboarding> createState() => _CookingProfileOnboardingState();
}

class _CookingProfileOnboardingState extends State<CookingProfileOnboarding> {
  int currentStep = 0;
  
  // Profile data
  String userName = '';
  String selectedExperience = '';
  List<String> selectedDiets = [];
  List<String> selectedAllergies = [];
  List<String> selectedCuisines = [];
  String selectedCookingTime = '';
  String selectedBudget = '';

  final List<String> experienceLevels = [
    'Beginner - I\'m just starting my cooking journey!',
    'Intermediate - I can follow recipes confidently',
    'Advanced - I love experimenting in the kitchen',
    'Expert - I could teach others to cook'
  ];

  final List<String> dietaryPreferences = [
    'Vegetarian',
    'Vegan',
    'Pescatarian',
    'Keto',
    'Paleo',
    'Mediterranean',
    'Low-carb',
    'No restrictions'
  ];

  final List<String> commonAllergies = [
    'Nuts',
    'Dairy',
    'Gluten',
    'Shellfish',
    'Eggs',
    'Soy',
    'Fish',
    'None'
  ];

  final List<String> cuisineTypes = [
    'Italian',
    'Mexican',
    'Asian',
    'Mediterranean',
    'American',
    'Indian',
    'French',
    'Thai'
  ];

  final List<String> cookingTimes = [
    '15 minutes or less',
    '15-30 minutes',
    '30-60 minutes',
    'Over 1 hour',
    'I have all day!'
  ];

  final List<String> budgetRanges = [
    'Very budget-friendly (\$)',
    'Moderate (\$\$)',
    'Higher-end (\$\$\$)',
    'No budget concerns'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _loadInitialData();
    }
  }

  void _loadInitialData() {
    final data = widget.initialData!;
    userName = data['name'] ?? '';
    selectedExperience = data['experience'] ?? '';
    selectedDiets = List<String>.from(data['diets'] ?? []);
    selectedAllergies = List<String>.from(data['allergies'] ?? []);
    selectedCuisines = List<String>.from(data['cuisines'] ?? []);
    selectedCookingTime = data['cookingTime'] ?? '';
    selectedBudget = data['budget'] ?? '';
  }

  void _nextStep() {
    if (currentStep < 7) {
      setState(() {
        currentStep++;
      });
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentStep == 0) {
      return _buildWelcomeScreen();
    } else if (currentStep == 1) {
      return _buildNameScreen();
    } else if (currentStep == 8) {
      return _buildCompletionScreen();
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF374151)),
          onPressed: _previousStep,
        ),
        actions: [
          TextButton(
            onPressed: _saveAndFinish,
            child: const Text(
              'Skip',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: currentStep / 8,
              minHeight: 6,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
            ),
            const SizedBox(height: 32),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: _buildCurrentStepContent(),
              ),
            ),
            
            // Navigation buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: currentStep > 1 ? _previousStep : null,
                  child: Text(
                    'Back',
                    style: TextStyle(
                      color: currentStep > 1 ? const Color(0xFF6B7280) : Colors.transparent,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _canProceed() ? (currentStep == 7 ? _saveAndFinish : _nextStep) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(currentStep == 7 ? 'Complete Setup' : 'Continue'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Chef Squire Mascot
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF059669),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    // Chef hat
                    Positioned(
                      top: 15,
                      child: Text('👨‍🍳', style: TextStyle(fontSize: 40)),
                    ),
                    // Leaf accent
                    Positioned(
                      bottom: 15,
                      right: 15,
                      child: Text('🍃', style: TextStyle(fontSize: 20)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                '👋 Welcome to Nibble!',
                style: TextStyle(
                  fontSize: 32, 
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your cozy cooking companion is here! I\'m Chef Squire, and I\'m excited to help you cook with more joy and less stress.',
                style: TextStyle(
                  fontSize: 18,
                  height: 1.4,
                  color: Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Let\'s set up your cooking profile so I can be genuinely helpful and make your kitchen adventures feel effortless!',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF9CA3AF),
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Start My Cooking Journey',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: 1 / 8,
                minHeight: 6,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
              ),
              const SizedBox(height: 32),
              const Text(
                'Let\'s get acquainted',
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.w700, 
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('👨‍🍳', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'First things first — what should I call you, Chef?',
                        style: TextStyle(
                          fontSize: 16, 
                          height: 1.5, 
                          color: Color(0xFF374151),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'What should I call you?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: userName,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
                  ),
                  hintText: 'Chef [Your Name]',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onChanged: (val) => setState(() => userName = val),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _previousStep,
                    child: const Text('Back', style: TextStyle(color: Color(0xFF6B7280))),
                  ),
                  ElevatedButton(
                    onPressed: userName.isNotEmpty ? _nextStep : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Continue Cooking Journey', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF059669),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Text('✨', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Wonderful, Chef ${userName.isNotEmpty ? userName : 'there'}!',
                style: const TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.w700, 
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'I\'ve got everything I need to be your perfect cooking companion. Let\'s take the pressure off and focus on what feels achievable and delicious.',
                style: TextStyle(
                  fontSize: 18, 
                  height: 1.5, 
                  color: Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Ready to create something amazing in your kitchen?',
                style: TextStyle(
                  fontSize: 16, 
                  color: Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Start Cooking with Nibble!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (currentStep) {
      case 2:
        return _buildExperienceStep();
      case 3:
        return _buildDietStep();
      case 4:
        return _buildAllergiesStep();
      case 5:
        return _buildCuisinesStep();
      case 6:
        return _buildTimeStep();
      case 7:
        return _buildBudgetStep();
      default:
        return Container();
    }
  }

  bool _canProceed() {
    switch (currentStep) {
      case 1:
        return userName.isNotEmpty;
      case 2:
        return selectedExperience.isNotEmpty;
      case 3:
        return selectedDiets.isNotEmpty;
      case 4:
        return selectedAllergies.isNotEmpty;
      case 5:
        return selectedCuisines.isNotEmpty;
      case 6:
        return selectedCookingTime.isNotEmpty;
      case 7:
        return selectedBudget.isNotEmpty;
      default:
        return true;
    }
  }

  Widget _buildExperienceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What\'s your cooking experience level?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'This helps me suggest recipes that match your skill level and comfort zone.',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        ...experienceLevels.map((level) => _buildOptionTile(
              level,
              selectedExperience == level,
              () => setState(() => selectedExperience = level),
            )),
      ],
    );
  }

  Widget _buildDietStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Any dietary preferences?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select all that apply so I can tailor your recipe suggestions perfectly.',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        _buildMultiSelectPills(
          options: dietaryPreferences,
          selectedOptions: selectedDiets,
          onSelectionChanged: (diet) {
            setState(() {
              if (selectedDiets.contains(diet)) {
                selectedDiets.remove(diet);
              } else {
                selectedDiets.add(diet);
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildAllergiesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Any food allergies or restrictions?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'I\'ll make sure to keep these completely out of your recommendations for safe cooking.',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        _buildMultiSelectPills(
          options: commonAllergies,
          selectedOptions: selectedAllergies,
          onSelectionChanged: (allergy) {
            setState(() {
              if (selectedAllergies.contains(allergy)) {
                selectedAllergies.remove(allergy);
              } else {
                selectedAllergies.add(allergy);
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildCuisinesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What cuisines make you excited to cook?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose your favorites so I can fill your feed with flavors you\'ll love exploring.',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        _buildMultiSelectPills(
          options: cuisineTypes,
          selectedOptions: selectedCuisines,
          onSelectionChanged: (cuisine) {
            setState(() {
              if (selectedCuisines.contains(cuisine)) {
                selectedCuisines.remove(cuisine);
              } else {
                selectedCuisines.add(cuisine);
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildTimeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How much time do you usually have for cooking?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'I\'ll prioritize recipes that fit comfortably into your schedule without stress.',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        ...cookingTimes.map((time) => _buildOptionTile(
              time,
              selectedCookingTime == time,
              () => setState(() => selectedCookingTime = time),
            )),
      ],
    );
  }

  Widget _buildBudgetStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What\'s your typical grocery budget?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'This helps me suggest recipes with ingredients that work for your budget and lifestyle.',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        ...budgetRanges.map((budget) => _buildOptionTile(
              budget,
              selectedBudget == budget,
              () => setState(() => selectedBudget = budget),
            )),
      ],
    );
  }

  Widget _buildOptionTile(String title, bool isSelected, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF059669).withOpacity(0.1) : Colors.white,
            border: Border.all(
              color: isSelected ? const Color(0xFF059669) : const Color(0xFFE5E7EB),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected ? [
              BoxShadow(
                color: const Color(0xFF059669).withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF059669) : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF059669) : const Color(0xFF9CA3AF),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? const Color(0xFF059669) : const Color(0xFF374151),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectPills({
    required List<String> options,
    required List<String> selectedOptions,
    required Function(String) onSelectionChanged,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.map((option) {
        final isSelected = selectedOptions.contains(option);
        return GestureDetector(
          onTap: () => onSelectionChanged(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF059669) : Colors.white,
              border: Border.all(
                color: isSelected ? const Color(0xFF059669) : const Color(0xFFE5E7EB),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: const Color(0xFF059669).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  option,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _saveAndFinish() async {
    final profileData = {
      'name': userName,
      'experience': selectedExperience,
      'diets': selectedDiets,
      'allergies': selectedAllergies,
      'cuisines': selectedCuisines,
      'cookingTime': selectedCookingTime,
      'budget': selectedBudget,
      'completedAt': DateTime.now().toIso8601String(),
    };

    await ProfileStorage.saveProfile(profileData);
    widget.onFinish();
  }
}

// Welcome Step with Chef Mascot
class _WelcomeStep extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomeStep({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          // Chef Squire Mascot
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF059669),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Stack(
              alignment: Alignment.center,
              children: [
                // Chef hat
                Positioned(
                  top: 15,
                  child: Text('👨‍🍳', style: TextStyle(fontSize: 40)),
                ),
                // Leaf accent
                Positioned(
                  bottom: 15,
                  right: 15,
                  child: Text('🍃', style: TextStyle(fontSize: 20)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            '👋 Welcome to Nibble!',
            style: TextStyle(
              fontSize: 32, 
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your cozy cooking companion is here! I\'m Chef Squire, and I\'m excited to help you cook with more joy and less stress.',
            style: TextStyle(
              fontSize: 18,
              height: 1.4,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Let\'s set up your cooking profile so I can be genuinely helpful and make your kitchen adventures feel effortless!',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF9CA3AF),
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Start My Cooking Journey',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Basic Info Step (simplified for now)
class _BasicInfoStep extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final Map<String, dynamic> formData;
  final int step;
  const _BasicInfoStep({required this.onNext, required this.onBack, required this.formData, required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepperHeader(step: step, title: 'Let\'s get acquainted'),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('👨‍�', style: TextStyle(fontSize: 24)),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'First things first — what should I call you, Chef?',
                    style: TextStyle(
                      fontSize: 16, 
                      height: 1.5, 
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'What should I call you?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: formData['name'] ?? '',
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
              ),
              hintText: 'Chef [Your Name]',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: (val) => formData['name'] = val,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: onBack,
                child: const Text('Back', style: TextStyle(color: Color(0xFF6B7280))),
              ),
              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Continue Cooking Journey', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Finish Step
class _FinishStep extends StatelessWidget {
  final VoidCallback onFinish;
  final VoidCallback onBack;
  final Map<String, dynamic> formData;
  const _FinishStep({required this.onFinish, required this.onBack, required this.formData});

  @override
  Widget build(BuildContext context) {
    String userName = formData['name'] ?? 'there';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF059669),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: Text('✨', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Wonderful, Chef $userName!',
            style: const TextStyle(
              fontSize: 28, 
              fontWeight: FontWeight.w700, 
              color: Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'I\'ve got everything I need to be your perfect cooking companion. Let\'s take the pressure off and focus on what feels achievable and delicious.',
            style: TextStyle(
              fontSize: 18, 
              height: 1.5, 
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Ready to create something amazing in your kitchen?',
            style: TextStyle(
              fontSize: 16, 
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await ProfileStorage.saveProfile(formData);
                onFinish();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'Start Cooking with Nibble!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onBack,
            child: const Text('Back', style: TextStyle(color: Color(0xFF6B7280))),
          ),
        ],
      ),
    );
  }
}

// Stepper Header
class StepperHeader extends StatelessWidget {
  final int step;
  final String title;
  const StepperHeader({super.key, required this.step, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: step / 2, // 2 steps for now
          minHeight: 6,
          backgroundColor: const Color(0xFFE5E7EB),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24, 
            fontWeight: FontWeight.w700, 
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}