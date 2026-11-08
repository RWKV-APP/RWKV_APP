import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/web_search_mode.dart';
import 'package:zone/model/web_search_provider.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/web_search_provider_icon.dart';

class WebSearchSettingsPanel extends ConsumerStatefulWidget {
  final WebSearchProvider? provider;

  const WebSearchSettingsPanel({super.key, this.provider});

  static bool _shown = false;

  static Future<void> show({WebSearchProvider? provider, BuildContext? context}) async {
    if (_shown) return;
    context ??= getContext();
    if (context == null || !context.mounted) return;
    _shown = true;
    try {
      await showDialog<void>(
        context: context,
        builder: (_) => WebSearchSettingsPanel(provider: provider),
      );
    } finally {
      P.chat.onWebSearchSettingsClosed();
      _shown = false;
    }
  }

  @override
  ConsumerState<WebSearchSettingsPanel> createState() => _WebSearchSettingsPanelState();
}

class _WebSearchSettingsPanelState extends ConsumerState<WebSearchSettingsPanel> {
  late WebSearchProvider provider;

  @override
  void initState() {
    super.initState();
    provider = widget.provider ?? P.chat.webSearchProvider.q;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final activeProvider = ref.watch(P.chat.webSearchProvider);
    final enabled = ref.watch(P.chat.webSearchMode) != WebSearchMode.off && activeProvider == provider;
    final generating = ref.watch(P.rwkvGeneration.generating);
    final loadingKeys = ref.watch(P.chat.webSearchKeysLoading);
    final storageError = ref.watch(P.chat.webSearchStorageError);
    final checks = ref.watch(P.chat.webSearchChecks);
    final checking = checks.values.any((value) => value.isLoading);
    final check = checks[provider];
    final keyEntered = (ref.watch(P.chat.webSearchApiKeys)[provider.credentialId] ?? '').isNotEmpty;
    final isDesktop = ref.watch(P.app.isDesktop);
    final allowance = P.chat.searchProviderAllowance(provider);
    return AlertDialog(
      title: Text(s.web_search_settings),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<WebSearchProvider>(
                initialValue: provider,
                isExpanded: true,
                decoration: InputDecoration(labelText: s.web_search_provider, border: const OutlineInputBorder()),
                items: [
                  for (final value in WebSearchProvider.values)
                    if (value != .browser || isDesktop)
                      DropdownMenuItem(
                        value: value,
                        child: Row(
                          children: [
                            WebSearchProviderIcon(provider: value, size: 20),
                            const SizedBox(width: 8),
                            Flexible(child: Text(P.chat.searchProviderLabel(value))),
                          ],
                        ),
                      ),
                ],
                onChanged: generating || checking || loadingKeys ? null : (value) => setState(() => provider = value!),
              ),
              if (provider == .zhihuGlobal || provider == .zhihuSite) ...[
                const SizedBox(height: 16),
                Text('${s.web_search_zhihu_global}: ${s.web_search_zhihu_web_description}', style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                Text('${s.web_search_zhihu_site}: ${s.web_search_zhihu_site_description}', style: theme.textTheme.bodySmall),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Text(s.web_search)),
                  Switch(
                    value: enabled,
                    onChanged: generating || checking || loadingKeys
                        ? null
                        : (value) => P.chat.onWebSearchProviderEnabledChanged(provider, value),
                  ),
                ],
              ),
              if (provider.credentialId.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(s.web_search_own_key_notice, style: theme.textTheme.bodySmall),
                if (!provider.requiresApiKey) ...[
                  const SizedBox(height: 8),
                  Text(s.web_search_optional_key_notice, style: theme.textTheme.bodySmall),
                ],
                const SizedBox(height: 12),
                _SearchKeyGuide(provider: provider),
                const SizedBox(height: 20),
                _SearchCredentialField(key: ValueKey(provider.credentialId), provider: provider),
                const SizedBox(height: 8),
                Text(s.web_search_key_auto_apply, style: theme.textTheme.bodySmall),
                const SizedBox(height: 12),
                Text(s.web_search_validation_notice, style: theme.textTheme.bodySmall),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: generating || checking || loadingKeys || (provider.requiresApiKey && !keyEntered)
                      ? null
                      : () => P.chat.onVerifyAndEnableWebSearchProvider(provider),
                  icon: checking
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.verified_user_outlined, size: 18),
                  label: Text(s.web_search_validate_enable),
                ),
                if (check != null) ...[
                  const SizedBox(height: 8),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      P.chat.webSearchValidationText(check),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: check.hasError ? theme.colorScheme.error : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(s.web_search_saved_key_notice, style: theme.textTheme.bodySmall),
                if (storageError) ...[
                  const SizedBox(height: 8),
                  Text(s.web_search_storage_error, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                  Align(
                    alignment: .centerLeft,
                    child: TextButton.icon(
                      onPressed: generating || checking || loadingKeys ? null : P.chat.restoreWebSearchCredentials,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text(s.web_search_reload_saved_keys),
                    ),
                  ),
                ],
              ],
              if (allowance.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(allowance, style: theme.textTheme.bodySmall),
                const SizedBox(height: 6),
                Text(s.web_search_allowance_notice, style: theme.textTheme.bodySmall),
                Align(
                  alignment: .centerLeft,
                  child: TextButton.icon(
                    onPressed: () => P.chat.onWebSearchProviderLinkTapped(provider, pricing: true),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text(s.web_search_pricing),
                  ),
                ),
              ],
              if (provider == .anysearch) ...[
                const SizedBox(height: 12),
                Text(s.web_search_anysearch_notice, style: theme.textTheme.bodySmall),
                Align(
                  alignment: .centerLeft,
                  child: TextButton.icon(
                    onPressed: () => P.chat.onWebSearchProviderLinkTapped(provider),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text(s.web_search_official_docs),
                  ),
                ),
              ],
              if (provider == .browser) ...[
                const SizedBox(height: 12),
                Text(s.web_search_browser_notice, style: theme.textTheme.bodySmall),
              ],
              const SizedBox(height: 20),
              Text(s.web_search_privacy_notice, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(s.close))],
    );
  }
}

