# This script implements the DGC algorithm from He et al. 2015 as described
# in supplementary file 1. Because the output from QIIME is a biom-formatted
# file, we change it into a mothur list file. The input is a fasta file and
# the output is a list file where dgc is used as the method tag

FASTA=$1
DGC_PATH=$(echo $FASTA | sed 's/fasta/dgc/')

rm -rf $DGC_PATH/
pick_de_novo_otus.py -i $FASTA -o $DGC_PATH -p code/dgc.params.txt
R -e "source('code/biom_to_list.R'); biom_to_list('$DGC_PATH/otu_table.biom')"
rm -rf $DGC_PATH/

