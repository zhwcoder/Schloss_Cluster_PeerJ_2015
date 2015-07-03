print-%:
	@echo '$*=$($*)'

data/raw/canada_soil.fasta : code/get_roesch_data.R
	R -e "source('code/get_roesch_data.R')"

data/he/canada_soil.good.unique.pick.redundant.fasta : code/get_he_data.batch data/raw/canada_soil.fasta
	mothur code/get_he_data.batch



NEIGHBOR = an nn fn
FRACTION = 0.2 0.4 0.6 0.8 1.0
REP = 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30

HE_BOOTSTRAP_FASTA = $(addprefix data/he/he_, $(foreach F,$(FRACTION), $(foreach R,$(REP), $F_$R.fasta)))

$(HE_BOOTSTRAP_FASTA) : code/generate_samples.R data/he/canada_soil.good.unique.pick.redundant.fasta
	$(eval BASE=$(patsubst data/he/he_%.fasta,%,$@))
	$(eval R=$(lastword $(subst _, ,$(BASE))))
	$(eval F=$(firstword $(subst _, ,$(BASE))))
	R -e "source('code/generate_samples.R'); generate_indiv_samples('data/he/canada_soil.good.unique.pick.redundant.fasta', 'data/he/he', $F, '$R')"



HE_UNIQUE_FASTA = $(addprefix data/he/he_, $(foreach F,$(FRACTION), $(foreach R,$(REP), $F_$R.unique.fasta)))
.SECONDEXPANSION:
$(HE_UNIQUE_FASTA) : $$(subst unique.fasta,fasta, $$@)
	mothur "#unique.seqs(fasta=$<)"

HE_NAMES = $(addprefix data/he/he_, $(foreach F,$(FRACTION), $(foreach R,$(REP), $F_$R.names)))
.SECONDEXPANSION:
$(HE_NAMES) : $$(subst names,unique.fasta, $$@)

HE_DISTANCE = $(addprefix data/he/he_, $(foreach F,$(FRACTION), $(foreach R,$(REP), $F_$R.unique.dist)))
.SECONDEXPANSION:
$(HE_DISTANCE) : $$(subst dist,fasta, $$@)
	mothur "#pairwise.seqs(fasta=$<, processors=8, cutoff=0.20)"




HE_AN_LIST = $(addprefix data/he/he_, $(foreach F,$(FRACTION), $(foreach R,$(REP),  $F_$R.unique.an.list)))
.SECONDEXPANSION:
$(HE_AN_LIST) : $$(subst .an.list,.dist, $$@) $$(subst unique.an.list,names, $$@) code/run_an.sh
	$(eval DIST=$(word 1,$^))
	$(eval NAMES=$(word 2,$^))
	bash code/run_an.sh $(DIST) $(NAMES)

HE_NN_LIST = $(addprefix data/he/he_, $(foreach F,$(FRACTION), $(foreach R,$(REP),  $F_$R.unique.nn.list))) 
.SECONDEXPANSION:
$(HE_NN_LIST) : $$(subst .nn.list,.dist, $$@) $$(subst unique.nn.list,names, $$@) code/run_nn.sh
	$(eval DIST=$(word 1,$^))
	$(eval NAMES=$(word 2,$^))
	bash code/run_nn.sh $(DIST) $(NAMES)

HE_FN_LIST = $(addprefix data/he/he_, $(foreach F,$(FRACTION), $(foreach R,$(REP),  $F_$R.unique.fn.list))) 
.SECONDEXPANSION:
$(HE_FN_LIST) : $$(subst .fn.list,.dist, $$@) $$(subst unique.fn.list,names, $$@) code/run_fn.sh
	$(eval DIST=$(word 1,$^))
	$(eval NAMES=$(word 2,$^))
	bash code/run_fn.sh $(DIST) $(NAMES)

HE_NEIGHBOR_LIST = $(HE_AN_LIST) $(HE_NN_LIST) $(HE_FN_LIST) 


HE_DGC_LIST = $(addprefix data/he/he_, $(foreach F,$(FRACTION), $(foreach R,$(REP),  $F_$R.dgc.list)))
.SECONDEXPANSION:
$(HE_DGC_LIST) : $$(subst dgc.list,fasta, $$@) code/run_dgc.sh code/dgc.params.txt
	bash code/run_dgc.sh $<

