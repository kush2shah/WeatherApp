# Daily Weather Detail View - Design

## Overview

A bottom sheet detail view that appears when tapping a day in the daily forecast list. Shows rich weather insights with hourly breakdowns, conditions grid, and multi-source comparison.

## Navigation & Presentation

- **Trigger**: Tap any day row in `DailyForecastCard`
- **Presentation**: Bottom sheet (`.sheet` modifier)
- **Detents**: Medium default, expandable to large
- **Dismiss**: Swipe down or drag indicator

## Header

- Full date display (e.g., "Wednesday, January 29")
- High/low temperature prominently displayed
- Condition icon and description
- **Source picker**: Segmented control with:
  - All available weather sources (WeatherKit, NOAA, etc.)
  - "Compare" option as final segment

## Primary Content: Hourly Timeline

Shown when hourly data is available for the selected day.

### Layout
- Horizontal scrolling row beneath header
- Auto-scrolls to current hour when viewing today

### Per-Hour Cell (Rich but Uncluttered)
Vertical stack with clear hierarchy:
1. Time (12h format, subtle weight)
2. Condition icon (SF Symbols, 24pt)
3. Temperature (prominent, medium weight)
4. Precipitation % (small, blue tint, only shown if >0%)
5. Wind speed (small, secondary color)

### Visual Treatment
- Ultra-thin material background
- Generous horizontal padding (whitespace as separator, no borders)
- Subtle gradient highlight on current hour
- Smooth momentum scrolling

## Fallback/Secondary: Conditions Grid

Shown as fallback when hourly unavailable, or as supplementary info below hourly.

### Layout
- 2x2 grid (expands to 2x3 when precipitation relevant)
- Each card: icon, value, label - vertically stacked, center-aligned

### Default Metrics (always shown)
- **Sunrise/Sunset**: Combined card with both times
- **UV Index**: Value with severity color coding
- **Humidity**: Percentage
- **Wind**: Speed and direction

### Precipitation Metrics (when chance >10%)
- **Precipitation chance**: Percentage
- **Precipitation amount**: mm or inches

## Comparison View (When "Compare" Selected)

Replaces hourly timeline area when user selects "Compare" in the source picker.

### Mini Charts (One Per Metric)
- **Temperature range**: Horizontal bars showing high/low per source
- **Precipitation chance**: Bar chart per source
- **Wind speed**: Bar chart per source

### Visual Treatment
- Consistent color per source across all charts
- Source legend at top
- Compact chart heights to minimize scrolling

## Design Principles

- **Neo-futuristic Jony Ive aesthetic**: Clean, minimal, generous whitespace
- **Information hierarchy through typography**, not borders or decoration
- **Ultra-thin materials** for depth without heaviness
- **SF Symbols** throughout
- **Contextual relevance**: Show precipitation only when >10% chance
