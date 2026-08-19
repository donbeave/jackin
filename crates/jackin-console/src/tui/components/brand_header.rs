//! jackin❯ brand header composition.

use ratatui::buffer::Buffer;
use ratatui::layout::{Alignment, Rect};
use ratatui::style::{Modifier, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::{Paragraph, Widget};

#[derive(Debug, Clone, Copy)]
struct BrandHeader<'a> {
    label: &'a str,
}

impl Widget for BrandHeader<'_> {
    fn render(self, area: Rect, buffer: &mut Buffer) {
        Paragraph::new(brand_header_line(self.label))
            .alignment(Alignment::Left)
            .render(area, buffer);
    }
}

fn brand_header_line(label: &str) -> Line<'static> {
    let block = Style::default()
        .bg(jackin_tui::tokens::BRAND_BLOCK)
        .add_modifier(Modifier::BOLD);
    // The chevron/separator/label pin jackin❯-owned brand constants: head's
    // palette recolored the roles they used to read, and the brand look is an
    // invariant across the bump.
    Line::from(vec![
        Span::styled(" jackin", block.fg(jackin_tui::tokens::INK)),
        Span::styled("❯", block.fg(jackin_tui::tokens::BRAND_CHEVRON)),
        Span::styled(" ", block),
        Span::styled(
            " · ",
            Style::default().fg(jackin_tui::tokens::BRAND_SEPARATOR),
        ),
        Span::styled(
            label.to_owned(),
            Style::default().fg(jackin_tui::tokens::BRAND_LABEL),
        ),
    ])
}

pub fn render_brand_header(frame: &mut ratatui::Frame<'_>, area: Rect, label: &str) {
    frame.render_widget(BrandHeader { label }, area);
}

#[cfg(test)]
mod tests;
