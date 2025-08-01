// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

// import 'button_bar.dart';
// import 'button_theme.dart';
// import 'color_scheme.dart';
// import 'colors.dart';
// import 'constants.dart';
// import 'curves.dart';
// import 'debug.dart';
// import 'dialog.dart';
// import 'feedback.dart';
// import 'flat_button.dart';
// import 'icon_button.dart';
// import 'icons.dart';
// import 'ink_well.dart';
// import 'input_border.dart';
// import 'input_decorator.dart';
// import 'material.dart';
// import 'material_localizations.dart';
// import 'material_state.dart';
// import 'text_form_field.dart';
// import 'text_theme.dart';
// import 'theme.dart';
// import 'theme_data.dart';
// import 'time.dart';
// import 'time_picker_theme.dart';

// Examples can assume:
// BuildContext context;

/// Signature for predicating times for enabled time selections.
///
/// See [showCustomTimePicker], which has a [SelectableTimePredicate] parameter used
/// to specify allowable times in the time picker.
typedef SelectableTimePredicate = bool Function(TimeOfDay time);

const Duration _kDialogSizeAnimationDuration = Duration(milliseconds: 200);
const Duration _kDialAnimateDuration = Duration(milliseconds: 200);
const double _kTwoPi = 2 * math.pi;
const Duration _kVibrateCommitDelay = Duration(milliseconds: 100);

enum _TimePickerMode { hour, minute }

const double _kTimePickerHeaderLandscapeWidth = 264.0;
const double _kTimePickerHeaderControlHeight = 80.0;

const double _kTimePickerWidthPortrait = 328.0;
const double _kTimePickerWidthLandscape = 528.0;

const double _kTimePickerHeightInput = 226.0;
const double _kTimePickerHeightPortrait = 496.0;
const double _kTimePickerHeightLandscape = 316.0;

const double _kTimePickerHeightPortraitCollapsed = 484.0;
const double _kTimePickerHeightLandscapeCollapsed = 304.0;

const BorderRadius _kDefaultBorderRadius =
    BorderRadius.all(Radius.circular(4.0));
const ShapeBorder _kDefaultShape =
    RoundedRectangleBorder(borderRadius: _kDefaultBorderRadius);

/// Interactive input mode of the time picker dialog.
///
/// In [TimePickerEntryMode.dial] mode, a clock dial is displayed and
/// the user taps or drags the time they wish to select. In
/// TimePickerEntryMode.input] mode, [TextField]s are displayed and the user
/// types in the time they wish to select.
enum TimePickerEntryMode {
  /// Tapping/dragging on a clock dial.
  dial,

  /// Text input.
  input,
}

/// Provides properties for rendering time picker header fragments.
@immutable
class _TimePickerFragmentContext {
  const _TimePickerFragmentContext({
    required this.selectedTime,
    required this.mode,
    required this.onTimeChange,
    required this.onModeChange,
    required this.use24HourDials,
  });

  final TimeOfDay selectedTime;
  final _TimePickerMode mode;
  final ValueChanged<TimeOfDay> onTimeChange;
  final ValueChanged<_TimePickerMode> onModeChange;
  final bool use24HourDials;
}

class _TimePickerHeader extends StatelessWidget {
  const _TimePickerHeader({
    required this.selectedTime,
    required this.mode,
    required this.orientation,
    required this.onModeChanged,
    required this.onChanged,
    required this.use24HourDials,
    required this.helpText,
    this.selectableTimePredicate,
  });

  final TimeOfDay selectedTime;
  final _TimePickerMode mode;
  final Orientation orientation;
  final ValueChanged<_TimePickerMode> onModeChanged;
  final ValueChanged<TimeOfDay> onChanged;
  final bool use24HourDials;
  final String? helpText;
  final SelectableTimePredicate? selectableTimePredicate;

  void _handleChangeMode(_TimePickerMode value) {
    if (value != mode) onModeChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final ThemeData themeData = Theme.of(context);
    final TimeOfDayFormat timeOfDayFormat =
        MaterialLocalizations.of(context).timeOfDayFormat(
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );

    final _TimePickerFragmentContext fragmentContext =
        _TimePickerFragmentContext(
      selectedTime: selectedTime,
      mode: mode,
      onTimeChange: onChanged,
      onModeChange: _handleChangeMode,
      use24HourDials: use24HourDials,
    );

    EdgeInsets? padding;
    double? width;
    Widget? controls;

    switch (orientation) {
      case Orientation.portrait:
        // Keep width null because in portrait we don't cap the width.
        padding = const EdgeInsets.symmetric(horizontal: 24.0);
        controls = Column(
          children: <Widget>[
            const SizedBox(height: 16.0),
            SizedBox(
              height: kMinInteractiveDimension * 2,
              child: Row(
                children: <Widget>[
                  if (!use24HourDials &&
                      timeOfDayFormat ==
                          TimeOfDayFormat.a_space_h_colon_mm) ...<Widget>[
                    _DayPeriodControl(
                      selectedTime: selectedTime,
                      orientation: orientation,
                      onChanged: onChanged,
                    ),
                    const SizedBox(width: 12.0),
                  ],
                  Expanded(
                    child: Row(
                      // Hour/minutes should not change positions in RTL locales.
                      textDirection: TextDirection.ltr,
                      children: <Widget>[
                        Expanded(
                            child:
                                _HourControl(fragmentContext: fragmentContext)),
                        _StringFragment(timeOfDayFormat: timeOfDayFormat),
                        Expanded(
                            child: _MinuteControl(
                                fragmentContext: fragmentContext)),
                      ],
                    ),
                  ),
                  if (!use24HourDials &&
                      timeOfDayFormat !=
                          TimeOfDayFormat.a_space_h_colon_mm) ...<Widget>[
                    const SizedBox(width: 12.0),
                    _DayPeriodControl(
                      selectedTime: selectedTime,
                      orientation: orientation,
                      onChanged: onChanged,
                    ),
                  ]
                ],
              ),
            ),
          ],
        );
        break;
      case Orientation.landscape:
        width = _kTimePickerHeaderLandscapeWidth;
        padding = const EdgeInsets.symmetric(horizontal: 24.0);
        controls = Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (!use24HourDials &&
                  timeOfDayFormat == TimeOfDayFormat.a_space_h_colon_mm)
                _DayPeriodControl(
                  selectedTime: selectedTime,
                  orientation: orientation,
                  onChanged: onChanged,
                ),
              SizedBox(
                height: kMinInteractiveDimension * 2,
                child: Row(
                  // Hour/minutes should not change positions in RTL locales.
                  textDirection: TextDirection.ltr,
                  children: <Widget>[
                    Expanded(
                        child: _HourControl(fragmentContext: fragmentContext)),
                    _StringFragment(timeOfDayFormat: timeOfDayFormat),
                    Expanded(
                        child:
                            _MinuteControl(fragmentContext: fragmentContext)),
                  ],
                ),
              ),
              if (!use24HourDials &&
                  timeOfDayFormat != TimeOfDayFormat.a_space_h_colon_mm)
                _DayPeriodControl(
                  selectedTime: selectedTime,
                  orientation: orientation,
                  onChanged: onChanged,
                ),
            ],
          ),
        );
        break;
    }

    return Container(
      width: width,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 16.0),
          Text(
            helpText ??
                MaterialLocalizations.of(context).timePickerDialHelpText,
            style: TimePickerTheme.of(context).helpTextStyle ??
                themeData.textTheme.labelSmall,
          ),
          controls,
        ],
      ),
    );
  }
}

class _HourMinuteControl extends StatelessWidget {
  const _HourMinuteControl({
    required this.text,
    required this.onTap,
    required this.isSelected,
  });

  final String text;
  final GestureTapCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final TimePickerThemeData timePickerTheme = TimePickerTheme.of(context);
    final bool isDark = themeData.colorScheme.brightness == Brightness.dark;
    final Color textColor = timePickerTheme.hourMinuteTextColor ??
        WidgetStateColor.resolveWith((Set<WidgetState> states) {
          return states.contains(WidgetState.selected)
              ? themeData.colorScheme.primary
              : themeData.colorScheme.onSurface;
        });
    final Color backgroundColor = timePickerTheme.hourMinuteColor ??
        WidgetStateColor.resolveWith((Set<WidgetState> states) {
          return states.contains(WidgetState.selected)
              ? themeData.colorScheme.primary
                  .withValues(alpha: isDark ? 0.24 : 0.12)
              : themeData.colorScheme.onSurface.withValues(alpha: 0.12);
        });
    final TextStyle style = timePickerTheme.hourMinuteTextStyle ??
        themeData.textTheme.displayMedium!;
    final ShapeBorder shape = timePickerTheme.hourMinuteShape ?? _kDefaultShape;

