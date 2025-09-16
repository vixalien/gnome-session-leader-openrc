[CCode(cheader_filename = "rc.h")]
namespace RC {
  [CCode(cname = "ServiceState", cprefix = "RC_SERVICE_")]
  public enum ServiceState {
    [CCode(cname = "RC_SERVICE_STOPPED")]
    STOPPED,
    [CCode(cname = "RC_SERVICE_STARTED")]
    STARTED,
    [CCode(cname = "RC_SERVICE_STOPPING")]
    STOPPING,
    [CCode(cname = "RC_SERVICE_STARTING")]
    STARTING,
    [CCode(cname = "RC_SERVICE_INACTIVE")]
    INACTIVE,
    [CCode(cname = "RC_SERVICE_HOTPLUGGED")]
    HOTPLUGGED,
    [CCode(cname = "RC_SERVICE_FAILED")]
    FAILED,
    [CCode(cname = "RC_SERVICE_SCHEDULED")]
    SCHEDULED,
    [CCode(cname = "RC_SERVICE_WASINACTIVE")]
    WASINACTIVE,
    [CCode(cname = "RC_SERVICE_CRASHED")]
    CRASHED,
  }

  [CCode(cname = "rc_set_user")]
  public void set_user();

  [CCode(cname = "rc_is_user")]
  public bool is_user();

  namespace Service {
    [CCode(cname = "rc_service_state")]
    public int state(string service_name);

    [CCode(cname = "rc_service_mark")]
    public bool mark(string service_name, ServiceState state);
  }
}