HE_AGC_LIST = $(addprefix data/he/he_, $(foreach F,$(FRACTION), $(foreach R,$(REP),  $F_$R.agc.list)))
.SECONDEXPANSION:
$(HE_AGC_LIST) : $$(subst agc.list,fasta, $$@) code/run_agc.sh code/agc.params.txt
	bash code/run_agc.sh $<

HE_CLOSED_LIST = $(addprefix data/he/he_, $(foreach F,$(FRACTION), $(foreach R,$(REP),  $F_$R.closed.list)))
.SECONDEXPANSION:
$(HE_CLOSED_LIST) : $$(subst closed.list,fasta, $$@) code/run_closed.sh code/closedref.params.txt
	bash code/run_closed.sh $<

HE_OPEN_LIST = $(addprefix data/he/he_, $(foreach F,$(FRACTION), $(foreach R,$(REP),  $F_$R.open.list)))
.SECONDEXPANSION:
$(HE_OPEN_LIST) : $$(subst open.list,fasta, $$@) code/run_open.sh code/openref.params.txt
	bash code/run_open.sh $<

HE_SWARM_LIST = $(addprefix data/he/he_, $(foreach F,$(FRACTION), $(foreach R,$(REP),  $F_$R.swarm.list)))
.SECONDEXPANSION:
$(HE_SWARM_LIST) : $$(subst swarm.list,unique.fasta, $$@) $$(subst swarm.list,names, $$@) code/cluster_swarm.R
	$(eval FASTA=$(word 1,$^))
	$(eval NAMES=$(word 2,$^))
	R -e 'source("code/cluster_swarm.R"); get_mothur_list("$(FASTA)", "$(NAMES)")'

HE_GREEDY_LIST = $(HE_DGC_LIST) $(HE_AGC_LIST) $(HE_OPEN_LIST) $(HE_CLOSED_LIST) $(HE_SWARM_LIST)


HE_NEIGHBOR_SENSSPEC = $(subst list,sensspec, $(HE_NEIGHBOR_LIST))
.SECONDEXPANSION:
$(HE_NEIGHBOR_SENSSPEC) : $$(addsuffix .dist,$$(basename $$(basename $$@)))  $$(subst sensspec,list,$$@)
	$(eval LIST=$(word 2,$^))
	mothur "#sens.spec(column=$<, list=$(LIST), label=0.03, outputdir=data/he)"

HE_GREEDY_SENSSPEC = $(subst list,sensspec, $(HE_GREEDY_LIST))
.SECONDEXPANSION:
$(HE_GREEDY_SENSSPEC) : $$(addsuffix .unique.dist,$$(basename $$(basename $$@)))  $$(subst sensspec,list,$$@)
	$(eval LIST=$(word 2,$^))
	mothur "#sens.spec(column=$<, list=$(LIST), label=userLabel, cutoff=0.03, outputdir=data/he)"


HE_REF_MCC = data/he/he.fn.ref_mcc data/he/he.nn.ref_mcc data/he/he.an.ref_mcc data/he/he.agc.ref_mcc data/he/he.dgc.ref_mcc data/he/he.closed.ref_mcc data/he/he.open.ref_mcc data/he/he.swarm.ref_mcc
data/he/he.an.ref_mcc : code/reference_mcc.R $(HE_AN_LIST) $(HE_NAMES)
	R -e "source('code/reference_mcc.R');run_reference_mcc('data/he/', 'he.*unique.an.list', 'he_1.0.*unique.an.list', 'he.*names', 'data/he/he.an.ref_mcc')"

data/he/he.fn.ref_mcc : code/reference_mcc.R $(HE_FN_LIST) $(HE_NAMES)
	R -e "source('code/reference_mcc.R');run_reference_mcc('data/he/', 'he.*unique.fn.list', 'he_1.0.*unique.fn.list', 'he.*names', 'data/he/he.fn.ref_mcc')"