    final Set<WidgetState> states =
        isSelected ? <WidgetState>{WidgetState.selected} : <WidgetState>{};
    return SizedBox(
      height: _kTimePickerHeaderControlHeight,
      child: Material(
        color: WidgetStateProperty.resolveAs(backgroundColor, states),
        clipBehavior: Clip.antiAlias,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text(
              text,
              style: style.copyWith(
                  color: WidgetStateProperty.resolveAs(textColor, states)),
              textScaler: const TextScaler.linear(1.0),
            ),
          ),
        ),
      ),
    );
  }
}

/// Displays the hour fragment.
///
/// When tapped changes time picker dial mode to [_TimePickerMode.hour].
class _HourControl extends StatelessWidget {
  const _HourControl({
    required this.fragmentContext,
  });

  final _TimePickerFragmentContext fragmentContext;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final bool alwaysUse24HourFormat =
        MediaQuery.of(context).alwaysUse24HourFormat;
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    final String formattedHour = localizations.formatHour(
      fragmentContext.selectedTime,
      alwaysUse24HourFormat: alwaysUse24HourFormat,
    );

    TimeOfDay hoursFromSelected(int hoursToAdd) {
      if (fragmentContext.use24HourDials) {
        final int selectedHour = fragmentContext.selectedTime.hour;
        return fragmentContext.selectedTime.replacing(
          hour: (selectedHour + hoursToAdd) % TimeOfDay.hoursPerDay,
        );
      } else {
        // Cycle 1 through 12 without changing day period.
        final int periodOffset = fragmentContext.selectedTime.periodOffset;
        final int hours = fragmentContext.selectedTime.hourOfPeriod;
        return fragmentContext.selectedTime.replacing(
          hour: periodOffset + (hours + hoursToAdd) % TimeOfDay.hoursPerPeriod,
        );
      }
    }

    final TimeOfDay nextHour = hoursFromSelected(1);
    final String formattedNextHour = localizations.formatHour(
      nextHour,
      alwaysUse24HourFormat: alwaysUse24HourFormat,
    );
    final TimeOfDay previousHour = hoursFromSelected(-1);
    final String formattedPreviousHour = localizations.formatHour(
      previousHour,
      alwaysUse24HourFormat: alwaysUse24HourFormat,
    );

    return Semantics(
      hint: localizations.timePickerHourModeAnnouncement,
      value: formattedHour,
      excludeSemantics: true,
      increasedValue: formattedNextHour,
      onIncrease: () {
        fragmentContext.onTimeChange(nextHour);
      },
      decreasedValue: formattedPreviousHour,
      onDecrease: () {
        fragmentContext.onTimeChange(previousHour);
      },
      child: _HourMinuteControl(
        isSelected: fragmentContext.mode == _TimePickerMode.hour,
        text: formattedHour,
        onTap: Feedback.wrapForTap(
            () => fragmentContext.onModeChange(_TimePickerMode.hour), context)!,
      ),
    );
  }
}

/// A passive fragment showing a string value.
class _StringFragment extends StatelessWidget {
  const _StringFragment({
    required this.timeOfDayFormat,
  });

  final TimeOfDayFormat timeOfDayFormat;

  String _stringFragmentValue(TimeOfDayFormat timeOfDayFormat) {
    String result = '';
    switch (timeOfDayFormat) {
      case TimeOfDayFormat.h_colon_mm_space_a:
      case TimeOfDayFormat.a_space_h_colon_mm:
      case TimeOfDayFormat.H_colon_mm:
      case TimeOfDayFormat.HH_colon_mm:
        result = ':';
        break;
      case TimeOfDayFormat.HH_dot_mm:
        result = '.';
        break;
      case TimeOfDayFormat.frenchCanadian:
        result = 'h';
        break;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TimePickerThemeData timePickerTheme = TimePickerTheme.of(context);
    final TextStyle hourMinuteStyle =
        timePickerTheme.hourMinuteTextStyle ?? theme.textTheme.displayMedium!;
    final Color textColor =
        timePickerTheme.hourMinuteTextColor ?? theme.colorScheme.onSurface;

    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        child: Center(
          child: Text(
            _stringFragmentValue(timeOfDayFormat),
            style: hourMinuteStyle.apply(
                color:
                    WidgetStateProperty.resolveAs(textColor, <WidgetState>{})),
            textScaler: const TextScaler.linear(1.0),
          ),
        ),
      ),
    );
  }
}

/// Displays the minute fragment.
///
/// When tapped changes time picker dial mode to [_TimePickerMode.minute].
class _MinuteControl extends StatelessWidget {
  const _MinuteControl({
    required this.fragmentContext,
  });

  final _TimePickerFragmentContext fragmentContext;

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    final String formattedMinute =
        localizations.formatMinute(fragmentContext.selectedTime);
    final TimeOfDay nextMinute = fragmentContext.selectedTime.replacing(
      minute:
          (fragmentContext.selectedTime.minute + 1) % TimeOfDay.minutesPerHour,
    );
    final String formattedNextMinute = localizations.formatMinute(nextMinute);
    final TimeOfDay previousMinute = fragmentContext.selectedTime.replacing(
      minute:
          (fragmentContext.selectedTime.minute - 1) % TimeOfDay.minutesPerHour,
    );
    final String formattedPreviousMinute =
        localizations.formatMinute(previousMinute);

    return Semantics(
      excludeSemantics: true,
      hint: localizations.timePickerMinuteModeAnnouncement,
      value: formattedMinute,
      increasedValue: formattedNextMinute,
      onIncrease: () {
        fragmentContext.onTimeChange(nextMinute);
      },
      decreasedValue: formattedPreviousMinute,
      onDecrease: () {
        fragmentContext.onTimeChange(previousMinute);
      },
      child: _HourMinuteControl(
        isSelected: fragmentContext.mode == _TimePickerMode.minute,
        text: formattedMinute,
        onTap: Feedback.wrapForTap(
            () => fragmentContext.onModeChange(_TimePickerMode.minute),
            context)!,
      ),
    );
  }
}

/// Displays the am/pm fragment and provides controls for switching between am
/// and pm.
class _DayPeriodControl extends StatelessWidget {
  const _DayPeriodControl({
    required this.selectedTime,
    required this.onChanged,
    required this.orientation,
  });

  final TimeOfDay? selectedTime;
  final Orientation orientation;
  final ValueChanged<TimeOfDay> onChanged;

  void _togglePeriod() {
    final int newHour =
        (selectedTime!.hour + TimeOfDay.hoursPerPeriod) % TimeOfDay.hoursPerDay;
    final TimeOfDay newTime = selectedTime!.replacing(hour: newHour);
    onChanged(newTime);
  }

