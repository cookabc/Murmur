use tauri::{
    menu::MenuBuilder,
    tray::{MouseButton, MouseButtonState, TrayIconEvent},
    AppHandle, Emitter, Manager, Runtime, Window, WindowEvent,
};

pub const MAIN_WINDOW_LABEL: &str = "main";
pub const MAIN_TRAY_ID: &str = "main";

const TRAY_MENU_SHOW_PANEL: &str = "show-panel";
const TRAY_MENU_TOGGLE_RECORDING: &str = "toggle-recording";
const TRAY_MENU_QUIT: &str = "quit";

pub fn reveal_main_window<R: Runtime>(app: &AppHandle<R>) {
    if let Some(window) = app.get_webview_window(MAIN_WINDOW_LABEL) {
        let _ = window.show();
        let _ = window.set_focus();
    }
}

pub fn toggle_main_window<R: Runtime>(app: &AppHandle<R>) {
    if let Some(window) = app.get_webview_window(MAIN_WINDOW_LABEL) {
        if window.is_visible().unwrap_or(false) {
            let _ = window.hide();
        } else {
            let _ = window.show();
            let _ = window.set_focus();
        }
    }
}

pub fn trigger_recording_toggle<R: Runtime>(app: &AppHandle<R>) {
    reveal_main_window(app);

    if let Some(window) = app.get_webview_window(MAIN_WINDOW_LABEL) {
        let _ = window.emit("toggle-recording", ());
    }
}

pub fn handle_window_event<R: Runtime>(window: &Window<R>, event: &WindowEvent) {
    if window.label() != MAIN_WINDOW_LABEL {
        return;
    }

    match event {
        WindowEvent::CloseRequested { api, .. } => {
            api.prevent_close();
            let _ = window.hide();
        }
        WindowEvent::Focused(false) => {
            let _ = window.hide();
        }
        _ => {}
    }
}

pub fn handle_menu_event<R: Runtime>(app: &AppHandle<R>, menu_id: &str) {
    match menu_id {
        TRAY_MENU_SHOW_PANEL => reveal_main_window(app),
        TRAY_MENU_TOGGLE_RECORDING => trigger_recording_toggle(app),
        TRAY_MENU_QUIT => app.exit(0),
        _ => {}
    }
}

pub fn handle_tray_icon_event<R: Runtime>(app: &AppHandle<R>, event: TrayIconEvent) {
    if event.id().as_ref() != MAIN_TRAY_ID {
        return;
    }

    if let TrayIconEvent::Click {
        button: MouseButton::Left,
        button_state: MouseButtonState::Up,
        ..
    } = event
    {
        toggle_main_window(app);
    }
}

pub fn configure_main_tray<R: Runtime>(app_handle: &AppHandle<R>) -> tauri::Result<()> {
    let tray_menu = MenuBuilder::new(app_handle)
        .text(TRAY_MENU_SHOW_PANEL, "Show Voice Input")
        .text(TRAY_MENU_TOGGLE_RECORDING, "Start or Stop Recording")
        .separator()
        .text(TRAY_MENU_QUIT, "Quit")
        .build()?;

    if let Some(tray) = app_handle.tray_by_id(MAIN_TRAY_ID) {
        tray.set_menu(Some(tray_menu))?;
        let _ = tray.set_tooltip(Some("Voice Input"));
    }

    Ok(())
}