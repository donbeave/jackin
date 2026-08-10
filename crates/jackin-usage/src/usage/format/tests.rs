use super::compact_duration_label;

#[test]
fn under_one_hour_is_minutes() {
    assert_eq!(compact_duration_label(0), "0m");
    assert_eq!(compact_duration_label(45 * 60), "45m");
    assert_eq!(compact_duration_label(3_599), "59m");
}

#[test]
fn under_forty_eight_hours_stays_hours_not_days() {
    assert_eq!(compact_duration_label(24 * 3_600), "24h");
    assert_eq!(compact_duration_label(36 * 3_600), "36h");
    assert_eq!(compact_duration_label(36 * 3_600 + 30 * 60), "36h 30m");
    assert_eq!(compact_duration_label(47 * 3_600), "47h");
    assert_eq!(compact_duration_label(47 * 3_600 + 59 * 60), "47h 59m");
    let label = compact_duration_label(47 * 3_600);
    assert!(!label.contains('d'), "got day form under 48h: {label}");
}

#[test]
fn at_and_above_forty_eight_hours_uses_days() {
    assert_eq!(compact_duration_label(48 * 3_600), "2d");
    assert_eq!(compact_duration_label(48 * 3_600 + 3_600), "2d 1h");
    assert_eq!(compact_duration_label(72 * 3_600), "3d");
    assert_eq!(compact_duration_label(3 * 86_400 + 4 * 3_600), "3d 4h");
}
