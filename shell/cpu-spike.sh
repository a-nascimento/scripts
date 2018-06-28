#!/bin/bash
#
# SYNOPSIS
#   ./scaling_launchme.sh [delay]
#
# DESCRIPTION
#   This script creates a CPU spike. It terminates after the time
#   specified as an argument (default 5 minutes).
#
PATH=/bin:/usr/bin

delay=${1:-5m}
launch_script="/tmp/launch-$$.sh"

cat > ${launch_script} << EOF
#!/bin/bash
PATH=/bin:/usr/bin
yes &
pid=\$!
sleep ${delay}
kill -TERM \${pid}
rm -f ${launch_script}
EOF
chmod 755 ${launch_script}

echo 'Stressing the server...'
nohup ${launch_script} &> /dev/null &
