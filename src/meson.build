executable(
  'gnome-session-openrc',
  sources: ['leader.vala', 'constants.vala'],
  # include glib
  dependencies: [glib, gio, openrc],
  install: true,
  vala_args: [
    '--vapidir', meson.current_source_dir() / 'vapi',
    '--pkg', 'posix',
  ],
)