  void _setAm(BuildContext context) {
    if (selectedTime!.period == DayPeriod.am) {
      return;
    }
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        _announceToAccessibility(context,
            MaterialLocalizations.of(context).anteMeridiemAbbreviation);
        break;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        break;
    }
    _togglePeriod();
  }

  void _setPm(BuildContext context) {
    if (selectedTime!.period == DayPeriod.pm) {
      return;
    }
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        _announceToAccessibility(context,
            MaterialLocalizations.of(context).postMeridiemAbbreviation);
        break;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        break;
    }
    _togglePeriod();
  }

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations materialLocalizations =
        MaterialLocalizations.of(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TimePickerThemeData timePickerTheme = TimePickerTheme.of(context);
    final bool isDark = colorScheme.brightness == Brightness.dark;
    final Color textColor = timePickerTheme.dayPeriodTextColor ??
        WidgetStateColor.resolveWith((Set<WidgetState> states) {
          return states.contains(WidgetState.selected)
              ? colorScheme.primary
              : colorScheme.onSurface.withValues(alpha: 0.60);
        });
    final Color backgroundColor = timePickerTheme.dayPeriodColor ??
        WidgetStateColor.resolveWith((Set<WidgetState> states) {
          // The unselected day period should match the overall picker dialog
          // color. Making it transparent enables that without being redundant
          // and allows the optional elevation overlay for dark mode to be
          // visible.
          return states.contains(WidgetState.selected)
              ? colorScheme.primary.withValues(alpha: isDark ? 0.24 : 0.12)
              : Colors.transparent;
        });
    final bool amSelected = selectedTime!.period == DayPeriod.am;
    final Set<WidgetState> amStates =
        amSelected ? <WidgetState>{WidgetState.selected} : <WidgetState>{};
    final bool pmSelected = !amSelected;
    final Set<WidgetState> pmStates =
        pmSelected ? <WidgetState>{WidgetState.selected} : <WidgetState>{};
    final TextStyle textStyle = timePickerTheme.dayPeriodTextStyle ??
        Theme.of(context).textTheme.titleMedium!;
    final TextStyle amStyle = textStyle.copyWith(
      color: WidgetStateProperty.resolveAs(textColor, amStates),
    );
    final TextStyle pmStyle = textStyle.copyWith(
      color: WidgetStateProperty.resolveAs(textColor, pmStates),
    );
    OutlinedBorder shape = timePickerTheme.dayPeriodShape ??
        const RoundedRectangleBorder(borderRadius: _kDefaultBorderRadius);
    final BorderSide borderSide = timePickerTheme.dayPeriodBorderSide ??
        BorderSide(
          color: Color.alphaBlend(colorScheme.onSurface.withValues(alpha: 0.38),
              colorScheme.surface),
        );
    // Apply the custom borderSide.
    shape = shape.copyWith(
      side: borderSide,
    );

    final double buttonTextScaleFactor =
        math.min(MediaQuery.textScalerOf(context).scale(16), 2.0);

    final hours =
        List.generate(12, (index) => TimeOfDay(hour: index, minute: 0));
    final bool hasAMHours = hours.where((h) => _isSelectableTime(h)).isNotEmpty;
    final bool hasPMHours = hours
        .where((h) => _isSelectableTime(h.replacing(hour: h.hour + 12)))
        .isNotEmpty;

    final Widget amButton = Opacity(
      opacity: !hasAMHours ? 0.1 : 1,
      child: Material(
        color: WidgetStateProperty.resolveAs(backgroundColor, amStates),
        child: InkWell(
          onTap: () {
            if (hasAMHours) {
              Feedback.wrapForTap(() => _setAm(context), context)!.call();
            }
          },
          child: Semantics(
            selected: amSelected,
            child: Center(
              child: Text(
                materialLocalizations.anteMeridiemAbbreviation,
                style: amStyle,
                textScaler: TextScaler.linear(buttonTextScaleFactor),
              ),
            ),
          ),
        ),
      ),
    );

    final Widget pmButton = Opacity(
        opacity: !hasPMHours ? 0.1 : 1,
        child: Material(
          color: WidgetStateProperty.resolveAs(backgroundColor, pmStates),
          child: InkWell(
            onTap: () {
              if (hasPMHours) {
                Feedback.wrapForTap(() => _setPm(context), context)!.call();
              }
            },
            child: Semantics(
              selected: pmSelected,
              child: Center(
                child: Text(
                  materialLocalizations.postMeridiemAbbreviation,
                  style: pmStyle,
                  textScaler: TextScaler.linear(buttonTextScaleFactor),
                ),
              ),
            ),
          ),
        ));

    late Widget result;
    switch (orientation) {
      case Orientation.portrait:
        const double width = 52.0;
        result = _DayPeriodInputPadding(
          minSize: const Size(width, kMinInteractiveDimension * 2),
          orientation: orientation,
          child: SizedBox(
            width: width,
            height: _kTimePickerHeaderControlHeight,
            child: Material(
              clipBehavior: Clip.antiAlias,
              color: Colors.transparent,
              shape: shape,
              child: Column(
                children: <Widget>[
                  Expanded(child: amButton),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(top: borderSide),
                    ),
                    height: 1,
                  ),
                  Expanded(child: pmButton),
                ],
              ),
            ),
          ),
        );
        break;
      case Orientation.landscape:
        result = _DayPeriodInputPadding(
          minSize: const Size(0.0, kMinInteractiveDimension),
          orientation: orientation,
          child: SizedBox(
            height: 40.0,
            child: Material(
              clipBehavior: Clip.antiAlias,
              color: Colors.transparent,
              shape: shape,
              child: Row(
                children: <Widget>[
                  Expanded(child: amButton),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(left: borderSide),
                    ),
                    width: 1,
                  ),
                  Expanded(child: pmButton),
                ],
              ),
            ),
          ),
        );
        break;
    }
    return result;
  }
}

/// A widget to pad the area around the [_DayPeriodControl]'s inner [Material].
class _DayPeriodInputPadding extends SingleChildRenderObjectWidget {
  const _DayPeriodInputPadding({
    super.child,
    this.minSize,
    this.orientation,
  });

  final Size? minSize;
  final Orientation? orientation;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderInputPadding(minSize, orientation);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderInputPadding renderObject) {
    renderObject.minSize = minSize;
  }
}

class _RenderInputPadding extends RenderShiftedBox {
  _RenderInputPadding(this._minSize, this.orientation, [RenderBox? child])
      : super(child);

  final Orientation? orientation;

  Size? get minSize => _minSize;
  Size? _minSize;
  set minSize(Size? value) {
    if (_minSize == value) return;
    _minSize = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    if (child != null) {
      return math.max(child!.getMinIntrinsicWidth(height), minSize!.width);
    }
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (child != null) {
      return math.max(child!.getMinIntrinsicHeight(width), minSize!.height);
    }
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (child != null) {
      return math.max(child!.getMaxIntrinsicWidth(height), minSize!.width);
    }
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (child != null) {
      return math.max(child!.getMaxIntrinsicHeight(width), minSize!.height);
    }
    return 0.0;
  }

  @override
  void performLayout() {
    if (child != null) {
      child!.layout(constraints, parentUsesSize: true);
      final double width = math.max(child!.size.width, minSize!.width);
      final double height = math.max(child!.size.height, minSize!.height);
      size = constraints.constrain(Size(width, height));
      final BoxParentData childParentData = child!.parentData as BoxParentData;
      childParentData.offset =
          Alignment.center.alongOffset(size - child!.size as Offset);
    } else {
      size = Size.zero;
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (super.hitTest(result, position: position)) {
      return true;
    }

    if (position.dx < 0.0 ||
        position.dx > math.max(child!.size.width, minSize!.width) ||
        position.dy < 0.0 ||
        position.dy > math.max(child!.size.height, minSize!.height)) {
      return false;
    }

    Offset newPosition = child!.size.center(Offset.zero);
    switch (orientation) {
      case null:
        break;
      case Orientation.portrait:
        if (position.dy > newPosition.dy) {
          newPosition += const Offset(0.0, 1.0);
        } else {
          newPosition += const Offset(0.0, -1.0);
        }
        break;
      case Orientation.landscape:
        if (position.dx > newPosition.dx) {
          newPosition += const Offset(1.0, 0.0);
        } else {
          newPosition += const Offset(-1.0, 0.0);
        }
        break;
    }

    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(newPosition),
      position: newPosition,
      hitTest: (BoxHitTestResult result, Offset position) {
        assert(position == newPosition);
        return child!.hitTest(result, position: newPosition);
      },
    );
  }
}

class _TappableLabel {
  _TappableLabel({
    required this.value,
    required this.painter,
    required this.onTap,
  });

  /// The value this label is displaying.
  final int value;

  /// Paints the text of the label.
  final TextPainter painter;