data/he/he.nn.ref_mcc : code/reference_mcc.R $(HE_NN_LIST) $(HE_NAMES)
	R -e "source('code/reference_mcc.R');run_reference_mcc('data/he/', 'he.*unique.nn.list', 'he_1.0.*unique.nn.list', 'he.*names', 'data/he/he.nn.ref_mcc')"

data/he/he.closed.ref_mcc : code/reference_mcc.R $(HE_CLOSED_LIST) $(HE_NAMES)
	R -e "source('code/reference_mcc.R');run_reference_mcc('data/he/', 'he.*closed.list', 'he_1.0.*closed.list', 'he.*names', 'data/he/he.closed.ref_mcc')"

data/he/he.open.ref_mcc : code/reference_mcc.R $(HE_OPEN_LIST) $(HE_NAMES)
	R -e "source('code/reference_mcc.R');run_reference_mcc('data/he/', 'he.*open.list', 'he_1.0.*open.list', 'he.*names', 'data/he/he.open.ref_mcc')"

data/he/he.agc.ref_mcc : code/reference_mcc.R $(HE_AGC_LIST) $(HE_NAMES)
	R -e "source('code/reference_mcc.R');run_reference_mcc('data/he/', 'he.*agc.list', 'he_1.0.*agc.list', 'he.*names', 'data/he/he.agc.ref_mcc')"

data/he/he.dgc.ref_mcc : code/reference_mcc.R $(HE_DGC_LIST) $(HE_NAMES)
	R -e "source('code/reference_mcc.R');run_reference_mcc('data/he/', 'he.*dgc.list', 'he_1.0.*dgc.list', 'he.*names', 'data/he/he.dgc.ref_mcc')"

data/he/he.swarm.ref_mcc : code/reference_mcc.R $(HE_SWARM_LIST) $(HE_NAMES)
	R -e "source('code/reference_mcc.R');run_reference_mcc('data/he/', 'he.*swarm.list', 'he_1.0.*swarm.list', 'he.*names', 'data/he/he.swarm.ref_mcc')"


data/he/he.an.pool_sensspec : code/merge_sensspec_files.R $$(subst list,sensspec, $$(HE_AN_LIST)) 
	R -e "source('code/merge_sensspec_files.R');merge_sens_spec('data/he', 'he_.*an.sensspec', 'data/he/he.an.pool_sensspec')"

data/he/he.fn.pool_sensspec : code/merge_sensspec_files.R $$(subst list,sensspec, $$(HE_FN_LIST))
	R -e "source('code/merge_sensspec_files.R');merge_sens_spec('data/he', 'he_.*Fn.sensspec', 'data/he/he.fn.pool_sensspec')"

data/he/he.nn.pool_sensspec : code/merge_sensspec_files.R $$(subst list,sensspec, $$(HE_NN_LIST))
	R -e "source('code/merge_sensspec_files.R');merge_sens_spec('data/he', 'he_.*nn.sensspec', 'data/he/he.nn.pool_sensspec')"

data/he/he.dgc.pool_sensspec : code/merge_sensspec_files.R $$(subst list,sensspec, $$(HE_DGC_LIST))
	R -e "source('code/merge_sensspec_files.R');merge_sens_spec('data/he', 'he_.*dgc.sensspec', 'data/he/he.dgc.pool_sensspec')"

data/he/he.agc.pool_sensspec : code/merge_sensspec_files.R $$(subst list,sensspec, $$(HE_AGC_LIST))
	R -e "source('code/merge_sensspec_files.R');merge_sens_spec('data/he', 'he_.*agc.sensspec', 'data/he/he.agc.pool_sensspec')"

data/he/he.open.pool_sensspec : code/merge_sensspec_files.R $$(subst list,sensspec, $$(HE_OPEN_LIST))
	R -e "source('code/merge_sensspec_files.R');merge_sens_spec('data/he', 'he_.*open.sensspec', 'data/he/he.open.pool_sensspec')"

data/he/he.closed.pool_sensspec : code/merge_sensspec_files.R $$(subst list,sensspec, $$(HE_CLOSED_LIST))
	R -e "source('code/merge_sensspec_files.R');merge_sens_spec('data/he', 'he_.*closed.sensspec', 'data/he/he.closed.pool_sensspec')"

