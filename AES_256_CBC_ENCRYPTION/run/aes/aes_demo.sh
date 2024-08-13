#!/bin/bash
#
#  SPIRS RoT DEMO  -- AES
#
#  Created on: 16/02/2023 (santiago@imse-cnm.csic.es)
#
#################################################################################

clear
#
echo ""
echo ""
echo "  SPIRS-RoT: aes_test"
echo "  -------------------"
echo "  AES operation with 128- and 256-bit keys"
echo ""
echo "  # bin/aes_test -v -n 1" 
#
bin/aes_test -v -n 1
#
read -s -r -p "Press any key to continue"
clear
# 
echo ""
echo ""
echo "  SPIRS-RoT: aes_test"
echo "  -------------------"
echo "  Use of NIST Test Vectors to test the correct operation of the AES-IP core"
echo ""
echo "  # bin/aes_test" 
#
bin/aes_test 
#
read -s -r -p "Press any key to continue"
clear
# 
echo ""
echo ""
echo "  SPIRS-RoT: aes_spirs (encryp)"
echo "  -----------------------------"
echo "  AES encryption operation "
echo ""
echo "  # bin/aes_spirs"
# 
bin/aes_spirs 
#
#read -s -r -p "Press any key to continue"
#
echo ""
echo ""
echo "  SPIRS-RoT: aes_spirs (decryp)"
echo "  ------------------------------"
echo "  AES decryption operation "
echo ""
echo "  # bin/aes_spirs -d -m 66E94BD4EF8A2C3B884CFA59CA342B2E"
#
bin/aes_spirs -d -m 66E94BD4EF8A2C3B884CFA59CA342B2E
#
echo "End AES demo"
echo ""