  /// Called when a tap gesture is detected on the label.
  final VoidCallback? onTap;
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.primaryLabels,
    required this.secondaryLabels,
    required this.backgroundColor,
    required this.accentColor,
    required this.dotColor,
    required this.theta,
    required this.textDirection,
    required this.selectedValue,
  }) : super(repaint: PaintingBinding.instance.systemFonts);

  final List<_TappableLabel>? primaryLabels;
  final List<_TappableLabel>? secondaryLabels;
  final Color backgroundColor;
  final Color accentColor;
  final Color dotColor;
  final double theta;
  final TextDirection textDirection;
  final int? selectedValue;

  static const double _labelPadding = 28.0;

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.shortestSide / 2.0;
    final Offset center = Offset(size.width / 2.0, size.height / 2.0);
    final Offset centerPoint = center;
    canvas.drawCircle(centerPoint, radius, Paint()..color = backgroundColor);

    final double labelRadius = radius - _labelPadding;
    Offset getOffsetForTheta(double theta) {
      return center +
          Offset(labelRadius * math.cos(theta), -labelRadius * math.sin(theta));
    }

    void paintLabels(List<_TappableLabel>? labels) {
      if (labels == null) return;
      final double labelThetaIncrement = -_kTwoPi / labels.length;
      double labelTheta = math.pi / 2.0;

      for (final _TappableLabel label in labels) {
        final TextPainter labelPainter = label.painter;
        final Offset labelOffset =
            Offset(-labelPainter.width / 2.0, -labelPainter.height / 2.0);
        labelPainter.paint(canvas, getOffsetForTheta(labelTheta) + labelOffset);
        labelTheta += labelThetaIncrement;
      }
    }

    paintLabels(primaryLabels);

    final Paint selectorPaint = Paint()..color = accentColor;
    final Offset focusedPoint = getOffsetForTheta(theta);
    const double focusedRadius = _labelPadding - 4.0;
    canvas.drawCircle(centerPoint, 4.0, selectorPaint);
    canvas.drawCircle(focusedPoint, focusedRadius, selectorPaint);
    selectorPaint.strokeWidth = 2.0;
    canvas.drawLine(centerPoint, focusedPoint, selectorPaint);

    // Add a dot inside the selector but only when it isn't over the labels.
    // This checks that the selector's theta is between two labels. A remainder
    // between 0.1 and 0.45 indicates that the selector is roughly not above any
    // labels. The values were derived by manually testing the dial.
    final double labelThetaIncrement = -_kTwoPi / primaryLabels!.length;
    if (theta % labelThetaIncrement > 0.1 &&
        theta % labelThetaIncrement < 0.45) {
      canvas.drawCircle(focusedPoint, 2.0, selectorPaint..color = dotColor);
    }

    final Rect focusedRect = Rect.fromCircle(
      center: focusedPoint,
      radius: focusedRadius,
    );
    canvas
      ..save()
      ..clipPath(Path()..addOval(focusedRect));
    paintLabels(secondaryLabels);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DialPainter oldPainter) {
    return oldPainter.primaryLabels != primaryLabels ||
        oldPainter.secondaryLabels != secondaryLabels ||
        oldPainter.backgroundColor != backgroundColor ||
        oldPainter.accentColor != accentColor ||
        oldPainter.theta != theta;
  }
}

class _Dial extends StatefulWidget {
  const _Dial(
      {required this.selectedTime,
      required this.mode,
      required this.use24HourDials,
      required this.onChanged,
      required this.onHourSelected,
      this.selectableTimePredicate});

  final TimeOfDay selectedTime;
  final _TimePickerMode mode;
  final bool use24HourDials;
  final ValueChanged<TimeOfDay> onChanged;
  final VoidCallback onHourSelected;
  final SelectableTimePredicate? selectableTimePredicate;

  @override
  _DialState createState() => _DialState();
}

class _DialState extends State<_Dial> with SingleTickerProviderStateMixin {
  TimeOfDay? _lastSelectableTime;
  bool get _isAM => widget.selectedTime.period == DayPeriod.am;

  @override
  void initState() {
    super.initState();
    _lastSelectableTime = widget.selectedTime;
    _thetaController = AnimationController(
      duration: _kDialAnimateDuration,
      vsync: this,
    );
    _thetaTween = Tween<double>(begin: _getThetaForTime(widget.selectedTime));
    _theta = _thetaController!
        .drive(CurveTween(curve: Curves.easeIn))
        .drive(_thetaTween!)
      ..addListener(() => setState(() {/* _theta.value has changed */}));
  }

