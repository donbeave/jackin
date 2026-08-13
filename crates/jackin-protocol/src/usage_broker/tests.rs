use super::*;

fn capability() -> UsageAccountCapability {
    UsageAccountCapability {
        account_id: "opaque-account".into(),
        surface_id: "claude".into(),
    }
}

#[test]
fn request_round_trip_preserves_generation_and_force_semantics() {
    let request = UsageBrokerRequest {
        protocol_version: USAGE_BROKER_PROTOCOL_VERSION.into(),
        build_id: "test-build".into(),
        operation: UsageBrokerOperation::Refresh {
            capability: capability(),
            observed_generation: 7,
            force: true,
        },
    };

    let bytes = serde_json::to_vec(&request).unwrap();
    assert!(bytes.len() < USAGE_BROKER_MAX_FRAME_BYTES);
    assert_eq!(
        serde_json::from_slice::<UsageBrokerRequest>(&bytes).unwrap(),
        request
    );
}

#[test]
fn response_round_trip_keeps_typed_sanitized_failure() {
    let response = UsageBrokerResponse::Error {
        error: UsageCoordinationError {
            kind: UsageCoordinationErrorKind::Unauthorized,
            message: "usage account capability is not authorized".into(),
        },
    };

    let bytes = serde_json::to_vec(&response).unwrap();
    assert!(bytes.len() < USAGE_BROKER_MAX_FRAME_BYTES);
    assert_eq!(
        serde_json::from_slice::<UsageBrokerResponse>(&bytes).unwrap(),
        response
    );
}

#[test]
fn scoped_surface_request_round_trip_exposes_no_capability() {
    let request = UsageBrokerRequest {
        protocol_version: USAGE_BROKER_PROTOCOL_VERSION.into(),
        build_id: "test-build".into(),
        operation: UsageBrokerOperation::RefreshForSurface {
            surface_id: "claude".into(),
            observed_generation: 3,
            force: false,
        },
    };

    let bytes = serde_json::to_vec(&request).unwrap();
    assert!(!String::from_utf8_lossy(&bytes).contains("account_id"));
    assert_eq!(
        serde_json::from_slice::<UsageBrokerRequest>(&bytes).unwrap(),
        request
    );
}
