/// Geometry matches the bundled v1 SVG polygons in a 100 × 200 viewBox.
/// Keep this revision when adding future assets. Coordinates use image bounds.
final class BodyRegion {
  const BodyRegion(this.code, this.points);
  final String code;
  final List<(double, double)> points;
  (double, double) get center => (
    points.fold<double>(0, (s, p) => s + p.$1) / points.length / 100,
    points.fold<double>(0, (s, p) => s + p.$2) / points.length / 200,
  );
  bool contains(double x, double y) {
    var inside = false;
    for (var i = 0, j = points.length - 1; i < points.length; j = i++) {
      final a = points[i];
      final b = points[j];
      if ((a.$2 > y * 200) != (b.$2 > y * 200) &&
          x * 100 < (b.$1 - a.$1) * (y * 200 - a.$2) / (b.$2 - a.$2) + a.$1) {
        inside = !inside;
      }
    }
    return inside;
  }
}

const bodyRegionsV1 = [
  BodyRegion('head', [
    (43, 4),
    (57, 4),
    (63, 12),
    (61, 24),
    (55, 30),
    (45, 30),
    (39, 24),
    (37, 12),
  ]),
  BodyRegion('torso', [
    (43, 30),
    (57, 30),
    (69, 40),
    (63, 94),
    (60, 110),
    (40, 110),
    (37, 94),
    (31, 40),
  ]),
  BodyRegion('viewer_left_arm', [
    (31, 40),
    (38, 48),
    (30, 76),
    (22, 109),
    (14, 112),
    (13, 104),
    (22, 71),
  ]),
  BodyRegion('viewer_right_arm', [
    (69, 40),
    (62, 48),
    (70, 76),
    (78, 109),
    (86, 112),
    (87, 104),
    (78, 71),
  ]),
  BodyRegion('viewer_left_leg', [
    (40, 110),
    (49, 110),
    (48, 151),
    (44, 188),
    (44, 196),
    (30, 196),
    (33, 185),
    (34, 151),
  ]),
  BodyRegion('viewer_right_leg', [
    (51, 110),
    (60, 110),
    (66, 151),
    (67, 185),
    (70, 196),
    (56, 196),
    (56, 188),
    (52, 151),
  ]),
];

BodyRegion? bodyRegionAt(double x, double y) {
  if (!x.isFinite || !y.isFinite || x < 0 || x > 1 || y < 0 || y > 1) {
    return null;
  }
  for (final region in bodyRegionsV1) {
    if (region.contains(x, y)) return region;
  }
  return null;
}

String anatomicalRegion(BodyRegion region, String view) {
  final side = region.code.startsWith('viewer_left')
      ? (view == 'front' ? 'right' : 'left')
      : (view == 'front' ? 'left' : 'right');
  return region.code
      .replaceFirst('viewer_left', side)
      .replaceFirst('viewer_right', side);
}