  late ThemeData themeData;
  late MaterialLocalizations localizations;
  late MediaQueryData media;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    assert(debugCheckHasMediaQuery(context));
    themeData = Theme.of(context);
    localizations = MaterialLocalizations.of(context);
    media = MediaQuery.of(context);
  }

  @override
  void didUpdateWidget(_Dial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode != oldWidget.mode ||
        widget.selectedTime != oldWidget.selectedTime) {
      if (!_dragging) _animateTo(_getThetaForTime(widget.selectedTime));
    }
  }

  @override
  void dispose() {
    _thetaController!.dispose();
    super.dispose();
  }

  Tween<double>? _thetaTween;
  late Animation<double> _theta;
  AnimationController? _thetaController;
  bool _dragging = false;

  static double _nearest(double target, double a, double b) {
    return ((target - a).abs() < (target - b).abs()) ? a : b;
  }

  void _animateTo(double targetTheta) {
    final double currentTheta = _theta.value;
    double beginTheta =
        _nearest(targetTheta, currentTheta, currentTheta + _kTwoPi);
    beginTheta = _nearest(targetTheta, beginTheta, currentTheta - _kTwoPi);
    _thetaTween!
      ..begin = beginTheta
      ..end = targetTheta;
    _thetaController!
      ..value = 0.0
      ..forward();
  }

  double _getThetaForTime(TimeOfDay? time) {
    final int hoursFactor = widget.use24HourDials
        ? TimeOfDay.hoursPerDay
        : TimeOfDay.hoursPerPeriod;
    final double fraction = widget.mode == _TimePickerMode.hour
        ? (time!.hour / hoursFactor) % hoursFactor
        : (time!.minute / TimeOfDay.minutesPerHour) % TimeOfDay.minutesPerHour;
    return (math.pi / 2.0 - fraction * _kTwoPi) % _kTwoPi;
  }

  TimeOfDay _getTimeForTheta(double theta, {bool roundMinutes = false}) {
    final double fraction = (0.25 - (theta % _kTwoPi) / _kTwoPi) % 1.0;
    TimeOfDay _newTime;
    if (widget.mode == _TimePickerMode.hour) {
      int newHour;
      if (widget.use24HourDials) {
        newHour =
            (fraction * TimeOfDay.hoursPerDay).round() % TimeOfDay.hoursPerDay;
      } else {
        newHour = (fraction * TimeOfDay.hoursPerPeriod).round() %
            TimeOfDay.hoursPerPeriod;
        newHour = newHour + widget.selectedTime.periodOffset;
      }
      _newTime = widget.selectedTime.replacing(hour: newHour);
    } else {
      int minute = (fraction * TimeOfDay.minutesPerHour).round() %
          TimeOfDay.minutesPerHour;
      if (roundMinutes) {
        // Round the minutes to nearest 5 minute interval.
        minute = ((minute + 2) ~/ 5) * 5 % TimeOfDay.minutesPerHour;
      }
      _newTime = widget.selectedTime.replacing(minute: minute);
    }
    if (_isSelectableTime(_newTime)) _lastSelectableTime = _newTime;
    return _newTime;
  }

  TimeOfDay _notifyOnChangedIfNeeded({bool roundMinutes = false}) {
    final TimeOfDay current =
        _getTimeForTheta(_theta.value, roundMinutes: roundMinutes);
    // if (widget.onChanged == null) return current;
    if (current != widget.selectedTime) widget.onChanged(current);
    return current;
  }

  void _updateThetaForPan({bool roundMinutes = false}) {
    setState(() {
      final Offset offset = _position! - _center!;
      double angle =
          (math.atan2(offset.dx, offset.dy) - math.pi / 2.0) % _kTwoPi;
      if (roundMinutes) {
        angle = _getThetaForTime(
            _getTimeForTheta(angle, roundMinutes: roundMinutes));
      }
      _thetaTween!
        ..begin = angle
        ..end = angle; // The controller doesn't animate during the pan gesture.
    });
  }

  Offset? _position;
  Offset? _center;

  void _handlePanStart(DragStartDetails details) {
    assert(!_dragging);
    _dragging = true;
    final RenderBox box = context.findRenderObject() as RenderBox;
    _position = box.globalToLocal(details.globalPosition);
    _center = box.size.center(Offset.zero);
    _updateThetaForPan();
    _notifyOnChangedIfNeeded();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    _position = _position! + details.delta;
    _updateThetaForPan();

    final TimeOfDay newTime =
        _getTimeForTheta(_theta.value, roundMinutes: false);
    if (_isSelectableTime(newTime)) _notifyOnChangedIfNeeded();
  }

  void _handlePanEnd(DragEndDetails details) {
    assert(_dragging);
    final TimeOfDay newTime =
        _getTimeForTheta(_theta.value, roundMinutes: false);
    _dragging = false;
    _position = null;
    _center = null;
    if (!_isSelectableTime(newTime)) {
      _animateTo(_getThetaForTime(_lastSelectableTime));
    } else {
      _animateTo(_getThetaForTime(widget.selectedTime));
      if (widget.mode == _TimePickerMode.hour) {
        // if (widget.onHourSelected != null) {
        widget.onHourSelected();
        // }
      }
    }
  }

  void _handleTapUp(TapUpDetails details) async {
    final RenderBox box = context.findRenderObject() as RenderBox;
    _position = box.globalToLocal(details.globalPosition);
    _center = box.size.center(Offset.zero);
    _updateThetaForPan(roundMinutes: true);

    final TimeOfDay newTime =
        _getTimeForTheta(_theta.value, roundMinutes: false);
    if (!_isSelectableTime(newTime)) {
      await Future.delayed(const Duration(milliseconds: 100));
      _animateTo(_getThetaForTime(_lastSelectableTime));
      return;
    }

    if (widget.mode == _TimePickerMode.hour) {
      if (widget.use24HourDials) {
        _announceToAccessibility(
            context, localizations.formatDecimal(newTime.hour));
      } else {
        _announceToAccessibility(
            context, localizations.formatDecimal(newTime.hourOfPeriod));
      }
      // if (widget.onHourSelected != null) {
      widget.onHourSelected();
      // }
    } else {
      _announceToAccessibility(
          context, localizations.formatDecimal(newTime.minute));
    }
    _animateTo(
        _getThetaForTime(_getTimeForTheta(_theta.value, roundMinutes: true)));
    _dragging = false;
    _position = null;
    _center = null;
    _notifyOnChangedIfNeeded();
  }

  void _selectHour(int hour) {
    _announceToAccessibility(context, localizations.formatDecimal(hour));
    TimeOfDay time;
    if (widget.mode == _TimePickerMode.hour && widget.use24HourDials) {
      time = TimeOfDay(hour: hour, minute: widget.selectedTime.minute);
    } else {
      if (widget.selectedTime.period == DayPeriod.am) {
        time = TimeOfDay(hour: hour, minute: widget.selectedTime.minute);
      } else {
        time = TimeOfDay(
            hour: hour + TimeOfDay.hoursPerPeriod,
            minute: widget.selectedTime.minute);
      }
    }
    final double angle = _getThetaForTime(time);
    _thetaTween!
      ..begin = angle
      ..end = angle;
    _notifyOnChangedIfNeeded();
  }

  void _selectMinute(int minute) {
    _announceToAccessibility(context, localizations.formatDecimal(minute));
    final TimeOfDay time = TimeOfDay(
      hour: widget.selectedTime.hour,
      minute: minute,
    );
    final double angle = _getThetaForTime(time);
    _thetaTween!
      ..begin = angle
      ..end = angle;
    _notifyOnChangedIfNeeded();
  }

  static const List<TimeOfDay> _amHours = <TimeOfDay>[
    TimeOfDay(hour: 12, minute: 0),
    TimeOfDay(hour: 1, minute: 0),
    TimeOfDay(hour: 2, minute: 0),
    TimeOfDay(hour: 3, minute: 0),
    TimeOfDay(hour: 4, minute: 0),
    TimeOfDay(hour: 5, minute: 0),
    TimeOfDay(hour: 6, minute: 0),
    TimeOfDay(hour: 7, minute: 0),
    TimeOfDay(hour: 8, minute: 0),
    TimeOfDay(hour: 9, minute: 0),
    TimeOfDay(hour: 10, minute: 0),
    TimeOfDay(hour: 11, minute: 0),
  ];

  static const List<TimeOfDay> _twentyFourHours = <TimeOfDay>[
    TimeOfDay(hour: 0, minute: 0),
    TimeOfDay(hour: 2, minute: 0),
    TimeOfDay(hour: 4, minute: 0),
    TimeOfDay(hour: 6, minute: 0),
    TimeOfDay(hour: 8, minute: 0),
    TimeOfDay(hour: 10, minute: 0),
    TimeOfDay(hour: 12, minute: 0),
    TimeOfDay(hour: 14, minute: 0),
    TimeOfDay(hour: 16, minute: 0),
    TimeOfDay(hour: 18, minute: 0),
    TimeOfDay(hour: 20, minute: 0),
    TimeOfDay(hour: 22, minute: 0),
  ];

  _TappableLabel _buildTappableLabel(TextTheme textTheme, Color color,
      int value, String label, VoidCallback? onTap) {
    final TextStyle style = textTheme.bodyLarge!.copyWith(color: color);
    final double labelScaleFactor = math.min(
        MediaQuery.of(context)
            .textScaler
            .scale(textTheme.bodyLarge?.fontSize ?? 0),
        2.0);
    return _TappableLabel(
      value: value,
      painter: TextPainter(
          text: TextSpan(style: style, text: label),
          textDirection: TextDirection.ltr,
          // textScaleFactor: labelScaleFactor,
          textScaler: TextScaler.linear(labelScaleFactor))
        ..layout(),
      onTap: onTap,
    );
  }

  List<_TappableLabel> _build24HourRing(TextTheme textTheme, Color color) =>
      <_TappableLabel>[
        for (final TimeOfDay timeOfDay in _twentyFourHours)
          _buildTappableLabel(
            textTheme,
            color,
            timeOfDay.hour,
            localizations.formatHour(timeOfDay,
                alwaysUse24HourFormat: media.alwaysUse24HourFormat),
            () {
              _selectHour(timeOfDay.hour);
            },
          ),
      ];

  List<_TappableLabel> _build12HourRing(TextTheme textTheme, Color color) =>
      <_TappableLabel>[
        for (final TimeOfDay timeOfDay in _amHours)
          _buildTappableLabel(
            textTheme,
            _isSelectableTime(TimeOfDay(
                    hour: _buildHourFrom12HourRing(timeOfDay.hour),
                    minute: timeOfDay.minute))
                ? color
                : color.withValues(alpha: 0.1),
            timeOfDay.hour,
            localizations.formatHour(timeOfDay,
                alwaysUse24HourFormat: media.alwaysUse24HourFormat),
            () {
              _selectHour(timeOfDay.hour);
            },
          ),
      ];
  int _buildHourFrom12HourRing(int hour) {
    if (hour == 12) {
      hour = 0;
    }

    return hour + (_isAM ? 0 : 12);
  }

  List<_TappableLabel> _buildMinutes(TextTheme textTheme, Color color) {
    const List<TimeOfDay> minuteMarkerValues = <TimeOfDay>[
      TimeOfDay(hour: 0, minute: 0),
      TimeOfDay(hour: 0, minute: 5),
      TimeOfDay(hour: 0, minute: 10),
      TimeOfDay(hour: 0, minute: 15),
      TimeOfDay(hour: 0, minute: 20),
      TimeOfDay(hour: 0, minute: 25),
      TimeOfDay(hour: 0, minute: 30),
      TimeOfDay(hour: 0, minute: 35),
      TimeOfDay(hour: 0, minute: 40),
      TimeOfDay(hour: 0, minute: 45),
      TimeOfDay(hour: 0, minute: 50),
      TimeOfDay(hour: 0, minute: 55),
    ];

    return <_TappableLabel>[
      for (final TimeOfDay timeOfDay in minuteMarkerValues)
        _buildTappableLabel(
          textTheme,
          _isSelectableTime(timeOfDay.replacing(hour: widget.selectedTime.hour))
              ? color
              : color.withValues(alpha: 0.1),
          timeOfDay.minute,
          localizations.formatMinute(timeOfDay),
          _isSelectableTime(timeOfDay)
              ? () {
                  _selectMinute(timeOfDay.minute);
                }
              : null,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TimePickerThemeData pickerTheme = TimePickerTheme.of(context);
    final Color backgroundColor = pickerTheme.dialBackgroundColor ??
        themeData.colorScheme.onSurface.withValues(alpha: 0.12);
    final Color accentColor =
        pickerTheme.dialHandColor ?? themeData.colorScheme.primary;
    final Color primaryLabelColor = WidgetStateProperty.resolveAs(
            pickerTheme.dialTextColor, <WidgetState>{}) ??
        themeData.colorScheme.onSurface;
    final Color secondaryLabelColor = WidgetStateProperty.resolveAs(
            pickerTheme.dialTextColor, <WidgetState>{WidgetState.selected}) ??
        themeData.colorScheme.onPrimary;
    List<_TappableLabel>? primaryLabels;
    List<_TappableLabel>? secondaryLabels;
    int? selectedDialValue;
    switch (widget.mode) {
      case _TimePickerMode.hour:
        if (widget.use24HourDials) {
          selectedDialValue = widget.selectedTime.hour;
          primaryLabels = _build24HourRing(theme.textTheme, primaryLabelColor);
          secondaryLabels =
              _build24HourRing(theme.textTheme, secondaryLabelColor);
        } else {
          selectedDialValue = widget.selectedTime.hourOfPeriod;
          primaryLabels = _build12HourRing(theme.textTheme, primaryLabelColor);
          secondaryLabels =
              _build12HourRing(theme.textTheme, secondaryLabelColor);
        }
        break;
      case _TimePickerMode.minute:
        selectedDialValue = widget.selectedTime.minute;
        primaryLabels = _buildMinutes(theme.textTheme, primaryLabelColor);
        secondaryLabels = _buildMinutes(theme.textTheme, secondaryLabelColor);
        break;
    }

    return GestureDetector(
      excludeFromSemantics: true,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      onTapUp: _handleTapUp,
      child: CustomPaint(
        key: const ValueKey<String>('time-picker-dial'),
        painter: _DialPainter(
          selectedValue: selectedDialValue,
          primaryLabels: primaryLabels,
          secondaryLabels: secondaryLabels,
          backgroundColor: backgroundColor,
          accentColor: accentColor,
          dotColor: theme.colorScheme.surface,
          theta: _theta.value,
          textDirection: Directionality.of(context),
        ),
      ),
    );
  }
}

class _TimePickerInput extends StatefulWidget {
  const _TimePickerInput({
    required this.initialSelectedTime,
    required this.helpText,
    required this.onChanged,
  });

  /// The time initially selected when the dialog is shown.
  final TimeOfDay initialSelectedTime;

  /// Optionally provide your own help text to the time picker.
  final String? helpText;

  final ValueChanged<TimeOfDay?> onChanged;

  @override
  _TimePickerInputState createState() => _TimePickerInputState();
}

class _TimePickerInputState extends State<_TimePickerInput> {
  TimeOfDay? _selectedTime;
  bool hourHasError = false;
  bool minuteHasError = false;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialSelectedTime;
  }

  int? _parseHour(String value) {
    int? newHour = int.tryParse(value);
    if (newHour == null) {
      return null;
    }

    if (MediaQuery.of(context).alwaysUse24HourFormat) {
      if (newHour >= 0 && newHour < 24) {
        return newHour;
      }
    } else {
      if (newHour > 0 && newHour < 13) {
        if ((_selectedTime!.period == DayPeriod.pm && newHour != 12) ||
            (_selectedTime!.period == DayPeriod.am && newHour == 12)) {
          newHour =
              (newHour + TimeOfDay.hoursPerPeriod) % TimeOfDay.hoursPerDay;
        }
        return newHour;
      }
    }
    return null;
  }

  int? _parseMinute(String value) {
    final int? newMinute = int.tryParse(value);
    if (newMinute == null) {
      return null;
    }

    if (newMinute >= 0 && newMinute < 60) {
      return newMinute;
    }
    return null;
  }

  void _handleHourSavedSubmitted(String? value) {
    final int? newHour = _parseHour(value!);
    if (newHour != null) {
      _selectedTime = TimeOfDay(hour: newHour, minute: _selectedTime!.minute);
      widget.onChanged(_selectedTime);
    }
  }

  void _handleHourChanged(String value) {
    final int? newHour = _parseHour(value);
    if (newHour != null && value.length == 2) {
      // If a valid hour is typed, move focus to the minute TextField.
      FocusScope.of(context).nextFocus();
    }
  }

  void _handleMinuteSavedSubmitted(String? value) {
    final int? newMinute = _parseMinute(value!);
    if (newMinute != null) {
      _selectedTime =
          TimeOfDay(hour: _selectedTime!.hour, minute: int.parse(value));
      widget.onChanged(_selectedTime);
    }
  }

  void _handleDayPeriodChanged(TimeOfDay value) {
    _selectedTime = value;
    widget.onChanged(_selectedTime);
  }

  String? _validateHour(String? value) {
    final int? newHour = _parseHour(value!);
    setState(() {
      hourHasError = newHour == null;
    });
    // This is used as the validator for the [TextFormField].
    // Returning an empty string allows the field to go into an error state.
    // Returning null means no error in the validation of the entered text.
    return newHour == null ? '' : null;
  }

  String? _validateMinute(String? value) {
    final int? newMinute = _parseMinute(value!);
    setState(() {
      minuteHasError = newMinute == null;
    });
    // This is used as the validator for the [TextFormField].
    // Returning an empty string allows the field to go into an error state.
    // Returning null means no error in the validation of the entered text.
    return newMinute == null ? '' : null;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final MediaQueryData media = MediaQuery.of(context);
    final TimeOfDayFormat timeOfDayFormat = MaterialLocalizations.of(context)
        .timeOfDayFormat(alwaysUse24HourFormat: media.alwaysUse24HourFormat);
    final bool use24HourDials = hourFormat(of: timeOfDayFormat) != HourFormat.h;
    final ThemeData theme = Theme.of(context);
    final TextStyle? hourMinuteStyle =
        TimePickerTheme.of(context).hourMinuteTextStyle ??
            theme.textTheme.displayMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            widget.helpText ??
                MaterialLocalizations.of(context).timePickerInputHelpText,
            style: TimePickerTheme.of(context).helpTextStyle ??
                theme.textTheme.labelSmall,
          ),
          const SizedBox(height: 16.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (!use24HourDials &&
                  timeOfDayFormat ==
                      TimeOfDayFormat.a_space_h_colon_mm) ...<Widget>[
                _DayPeriodControl(
                  selectedTime: _selectedTime,
                  orientation: Orientation.portrait,
                  onChanged: _handleDayPeriodChanged,
                ),
                const SizedBox(width: 12.0),
              ],
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // Hour/minutes should not change positions in RTL locales.
                  textDirection: TextDirection.ltr,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(height: 8.0),
                          _HourTextField(
                            selectedTime: _selectedTime,
                            style: hourMinuteStyle,
                            validator: _validateHour,
                            onSavedSubmitted: _handleHourSavedSubmitted,
                            onChanged: _handleHourChanged,
                          ),
                          const SizedBox(height: 8.0),
                          if (!hourHasError && !minuteHasError)
                            ExcludeSemantics(
                              child: Text(
                                MaterialLocalizations.of(context)
                                    .timePickerHourLabel,
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 8.0),
                      height: _kTimePickerHeaderControlHeight,
                      child: _StringFragment(timeOfDayFormat: timeOfDayFormat),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(height: 8.0),
                          _MinuteTextField(
                            selectedTime: _selectedTime,
                            style: hourMinuteStyle,
                            validator: _validateMinute,
                            onSavedSubmitted: _handleMinuteSavedSubmitted,
                          ),
                          const SizedBox(height: 8.0),
                          if (!hourHasError && !minuteHasError)
                            ExcludeSemantics(
                              child: Text(
                                MaterialLocalizations.of(context)
                                    .timePickerMinuteLabel,
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!use24HourDials &&
                  timeOfDayFormat !=
                      TimeOfDayFormat.a_space_h_colon_mm) ...<Widget>[
                const SizedBox(width: 12.0),
                _DayPeriodControl(
                  selectedTime: _selectedTime,
                  orientation: Orientation.portrait,
                  onChanged: _handleDayPeriodChanged,
                ),
              ],
            ],
          ),
          if (hourHasError || minuteHasError)
            Text(
              MaterialLocalizations.of(context).invalidTimeLabel,
              style: theme.textTheme.bodyMedium!
                  .copyWith(color: theme.colorScheme.error),
            )
          else
            const SizedBox(height: 2.0),
        ],
      ),
    );
  }
}

