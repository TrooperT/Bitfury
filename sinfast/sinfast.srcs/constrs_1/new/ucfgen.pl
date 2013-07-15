# 14 rounds (topmost)

for ($idx = 0; $idx < 7; $idx++) {
	$i = 14 - (($idx*2));
	$ii = 14 - (($idx*2)+1);
	
	$x1 = 18*$idx;
	$x2 = $x1+17;
	if ($x1 >= 54) { $x2 += 2; }
	if ($x1 > 60) { $x1 += 2; }

	print "INST \"SHAFCE/SP/GR1[$i].RND\" AREA_GROUP = \"SP_rndini$i\";\n";
	print "INST \"SHAFCE/SP/GR1[$ii].RND\" AREA_GROUP = \"SP_rndini$i\";\n";
	print "AREA_GROUP \"SP_rndini$i\" RANGE=SLICE_X${x1}Y148:SLICE_X${x2}Y159;\n";
}
sub place_element($$$) {
	my ($n, $b, $e) = @_;

	$i = $n+15; # First part
	$ii = $i + 1;
	if ($i <= 38 && $i >= 16) { print "INST \"SHAFCE/SP/GR2[$i].RND\" AREA_GROUP = \"SP_rndf$i\";\n"; }
	if ($ii <= 38 && $ii >= 16) { print "INST \"SHAFCE/SP/GR2[$ii].RND\" AREA_GROUP = \"SP_rndf$i\";\n"; }
	print "AREA_GROUP \"SP_rndf$i\" RANGE=SLICE_X${b}Y130:SLICE_X${e}Y147;\n";

	#if ($i <= 38 && $i >= 16) { print "INST \"SHAFCE/SP/GR2[$i].WRN\" AREA_GROUP = \"SP_wexpf\";\n"; }
	#if ($ii <= 38 && $ii >= 16) { print "INST \"SHAFCE/SP/GR2[$ii].WRN\" AREA_GROUP = \"SP_wexpf\";\n"; }
	#print "AREA_GROUP \"SP_wexpf\" RANGE=SLICE_X0Y116:SLICE_X123Y128;\n";

	$i = 63-$n;
	$ii = $i - 1;

	#if ($i <= 63 && $i >= 40) { print "INST \"SHAFCE/SP/GR3[$i].WRN\" AREA_GROUP = \"SP_wexps\";\n"; }
	#if ($ii <= 63 && $ii >= 40) { print "INST \"SHAFCE/SP/GR3[$ii].WRN\" AREA_GROUP = \"SP_wexps\";\n"; }
	#print "AREA_GROUP \"SP_wexps\" RANGE=SLICE_X0Y103:SLICE_X123Y115;\n";

	#if ($i <= 63 && $i >= 40) {  print "INST \"SHAFCE/SP/GR3[$i].RND\" AREA_GROUP = \"SP_rnds\";\n"; }
	#if ($ii <= 63 && $ii >= 40) { print "INST \"SHAFCE/SP/GR3[$ii].RND\" AREA_GROUP = \"SP_rnds\";\n"; }
	#print "AREA_GROUP \"SP_rnds\" RANGE=SLICE_X0Y84:SLICE_X127Y102;\n";
}

for ($idx = 0; $idx < 12; $idx ++) {
	if ($idx < 6) { # Produce overlapping placement
#		place_element($idx*2, 10*$idx, 10*$idx+5);
		place_element($idx*2, 10*$idx, 10*$idx+9);
#		place_element($idx*2+1, 10*$idx+4, 10*$idx+9);
	} elsif ($idx == 6) {
		place_element($idx*2, 10*$idx, 10*$idx+9+2);
#		place_element($idx*2, 10*$idx, 10*$idx+5);
#		place_element($idx*2+1, 10*$idx+4, 10*$idx+9+2);
	} else {
		place_element($idx*2, 10*$idx+2, 10*$idx+9+2);
#		place_element($idx*2, 10*$idx+2, 10*$idx+5+2);
#		place_element($idx*2+1, 10*$idx+4+2, 10*$idx+9+2);
	}
}

