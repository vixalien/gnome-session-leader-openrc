struct Leader {
  MainLoop loop;
  int fifo_fd;
}

static bool export_user_environment (Leader ctx) throws Error {
  var environment_updated = false;

  debug ("Exporting DBus activation environment");

  var regex = new Regex ("^" + ENV_NAME_PATTERN + "=" + ENV_VALUE_PATTERN + "$", OPTIMIZE, 0);
  var entries = Environ.get ();

  foreach (var blacklisted in variable_blacklist) {
    entries = Environ.unset_variable (entries, blacklisted);
  }

  var builder = new VariantBuilder (new VariantType ("(asas)"));

  builder.open (new VariantType ("as"));
  foreach (var unsetvariab in variable_unsetlist) {
    builder.add ("s", unsetvariab);
  }
  foreach (var blacklisted in variable_blacklist) {
    builder.add ("s", blacklisted);
  }
  builder.close ();

  builder.open (new VariantType ("as"));
  foreach (var entry in entries) {
    if (!entry.validate (-1, null) ||
        !regex.match (entry, 0, null)) {
      message ("Environment entry is unsafe to upload into user environment: %s", entry);
      continue;
    }

    builder.add ("s", entry);
  }
  builder.close ();

  var connection = Bus.get_sync (SESSION, null);

  try {

    /* Start a shutdown explicitly. */
    connection.call_sync ("org.freedesktop.DBus",
                          "/org/freedesktop/DBus",
                          "org.freedesktop.DBus",
                          "UnsetAndSetEnvironment",
                          builder.end (),
                          null,
                          NO_AUTO_START,
                          -1,
                          null);

    environment_updated = true;
  } catch (Error error) {
    DBusError.strip_remote_error (error);
    throw error;
  }

  return environment_updated;
}

static bool leader_term_or_int_signal_cb (Leader ctx) {
  debug ("Session termination requested");

  try {
    var connection = Bus.get_sync (SESSION, null);

    /* Start a shutdown explicitly. */
    connection.call_sync ("org.freedesktop.login1",
                          "/org/freedesktop/login1",
                          "org.freedesktop.systemd1.Manager",
                          "PowerOff",
                          new Variant ("b", false),
                          null,
                          NO_AUTO_START,
                          -1,
                          null);

    if (Posix.write (ctx.fifo_fd, "S", 1) < 0) {
      warning ("Failed to signal shutdown to monitor: %m");
      ctx.loop.quit ();
    }
  } catch (Error e) {
    error ("Failed to power off: %s", e.message);
  }

  return Source.REMOVE;
}

int main (string[] args) {
  if (args.length < 2) {
    error ("No session name was specified");
  }
  var session_name = args[1];

  var debug_string = Environment.get_variable ("GNOME_SESSION_DEBUG");
  if (debug_string != null) {
    Log.set_debug_enabled (debug_string == "1");
  }

  var ctx = Leader ();

  ctx.loop = new MainLoop (null, true);

  try {
    export_user_environment (ctx);
  } catch (Error error) {
    warning ("Failed to upload environment to openrc: %s", error.message);
  }


  /* We don't escape the name (i.e. we leave any '-' intact). */
  var service_name = "gnome-session-%s".printf (Environment.get_variable ("XDG_SESSION_TYPE"));

  RC.set_user ();

  if (RC.Service.state (service_name) == RC.ServiceState.STARTED) {
    error ("Session manager is already running!");
  }

  // TODO: Reset failed

  message ("Starting GNOME session service: %s", service_name);

  if (!RC.Service.mark (service_name, STARTED)) {
    error ("Failed to start service");
  }

  var fifo_path = Path.build_filename (Environment.get_user_runtime_dir (),
                                       "gnome-session-leader-fifo");

  if (Posix.mkfifo (fifo_path, 0666) < 0 && Posix.errno != Posix.EEXIST) {
    warning ("Failed to create leader FIFO: %m");
  }

  Posix.Stat statbuf;

  ctx.fifo_fd = Posix.open (fifo_path, Posix.O_WRONLY | Posix.O_CLOEXEC, 0666);
  if (ctx.fifo_fd < 0) {
    error ("Failed to watch openrc session: open failed: %m");
  } else if (Posix.fstat (ctx.fifo_fd, out statbuf) < 0) {
    error ("Failed to watch openrc session: fstat failed: %m");
  } else if ((statbuf.st_mode & Posix.S_IFIFO) == 0) {
    error ("Failed to watch openrc session: FD is not a FIFO");
  }


  Unix.signal_add (Posix.Signal.HUP, () => leader_term_or_int_signal_cb (ctx));
  Unix.signal_add (Posix.Signal.TERM, () => leader_term_or_int_signal_cb (ctx));
  Unix.signal_add (Posix.Signal.INT, () => leader_term_or_int_signal_cb (ctx));

  debug ("Waiting for session to shutdown");
  ctx.loop.run ();

  return 0;
}
