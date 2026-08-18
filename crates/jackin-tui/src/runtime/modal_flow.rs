// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

//! Atomic product modal and overlay-stack lifecycle.

use ratatui::layout::Rect;
use termrock::interaction::{OverlaySize, OverlaySpec, OverlayStack};

/// Modal chain coordinated with a `TermRock` overlay stack.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ModalFlow<Modal> {
    current: Option<Modal>,
    parents: Vec<Modal>,
    stack: OverlayStack,
}

impl<Modal> Default for ModalFlow<Modal> {
    fn default() -> Self {
        Self::new()
    }
}

impl<Modal> ModalFlow<Modal> {
    /// Create an empty modal flow.
    pub fn new() -> Self {
        Self {
            current: None,
            parents: Vec::new(),
            stack: OverlayStack::new(),
        }
    }

    /// Return the active modal.
    pub const fn current(&self) -> Option<&Modal> {
        self.current.as_ref()
    }

    /// Return mutable access to the active modal.
    pub fn current_mut(&mut self) -> Option<&mut Modal> {
        self.current.as_mut()
    }

    /// Return the suspended parent chain.
    pub fn parents(&self) -> &[Modal] {
        &self.parents
    }

    /// Return mutable access to suspended product modals.
    pub fn parents_mut(&mut self) -> &mut Vec<Modal> {
        &mut self.parents
    }

    /// Whether a modal is active.
    pub const fn is_open(&self) -> bool {
        self.current.is_some()
    }

    /// Whether a parent modal can be restored.
    pub fn has_parent(&self) -> bool {
        !self.parents.is_empty()
    }

    /// Open a root modal and matching overlay entry atomically.
    pub fn open(&mut self, modal: Modal) {
        self.stack.clear();
        self.open_entry();
        self.current = Some(modal);
        self.parents.clear();
    }

    /// Open a child modal and matching overlay entry atomically.
    pub fn open_sub(&mut self, modal: Modal) {
        self.open_entry();
        if let Some(parent) = self.current.take() {
            self.parents.push(parent);
        }
        self.current = Some(modal);
    }

    /// Close one modal level and restore its parent.
    pub fn pop(&mut self) {
        if let Some(top) = self.stack.entries().last().map(|entry| entry.id.clone()) {
            drop(self.stack.dismiss(&top));
        }
        self.current = self.parents.pop();
    }

    /// Clear the modal chain and the overlay stack.
    pub fn clear(&mut self) {
        self.stack.clear();
        self.current = None;
        self.parents.clear();
    }

    /// Temporarily take the current product modal during synchronous dispatch.
    pub fn take_current(&mut self) -> Option<Modal> {
        self.current.take()
    }

    /// Restore or replace the current product modal without changing the stack.
    pub fn set_current(&mut self, modal: Modal) {
        self.current = Some(modal);
    }

    /// Push a parent product modal and open a child entry.
    pub fn open_pair(&mut self, parent: Modal, child: Modal) {
        self.open(parent);
        self.open_sub(child);
    }

    /// The stack tracks depth only — jackin❯ owns no overlay geometry here.
    fn open_entry(&mut self) {
        let depth = self.stack.entries().len();
        drop(self.stack.open(
            Rect::new(0, 0, 0, 0),
            OverlaySpec::dialog(
                format!("modal-{depth}"),
                OverlaySize::dialog(0, 0),
                None,
            ),
        ));
    }
}
