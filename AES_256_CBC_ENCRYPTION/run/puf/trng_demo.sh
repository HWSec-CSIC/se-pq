#!/bin/bash
#
#  SPIRS RoT DEMO  -- TRNG
#
#  Created on: 16/02/2023 (santiago@imse-cnm.csic.es)
#
#################################################################################

clear
#
echo ""
echo ""
echo "  SPIRS-RoT: TRNG Test"
echo "  -------------------"
echo "  Use of the PUF as Entropy Source"
echo ""
echo "  # bin/puf_getdata -t 5 -c 64 -d 2 -e" 
#
bin/puf_getdata -t 4 -c 64 -d 2 -e 
#
read -s -r -p "Press any key to continue"
clear
#
echo ""
echo ""
echo "  SPIRS-RoT: TRNG Test"
echo "  --------------------"
echo "  Collects 10^6 random bits by running 1000 tests for the PUF"
echo ""
echo "  # bin/puf_es_validation" 
#
bin/puf_es_validation 
#
read -s -r -p "Press any key to continue"
clear
# 
echo ""
echo ""
echo "  SPIRS-RoT: TRNG Test"
echo "  --------------------"
echo "  Health check test execution"
echo ""
echo "  bin/puf_es_health_check" 
#
bin/puf_es_health_check
#
echo "End TRNG demo"
echo ""
#
