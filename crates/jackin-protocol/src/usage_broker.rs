// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

//! Versioned, secret-free usage-broker wire records.

use serde::{Deserialize, Serialize};

use crate::control::FocusedUsageView;

/// Usage-broker wire protocol version.
pub const USAGE_BROKER_PROTOCOL_VERSION: &str = "v1";

/// Maximum newline-delimited request or response body.
pub const USAGE_BROKER_MAX_FRAME_BYTES: usize = 64 * 1024;

/// Opaque authority for one canonical provider account.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub struct UsageAccountCapability {
    /// Host-generated opaque canonical account identifier.
    pub account_id: String,
    /// Closed Rust-owned provider surface identifier.
    pub surface_id: String,
}

/// Lifecycle phase of one account refresh generation.
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum UsageRefreshPhase {
    /// No generation has started.
    Idle,
    /// A bounded worker owns the generation but has not begun its probe.
    Queued,
    /// Provider work is active.
    Updating,
    /// The generation published a data-bearing result.
    Completed,
    /// The generation terminated without replacing last-good data.
    Failed,
}

impl UsageRefreshPhase {
    /// Whether this phase has a terminal result.
    #[must_use]
    pub const fn is_terminal(self) -> bool {
        matches!(self, Self::Completed | Self::Failed)
    }

    /// Whether this phase has an active owner.
    #[must_use]
    pub const fn is_active(self) -> bool {
        matches!(self, Self::Queued | Self::Updating)
    }
}

/// Stable coordination failure category; never contains raw I/O details.
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum UsageCoordinationErrorKind {
    /// Broker or state infrastructure is unavailable.
    Unavailable,
    /// The caller lacks the requested account capability.
    Unauthorized,
    /// The active generation owner disappeared.
    OwnerLost,
    /// A bounded generation wait expired while ownership remained active.
    WaitTimeout,
    /// Persisted state failed validation.
    CorruptState,
    /// Provider work timed out without publishing empty data.
    ProviderTimeout,
    /// Provider declined or cannot supply this usage surface.
    ProviderUnavailable,
    /// Provider authentication needs a host-side secret.
    NeedsSecret,
    /// Provider rate limiting deferred the next generation.
    RateLimited,
    /// Broker protocol or build handshake failed.
    ProtocolMismatch,
}

/// Sanitized coordination error.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct UsageCoordinationError {
    /// Stable failure category.
    pub kind: UsageCoordinationErrorKind,
    /// Bounded operator-facing message with no path or credential material.
    pub message: String,
}

/// Current projection of one canonical refresh generation.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct UsageGenerationView {
    /// Account authority this state belongs to.
    pub capability: UsageAccountCapability,
    /// Monotonic per-account generation number.
    pub generation: u64,
    /// Current generation phase.
    pub phase: UsageRefreshPhase,
    /// Sanitized current or preserved last-good quota projection.
    pub snapshot: Option<FocusedUsageView>,
    /// Typed terminal or coordination failure.
    pub error: Option<UsageCoordinationError>,
    /// Shared provider retry deadline when supplied.
    pub retry_at_epoch: Option<i64>,
}

/// One client operation against the host usage broker.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(tag = "operation", rename_all = "snake_case")]
pub enum UsageBrokerOperation {
    /// Relay-only current-state request for one known provider surface.
    /// The per-container relay resolves this to exactly one allowed capability;
    /// the global host broker rejects this operation directly.
    CurrentForSurface {
        /// Closed provider surface id already known to the Capsule.
        surface_id: String,
    },
    /// Relay-only refresh request for one known provider surface.
    RefreshForSurface {
        /// Closed provider surface id already known to the Capsule.
        surface_id: String,
        /// Last generation observed by the caller.
        observed_generation: u64,
        /// True only for an explicit operator Refresh action.
        force: bool,
    },
    /// Relay-only wait for one surface generation.
    JoinForSurface {
        /// Closed provider surface id already known to the Capsule.
        surface_id: String,
        /// Generation returned by a prior refresh request.
        generation: u64,
        /// Bounded client wait in milliseconds.
        timeout_ms: u64,
    },
    /// Read current account state without starting provider work.
    Current {
        /// Authorized account.
        capability: UsageAccountCapability,
    },
    /// Request or join a refresh generation.
    Refresh {
        /// Authorized account.
        capability: UsageAccountCapability,
        /// Last generation observed by the caller.
        observed_generation: u64,
        /// True only for an explicit operator Refresh action.
        force: bool,
    },
    /// Wait for a named generation to become terminal.
    Join {
        /// Authorized account.
        capability: UsageAccountCapability,
        /// Generation returned by a prior refresh request.
        generation: u64,
        /// Bounded client wait in milliseconds.
        timeout_ms: u64,
    },
}

/// Versioned request envelope with a build handshake.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct UsageBrokerRequest {
    /// [`USAGE_BROKER_PROTOCOL_VERSION`].
    pub protocol_version: String,
    /// Exact host build identifier.
    pub build_id: String,
    /// Requested operation.
    pub operation: UsageBrokerOperation,
}

/// Versioned broker response.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(tag = "status", rename_all = "snake_case")]
pub enum UsageBrokerResponse {
    /// Operation succeeded or joined an active generation.
    State {
        /// Current generation projection.
        state: Box<UsageGenerationView>,
    },
    /// Operation failed before provider dispatch.
    Error {
        /// Typed sanitized failure.
        error: UsageCoordinationError,
    },
}

#[cfg(test)]
mod tests;
