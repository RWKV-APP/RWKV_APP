// Project imports:
import 'package:zone/model/app_style.dart';

enum NavigationArrangement { editorial, rail, topTabs, dock, commandBar, compact, segmented }

enum LauncherArrangement { editorial, dashboard, studio, ledger, focus, workshop, console, directory, device }

enum SettingsArrangement { directory, dashboard, groups }

enum WorkspaceArrangement { reading, split, framed, focus, console, compact }

enum PromptArrangement { rows, grid, feature, centered }

enum AppPresentation {
  editorial(.editorial, .editorial, .directory, .reading, .rows),
  dashboard(.rail, .dashboard, .dashboard, .split, .grid),
  studio(.topTabs, .studio, .dashboard, .framed, .feature),
  ledger(.rail, .ledger, .directory, .split, .rows),
  focus(.dock, .focus, .groups, .focus, .centered),
  workshop(.editorial, .workshop, .dashboard, .framed, .rows),
  console(.commandBar, .console, .directory, .console, .grid),
  directory(.compact, .directory, .groups, .compact, .rows),
  device(.segmented, .device, .groups, .framed, .centered);

  const AppPresentation(this.navigation, this.launcher, this.settings, this.workspace, this.prompts);

  final NavigationArrangement navigation;
  final LauncherArrangement launcher;
  final SettingsArrangement settings;
  final WorkspaceArrangement workspace;
  final PromptArrangement prompts;

  static AppPresentation? forStyle(AppStyle style) => switch (style) {
    .classic => null,
    .anthropic => .editorial,
    .proMax => .dashboard,
    .taste => .studio,
    .impeccable => .ledger,
    .emil => .focus,
    .hallmark => .workshop,
    .vercel => .console,
    .uiSkills => .directory,
    .smartisan => .device,
  };

  double get readingWidth => switch (workspace) {
    .reading => 780,
    .focus => 720,
    .console => 1180,
    .compact => 920,
    _ => 1260,
  };
}