class _HourTextField extends StatelessWidget {
  const _HourTextField({
    required this.selectedTime,
    required this.style,
    required this.validator,
    required this.onSavedSubmitted,
    required this.onChanged,
  });

  final TimeOfDay? selectedTime;
  final TextStyle? style;
  final FormFieldValidator<String> validator;
  final ValueChanged<String?> onSavedSubmitted;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _HourMinuteTextField(
      selectedTime: selectedTime,
      isHour: true,
      style: style,
      validator: validator,
      onSavedSubmitted: onSavedSubmitted,
      onChanged: onChanged,
    );
  }
}

class _MinuteTextField extends StatelessWidget {
  const _MinuteTextField({
    required this.selectedTime,
    required this.style,
    required this.validator,
    required this.onSavedSubmitted,
  });

  final TimeOfDay? selectedTime;
  final TextStyle? style;
  final FormFieldValidator<String> validator;
  final ValueChanged<String?> onSavedSubmitted;

  @override
  Widget build(BuildContext context) {
    return _HourMinuteTextField(
      selectedTime: selectedTime,
      isHour: false,
      style: style,
      validator: validator,
      onSavedSubmitted: onSavedSubmitted,
    );
  }
}

class _HourMinuteTextField extends StatefulWidget {
  const _HourMinuteTextField({
    required this.selectedTime,
    required this.isHour,
    required this.style,
    required this.validator,
    required this.onSavedSubmitted,
    this.onChanged,
  });