data/he/he.swarm.pool_sensspec : code/merge_sensspec_files.R $$(subst list,sensspec, $$(HE_SWARM_LIST))
	R -e "source('code/merge_sensspec_files.R');merge_sens_spec('data/he', 'he_.*swarm.sensspec', 'data/he/he.swarm.pool_sensspec')"


HE_RAREFACTION = data/he/he.an.rarefaction data/he/he.nn.rarefaction data/he/he.fn.rarefaction data/he/he.agc.rarefaction data/he/he.dgc.rarefaction data/he/he.closed.rarefaction data/he/he.open.rarefaction data/he/he.swarm.rarefaction

data/he/he.an.rarefaction : $(HE_AN_LIST) code/rarefy_data.R 
	R -e "source('code/rarefy_data.R');rarefy_sobs('unique.an', 'data/he')"

data/he/he.nn.rarefaction : $(HE_NN_LIST) code/rarefy_data.R 
	R -e "source('code/rarefy_data.R');rarefy_sobs('unique.nn', 'data/he')"

data/he/he.fn.rarefaction : $(HE_FN_LIST) code/rarefy_data.R 
	R -e "source('code/rarefy_data.R');rarefy_sobs('unique.fn', 'data/he')"

data/he/he.agc.rarefaction : $(HE_AGC_LIST) code/rarefy_data.R 
	R -e "source('code/rarefy_data.R');rarefy_sobs('agc', 'data/he')"

data/he/he.dgc.rarefaction : $(HE_DGC_LIST) code/rarefy_data.R 
	R -e "source('code/rarefy_data.R');rarefy_sobs('dgc', 'data/he')"

data/he/he.closed.rarefaction : $(HE_CLOSED_LIST) code/rarefy_data.R 
	R -e "source('code/rarefy_data.R');rarefy_sobs('closed', 'data/he')"

data/he/he.open.rarefaction : $(HE_OPEN_LIST) code/rarefy_data.R 
	R -e "source('code/rarefy_data.R');rarefy_sobs('open', 'data/he')"

data/he/he.swarm.rarefaction : $(HE_SWARM_LIST) code/rarefy_data.R 
	R -e "source('code/rarefy_data.R');rarefy_sobs('swarm', 'data/he')"




#get the silva reference alignment
REFS = data/references/
$(REFS)silva.bacteria.align :
	wget -N -P $(REFS) http://www.mothur.org/w/images/2/27/Silva.nr_v119.tgz; \
	tar xvzf $(REFS)Silva.nr_v119.tgz -C $(REFS);
	mothur "#get.lineage(fasta=$(REFS)silva.nr_v119.align, taxonomy=$(REFS)silva.nr_v119.tax, taxon=Bacteria)";
	mv $(REFS)silva.nr_v119.pick.align $(REFS)silva.bacteria.align; \
	rm $(REFS)README.html; \
	rm $(REFS)README.Rmd; \
	rm $(REFS)silva.nr_v119.*

data/schloss/canada_soil.good.unique.pick.redundant.fasta : data/he/canada_soil.good.unique.pick.redundant.fasta
	cp $< $@

data/schloss/canada_soil.good.unique.pick.redundant.good.filter.fasta : code/get_schloss_data.batch data/schloss/canada_soil.good.unique.pick.redundant.fasta
	mothur code/get_schloss_data.batch
	rm data/schloss/canada_soil.filter
	rm data/schloss/canada_soil.good.unique.pick.redundant.bad.accnos
	rm data/schloss/canada_soil.good.unique.pick.redundant.good.align
	rm data/schloss/canada_soil.good.unique.pick.redundant.flip.accnos
	rm data/schloss/canada_soil.good.unique.pick.redundant.align.report
	rm data/schloss/canada_soil.good.unique.pick.redundant.align


