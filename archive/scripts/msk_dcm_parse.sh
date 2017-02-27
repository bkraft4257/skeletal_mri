#!/usr/bin/env bash 

source ${TIC_TOOLS_PATH}/other/unix/dcm_functions.sh
basename=dcmConvert_pepper.cfg

dcm_group dcmConvertAll.cfg > 01.${basename}
sed -e 's/m\(v\|V\)O2_rs01/mVO2_magnitude/' -e 's/m\(v\|V\)O2_rs02/mVO2_phase/' 01.${basename} > 02.${basename}
sed -e '/3Plane/d' -e '/B1map/d' -e '/3_plane/d' -e '/localizer/d' 02.${basename} > 03.${basename}
sed -e 's/_ms_rs01/_ms_magnitude/' -e 's/_ms_rs02/_ms_phase/' 03.${basename} > 04.${basename}
sed -e '/T1map_rs0\(1\|2\)/d' -e 's/T1map_rs03/t1map/' 04.${basename} > 05.${basename}
#sed -e 's/phase_contrast_rs01/pc_magnitude/' -e 's/phase_contrast_rs02/pc_phase/' 05.${basename} > 06.${basename}
sed -e 's/PhaseContrastgated_rs01/pc_magnitude/' -e 's/PhaseContrastgated_rs02/pc_phase/' 05.${basename} > 06.${basename}

sed -e '/rs02/d' -e '/rs03/d' -e '/rs04/d' 06.${basename} > 07.${basename}
dcm_group 07.${basename} > 08.${basename}

sed -e 's/TOF_2DThompson(H)/tof/' -e 's/tof_rs01/tof_1/' -e 's/tof_rs02/tof_2/'  08.${basename} > 09.${basename}

dcm_remove_rs01 09.${basename} > ${basename}

rm 0[1-9].${basename}

