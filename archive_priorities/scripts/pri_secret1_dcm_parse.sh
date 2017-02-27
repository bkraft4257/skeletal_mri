secret1_dcm_parse() {

  echo
  echo ">>>>>>>>>> Selecting T1 axial images of the thigh "
  echo

  grep  'T1AXDBLEFTTHIGH' $1 > ${1}.tmp1
 
  dcm_remove_rs ${1}.tmp1 > ${1}.tmp2
  
  mv -f ${1}.tmp2 ${1}

  rm -f ${1}.tmp[12] 

  cat $1
 
  echo
}