SCHL_BOOTSTRAP_FASTA = $(addprefix data/schloss/schloss_, $(foreach F,$(FRACTION), $(foreach R,$(REP), $F_$R.fasta)))
$(SCHL_BOOTSTRAP_FASTA) : code/generate_samples.R data/schloss/canada_soil.good.unique.pick.redundant.good.filter.fasta
	$(eval BASE=$(patsubst data/schloss/schloss_%.fasta,%,$@))
	$(eval R=$(lastword $(subst _, ,$(BASE))))
	$(eval F=$(firstword $(subst _, ,$(BASE))))
	R -e "source('code/generate_samples.R'); generate_indiv_samples('data/schloss/canada_soil.good.unique.pick.redundant.good.filter.fasta', 'data/schloss/schloss', $F, '$R')"


SCHL_UNIQUE_FASTA = $(addprefix data/schloss/schloss_, $(foreach F,$(FRACTION), $(foreach R,$(REP), $F_$R.unique.fasta)))
.SECONDEXPANSION:
$(SCHL_UNIQUE_FASTA) : $$(subst unique.fasta,fasta, $$@)
	mothur "#unique.seqs(fasta=$<)"

SCHL_NAMES = $(addprefix data/schloss/schloss_, $(foreach F,$(FRACTION), $(foreach R,$(REP), $F_$R.names)))
.SECONDEXPANSION:
$(SCHL_NAMES) : $$(subst names,unique.fasta, $$@)

SCHL_DISTANCE = $(addprefix data/schloss/schloss_, $(foreach F,$(FRACTION), $(foreach R,$(REP), $F_$R.unique.dist)))
.SECONDEXPANSION:
$(SCHL_DISTANCE) : $$(subst dist,fasta, $$@)
	mothur "#dist.seqs(fasta=$<, processors=8, cutoff=0.20)"



SCHL_AN_LIST = $(addprefix data/schloss/schloss_, $(foreach F,$(FRACTION), $(foreach R,$(REP),  $F_$R.unique.an.list)))
.SECONDEXPANSION:
$(SCHL_AN_LIST) : $$(subst .an.list,.dist, $$@) $$(subst unique.an.list,names, $$@) code/run_an.sh
	$(eval DIST=$(word 1,$^))
	$(eval NAMES=$(word 2,$^))
	bash code/run_an.sh $(DIST) $(NAMES)

SCHL_NN_LIST = $(addprefix data/schloss/schloss_, $(foreach F,$(FRACTION), $(foreach R,$(REP),  $F_$R.unique.nn.list))) 
.SECONDEXPANSION:
$(SCHL_NN_LIST) : $$(subst .nn.list,.dist, $$@) $$(subst unique.nn.list,names, $$@) code/run_nn.sh
	$(eval DIST=$(word 1,$^))
	$(eval NAMES=$(word 2,$^))
	bash code/run_nn.sh $(DIST) $(NAMES)

SCHL_FN_LIST = $(addprefix data/schloss/schloss_, $(foreach F,$(FRACTION), $(foreach R,$(REP),  $F_$R.unique.fn.list))) 
.SECONDEXPANSION:
$(SCHL_FN_LIST) : $$(subst .fn.list,.dist, $$@) $$(subst unique.fn.list,names, $$@) code/run_fn.sh
	$(eval DIST=$(word 1,$^))
	$(eval NAMES=$(word 2,$^))
	bash code/run_fn.sh $(DIST) $(NAMES)

SCHL_NEIGHBOR_LIST = $(SCHL_AN_LIST) $(SCHL_NN_LIST) $(SCHL_FN_LIST) 


SCHL_DEGAP_FASTA = $(subst fasta,ng.fasta,$(SCHL_BOOTSTRAP_FASTA))
$(SCHL_DEGAP_FASTA) : $$(subst ng.fasta,fasta, $$@)
	mothur "#degap.seqs(fasta=$<)"

SCHL_DGC_LIST = $(addprefix data/schloss/schloss_, $(foreach F,$(FRACTION), $(foreach R,$(REP),  $F_$R.dgc.list)))
.SECONDEXPANSION:
$(SCHL_DGC_LIST) : $$(subst dgc.list,ng.fasta, $$@) code/run_dgc.sh code/dgc.params.txt
	bash code/run_dgc.sh $<
	$(eval NG_LIST=$(subst dgc.list,ng.dgc.list,$@))
	mv $(NG_LIST) $@

