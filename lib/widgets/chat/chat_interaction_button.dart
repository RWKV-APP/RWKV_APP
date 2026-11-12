import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/interaction_visual_state.dart';

class ChatInteractionButton extends ConsumerWidget {
  final String? label;
  final String? tooltip;
  final InteractionVisualState state;
  final Widget Function(Color color, double size) iconBuilder;
  final VoidCallback? onTap;

  const ChatInteractionButton({super.key, this.label, this.tooltip, required this.state, required this.iconBuilder, required this.onTap});

  static double calculateHeight(BuildContext context) => MediaQuery.textScalerOf(context).scale(14) + 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);
    final style = ref.watch(P.preference.appStyle);
    final colors = interactionVisualColors(appTheme: appTheme, state: state, themed: !style.isClassic);
    final useBackdropFilter = style.isClassic && ref.watch(P.ui.useBackdropFilterForInputOptions);
    final alpha = ref.watch(P.ui.backdropFilterBgAlphaForInputOptions);
    final darkModifier = ref.watch(P.ui.backdropFilterBgAlphaForInputOptionsDarkModifier);
    final sigma = ref.watch(P.ui.sigmaForBackdropFilterForInputOptions).toDouble();
    final fontSize = theme.textTheme.bodyMedium?.fontSize ?? 14;
    final corners = BorderRadius.circular(style.isClassic ? 60 : style.radius);
    final text = Text(
      label ?? '',
      maxLines: style.isClassic ? null : 1,
      overflow: style.isClassic ? null : .ellipsis,
      style: TextStyle(color: colors.foreground, fontSize: fontSize, height: 1, fontWeight: .w500),
      strutStyle: StrutStyle(
        fontSize: fontSize,
        height: 1,
        forceStrutHeight: true,
        leadingDistribution: TextLeadingDistribution.even,
      ),
    );

    return Tooltip(
      message: tooltip ?? label ?? '',
      child: Semantics(
        button: true,
        enabled: onTap != null,
        selected: state == .enabled,
        child: IntrinsicWidth(
          child: ClipRRect(
            borderRadius: corners,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              enabled: useBackdropFilter,
              child: Material(
                color: colors.background.withValues(alpha: useBackdropFilter ? alpha * darkModifier : 1),
                shape: RoundedRectangleBorder(
                  borderRadius: corners,
                  side: BorderSide(color: colors.border),
                ),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: corners,
                  child: SizedBox(
                    height: calculateHeight(context),
                    child: Padding(
                      padding: .symmetric(horizontal: style.isClassic ? 8 : 6),
                      child: Row(
                        mainAxisSize: .min,
                        mainAxisAlignment: .center,
                        children: [
                          iconBuilder(colors.foreground, appTheme.inputBarInteractionsIconSize),
                          if (label != null) ...[
                            const SizedBox(width: 4),
                            if (style.isClassic) text else Flexible(child: text),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