  final TimeOfDay? selectedTime;
  final bool isHour;
  final TextStyle? style;
  final FormFieldValidator<String> validator;
  final ValueChanged<String?> onSavedSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  _HourMinuteTextFieldState createState() => _HourMinuteTextFieldState();
}

class _HourMinuteTextFieldState extends State<_HourMinuteTextField> {
  TextEditingController? controller;
  FocusNode? focusNode;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode()
      ..addListener(() {
        setState(() {}); // Rebuild.
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller ??= TextEditingController(text: _formattedValue);
  }

  String get _formattedValue {
    final bool alwaysUse24HourFormat =
        MediaQuery.of(context).alwaysUse24HourFormat;
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    return !widget.isHour
        ? localizations.formatMinute(widget.selectedTime!)
        : localizations.formatHour(
            widget.selectedTime!,
            alwaysUse24HourFormat: alwaysUse24HourFormat,
          );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TimePickerThemeData timePickerTheme = TimePickerTheme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final InputDecorationTheme? inputDecorationTheme =
        timePickerTheme.inputDecorationTheme;
    InputDecoration inputDecoration;
    if (inputDecorationTheme != null) {
      inputDecoration =
          const InputDecoration().applyDefaults(inputDecorationTheme);
    } else {
      inputDecoration = InputDecoration(
        contentPadding: EdgeInsets.zero,
        filled: true,
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.error, width: 2.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.error, width: 2.0),
        ),
        hintStyle: widget.style!
            .copyWith(color: colorScheme.onSurface.withValues(alpha: 0.36)),
        errorStyle: const TextStyle(
            fontSize: 0.0,
            height: 0.0), // Prevent the error text from appearing.
      );
    }
    final Color unfocusedFillColor = timePickerTheme.hourMinuteColor ??
        colorScheme.onSurface.withValues(alpha: 0.12);
    inputDecoration = inputDecoration.copyWith(
      // Remove the hint text when focused because the centered cursor appears
      // odd above the hint text.
      hintText: focusNode!.hasFocus ? null : _formattedValue,
      fillColor: focusNode!.hasFocus
          ? Colors.transparent
          : inputDecorationTheme?.fillColor ?? unfocusedFillColor,
    );

    return SizedBox(
      height: _kTimePickerHeaderControlHeight,
      child: MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.0)),
        child: TextFormField(
          expands: true,
          maxLines: null,
          inputFormatters: <TextInputFormatter>[
            LengthLimitingTextInputFormatter(2),
          ],
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          style: widget.style!.copyWith(
              color:
                  timePickerTheme.hourMinuteTextColor ?? colorScheme.onSurface),
          controller: controller,
          decoration: inputDecoration,
          validator: widget.validator,
          onEditingComplete: () => widget.onSavedSubmitted(controller!.text),
          onSaved: widget.onSavedSubmitted,
          onFieldSubmitted: widget.onSavedSubmitted,
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}

/// A material design time picker designed to appear inside a popup dialog.
///
/// Pass this widget to [showDialog]. The value returned by [showDialog] is the
/// selected [TimeOfDay] if the user taps the "OK" button, or null if the user
/// taps the "CANCEL" button. The selected time is reported by calling
/// [Navigator.pop].
class _TimePickerDialog extends StatefulWidget {
  /// Creates a material time picker.
  ///
  /// [initialTime] must not be null.
  _TimePickerDialog({
    required this.initialTime,
    required this.cancelText,
    required this.confirmText,
    required this.helpText,
    this.initialEntryMode = TimePickerEntryMode.dial,
    this.selectableTimePredicate,
  }) {
    assert(
        selectableTimePredicate == null ||
            selectableTimePredicate!(initialTime),
        'Provided initialTime $initialTime must satisfy provided selectableTimePredicate.');
  }

  /// The time initially selected when the dialog is shown.
  final TimeOfDay initialTime;

  /// The entry mode for the picker. Whether it's text input or a dial.
  final TimePickerEntryMode initialEntryMode;

  /// Optionally provide your own text for the cancel button.
  ///
  /// If null, the button uses [MaterialLocalizations.cancelButtonLabel].
  final String? cancelText;

  /// Optionally provide your own text for the confirm button.
  ///
  /// If null, the button uses [MaterialLocalizations.okButtonLabel].
  final String? confirmText;

  /// Optionally provide your own help text to the header of the time picker.
  final String? helpText;

  /// Function to provide full control over which [Time] can be selected.
  final SelectableTimePredicate? selectableTimePredicate;

  @override
  _TimePickerDialogState createState() => _TimePickerDialogState();
}

class _TimePickerDialogState extends State<_TimePickerDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime;
    _selectableTimePredicate = widget.selectableTimePredicate;
    _entryMode = widget.initialEntryMode;
//     _autoValidate = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    localizations = MaterialLocalizations.of(context);
    _announceInitialTimeOnce();
    _announceModeOnce();
  }

  TimePickerEntryMode? _entryMode;
  _TimePickerMode _mode = _TimePickerMode.hour;
  _TimePickerMode? _lastModeAnnounced;
//   bool _autoValidate;

  TimeOfDay? get selectedTime => _selectedTime;
  TimeOfDay? _selectedTime;

  SelectableTimePredicate? _selectableTimePredicate;

  Timer? _vibrateTimer;
  late MaterialLocalizations localizations;

  void _vibrate() {
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        _vibrateTimer?.cancel();
        _vibrateTimer = Timer(_kVibrateCommitDelay, () {
          HapticFeedback.vibrate();
          _vibrateTimer = null;
        });
        break;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        break;
    }
  }

  void _handleModeChanged(_TimePickerMode mode) {
    _vibrate();
    setState(() {
      _mode = mode;
      _announceModeOnce();
    });
  }

