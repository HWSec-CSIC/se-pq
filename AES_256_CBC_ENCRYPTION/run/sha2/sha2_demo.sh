#!/bin/bash
#
#  SPIRS RoT DEMO  -- SHA2
#
#  Created on: 16/02/2023 (santiago@imse-cnm.csic.es)
#
#################################################################################

clear
#
echo ""
echo ""
echo "  SPIRS-RoT: sha2_test"
echo "  --------------------"
echo "  Detail of use of NIST Test Vectors to verify the correct operation of the SHA2-IP core"
echo ""
echo "  # bin/sha2_test -v 1 -i 50 -f 70" 
#
bin/sha2_test -v 1 -i 50 -f 70
#
read -s -r -p "Press any key to continue"
clear
#
echo ""
echo ""
echo "  SPIRS-RoT: sha2_test"
echo "  --------------------"
echo "  Use of NIST Test Vectors to verify the correct operation of the SHA2-IP core"
echo ""
echo "  # bin/sha2_test -v 0" 
#
bin/sha2_test -v 0 
#
read -s -r -p "Press any key to continue"
clear
# 
echo ""
echo ""
echo "  SPIRS-RoT: sha2_spirs"
echo "  ---------------------"
echo "  SHA2 operation (input from command line)"
echo ""
echo "  # bin/sha2_spirs"
# 
bin/sha2_spirs 
#
#read -s -r -p "Press any key to continue"
#
echo ""
echo "  SPIRS-RoT: sha2_spirs"
echo "  ---------------------"
echo "  SHA2 operation (input from file)"
echo ""
echo "  # bin/sha2_spirs -f src/sha2/input_data.txt "
# 
bin/sha2_spirs -f src/sha2/input_data.txt 
#
echo "End SHA2 demo"
echo ""



