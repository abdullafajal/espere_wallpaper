import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const String kLogoAsset = 'assets/brand/logo.png';

/// The Espere app mark: a rounded navy tile with an "E" built from
/// masonry blocks (the middle one in leaf green).
class BrandLogo extends StatelessWidget {
  final double size;

  const BrandLogo({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      kLogoAsset,
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Espere logo',
    );
  }
}

/// Logo + product name, used as the title on the Photos tab.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandLogo(size: 30),
        const SizedBox(width: 10),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: _wordmarkText(theme),
          ),
        ),
      ],
    );
  }

  Widget _wordmarkText(ThemeData theme) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Espere ',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: 'Wallpapers',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      style: theme.textTheme.titleLarge?.copyWith(fontSize: 22),
      maxLines: 1,
    );
  }
}

/// Round account-style button at the end of top bars; opens Settings.
class SettingsAvatarButton extends StatelessWidget {
  const SettingsAvatarButton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        tooltip: 'Settings',
        onPressed: () => context.push('/settings'),
        icon: CircleAvatar(
          radius: 16,
          backgroundColor: cs.primaryContainer,
          child: Icon(
            Icons.person_rounded,
            size: 20,
            color: cs.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
