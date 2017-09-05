location = / {
  if ($is_prv_addr = 0) {
    return 307 https://launch.alces-flight.com/cluster/_HOSTNAME_;
  }
}
