#! /usr/bin/env nextflow
/*
nextflow run compare.nf --input /home/docker/Data/vcfs_tests --pattern *.vcf --output /home/docker/Data/vcfs_tests_output
*/

params.ref = "tests/ref/NC_000962.fasta"
ref = file(params.ref)

params.refindex = "tests/ref/NC_000962.fasta.fai"
refindex = file(params.refindex)

params.refvcf = "tests/ref/snps.vcf"
refvcf = file(params.refvcf)

params.input = "tests/input/"
params.pattern = "*.vcf"
params.output = "tests/output"

vcf_path = params.input + params.pattern

if (params.pattern == "*.vcf.gz"){

    gzip_files_channel = Channel.fromPath(vcf_path)

    process unzip_vcf {

        tag {gzip_file.getBaseName()}

        input:
            file gzip_file from gzip_files_channel

        output:
            set file("${gzip_file.getBaseName()}.vcf") into vcf_files_channel

        """
            gunzip -c ${gzip_file} > ${gzip_file.getBaseName()}.vcf
        """
        }
}

if (params.pattern == "*.vcf"){

   vcf_files_channel = Channel.fromPath(vcf_path)
}


process process_vcf {
    echo true
    scratch true

    label "happy"

    //errorStrategy 'ignore'

    publishDir "${params.output}/${vcf_file.getBaseName()}/", mode: "copy"

    tag {vcf_file.getBaseName()}

    input:
    file ref
    file refvcf
    file refindex
    file vcf_file from vcf_files_channel

    output:
    set val("${vcf_file.getBaseName()}"), file("${vcf_file.getBaseName()}.*") 

    """
    /opt/hap.py/bin/hap.py -r ${ref} ${refvcf} ${vcf_file} -o ${vcf_file.getBaseName()}
    """
}