//   void _handleEntryModeToggle() {
//     setState(() {
//       switch (_entryMode) {
//         case TimePickerEntryMode.dial:
//           _autoValidate = false;
//           _entryMode = TimePickerEntryMode.input;
//           break;
//         case TimePickerEntryMode.input:
//           _formKey.currentState.save();
//           _entryMode = TimePickerEntryMode.dial;
//           break;
//       }
//     });
//   }

  void _announceModeOnce() {
    if (_lastModeAnnounced == _mode) {
      // Already announced it.
      return;
    }

    switch (_mode) {
      case _TimePickerMode.hour:
        _announceToAccessibility(
            context, localizations.timePickerHourModeAnnouncement);
        break;
      case _TimePickerMode.minute:
        _announceToAccessibility(
            context, localizations.timePickerMinuteModeAnnouncement);
        break;
    }
    _lastModeAnnounced = _mode;
  }

  bool _announcedInitialTime = false;

  void _announceInitialTimeOnce() {
    if (_announcedInitialTime) return;

    final MediaQueryData media = MediaQuery.of(context);
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    _announceToAccessibility(
      context,
      localizations.formatTimeOfDay(widget.initialTime,
          alwaysUse24HourFormat: media.alwaysUse24HourFormat),
    );
    _announcedInitialTime = true;
  }

  void _handleTimeChanged(TimeOfDay? value) {
    _vibrate();
    setState(() {
      _selectedTime = value;
    });
  }

  void _handleHourSelected() {
    setState(() {
      _mode = _TimePickerMode.minute;
    });
  }

  void _handleCancel() {
    Navigator.pop(context);
  }

  void _handleOk() {
    if (!_isSelectableTime(selectedTime)) {
      _notifyFailValidation();
      return;
    }

    if (_entryMode == TimePickerEntryMode.input) {
      final FormState form = _formKey.currentState!;
      if (!form.validate()) {
//         setState(() {
//           _autoValidate = true;
//         });
        return;
      }
      form.save();
    }
    Navigator.pop(context, _selectedTime);
  }

  Size _dialogSize(BuildContext context) {
    final Orientation orientation = MediaQuery.of(context).orientation;
    final ThemeData theme = Theme.of(context);
    // Constrain the textScaleFactor to prevent layout issues. Since only some
    // parts of the time picker scale up with textScaleFactor, we cap the factor
    // to 1.1 as that provides enough space to reasonably fit all the content.
    final double textScaleFactor =
        math.min(MediaQuery.textScalerOf(context).scale(1.0), 1.1);

    late double timePickerWidth;
    late double timePickerHeight;
    switch (_entryMode) {
      case null:
        break;
      case TimePickerEntryMode.dial:
        switch (orientation) {
          case Orientation.portrait:
            timePickerWidth = _kTimePickerWidthPortrait;
            timePickerHeight =
                theme.materialTapTargetSize == MaterialTapTargetSize.padded
                    ? _kTimePickerHeightPortrait
                    : _kTimePickerHeightPortraitCollapsed;
            break;
          case Orientation.landscape:
            timePickerWidth = _kTimePickerWidthLandscape * textScaleFactor;
            timePickerHeight =
                theme.materialTapTargetSize == MaterialTapTargetSize.padded
                    ? _kTimePickerHeightLandscape
                    : _kTimePickerHeightLandscapeCollapsed;
            break;
        }
        break;
      case TimePickerEntryMode.input:
        timePickerWidth = _kTimePickerWidthPortrait;
        timePickerHeight = _kTimePickerHeightInput;
        break;
    }
    return Size(timePickerWidth, timePickerHeight * textScaleFactor);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final MediaQueryData media = MediaQuery.of(context);
//     final TimeOfDayFormat timeOfDayFormat = localizations.timeOfDayFormat(
//         alwaysUse24HourFormat: false //media.alwaysUse24HourFormat
//         );
    const bool use24HourDials =
        false; // hourFormat(of: timeOfDayFormat) != HourFormat.h;
    final ThemeData theme = Theme.of(context);
    final ShapeBorder shape =
        TimePickerTheme.of(context).shape ?? _kDefaultShape;
    final Orientation orientation = media.orientation;

    final Widget actions = Row(
      children: <Widget>[
        const SizedBox(width: 10.0),
        // IconButton(
        //   color: TimePickerTheme.of(context).entryModeIconColor ??
        //       theme.colorScheme.onSurface.withValues(alpha:
        //         theme.colorScheme.brightness == Brightness.dark ? 1.0 : 0.6,
        //       ),
        //   onPressed: _handleEntryModeToggle,
        //   icon: Icon(_entryMode == TimePickerEntryMode.dial
        //       ? Icons.keyboard
        //       : Icons.access_time),
        //   tooltip: _entryMode == TimePickerEntryMode.dial
        //       ? MaterialLocalizations.of(context).inputTimeModeButtonLabel
        //       : MaterialLocalizations.of(context).dialModeButtonLabel,
        // ),
        Expanded(
          child: OverflowBar(
            // layoutBehavior: ButtonBarLayoutBehavior.constrained,
            children: <Widget>[
              TextButton(
                style: TimePickerTheme.of(context).cancelButtonStyle,
                onPressed: _handleCancel,
                child: Text(
                  widget.cancelText ?? localizations.cancelButtonLabel,
                ),
              ),
              TextButton(
                style: TimePickerTheme.of(context).confirmButtonStyle,
                onPressed: _handleOk,
                child: Text(widget.confirmText ?? localizations.okButtonLabel),
              ),
            ],
          ),
        ),
      ],
    );

    Widget? picker;
    switch (_entryMode) {
      case null:
        break;
      case TimePickerEntryMode.dial:
        final Widget dial = Padding(
          padding: orientation == Orientation.portrait
              ? const EdgeInsets.symmetric(horizontal: 36, vertical: 24)
              : const EdgeInsets.all(24),
          child: ExcludeSemantics(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: _Dial(
                  mode: _mode,
                  use24HourDials: use24HourDials,
                  selectedTime: _selectedTime!,
                  onChanged: _handleTimeChanged,
                  onHourSelected: _handleHourSelected,
                  selectableTimePredicate: _selectableTimePredicate),
            ),
          ),
        );

        final Widget header = _TimePickerHeader(
          selectedTime: _selectedTime!,
          mode: _mode,
          orientation: orientation,
          onModeChanged: _handleModeChanged,
          onChanged: _handleTimeChanged,
          use24HourDials: use24HourDials,
          helpText: widget.helpText,
          selectableTimePredicate: _selectableTimePredicate,
        );

        switch (orientation) {
          case Orientation.portrait:
            picker = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                header,
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Dial grows and shrinks with the available space.
                      Expanded(child: dial),
                      actions,
                    ],
                  ),
                ),
              ],
            );
            break;
          case Orientation.landscape:
            picker = Column(
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: <Widget>[
                      header,
                      Expanded(child: dial),
                    ],
                  ),
                ),
                actions,
              ],
            );
            break;
        }
        break;
      case TimePickerEntryMode.input:
        picker = Form(
          key: _formKey,
//           autovalidate: _autoValidate,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _TimePickerInput(
                  initialSelectedTime: _selectedTime!,
                  helpText: widget.helpText,
                  onChanged: _handleTimeChanged,
                ),
                actions,
              ],
            ),
          ),
        );
        break;
    }

    final Size dialogSize = _dialogSize(context);
    return Dialog(
      shape: shape,
      backgroundColor: TimePickerTheme.of(context).backgroundColor ??
          theme.colorScheme.surface,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: _entryMode == TimePickerEntryMode.input ? 0.0 : 24.0,
      ),
      child: AnimatedContainer(
        width: dialogSize.width,
        height: dialogSize.height,
        duration: _kDialogSizeAnimationDuration,
        curve: Curves.easeIn,
        child: picker,
      ),
    );
  }

  @override
  void dispose() {
    _vibrateTimer?.cancel();
    _vibrateTimer = null;
    super.dispose();
  }
}

/// Shows a dialog containing a material design time picker.
///
/// The returned Future resolves to the time selected by the user when the user
/// closes the dialog. If the user cancels the dialog, null is returned.
///
/// {@tool snippet}
/// Show a dialog with [initialTime] equal to the current time.
///
/// ```dart
/// Future<TimeOfDay> selectedTime = showTimePicker(
///   initialTime: TimeOfDay.now(),
///   context: context,
/// );
/// ```
/// {@end-tool}
///
/// The [context], [useRootNavigator] and [routeSettings] arguments are passed to
/// [showDialog], the documentation for which discusses how it is used.
///
/// The [builder] parameter can be used to wrap the dialog widget
/// to add inherited widgets like [Localizations.override],
/// [Directionality], or [MediaQuery].
///
/// The [entryMode] parameter can be used to
/// determine the initial time entry selection of the picker (either a clock
/// dial or text input).
///
/// Optional strings for the [helpText], [cancelText], and [confirmText] can be
/// provided to override the default values.
///
/// {@tool snippet}
/// Show a dialog with the text direction overridden to be [TextDirection.rtl].
///
/// ```dart
/// Future<TimeOfDay> selectedTimeRTL = showTimePicker(
///   context: context,
///   initialTime: TimeOfDay.now(),
///   builder: (BuildContext context, Widget child) {
///     return Directionality(
///       textDirection: TextDirection.rtl,
///       child: child,
///     );
///   },
/// );
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// Show a dialog with time unconditionally displayed in 24 hour format.
///
/// ```dart
/// Future<TimeOfDay> selectedTime24Hour = showTimePicker(
///   context: context,
///   initialTime: TimeOfDay(hour: 10, minute: 47),
///   builder: (BuildContext context, Widget child) {
///     return MediaQuery(
///       data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
///       child: child,
///     );
///   },
/// );
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [showDatePicker], which shows a dialog that contains a material design
///    date picker.
Future<TimeOfDay?> showSimpleTimePicker(
    {required BuildContext context,
    required TimeOfDay initialTime,
    TransitionBuilder? builder,
    bool useRootNavigator = true,
    TimePickerEntryMode initialEntryMode = TimePickerEntryMode.dial,
    String? cancelText,
    String? confirmText,
    String? helpText,
    RouteSettings? routeSettings,
    bool Function(TimeOfDay?)? selectableTimePredicate,
    Function(BuildContext)? onFailValidation}) async {
  assert(debugCheckHasMaterialLocalizations(context));
  assert(onFailValidation != null || selectableTimePredicate == null,
      "'onFailValidation' can't be null if 'selectableTimePredicate' has been set");

  _isSelectableTime = (time) => selectableTimePredicate?.call(time) ?? true;

  final Widget dialog = _TimePickerDialog(
      initialTime: initialTime,
      initialEntryMode: initialEntryMode,
      cancelText: cancelText,
      confirmText: confirmText,
      helpText: helpText,
      selectableTimePredicate: selectableTimePredicate);
  return await showDialog<TimeOfDay>(
    context: context,
    useRootNavigator: useRootNavigator,
    builder: (BuildContext context) {
      _notifyFailValidation = () => onFailValidation?.call(context);
      return builder == null ? dialog : builder(context, dialog);
    },
    routeSettings: routeSettings,
  );
}

void _announceToAccessibility(BuildContext context, String message) {
  SemanticsService.announce(message, Directionality.of(context));
}

late bool Function(TimeOfDay? time) _isSelectableTime;
late Function() _notifyFailValidation;
