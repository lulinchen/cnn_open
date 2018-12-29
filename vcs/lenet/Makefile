ver:
	verdi -sv  simDefines.v +incdir+../../src+ -top tb -syntaxerrormax 1000   -f lenet_tb.f -ssf ./fsdb/xx.fsdb   #-sswr verdi.rc   #-
gold:
	verdi -sv  simDefines.v +incdir+../../src+ -top tb -syntaxerrormax 1000   -f lenet_tb.f -ssf ./fsdb/xx_gold.fsdb   #-sswr verdi.rc   #-
clean:
	rm -rf ./*.jpeg
	rm -rf ./csrc
	rm -rf ./simv
	rm -rf ./simv.*
	rm -rf ./vcs*
	rm -rf ./.vcs*
	rm -rf ./*.h
	rm -rf ./core*
	rm -rf ./*.vpd
	rm -rf ./save.*
