import 'package:flutter/material.dart';
import '../design_tokens/design_tokens.dart';

/// Example Widget demonstrating Design Token usage
/// This shows how to properly use your cb_designSystem tokens in Flutter
class DesignTokensExample extends StatelessWidget {
  const DesignTokensExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BackgroundColors.primary,
      appBar: AppBar(
        title: Text(
          'Design Tokens Example',
          style: TextStyles.heading125.copyWith(color: TextColors.inverse),
        ),
        backgroundColor: BackgroundColors.brand,
        elevation: ElevationTokens.raised,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SpacingTokens.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Typography Examples
            Text(
              'Typography Scale',
              style: TextStyles.heading150.copyWith(color: TextColors.primary),
            ),
            const SizedBox(height: SpacingTokens.spaceMD),
            
            Text('Heading 200', style: TextStyles.heading200),
            Text('Heading 150', style: TextStyles.heading150),
            Text('Heading 125', style: TextStyles.heading125),
            Text('Body 100 - This is body text', style: TextStyles.body100),
            Text('Body 85 - Smaller body text', style: TextStyles.body85),
            Text('Caption text', style: TextStyles.caption),
            
            const SizedBox(height: SpacingTokens.spaceXL),
            
            // Button Examples
            Text(
              'Button Variants',
              style: TextStyles.heading150.copyWith(color: TextColors.primary),
            ),
            const SizedBox(height: SpacingTokens.spaceMD),
            
            // Primary Button (Nibble Brand)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ComponentTokens.primaryButton(),
                child: const Text('Primary Button'),
              ),
            ),
            const SizedBox(height: SpacingTokens.spaceMD),
            
            // Secondary Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: ComponentTokens.secondaryButton(),
                child: const Text('Secondary Button'),
              ),
            ),
            const SizedBox(height: SpacingTokens.spaceMD),
            
            // Text Button
            TextButton(
              onPressed: () {},
              style: ComponentTokens.textButton(),
              child: const Text('Text Button'),
            ),
            
            const SizedBox(height: SpacingTokens.spaceXL),
            
            // Input Field Examples
            Text(
              'Input Fields',
              style: TextStyles.heading150.copyWith(color: TextColors.primary),
            ),
            const SizedBox(height: SpacingTokens.spaceMD),
            
            TextField(
              decoration: ComponentTokens.inputDecoration(
                labelText: 'Standard Input',
                hintText: 'Enter text here',
              ),
            ),
            const SizedBox(height: SpacingTokens.spaceMD),
            
            TextField(
              decoration: ComponentTokens.inputDecoration(
                labelText: 'Input with Icon',
                prefixIcon: const Icon(Icons.email),
              ),
            ),
            const SizedBox(height: SpacingTokens.spaceMD),
            
            TextField(
              decoration: ComponentTokens.inputDecoration(
                labelText: 'Error State',
                errorText: 'This field is required',
              ),
            ),
            
            const SizedBox(height: SpacingTokens.spaceXL),
            
            // Card Examples
            Text(
              'Cards & Containers',
              style: TextStyles.heading150.copyWith(color: TextColors.primary),
            ),
            const SizedBox(height: SpacingTokens.spaceMD),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(SpacingTokens.spaceLG),
              decoration: ComponentTokens.cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Card Title',
                    style: TextStyles.heading125.copyWith(color: TextColors.primary),
                  ),
                  const SizedBox(height: SpacingTokens.spaceSM),
                  Text(
                    'This is a card with proper design token usage for spacing, borders, and shadows.',
                    style: TextStyles.body85.copyWith(color: TextColors.secondary),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: SpacingTokens.spaceXL),
            
            // Color Examples
            Text(
              'Color Palette',
              style: TextStyles.heading150.copyWith(color: TextColors.primary),
            ),
            const SizedBox(height: SpacingTokens.spaceMD),
            
            Wrap(
              spacing: SpacingTokens.spaceSM,
              runSpacing: SpacingTokens.spaceSM,
              children: [
                _colorSwatch('Garden Herb', DesignTokens.gardenHerb),
                _colorSwatch('Nibble Red', DesignTokens.nibbleRed),
                _colorSwatch('Golden Crust', DesignTokens.goldenCrust),
                _colorSwatch('Deep Roast', DesignTokens.deepRoast),
                _colorSwatch('Cream Whisk', DesignTokens.creamWhisk),
                _colorSwatch('Flame Orange', DesignTokens.flameOrange),
              ],
            ),
            
            const SizedBox(height: SpacingTokens.spaceXL),
            
            // Spacing Examples
            Text(
              'Spacing Scale',
              style: TextStyles.heading150.copyWith(color: TextColors.primary),
            ),
            const SizedBox(height: SpacingTokens.spaceMD),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _spacingExample('XS', SpacingTokens.spaceXS),
                _spacingExample('SM', SpacingTokens.spaceSM),
                _spacingExample('MD', SpacingTokens.spaceMD),
                _spacingExample('LG', SpacingTokens.spaceLG),
                _spacingExample('XL', SpacingTokens.spaceXL),
                _spacingExample('2XL', SpacingTokens.space2XL),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _colorSwatch(String name, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(RadiusTokens.lg),
            border: Border.all(color: BorderColors.primary),
          ),
        ),
        const SizedBox(height: SpacingTokens.spaceXS),
        Text(
          name,
          style: TextStyles.body75.copyWith(color: TextColors.secondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _spacingExample(String name, double space) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.spaceSM),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              name,
              style: TextStyles.body75.copyWith(color: TextColors.secondary),
            ),
          ),
          Container(
            width: space,
            height: 16,
            decoration: BoxDecoration(
              color: DesignTokens.gardenHerb.withAlpha((255 * 0.3).round()),
              borderRadius: BorderRadius.circular(RadiusTokens.sm),
            ),
          ),
          const SizedBox(width: SpacingTokens.spaceSM),
          Text(
            '${space.toInt()}px',
            style: TextStyles.body75.copyWith(color: TextColors.secondary),
          ),
        ],
      ),
    );
  }
}
