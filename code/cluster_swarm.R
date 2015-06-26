# this is an r-based wrapper to cluster sequences using the swarm algorithm.
# swarm isn't really designed to be used as a distance-based threshold method,
# but whatever, that's what people really want. this is how to run the code:
#
#		get_mothur_list(something.unique.fasta, something.names)
#
#		output: something.swarm.list
#


# here we read in the names and unique'd fasta file generated in mothur and
# output a modified fasta file that will work with swarm. the only change is to
# concatenate the number of sequences each unique sequence represents to the end
# of the sequence name with a _ separating the sequence name and frequency.

prep_swarm_clust <- function(names, fasta){
	names_file <- read.table(file=names, stringsAsFactors=FALSE)
	names_data <- names_file[,2]
	names(names_data) <- names_file[,1]
	n_seqs <- nchar(names_data) - nchar(gsub(",", "", names_data)) + 1

	fasta_data <- scan(fasta, what="")
	sequence_data <- fasta_data[grepl("^[ATGCatgc]", fasta_data)]
	names(sequence_data) <- gsub(">", "", fasta_data[grepl("^>", fasta_data)], 2, )

	seq_with_freq <- paste0(">", names(sequence_data), "_", n_seqs[names(sequence_data)], "\n", sequence_data)

	swarm_fasta <- gsub("unique", "swarm", fasta)
	write(seq_with_freq, swarm_fasta)

	swarm_fasta
}


# here's the wrapper that calls swarm. this assumes that swarm is installed in
# code/swarm/bin. the output will only contain the unique sequence names with
# the frequency data concatenated to the end.
run_swarm_clust <- function(fasta){
	swarm_fasta <- gsub("unique", "swarm", fasta)
	swarm_list <- gsub("fasta", "temp_list", swarm_fasta)

	command_string <- paste("code/swarm/bin/swarm -f -t 8 --mothur -o", swarm_list,  swarm_fasta)
	system(command_string)

	swarm_list
}


# this takes the name file mapping and integrates the names of the redundant
# sequences into the list file in place of the unique sequence names from the
# swarm list file.
map_names <- function(otu_list, names_mapping){
	sequences <- unlist(strsplit(otu_list, split=","))
	paste(names_mapping[sequences], collapse=",")
}


# this function will convert the swarm mothur-based list file and converts it
# to a true mothur-based list file. basically, for each unique sequence name
# from the swarm file, it inserts the names of the redundant sequence names.
convert_swarm_clust <- function(swarm_fasta_file, swarm_list_file, names_file){
	names_mapping <- read.table(file=names_file, stringsAsFactors=FALSE)
	temp <- names_mapping[,1]
	names_mapping <- names_mapping[,-1]
	names(names_mapping) <- temp

	swarm_list <- scan(swarm_list_file, what="")
	swarm_list <- swarm_list[-c(1,2)]
	swarm_list <- gsub("_\\d*", "", swarm_list)

	sapply(swarm_list, map_names, names_mapping)
}


# this function drives the assignment of sequences to OTUs using swarm. takes
# as input the output of running unique.seqs (*.unique.fasta and *.names) and
# outputs *.swarm.list using 'swarm' as the label in the list file
get_mothur_list <- function(fasta, names){
	swarm_fasta_file_name <- prep_swarm_clust(names, fasta)
	swarm_list_file_name <- run_swarm_clust(fasta)

	red_names_list <- convert_swarm_clust(swarm_fasta_file_name, swarm_list_file_name, names)
	mothur_list_file_name <- gsub("temp_list", "list", swarm_list_file_name)
	mothur_list_file_content <- paste(c("swarm", length(red_names_list), red_names_list), collapse="\t")
	write(mothur_list_file_content, mothur_list_file_name)
}