class _SearchKeyGuide extends StatelessWidget {
  final WebSearchProvider provider;

  const _SearchKeyGuide({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Text(s.web_search_key_help_title, style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        Text(
          switch (provider) {
            .deepseek => s.web_search_deepseek_key_steps,
            .zhihuGlobal || .zhihuSite => s.web_search_zhihu_key_steps,
            _ => s.web_search_generic_key_steps,
          },
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            TextButton.icon(
              onPressed: () => P.chat.onWebSearchProviderLinkTapped(provider, manageKey: true),
              icon: const Icon(Icons.key, size: 16),
              label: Text(s.web_search_get_key),
            ),
            TextButton.icon(
              onPressed: () => P.chat.onWebSearchProviderLinkTapped(provider),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(s.web_search_official_docs),
            ),
          ],
        ),
      ],
    );
  }
}

class _SearchCredentialField extends ConsumerStatefulWidget {
  final WebSearchProvider provider;

  const _SearchCredentialField({super.key, required this.provider});

  @override
  ConsumerState<_SearchCredentialField> createState() => _SearchCredentialFieldState();
}

class _SearchCredentialFieldState extends ConsumerState<_SearchCredentialField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final configured = (ref.watch(P.chat.webSearchApiKeys)[widget.provider.credentialId] ?? '').isNotEmpty;
    final generating = ref.watch(P.rwkvGeneration.generating);
    final checking = ref.watch(P.chat.webSearchChecks).values.any((value) => value.isLoading);
    final loadingKeys = ref.watch(P.chat.webSearchKeysLoading);
    return TextField(
      controller: _controller,
      enabled: !generating && !checking && !loadingKeys,
      obscureText: true,
      autocorrect: false,
      enableSuggestions: false,
      enableIMEPersonalizedLearning: false,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: widget.provider == .zhihuGlobal || widget.provider == .zhihuSite
            ? 'Zhihu Access Secret'
            : '${P.chat.searchProviderLabel(widget.provider)} API Key',
        hintText: configured
            ? s.web_search_key_configured
            : widget.provider.requiresApiKey
            ? s.web_search_missing_key
            : null,
        helperText: configured ? s.web_search_key_configured : null,
        helperMaxLines: 2,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          tooltip: s.clear,
          onPressed: generating || checking || loadingKeys
              ? null
              : () {
                  _controller.clear();
                  P.chat.onWebSearchKeyChanged(widget.provider, '');
                },
          icon: const Icon(Icons.clear),
        ),
      ),
      onChanged: (value) => P.chat.onWebSearchKeyChanged(widget.provider, value),
    );
  }
}
