const string ENV_NAME_PATTERN = "[a-zA-Z_][a-zA-Z0-9_]*";
const string ENV_VALUE_PATTERN = ".*";
// More strict
// static const string ENV_VALUE_PATTERN = "(?:[ \t\n]|[^[:cntrl:]])*";

/* These are variables that will not be passed on to subprocesses
 * (either directly, via systemd or DBus).
 * Some of these are blacklisted as they might end up in the wrong session
 * (e.g. XDG_VTNR), others because they simply must never be passed on
 * (NOTIFY_SOCKET).
 */
const string[] variable_blacklist = {
  "NOTIFY_SOCKET",
  "XDG_SEAT",
  "XDG_SESSION_ID",
  "XDG_VTNR",
};

/* The following is copied from GDMs spawn_session function.
 *
 * Environment variables listed here will be copied into the user's service
 * environments if they are set in gnome-session's environment. If they are
 * not set in gnome-session's environment, they will be removed from the
 * service environments. This is to protect against environment variables
 * leaking from previous sessions (e.g. when switching from classic to
 * default GNOME $GNOME_SHELL_SESSION_MODE will become unset).
 */
const string[] variable_unsetlist = {
  "DISPLAY",
  "XAUTHORITY",
  "WAYLAND_DISPLAY",
  "WAYLAND_SOCKET",
  "GNOME_SHELL_SESSION_MODE",
  "GNOME_SETUP_DISPLAY",

  /* None of the LC_* variables should survive a logout/login */
  "LC_CTYPE",
  "LC_NUMERIC",
  "LC_TIME",
  "LC_COLLATE",
  "LC_MONETARY",
  "LC_MESSAGES",
  "LC_PAPER",
  "LC_NAME",
  "LC_ADDRESS",
  "LC_TELEPHONE",
  "LC_MEASUREMENT",
  "LC_IDENTIFICATION",
  "LC_ALL",
};