SCHL_AGC_LIST = $(addprefix data/schloss/schloss_, $(foreach F,$(FRACTION), $(foreach R,$(REP),  $F_$R.agc.list)))
.SECONDEXPANSION:
$(SCHL_AGC_LIST) : $$(subst agc.list,ng.fasta, $$@) code/run_agc.sh code/agc.params.txt
	bash code/run_agc.sh $<
	$(eval NG_LIST=$(subst agc.list,ng.agc.list,$@))
	mv $(NG_LIST) $@

SCHL_CLOSED_LIST = $(addprefix data/schloss/schloss_, $(foreach F,$(FRACTION), $(foreach R,$(REP),  $F_$R.closed.list)))
.SECONDEXPANSION:
$(SCHL_CLOSED_LIST) : $$(subst closed.list,ng.fasta, $$@) code/run_closed.sh code/closedref.params.txt
	bash code/run_closed.sh $<
	$(eval NG_LIST=$(subst closed.list,ng.closed.list,$@))
	mv $(NG_LIST) $@

SCHL_OPEN_LIST = $(addprefix data/schloss/schloss_, $(foreach F,$(FRACTION), $(foreach R,$(REP),  $F_$R.open.list)))
.SECONDEXPANSION:
$(SCHL_OPEN_LIST) : $$(subst open.list,ng.fasta, $$@) code/run_open.sh code/openref.params.txt
	bash code/run_open.sh $<
	$(eval NG_LIST=$(subst open.list,ng.open.list,$@))
	mv $(NG_LIST) $@

SCHL_SWARM_LIST = $(addprefix data/schloss/schloss_, $(foreach F,$(FRACTION), $(foreach R,$(REP),  $F_$R.swarm.list)))
.SECONDEXPANSION:
$(SCHL_SWARM_LIST) : $$(subst swarm.list,unique.fasta, $$@) $$(subst swarm.list,names, $$@) code/cluster_swarm.R
	$(eval FASTA=$(word 1,$^))
	$(eval NAMES=$(word 2,$^))
	R -e 'source("code/cluster_swarm.R"); get_mothur_list("$(FASTA)", "$(NAMES)")'

SCHL_GREEDY_LIST = $(SCHL_DGC_LIST) $(SCHL_AGC_LIST) $(SCHL_OPEN_LIST) $(SCHL_CLOSED_LIST) $(SCHL_SWARM_LIST)


SCHL_NEIGHBOR_SENSSPEC = $(subst list,sensspec, $(SCHL_NEIGHBOR_LIST))
.SECONDEXPANSION:
$(SCHL_NEIGHBOR_SENSSPEC) : $$(addsuffix .dist,$$(basename $$(basename $$@)))  $$(subst sensspec,list,$$@)
	$(eval LIST=$(word 2,$^))
	mothur "#sens.spec(column=$<, list=$(LIST), label=0.03, outputdir=data/schloss)"

SCHL_GREEDY_SENSSPEC = $(subst list,sensspec, $(SCHL_GREEDY_LIST))
.SECONDEXPANSION:
$(SCHL_GREEDY_SENSSPEC) : $$(addsuffix .unique.dist,$$(basename $$(basename $$@)))  $$(subst sensspec,list,$$@)
	$(eval LIST=$(word 2,$^))
	mothur "#sens.spec(column=$<, list=$(LIST), label=userLabel, cutoff=0.03, outputdir=data/schloss)"


SCHL_REF_MCC = data/schloss/schloss.fn.ref_mcc data/schloss/schloss.nn.ref_mcc data/schloss/schloss.an.ref_mcc data/schloss/schloss.agc.ref_mcc data/schloss/schloss.dgc.ref_mcc data/schloss/schloss.closed.ref_mcc data/schloss/schloss.open.ref_mcc data/schloss/schloss.swarm.ref_mcc
data/schloss/schloss.an.ref_mcc : code/reference_mcc.R $(SCHL_AN_LIST) $(SCHL_NAMES)
	R -e "source('code/reference_mcc.R');run_reference_mcc('data/schloss/', 'schloss.*unique.an.list', 'schloss_1.0.*unique.an.list', 'schloss.*names', 'data/schloss/schloss.an.ref_mcc')"

