#!/bin/sh

. /opt/Xilinx/14.2/ISE_DS/settings64.sh

### export PL_NO_CONGESTION_CHECK=1
### export PL_DISABLE_CONG_AWARE=1
### export XIL_PAR_OPTIMIZE_CONGESTION=0

par -w -k -ol high -xe c -mt 4 s1.ncd s1r.ncd s1.pcf

