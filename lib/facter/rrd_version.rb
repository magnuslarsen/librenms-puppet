Facter.add('rrd_version') do
  setcode do
    rrd_ver = Facter::Util::Resolution.exec("rrdtool | head -n 1 | awk -F ' ' '{print $2}'")
    rrd_ver.match(%r{\d+\.\d+\.\d+})[0] if rrd_ver
  end
end
