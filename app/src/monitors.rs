//! Multi-monitor discovery + lookup.
//!
//! Cross-platform surface. Windows uses `EnumDisplayMonitors`; macOS uses
//! CoreGraphics' active-display list. Linux still returns an empty list until a
//! backend can cover both X11 and Wayland without guessing.

/// A monitor rect in virtual-screen pixel coords. Platform-neutral (avoids the
/// Win32 `RECT` so the type is usable on every OS).
#[derive(Clone, Debug, Default)]
pub struct Rect {
    pub left: i32,
    pub top: i32,
    pub right: i32,
    pub bottom: i32,
}

#[derive(Clone, Debug)]
pub struct Monitor {
    /// Zero-based index in enumeration order. We persist this (not a native
    /// handle — those are not stable across reboots) as the config identifier.
    pub index: u32,
    /// True if this is the system's primary display.
    pub primary: bool,
    /// Monitor rect in virtual-screen coords.
    pub rect: Rect,
}

impl Monitor {
    pub fn width(&self) -> i32 { self.rect.right - self.rect.left }
    pub fn height(&self) -> i32 { self.rect.bottom - self.rect.top }
}

#[cfg(windows)]
mod sys {
    use super::{Monitor, Rect};
    use windows::core::BOOL;
    use windows::Win32::Foundation::{LPARAM, RECT};
    use windows::Win32::Graphics::Gdi::{
        EnumDisplayMonitors, GetMonitorInfoW, HDC, HMONITOR, MONITORINFOEXW,
    };

    struct EnumCtx { v: Vec<Monitor>, idx: u32 }

    unsafe extern "system" fn enum_cb(
        hmon: HMONITOR, _hdc: HDC, _rect: *mut RECT, lparam: LPARAM,
    ) -> BOOL {
        let ctx = &mut *(lparam.0 as *mut EnumCtx);
        let mut info = MONITORINFOEXW::default();
        info.monitorInfo.cbSize = std::mem::size_of::<MONITORINFOEXW>() as u32;
        if GetMonitorInfoW(hmon, &mut info.monitorInfo as *mut _ as *mut _).as_bool() {
            let r = info.monitorInfo.rcMonitor;
            ctx.v.push(Monitor {
                index: ctx.idx,
                primary: (info.monitorInfo.dwFlags & 1) != 0, // MONITORINFOF_PRIMARY = 1
                rect: Rect { left: r.left, top: r.top, right: r.right, bottom: r.bottom },
            });
            ctx.idx += 1;
        }
        BOOL(1)
    }

    pub fn list() -> Vec<Monitor> {
        let mut ctx = EnumCtx { v: Vec::new(), idx: 0 };
        unsafe {
            let _ = EnumDisplayMonitors(None, None, Some(enum_cb),
                                        LPARAM(&mut ctx as *mut _ as isize));
        }
        ctx.v
    }
}

#[cfg(target_os = "macos")]
mod sys {
    use super::{Monitor, Rect};

    type CGDirectDisplayID = u32;
    type CGError = i32;

    #[repr(C)]
    #[derive(Clone, Copy)]
    struct CGPoint {
        x: f64,
        y: f64,
    }

    #[repr(C)]
    #[derive(Clone, Copy)]
    struct CGSize {
        width: f64,
        height: f64,
    }

    #[repr(C)]
    #[derive(Clone, Copy)]
    struct CGRect {
        origin: CGPoint,
        size: CGSize,
    }

    #[link(name = "CoreGraphics", kind = "framework")]
    extern "C" {
        fn CGGetActiveDisplayList(
            max_displays: u32,
            active_displays: *mut CGDirectDisplayID,
            display_count: *mut u32,
        ) -> CGError;
        fn CGMainDisplayID() -> CGDirectDisplayID;
        fn CGDisplayBounds(display: CGDirectDisplayID) -> CGRect;
    }

    pub fn list() -> Vec<Monitor> {
        // A theater setup is expected to have two displays, but leave generous
        // headroom for capture cards and virtual displays. If there are more,
        // CoreGraphics reports the first 32 instead of making discovery fail.
        let mut ids = [0_u32; 32];
        let mut count = 0_u32;
        let err = unsafe {
            CGGetActiveDisplayList(ids.len() as u32, ids.as_mut_ptr(), &mut count)
        };
        if err != 0 {
            return Vec::new();
        }

        let main = unsafe { CGMainDisplayID() };
        ids[..count.min(ids.len() as u32) as usize]
            .iter()
            .enumerate()
            .map(|(index, id)| {
                let b = unsafe { CGDisplayBounds(*id) };
                // CGDisplayBounds and tao both use the macOS global display
                // coordinate space. Rounding is intentional: the public model
                // stores physical window coordinates as integers.
                let left = b.origin.x.round() as i32;
                let top = b.origin.y.round() as i32;
                let width = b.size.width.round() as i32;
                let height = b.size.height.round() as i32;
                Monitor {
                    index: index as u32,
                    primary: *id == main,
                    rect: Rect {
                        left,
                        top,
                        right: left.saturating_add(width),
                        bottom: top.saturating_add(height),
                    },
                }
            })
            .collect()
    }
}

#[cfg(not(any(windows, target_os = "macos")))]
mod sys {
    use super::Monitor;
    /// X11 (RandR/Xinerama) + Wayland enumeration is still pending. Empty means
    /// the Settings display dropdown hides and the engine uses default placement.
    pub fn list() -> Vec<Monitor> { Vec::new() }
}

/// Snapshot the currently connected monitors (empty on platforms without
/// enumeration yet).
pub fn list() -> Vec<Monitor> { sys::list() }

/// Resolve a `Config::preferred_monitor` value to an actual `Monitor`, or fall
/// back to the primary (then the first), or `None` if none are enumerated.
pub fn resolve(preferred: Option<u32>) -> Option<Monitor> {
    let mons = list();
    if mons.is_empty() { return None; }
    if let Some(i) = preferred {
        if let Some(m) = mons.iter().find(|m| m.index == i) {
            return Some(m.clone());
        }
    }
    mons.iter().find(|m| m.primary).cloned()
        .or_else(|| mons.into_iter().next())
}