data/schloss/schloss.fn.ref_mcc : code/reference_mcc.R $(SCHL_FN_LIST) $(SCHL_NAMES)
	R -e "source('code/reference_mcc.R');run_reference_mcc('data/schloss/', 'schloss.*unique.fn.list', 'schloss_1.0.*unique.fn.list', 'schloss.*names', 'data/schloss/schloss.fn.ref_mcc')"

data/schloss/schloss.nn.ref_mcc : code/reference_mcc.R $(SCHL_NN_LIST) $(SCHL_NAMES)
	R -e "source('code/reference_mcc.R');run_reference_mcc('data/schloss/', 'schloss.*unique.nn.list', 'schloss_1.0.*unique.nn.list', 'schloss.*names', 'data/schloss/schloss.nn.ref_mcc')"

data/schloss/schloss.closed.ref_mcc : code/reference_mcc.R $(SCHL_CLOSED_LIST) $(SCHL_NAMES)
	R -e "source('code/reference_mcc.R');run_reference_mcc('data/schloss/', 'schloss.*closed.list', 'schloss_1.0.*closed.list', 'schloss.*names', 'data/schloss/schloss.closed.ref_mcc')"

data/schloss/schloss.open.ref_mcc : code/reference_mcc.R $(SCHL_OPEN_LIST) $(SCHL_NAMES)
	R -e "source('code/reference_mcc.R');run_reference_mcc('data/schloss/', 'schloss.*open.list', 'schloss_1.0.*open.list', 'schloss.*names', 'data/schloss/schloss.open.ref_mcc')"

data/schloss/schloss.agc.ref_mcc : code/reference_mcc.R $(SCHL_AGC_LIST) $(SCHL_NAMES)
	R -e "source('code/reference_mcc.R');run_reference_mcc('data/schloss/', 'schloss.*agc.list', 'schloss_1.0.*agc.list', 'schloss.*names', 'data/schloss/schloss.agc.ref_mcc')"

data/schloss/schloss.dgc.ref_mcc : code/reference_mcc.R $(SCHL_DGC_LIST) $(SCHL_NAMES)
	R -e "source('code/reference_mcc.R');run_reference_mcc('data/schloss/', 'schloss.*dgc.list', 'schloss_1.0.*dgc.list', 'schloss.*names', 'data/schloss/schloss.dgc.ref_mcc')"

data/schloss/schloss.swarm.ref_mcc : code/reference_mcc.R $(SCHL_SWARM_LIST) $(SCHL_NAMES)
	R -e "source('code/reference_mcc.R');run_reference_mcc('data/schloss/', 'schloss.*swarm.list', 'schloss_1.0.*swarm.list', 'schloss.*names', 'data/schloss/schloss.swarm.ref_mcc')"


SCHL_POOL_SENSSPEC = data/schloss/schloss.an.pool_sensspec data/schloss/schloss.fn.pool_sensspec data/schloss/schloss.nn.pool_sensspec data/schloss/schloss.dgc.pool_sensspec data/schloss/schloss.agc.pool_sensspec data/schloss/schloss.open.pool_sensspec data/schloss/schloss.closed.pool_sensspec data/schloss/schloss.swarm.pool_sensspec
data/schloss/schloss.an.pool_sensspec : code/merge_sensspec_files.R $$(subst list,sensspec, $$(SCHL_AN_LIST)) 
	R -e "source('code/merge_sensspec_files.R');merge_sens_spec('data/schloss', 'schloss_.*an.sensspec', 'data/schloss/schloss.an.pool_sensspec')"

data/schloss/schloss.fn.pool_sensspec : code/merge_sensspec_files.R $$(subst list,sensspec, $$(SCHL_FN_LIST))
	R -e "source('code/merge_sensspec_files.R');merge_sens_spec('data/schloss', 'schloss_.*Fn.sensspec', 'data/schloss/schloss.fn.pool_sensspec')"

