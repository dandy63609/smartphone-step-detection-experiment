import 'package:flutter/material.dart';

import '../../l10n/stradio_strings.dart';
import '../../models/experiment_models.dart';
import '../../theme/stradio_theme.dart';
import 'root_navigation_shell.dart';

/// Music-app style Soundscape & Tempo Catalog screen (`v0.2.0` Milestone 5).
///
/// Follows `assets/images/stradio-reference-1.png` (Screens 2 & 3),
/// `docs/DESIGN.md`, and `docs/EXPERIENCE.md` Flow 3:
/// - **Active Soundscape Hero Card (`28px` Pebble):** Displays the currently
///   selected tempo theme, target BPM & ideal SPM cadence range, rhythmic wave
///   bars, honest audio preview notice (`audioComingSoonNotice`), and a 1-tap
///   `Run This Tempo` CTA button.
/// - **Horizontal Filter Chips (`999px` Pill):** `All`, `Chill`, `Jog`, `Fast`,
///   and `Favorites` with `48x48 dp` minimum touch targets.
/// - **Music-Style Track List (`16px` Card):** `56x56 dp` left artwork tile,
///   theme title + BPM tag + cadence range, localized vibe description,
///   Favorite heart button, and Preview/Select button.
/// - **Honest Empty Favorites State:** Friendly guidance card when `Favorites`
///   is selected before any theme is favorited.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    super.key,
    required this.profile,
    required this.onSelectTheme,
    required this.onToggleFavorite,
    required this.onStartRunWithTheme,
    this.onOpenGoalSelectorForTheme,
  });

  final StradioUserProfile profile;
  final ValueChanged<StradioSoundscapeTheme> onSelectTheme;
  final ValueChanged<String> onToggleFavorite;
  final ValueChanged<StradioSoundscapeTheme> onStartRunWithTheme;
  final ValueChanged<StradioSoundscapeTheme>? onOpenGoalSelectorForTheme;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _selectedCategory = 'all';
  String? _previewingSoundscapeId;

  Color _categoryAccentColor(StradioPalette palette, String category) {
    return switch (category) {
      'chill' => StradioColors.statusLive,
      'fast' => palette.accentCoral,
      _ => palette.accentViolet,
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = StradioPalette.of(context);
    final strings = StradioStrings.of(widget.profile.language);
    final activeTheme = StradioSoundscapeTheme.byId(
      widget.profile.activeSoundscapeId,
    );
    final bottomClearance = 104.0 + MediaQuery.paddingOf(context).bottom;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    final filteredThemes = StradioSoundscapeTheme.catalog.where((theme) {
      if (_selectedCategory == 'all') return true;
      if (_selectedCategory == 'favorites') {
        return widget.profile.favoriteSoundscapeIds.contains(theme.id);
      }
      return theme.category == _selectedCategory;
    }).toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final horizontalPad = isTablet ? 28.0 : 20.0;

        return SingleChildScrollView(
          key: const Key('shell_library_scroll'),
          padding: EdgeInsets.fromLTRB(
            horizontalPad,
            16,
            horizontalPad,
            bottomClearance,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.navLibrary,
                    style: StradioTypography.soraHeading(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.libraryHeaderSubtitle,
                    style: StradioTypography.interBody(
                      fontSize: 13,
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 1. Active Soundscape Hero Card (28px Deep Pebble)
                  _buildActiveSoundscapeHeroCard(
                    palette: palette,
                    strings: strings,
                    activeTheme: activeTheme,
                    disableAnimations: disableAnimations,
                  ),
                  const SizedBox(height: 18),

                  // 2. Horizontal Filter Chips Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          key: const Key('library_filter_all'),
                          palette: palette,
                          category: 'all',
                          label: strings.libraryFilterAll,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          key: const Key('library_filter_chill'),
                          palette: palette,
                          category: 'chill',
                          label: 'Chill',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          key: const Key('library_filter_jog'),
                          palette: palette,
                          category: 'jog',
                          label: 'Jog',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          key: const Key('library_filter_fast'),
                          palette: palette,
                          category: 'fast',
                          label: 'Fast',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          key: const Key('library_filter_favorites'),
                          palette: palette,
                          category: 'favorites',
                          label: strings.libraryFilterFavorites,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Track List or Empty Favorites State
                  if (filteredThemes.isEmpty)
                    _buildEmptyFavoritesCard(palette, strings)
                  else
                    ...filteredThemes.map(
                      (theme) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildTrackRowCard(
                          palette: palette,
                          strings: strings,
                          theme: theme,
                          disableAnimations: disableAnimations,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveSoundscapeHeroCard({
    required StradioPalette palette,
    required StradioStrings strings,
    required StradioSoundscapeTheme activeTheme,
    required bool disableAnimations,
  }) {
    final isPreviewingActive = _previewingSoundscapeId == activeTheme.id;
    final categoryAccent = _categoryAccentColor(palette, activeTheme.category);

    return Container(
      key: const Key('library_active_hero_card'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(StradioRadii.hero),
        boxShadow: palette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.equalizer_rounded,
                    size: 16,
                    color: palette.accentCoral,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    strings.activeSoundscapeLabel.toUpperCase(),
                    style: StradioTypography.interLabel(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: palette.textSecondary,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isPreviewingActive
                      ? palette.accentViolet.withValues(alpha: 0.16)
                      : categoryAccent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(StradioRadii.pill),
                ),
                child: Text(
                  isPreviewingActive
                      ? strings.libraryPreviewingBadge
                      : '${activeTheme.bpm} BPM · ${activeTheme.cadenceRangeLabel}',
                  style: StradioTypography.interLabel(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isPreviewingActive
                        ? palette.accentViolet
                        : categoryAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: palette.accentCoral.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(StradioRadii.card),
                ),
                child: Icon(
                  activeTheme.icon,
                  size: 26,
                  color: palette.accentCoral,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeTheme.title,
                      key: const Key('library_active_hero_title'),
                      style: StradioTypography.soraHeading(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activeTheme.subtitle(widget.profile.language),
                      style: StradioTypography.interBody(
                        fontSize: 13,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _MiniTempoPulseBars(
                isActive: isPreviewingActive,
                accentColor: isPreviewingActive
                    ? palette.accentViolet
                    : palette.accentCoral,
                disableAnimations: disableAnimations,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    key: const Key('library_start_active_theme_button'),
                    onPressed: () => widget.onStartRunWithTheme(activeTheme),
                    icon: const Icon(Icons.directions_run_rounded, size: 20),
                    label: Text(
                      '${strings.libraryRunWithThemeAction} (${activeTheme.bpm} BPM)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              if (widget.onOpenGoalSelectorForTheme != null) ...[
                const SizedBox(width: 10),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    key: const Key('library_choose_goal_active_theme_button'),
                    tooltip: strings.preRunSheetTitle,
                    onPressed: () =>
                        widget.onOpenGoalSelectorForTheme!(activeTheme),
                    style: IconButton.styleFrom(
                      backgroundColor: palette.surfaceSubtle,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(StradioRadii.pill),
                      ),
                    ),
                    icon: Icon(
                      Icons.flag_rounded,
                      size: 20,
                      color: palette.accentCoral,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required Key key,
    required StradioPalette palette,
    required String category,
    required String label,
  }) {
    final isSelected = _selectedCategory == category;
    return Material(
      color: isSelected ? palette.accentCoral : palette.surface,
      borderRadius: BorderRadius.circular(StradioRadii.pill),
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(StradioRadii.pill),
        onTap: () {
          setState(() {
            _selectedCategory = category;
          });
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Center(
              child: Text(
                label,
                style: StradioTypography.interLabel(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : palette.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackRowCard({
    required StradioPalette palette,
    required StradioStrings strings,
    required StradioSoundscapeTheme theme,
    required bool disableAnimations,
  }) {
    final isActive = widget.profile.activeSoundscapeId == theme.id;
    final isFavorite = widget.profile.favoriteSoundscapeIds.contains(theme.id);
    final isPreviewing = _previewingSoundscapeId == theme.id;
    final categoryAccent = _categoryAccentColor(palette, theme.category);
    final activityTag = theme.activity == Activity.jogging ? 'JOG' : 'WALK';

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(StradioRadii.card),
      child: InkWell(
        key: Key('library_select_${theme.id}'),
        borderRadius: BorderRadius.circular(StradioRadii.card),
        onTap: () => widget.onSelectTheme(theme),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(StradioRadii.card),
            boxShadow: palette.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  // 56x56 dp Artwork / Mini Wave Thumbnail
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isActive
                          ? palette.accentCoral.withValues(alpha: 0.16)
                          : categoryAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(StradioRadii.control),
                    ),
                    child: Center(
                      child: isPreviewing
                          ? _MiniTempoPulseBars(
                              isActive: true,
                              accentColor: palette.accentViolet,
                              disableAnimations: disableAnimations,
                            )
                          : Icon(
                              theme.icon,
                              size: 24,
                              color: isActive
                                  ? palette.accentCoral
                                  : categoryAccent,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Center Metadata Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(
                              theme.title,
                              style: StradioTypography.soraHeading(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: palette.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: palette.surfaceSubtle,
                                borderRadius: BorderRadius.circular(
                                  StradioRadii.tag,
                                ),
                              ),
                              child: Text(
                                '${theme.bpm} BPM',
                                style: StradioTypography.interLabel(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: palette.accentViolet,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: categoryAccent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  StradioRadii.tag,
                                ),
                              ),
                              child: Text(
                                '$activityTag · ${theme.cadenceRangeLabel}',
                                style: StradioTypography.interLabel(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: categoryAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          theme.subtitle(widget.profile.language),
                          style: StradioTypography.interBody(
                            fontSize: 12,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right Action Buttons (48x48 dp touch targets)
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      key: Key('library_fav_${theme.id}'),
                      tooltip: strings.libraryFilterFavorites,
                      onPressed: () => widget.onToggleFavorite(theme.id),
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 20,
                        color: isFavorite
                            ? palette.accentCoral
                            : palette.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      key: Key('library_preview_${theme.id}'),
                      tooltip: strings.libraryPreviewingBadge,
                      onPressed: () {
                        setState(() {
                          _previewingSoundscapeId = isPreviewing
                              ? null
                              : theme.id;
                        });
                        widget.onSelectTheme(theme);
                      },
                      icon: Icon(
                        isPreviewing
                            ? Icons.stop_circle_rounded
                            : Icons.play_circle_fill_rounded,
                        size: 24,
                        color: isActive
                            ? palette.accentCoral
                            : palette.accentViolet,
                      ),
                    ),
                  ),
                ],
              ),

              // Inline Contextual Audio Preview Notice directly inside the previewed row
              if (isPreviewing) ...[
                const SizedBox(height: 10),
                Container(
                  key: const Key('library_audio_preview_banner'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: palette.accentViolet.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(StradioRadii.control),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.graphic_eq_rounded,
                        size: 18,
                        color: palette.accentViolet,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          strings.audioComingSoonNotice,
                          style: StradioTypography.interBody(
                            fontSize: 12,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyFavoritesCard(
    StradioPalette palette,
    StradioStrings strings,
  ) {
    return Container(
      key: const Key('library_empty_favorites_card'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(StradioRadii.squircle),
        boxShadow: palette.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: palette.accentCoral.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_border_rounded,
              size: 24,
              color: palette.accentCoral,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            strings.libraryEmptyFavoritesTitle,
            textAlign: TextAlign.center,
            style: StradioTypography.soraHeading(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.libraryEmptyFavoritesBody,
            textAlign: TextAlign.center,
            style: StradioTypography.interBody(
              fontSize: 13,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              key: const Key('library_empty_favorites_reset_button'),
              onPressed: () {
                setState(() {
                  _selectedCategory = 'all';
                });
              },
              child: Text(strings.libraryFilterAll),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTempoPulseBars extends StatelessWidget {
  const _MiniTempoPulseBars({
    required this.isActive,
    required this.accentColor,
    required this.disableAnimations,
  });

  final bool isActive;
  final Color accentColor;
  final bool disableAnimations;

  static const List<double> _idleHeights = [10, 18, 14, 22, 12];
  static const List<double> _activeHeights = [16, 26, 20, 28, 18];

  @override
  Widget build(BuildContext context) {
    final heights = isActive ? _activeHeights : _idleHeights;
    final barDuration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 220);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < heights.length; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          AnimatedContainer(
            duration: barDuration,
            curve: Curves.easeOutCubic,
            width: 3.5,
            height: heights[i],
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isActive ? 0.95 : 0.55),
              borderRadius: BorderRadius.circular(StradioRadii.pill),
            ),
          ),
        ],
      ],
    );
  }
}

