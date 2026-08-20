// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

//! Shared jackin❯ application-adapter wiring for the console TUI.
//!
//! The shared TEA `Component<Ev, Msg>` and `View<Model>` contracts live in
//! `jackin_tui::runtime`. This module is the console's implementation of
//! those traits over its model (`ConsoleState`) and the existing render
//! function (`crate::tui::view::render`). The trait impls are thin
//! delegations that satisfy the shared contract at the type level. The
//! existing event loop in `crates/jackin/src/console/adapter/run.rs` owns
//! scheduling and dispatches rendering through this adapter.

#[derive(Debug)]
pub struct ConsoleViewContext<'a> {
    pub config: &'a jackin_config::AppConfig,
    pub cwd: &'a std::path::Path,
}

#[derive(Debug)]
pub struct ConsoleView<'a> {
    pub context: ConsoleViewContext<'a>,
}

impl jackin_tui::runtime::View<crate::tui::console::ConsoleState> for ConsoleView<'_> {
    fn render(
        &self,
        model: &crate::tui::console::ConsoleState,
        frame: &mut ratatui::Frame<'_>,
        area: ratatui::layout::Rect,
    ) {
        let crate::tui::console::ConsoleStage::Manager(ms) = &model.stage;
        crate::tui::view::render(frame, area, ms, self.context.config, self.context.cwd);
    }
}

use std::future::Future;

/// Console-owned blocking-subscription poll tri-state (re-homed from the
/// retired facade contract).
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum SubscriptionPoll<T> {
    /// The worker finished and yielded its value.
    Ready(T),
    /// The worker is still running.
    Pending,
    /// The worker was dropped without yielding a value.
    Closed,
}

#[derive(Debug)]
enum BlockingSource<T> {
    Receiver(tokio::sync::oneshot::Receiver<T>),
    Ready(termrock::runtime::ReadySubscription<T>),
}

/// A one-shot blocking worker's receiver: poll it until it yields or closes.
#[derive(Debug)]
pub struct BlockingSubscription<T>(BlockingSource<T>);

impl<T> BlockingSubscription<T> {
    pub fn poll_next(&mut self) -> SubscriptionPoll<T> {
        match &mut self.0 {
            BlockingSource::Receiver(rx) => match rx.try_recv() {
                Ok(value) => SubscriptionPoll::Ready(value),
                Err(tokio::sync::oneshot::error::TryRecvError::Empty) => SubscriptionPoll::Pending,
                Err(tokio::sync::oneshot::error::TryRecvError::Closed) => SubscriptionPoll::Closed,
            },
            BlockingSource::Ready(ready) => match ready.poll_next() {
                termrock::runtime::ReadySubscriptionPoll::Ready(value) => {
                    SubscriptionPoll::Ready(value)
                }
                // `ReadySubscriptionPoll` is non-exhaustive; every non-Ready
                // arm means the one-shot value is gone.
                _ => SubscriptionPoll::Closed,
            },
        }
    }
}

pub fn ready_blocking_subscription<T>(value: T) -> BlockingSubscription<T> {
    BlockingSubscription(BlockingSource::Ready(
        termrock::runtime::ready_subscription(value),
    ))
}

pub fn spawn_blocking_subscription<T, F>(worker: F) -> BlockingSubscription<T>
where
    T: Send + 'static,
    F: FnOnce() -> T + Send + 'static,
{
    spawn_named_blocking_subscription("jackin-console-blocking-subscription", worker)
}

pub fn spawn_named_blocking_subscription<T, F>(
    name: impl Into<String>,
    worker: F,
) -> BlockingSubscription<T>
where
    T: Send + 'static,
    F: FnOnce() -> T + Send + 'static,
{
    let (tx, rx) = tokio::sync::oneshot::channel();
    let run = move || drop(tx.send(worker()));
    let name = name.into();
    if tokio::runtime::Handle::try_current().is_ok() {
        drop(jackin_telemetry::spawn::joined_blocking(run));
    } else {
        drop(jackin_telemetry::spawn::thread_joined_named(name, run));
    }
    BlockingSubscription(BlockingSource::Receiver(rx))
}

pub fn spawn_named_async_subscription<T, F>(
    name: impl Into<String>,
    future: F,
) -> BlockingSubscription<T>
where
    T: Send + 'static,
    F: Future<Output = T> + Send + 'static,
{
    let (tx, rx) = tokio::sync::oneshot::channel();
    let run = async move { drop(tx.send(future.await)) };
    let name = name.into();
    if tokio::runtime::Handle::try_current().is_ok() {
        drop(jackin_telemetry::spawn::spawn_joined(run));
    } else {
        drop(jackin_telemetry::spawn::thread_joined_named(
            name,
            move || {
                if let Ok(runtime) = tokio::runtime::Builder::new_current_thread()
                    .enable_all()
                    .build()
                {
                    runtime.block_on(run);
                }
            },
        ));
    }
    BlockingSubscription(BlockingSource::Receiver(rx))
}