data/schloss/schloss.nn.pool_sensspec : code/merge_sensspec_files.R $$(subst list,sensspec, $$(SCHL_NN_LIST))
	R -e "source('code/merge_sensspec_files.R');merge_sens_spec('data/schloss', 'schloss_.*nn.sensspec', 'data/schloss/schloss.nn.pool_sensspec')"

data/schloss/schloss.dgc.pool_sensspec : code/merge_sensspec_files.R $$(subst list,sensspec, $$(SCHL_DGC_LIST))
	R -e "source('code/merge_sensspec_files.R');merge_sens_spec('data/schloss', 'schloss_.*dgc.sensspec', 'data/schloss/schloss.dgc.pool_sensspec')"

data/schloss/schloss.agc.pool_sensspec : code/merge_sensspec_files.R $$(subst list,sensspec, $$(SCHL_AGC_LIST))
	R -e "source('code/merge_sensspec_files.R');merge_sens_spec('data/schloss', 'schloss_.*agc.sensspec', 'data/schloss/schloss.agc.pool_sensspec')"

data/schloss/schloss.open.pool_sensspec : code/merge_sensspec_files.R $$(subst list,sensspec, $$(SCHL_OPEN_LIST))
	R -e "source('code/merge_sensspec_files.R');merge_sens_spec('data/schloss', 'schloss_.*open.sensspec', 'data/schloss/schloss.open.pool_sensspec')"

data/schloss/schloss.closed.pool_sensspec : code/merge_sensspec_files.R $$(subst list,sensspec, $$(SCHL_CLOSED_LIST))
	R -e "source('code/merge_sensspec_files.R');merge_sens_spec('data/schloss', 'schloss_.*closed.sensspec', 'data/schloss/schloss.closed.pool_sensspec')"

data/schloss/schloss.swarm.pool_sensspec : code/merge_sensspec_files.R $$(subst list,sensspec, $$(SCHL_SWARM_LIST))
	R -e "source('code/merge_sensspec_files.R');merge_sens_spec('data/schloss', 'schloss_.*swarm.sensspec', 'data/schloss/schloss.swarm.pool_sensspec')"


SCHL_RAREFACTION = data/schloss/schloss.an.rarefaction data/schloss/schloss.nn.rarefaction data/schloss/schloss.fn.rarefaction data/schloss/schloss.agc.rarefaction data/schloss/schloss.dgc.rarefaction data/schloss/schloss.closed.rarefaction data/schloss/schloss.open.rarefaction data/schloss/schloss.swarm.rarefaction

data/schloss/schloss.an.rarefaction : $(SCHL_AN_LIST) code/rarefy_data.R 
	R -e "source('code/rarefy_data.R');rarefy_sobs('unique.an', 'data/schloss')"

data/schloss/schloss.nn.rarefaction : $(SCHL_NN_LIST) code/rarefy_data.R 
	R -e "source('code/rarefy_data.R');rarefy_sobs('unique.nn', 'data/schloss')"

data/schloss/schloss.fn.rarefaction : $(SCHL_FN_LIST) code/rarefy_data.R 
	R -e "source('code/rarefy_data.R');rarefy_sobs('unique.fn', 'data/schloss')"

data/schloss/schloss.agc.rarefaction : $(SCHL_AGC_LIST) code/rarefy_data.R 
	R -e "source('code/rarefy_data.R');rarefy_sobs('agc', 'data/schloss')"

data/schloss/schloss.dgc.rarefaction : $(SCHL_DGC_LIST) code/rarefy_data.R 
	R -e "source('code/rarefy_data.R');rarefy_sobs('dgc', 'data/schloss')"

data/schloss/schloss.closed.rarefaction : $(SCHL_CLOSED_LIST) code/rarefy_data.R 
	R -e "source('code/rarefy_data.R');rarefy_sobs('closed', 'data/schloss')"

data/schloss/schloss.open.rarefaction : $(SCHL_OPEN_LIST) code/rarefy_data.R 
	R -e "source('code/rarefy_data.R');rarefy_sobs('open', 'data/schloss')"

data/schloss/schloss.swarm.rarefaction : $(SCHL_SWARM_LIST) code/rarefy_data.R 
	R -e "source('code/rarefy_data.R');rarefy_sobs('swarm', 'data/schloss')"

