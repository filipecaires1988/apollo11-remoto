use std::collections::HashMap;

use hbb_common::config;
use serde_json::{json, Value};
use url::Url;

const URL_OPTION: &str = "apollo11-central-url";
const TOKEN_OPTION: &str = "apollo11-central-token";

struct Heartbeat {
    endpoint: Url,
    token: String,
    payload: Value,
}

fn heartbeat_endpoint(base: &str) -> Result<Url, &'static str> {
    if base.len() > 2048 || base != base.trim() {
        return Err("Invalid catalog address");
    }
    let mut endpoint = Url::parse(base).map_err(|_| "Invalid catalog address")?;
    if endpoint.scheme() != "https"
        || endpoint.host_str().is_none()
        || !endpoint.username().is_empty()
        || endpoint.password().is_some()
        || endpoint.query().is_some()
        || endpoint.fragment().is_some()
    {
        return Err("The catalog requires HTTPS without credentials, query or fragment");
    }
    endpoint
        .query_pairs_mut()
        .append_pair("route", "/v1/heartbeat");
    Ok(endpoint)
}

fn prepare_heartbeat(
    options: &HashMap<String, String>,
    peer_id: &str,
    platform: &str,
) -> Result<Option<Heartbeat>, &'static str> {
    if options
        .get("stop-service")
        .map(|value| config::option2bool("stop-service", value))
        .unwrap_or(false)
    {
        return Ok(None);
    }
    let base = options.get(URL_OPTION).map(String::as_str).unwrap_or("");
    let token = options.get(TOKEN_OPTION).map(String::as_str).unwrap_or("");
    // Enrollment clears the token before changing the endpoint or unlinking the device.
    if base.is_empty() || token.is_empty() {
        return Ok(None);
    }
    let endpoint = heartbeat_endpoint(base)?;
    if !(32..=256).contains(&token.len())
        || !token
            .bytes()
            .all(|c| c.is_ascii_alphanumeric() || c == b'-' || c == b'_')
    {
        return Err("Invalid catalog device credential");
    }
    if !(6..=16).contains(&peer_id.len()) || !peer_id.bytes().all(|c| c.is_ascii_digit()) {
        return Err("Invalid catalog device ID");
    }
    Ok(Some(Heartbeat {
        endpoint,
        token: token.to_owned(),
        payload: json!({"peer_id": peer_id, "platform": platform}),
    }))
}

#[cfg(any(target_os = "windows", target_os = "macos"))]
pub fn start() {
    use std::{sync::Once, time::Duration};

    use hbb_common::{config::Config, log, tokio};

    static STARTED: Once = Once::new();
    STARTED.call_once(|| {
        tokio::spawn(async {
            loop {
                let platform = if cfg!(target_os = "windows") {
                    "Windows"
                } else {
                    "macOS"
                };
                let options = Config::get_options();
                // Do not generate an ID or open a connection for an unlinked device.
                if options.get(TOKEN_OPTION).map_or(false, |v| !v.is_empty()) {
                    match prepare_heartbeat(&options, &Config::get_id(), platform) {
                        Ok(Some(heartbeat)) => {
                            let client = reqwest::Client::builder()
                                .no_proxy()
                                .https_only(true)
                                .redirect(reqwest::redirect::Policy::none())
                                .connect_timeout(Duration::from_secs(5))
                                .timeout(Duration::from_secs(10))
                                .build();
                            match client {
                                Ok(client) => {
                                    let response = client
                                        .post(heartbeat.endpoint)
                                        .bearer_auth(heartbeat.token)
                                        .json(&heartbeat.payload)
                                        .send()
                                        .await;
                                    match response {
                                        Ok(response) if response.status().is_success() => {}
                                        _ => log::trace!("Apollo11 catalog contact failed"),
                                    }
                                }
                                Err(_) => log::trace!("Apollo11 catalog HTTPS client unavailable"),
                            }
                        }
                        Ok(None) => {}
                        Err(reason) => log::trace!("Apollo11 catalog configuration: {reason}"),
                    }
                }
                tokio::time::sleep(Duration::from_secs(60)).await;
            }
        });
    });
}

#[cfg(test)]
mod tests {
    use super::*;

    fn options() -> HashMap<String, String> {
        HashMap::from([
            (URL_OPTION.to_owned(), "https://central.example/api.php".to_owned()),
            (TOKEN_OPTION.to_owned(), "a".repeat(64)),
        ])
    }

    #[test]
    fn catalog_endpoint_keeps_api_path_and_rejects_unsafe_addresses() {
        let endpoint = heartbeat_endpoint("https://central.example/sub/api.php").unwrap();
        assert_eq!(endpoint.path(), "/sub/api.php");
        assert_eq!(
            endpoint.query_pairs().into_owned().collect::<Vec<_>>(),
            vec![("route".to_owned(), "/v1/heartbeat".to_owned())]
        );
        for base in [
            "http://central.example/api.php",
            "https://user:secret@central.example/api.php",
            "https://central.example/api.php?route=/v1/enroll",
            "https://central.example/api.php#secret",
            " https://central.example/api.php",
            "file:///api.php",
        ] {
            assert!(heartbeat_endpoint(base).is_err());
        }
    }

    #[test]
    fn unlinked_or_stopped_service_sends_no_heartbeat() {
        assert!(prepare_heartbeat(&HashMap::new(), "123456789", "Windows")
            .unwrap()
            .is_none());
        let mut values = options();
        values.insert(TOKEN_OPTION.to_owned(), String::new());
        assert!(prepare_heartbeat(&values, "123456789", "Windows")
            .unwrap()
            .is_none());
        values = options();
        values.insert("stop-service".to_owned(), "Y".to_owned());
        assert!(prepare_heartbeat(&values, "123456789", "Windows")
            .unwrap()
            .is_none());
    }

    #[test]
    fn heartbeat_contains_only_catalog_identity_and_uses_separate_credential() {
        let mut values = options();
        values.insert("apollo11-central-name".to_owned(), "Private PC".to_owned());
        let heartbeat = prepare_heartbeat(&values, "123456789", "Windows")
            .unwrap()
            .unwrap();
        assert_eq!(heartbeat.payload, json!({"peer_id":"123456789", "platform":"Windows"}));
        assert_eq!(heartbeat.token, "a".repeat(64));
        assert!(!heartbeat.endpoint.as_str().contains(&heartbeat.token));
        values.insert(TOKEN_OPTION.to_owned(), "bad\r\ncredential".to_owned());
        assert!(prepare_heartbeat(&values, "123456789", "Windows").is_err());
        assert!(prepare_heartbeat(&options(), "123/unsafe", "macOS").is_err());
    }
}
