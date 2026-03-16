use std::path::PathBuf;
use std::sync::{Arc, Mutex};
use std::process::Command;

/// Audio recording state (Send + Sync safe)
#[derive(Clone, Default)]
pub struct AudioRecorder {
    inner: Arc<Mutex<AudioRecorderInner>>,
}

struct AudioRecorderInner {
    is_recording: bool,
    current_file: Option<PathBuf>,
}

impl Default for AudioRecorderInner {
    fn default() -> Self {
        Self {
            is_recording: false,
            current_file: None,
        }
    }
}

impl AudioRecorder {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn is_recording(&self) -> bool {
        self.inner.lock().unwrap().is_recording
    }

    pub fn start_recording(&self) -> Result<String, String> {
        let mut inner = self.inner.lock().unwrap();

        if inner.is_recording {
            return Err("Already recording".to_string());
        }

        let temp_dir = std::env::temp_dir();
        let file_path = temp_dir.join(format!(
            "voice_input_{}.wav",
            chrono::Local::now().timestamp()
        ));

        // Use `sox` or `ffmpeg` for recording if available
        // Otherwise, use macOS's built-in `afrecord` (deprecated but available)
        // or the modern approach using `avfoundation`

        #[cfg(target_os = "macos")]
        {
            // Try using ffmpeg for audio recording (most reliable)
            let result = Command::new("ffmpeg")
                .args([
                    "-f", "avfoundation",
                    "-i", ":0",
                    "-t", "300", // 5 minutes max
                    "-ac", "1",
                    "-ar", "16000",
                    "-y",
                    file_path.to_str().unwrap(),
                ])
                .spawn();

            match result {
                Ok(child) => {
                    inner.is_recording = true;
                    inner.current_file = Some(file_path.clone());
                    // Drop the child intentionally - it will continue running
                    // We'll terminate it when stopping
                    std::mem::forget(child);
                    Ok(file_path.to_str().unwrap().to_string())
                }
                Err(_) => {
                    // Fallback: try using afplay/rec approach
                    // For now, return error if ffmpeg not available
                    Err("ffmpeg not found. Please install: brew install ffmpeg".to_string())
                }
            }
        }

        #[cfg(not(target_os = "macos"))]
        {
            Err("Audio recording only supported on macOS".to_string())
        }
    }

    pub fn stop_recording(&self) -> Result<(), String> {
        let mut inner = self.inner.lock().unwrap();

        if !inner.is_recording {
            return Err("Not recording".to_string());
        }

        #[cfg(target_os = "macos")]
        {
            // Kill any ffmpeg recording processes
            let _ = Command::new("pkill")
                .args(["-INT", "ffmpeg"])
                .status();

            inner.is_recording = false;
            inner.current_file = None;
            Ok(())
        }

        #[cfg(not(target_os = "macos"))]
        {
            Err("Audio recording only supported on macOS".to_string())
        }
    }

    pub fn get_current_file(&self) -> Option<PathBuf> {
        self.inner.lock().unwrap().current_file.clone()
    }
}

// Alternative: Use AVFoundation via objc for direct recording
// This is a simpler version that avoids Send/Sync issues
#[cfg(target_os = "macos")]
pub mod av_audio {
    use cocoa::base::{id, nil};
    use cocoa::foundation::{NSString};
    use objc::{class, msg_send, sel, sel_impl};
    use std::path::PathBuf;

    pub struct AvAudioRecorder {
        // This struct exists only for the AVFoundation API wrapper
        // We don't store the recorder in Tauri state to avoid Send/Sync issues
    }

    impl AvAudioRecorder {
        pub unsafe fn record_to_file(path: &PathBuf) -> Result<(), String> {
            let ns_path = NSString::alloc(nil).init_str(path.to_str().unwrap());

            let url: id = msg_send![class!(NSURL), fileURLWithPath: ns_path];

            let settings: id = msg_send![class!(NSMutableDictionary), alloc];
            let settings: id = msg_send![settings, init];

            // Configure for WAV output
            let format_key = NSString::alloc(nil).init_str("AVFormatIDKey");
            let linear_pcm: u32 = 0x6c70636d; // 'lpcm'
            let _: () = msg_send![settings, setObject: &(linear_pcm as i32) forKey: format_key];

            let sample_rate_key = NSString::alloc(nil).init_str("AVSampleRateKey");
            let sample_rate: f64 = 16000.0;
            let _: () = msg_send![settings, setObject: &(sample_rate as f64) forKey: sample_rate_key];

            let channels_key = NSString::alloc(nil).init_str("AVNumberOfChannelsKey");
            let channels: u32 = 1;
            let _: () = msg_send![settings, setObject: &(channels as u32) forKey: channels_key];

            let bit_depth_key = NSString::alloc(nil).init_str("AVLinearPCMBitDepthKey");
            let bit_depth: u32 = 16;
            let _: () = msg_send![settings, setObject: &(bit_depth as u32) forKey: bit_depth_key];

            let big_endian_key = NSString::alloc(nil).init_str("AVLinearPCMIsBigEndianKey");
            let _: () = msg_send![settings, setObject: &(false as u8) forKey: big_endian_key];

            let float_key = NSString::alloc(nil).init_str("AVLinearPCMIsFloatKey");
            let _: () = msg_send![settings, setObject: &(false as u8) forKey: float_key];

            let session: id = msg_send![class!(AVAudioSession), sharedInstance];
            let _: () = msg_send![session, setCategory: "record" error: nil];
            let _: () = msg_send![session, setActive: true error: nil];

            let recorder: id = msg_send![class!(AVAudioRecorder), alloc];
            let recorder: id = msg_send![
                recorder,
                initWithURL: url
                settings: settings
                error: nil
            ];

            if recorder != nil {
                let record_result: bool = msg_send![recorder, record];
                if record_result {
                    // Wait for user input to stop
                    // In real use, this would be handled differently
                    Ok(())
                } else {
                    Err("Failed to start recording".to_string())
                }
            } else {
                Err("Failed to create recorder".to_string())
            }
        }
    }
}

// Check if ffmpeg is available for audio recording
pub fn check_ffmpeg_available() -> bool {
    Command::new("ffmpeg")
        .arg("-version")
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false)
}

// Check if sox is available
pub fn check_sox_available() -> bool {
    Command::new("sox")
        .arg("--version")
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false)
}

// Tauri commands
#[tauri::command]
pub fn start_recording(state: tauri::State<'_, AudioRecorder>) -> Result<String, String> {
    state.start_recording()
}

#[tauri::command]
pub fn stop_recording(state: tauri::State<'_, AudioRecorder>) -> Result<(), String> {
    state.stop_recording()
}

#[tauri::command]
pub fn is_recording(state: tauri::State<'_, AudioRecorder>) -> bool {
    state.is_recording()
}

#[tauri::command]
pub fn check_audio_deps() -> serde_json::Value {
    serde_json::json!({
        "ffmpeg": check_ffmpeg_available(),
        "sox": check_sox_available()
    })
}
