package CoGeX::Result::Dataset;

use strict;
use warnings;
use Data::Dumper;
use POSIX;
use Carp qw (cluck);
use CoGe::Core::Storage qw( reverse_complement );

use base 'DBIx::Class::Core';

#use CoGeX::Result::Feature; #need to figure this out and uncomment.  Going to case a lot of problems.
use Text::Wrap;
use Carp;

=head1 NAME

CoGeX::Dataset

=head1 SYNOPSIS

This object uses the DBIx::Class to define an interface to the C<dataset> table in the CoGe database.

=head1 DESCRIPTION

=head1 AUTHORS

 Eric Lyons
 Brent Pedersen

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

__PACKAGE__->table("dataset");
__PACKAGE__->resultset_class("CoGeX::ResultSet::Dataset");
__PACKAGE__->add_columns(
    "dataset_id",
    {
        data_type     => "INT",
        default_value => undef,
        is_nullable   => 0,
        size          => 11
    },
    "data_source_id",
    { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
    "name",
    {
        data_type     => "VARCHAR",
        default_value => "",
        is_nullable   => 0,
        size          => 100
    },
    "description",
    {
        data_type     => "VARCHAR",
        default_value => undef,
        is_nullable   => 1,
        size          => 255,
    },
    "version",
    {
        data_type     => "VARCHAR",
        default_value => undef,
        is_nullable   => 1,
        size          => 50,
    },
    "link",
    {
        data_type     => "TEXT",
        default_value => undef,
        is_nullable   => 1,
        size          => 65535,
    },
    "date",
    {
        data_type     => "DATETIME",
        default_value => "",
        is_nullable   => 0,
        size          => 19
    },
    "restricted",
    { data_type => "int", default_value => "0", is_nullable => 0, size => 1 },
    "deleted",
    { data_type => "int", default_value => "0", is_nullable => 0, size => 1 },
    "creator_id",
    { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
);

__PACKAGE__->set_primary_key("dataset_id");
__PACKAGE__->has_many( "features" => "CoGeX::Result::Feature", 'dataset_id' );
__PACKAGE__->has_many(
    "dataset_connectors" => "CoGeX::Result::DatasetConnector",
    'dataset_id'
);
__PACKAGE__->belongs_to(
    "data_source" => "CoGeX::Result::DataSource",
    'data_source_id'
);

################################################ subroutine header begin ##

=head2 genomes

 Usage     :
 Purpose   :
 Returns   :
 Argument  :
 Throws    :
 Comments  :

See Also   :

=cut

################################################## subroutine header end ##

sub genomes {
    my $self = shift;
    my %opts = @_;
    my $chr  = $opts{chr};

    my @genomes;
    foreach my $dsc ( $self->dataset_connectors() ) {
        if ( defined $chr ) {
            my %chrs = map { $_, 1 } $dsc->genome->chromosomes;
            next unless $chrs{$chr};
        }
        push @genomes, $dsc->genome;
    }
    return wantarray ? @genomes : \@genomes;
}

sub first_genome {
    my $self = shift;

    #my %opts = @_;
    foreach my $dsc ( $self->dataset_connectors() ) {
        return $dsc->genome;
    }
}

sub dataset_groups {
    cluck "Dataset::dataset_groups is obselete, please use ->genomes\n";
    shift->genomes(@_);
}

################################################ subroutine header begin ##

=head2 organism

 Usage     :
 Purpose   :
 Returns   :
 Argument  :
 Throws    :
 Comments  :

See Also   :

=cut

################################################## subroutine header end ##

sub organism {
    my $self = shift;
    my %opts = @_;
    my %orgs = map { $_->id, $_ } map { $_->organism } $self->genomes;
    if ( keys %orgs > 1 ) {
        warn "sub organism in Dataset.pm fetched more than one organism!  Very odd:\n";
        warn join( "\n", map { $_->name } values %orgs ), "\n";
        warn "Only one will be returned\n";
    }
    my ($org) = values %orgs;
    return $org;
}

sub datasource {
    shift->data_source(@_);
}

sub source {
    shift->data_source(@_);
}

sub desc {
    shift->description(@_);
}

################################################ subroutine header begin ##

=head2 info

 Usage     : $self->info
 Purpose   : returns a string of information about the data set.

 Returns   : returns a string
 Argument  : none
 Throws    :
 Comments  : To be used to quickly generate a string about the data set

See Also   :

=cut

################################################## subroutine header end ##

sub info {
    my $self = shift;
    my $info;
    $info .= $self->name if $self->name;
    $info .= ": " . $self->description if $self->description;
    $info .=
      " (v" . $self->version . ", " . $self->date . ", id" . $self->id . ")";
    return $info;
}

################################################ subroutine header begin ##

=head2 get_genomic_sequence

 Usage     :
 Purpose   :
 Returns   :
 Argument  :
 Throws    :
 Comments  :

See Also   :

=cut

################################################## subroutine header end ##

# mdb replaced 7/31/13, issue 77
#sub get_genomic_sequence
#{
#	my $self = shift;
#	my %opts = @_;
#
#	my $start = $opts{start} || $opts{begin};
#	my $stop  = $opts{stop}  || $opts{end};
#	my $chr   = $opts{chr};
#	$chr = $opts{chromosome} unless defined $chr;
#	my $strand   = $opts{strand};
#	my $seq_type = $opts{seq_type} || $opts{gstid};
#	my $debug    = $opts{debug};
#	my $dsgid    = $opts{dsgid};
#	my $server   = $opts{server};                     #server from which to retrieve genomic sequence if not stored on local machine.  Web retrieval from CoGe/GetSequence.pl
#	my $dsg;
#	$dsg = $dsgid if $dsgid && ref($dsgid) =~ /Genome/;
#	return $dsg->genomic_sequence( start => $start, stop => $stop, chr => $chr, strand => $strand, debug => $debug, server => $server ) if $dsg;
#	my $seq_type_id = ref($seq_type) =~ /GenomicSequenceType/i ? $seq_type->id : $seq_type;
#	$seq_type_id = 1 unless $seq_type_id && $seq_type_id =~ /^\d+$/;
#
#	foreach my $tmp_dsg ( $self->groups )
#	{
#		if ( ( $dsgid && $tmp_dsg->id == $dsgid ) || ( $seq_type_id && $tmp_dsg->genomic_sequence_type->id == $seq_type_id ) )
#		{
#			return $tmp_dsg->genomic_sequence( start => $start, stop => $stop, chr => $chr, strand => $strand, debug => $debug, server => $server );
#		}
#	}
#
#	#hmm didn't return -- perhaps the seq_type_id was off.  Go ahead and see if anything can be returned
#	#    carp "In Dataset.pm, sub get_genomic_sequence.  Did not return sequence from a genome with a matching sequence_type_id.  Going to try to return some sequence from any genome.\n";
#	($dsg) = $self->groups;
#	return $dsg->genomic_sequence( start => $start, stop => $stop, chr => $chr, strand => $strand, debug => $debug, server => $server );
#}
sub get_genomic_sequence {
    my $self = shift;
    my %opts = @_;

    my $start  = $opts{start};
    my $stop   = $opts{stop};
    my $chr    = $opts{chr};
    $chr = $opts{chromosome} unless defined $opts{chr};
    my $strand = $opts{strand};
    my $gstid  = $opts{gstid};
    #print STDERR "Dataset->get_genomic_sequence:  start $start stop $stop chr $chr strand $strand\n";
    $gstid = 1 unless $gstid;    #FIXME hardcoded type value
    my $gid = $opts{gid};
    my $genome = $opts{genome}; #genome object
    $genome = $gid if ( $gid && ref($gid) =~ /Genome/ );
    unless ($genome && ref($genome) =~ /Genome/) {
        foreach ( $self->genomes ) {
            if ( $_->genomic_sequence_type_id == $gstid ) {
                $genome = $_;
                last;
            }
        }

# Hmmm didn't return -- perhaps the seq_type_id was off.  Go ahead and see if anything can be returned.
        unless ($genome) {
            ($genome) = $self->genomes;
        }
    }

    return $genome->get_genomic_sequence(
        chr    => $chr,
        start  => $start,
        stop   => $stop,
        strand => $strand
    );
}

# mdb removed 7/31/13, issue 77
#sub get_genome_sequence
#{
#	return shift->get_genomic_sequence(@_);
#}
#sub genomic_sequence
#{
#	return shift->get_genomic_sequence(@_);
#}

################################################ subroutine header begin ##

=head2 trim_sequence

 Usage     :
 Purpose   :
 Returns   :
 Argument  :
 Throws    :
 Comments  :

See Also   :

=cut

################################################## subroutine header end ##

sub trim_sequence {
    my $self = shift;
    my ( $seq, $seqstart, $seqend, $newstart, $newend ) = @_;

    my $start = $newstart - $seqstart;
    my $stop = length($seq) - ( $seqend - $newend ) - 1;
    $seq = substr( $seq, $start, $stop - $start + 1 );

    return ($seq);
}

################################################## subroutine header start ##

=head2 last_chromsome_position

 Usage     : my $last = $genome_seq_obj->last_chromosome_position($chr);
 Purpose   : gets the last genomic sequence position for a dataset given a chromosome
 Returns   : an integer that refers to the last position in the genomic sequence refered
             to by a dataset given a chromosome
 Argument  : string => chromsome for which the last position is sought
 Throws    :
 Comments  :

See Also   :

=cut

################################################## subroutine header end ##

sub last_chromosome_position {
    my $self = shift;
    my $chr  = shift;
    return 0 unless defined $chr;

    my $dsg = $self->first_genome; #my ($dsg) = $self->genomes; # mdb changed 4/23/14 issue 364
    my ($item) = $dsg->genomic_sequences( { chromosome => "$chr" } );
    unless ($item) {
        warn "Dataset::last_chromosome_position: unable to find genomic_sequence object for '$chr'";
        return 0;
    }
    my $stop = $item->sequence_length();
    unless ($stop) {
        warn "No genomic sequence for ", $self->name, " for chr $chr\n";
        return 0;
    }
    return $stop;
}

################################################ subroutine header begin ##

=head2 last_chromosome_position_old

 Usage     :
 Purpose   :
 Returns   :
 Argument  :
 Throws    :
 Comments  :

See Also   :

=cut

################################################## subroutine header end ##

sub last_chromosome_position_old {
    my $self = shift;
    my $chr  = shift;
    my $stop = $self->genomic_sequences( { chromosome => "$chr", }, )->get_column('stop')->max;
    unless ($stop) {
        warn "No genomic sequence for ", $self->name, " for chr $chr\n";
        return;
    }
    return $stop;
}

################################################ subroutine header begin ##

=head2 sequence_type

 Usage     :
 Purpose   :
 Returns   :
 Argument  :
 Throws    :
 Comments  :

See Also   :

=cut

################################################## subroutine header end ##

sub total_length {
    my $self = shift;
    my %opts = @_;
    my $ftid = $opts{ftid};
    my $search;
    my $join = {
        select => [ { sum => 'stop' } ],
        as     => ['total_length']
        ,    # remember this 'as' is for DBIx::Class::ResultSet not SQL
    };
    if ($ftid) {
        $search = { 'feature_type_id' => $ftid };
    }
    else {
        $search = { 'name' => 'chromosome' };
        $join->{join} = 'feature_type';
    }

    my $rs = $self->features( $search, $join );
    my $total_length = $rs->first->get_column('total_length');
    return ( defined $total_length ? $total_length : 0);
}

############################################### subroutine header begin ##

=head2 chromosome_count

 Usage     : $self->chromosome_count
 Purpose   : get count of chromosomes in the dataset group
 Returns   : number
 Argument  :
 Throws    :
 Comments  :

See Also   :

=cut

################################################## subroutine header end ##

sub chromosome_count {
    my $self = shift;
    my %opts = @_;
    my $ftid = $opts{ftid};
    my $search;
    my $join;
    if ($ftid) {
        $search = { 'feature_type_id' => $ftid };
    }
    else {
        $search = { 'name' => 'chromosome' };
        $join->{join} = 'feature_type';
    }

    my $count = $self->features( $search, $join )->count;
    return $count;
}

sub has_gene_annotation {
    my $self = shift;

    #my %opts = @_;
    return $self->features( { 'feature_type_id' => { -in => [ 1, 2, 3 ] } } )
      ->count;
}

sub sequence_type {
    my $self   = shift;
    my (@dsgs) = $self->genomes;
    my %types  = map { $_->id, $_ } map { $_->genomic_sequence_type } @dsgs;
    my @types  = values %types;

    #    my ($type) = $self->genomic_sequences->slice(0,0);
    #    return $type ? $type->genomic_sequence_type : undef;
    if ( @types == 1 ) {
        return shift @types;
    }
    elsif ( @types > 1 ) {
        return wantarray ? @types : \@types;
    }
    else {
        return undef;
    }
}

sub genomic_sequence_type {
    my $self = shift;
    return $self->sequence_type(@_);
}

################################################ subroutine header begin ##

=head2 get_chromosomes

 Usage     :
 Purpose   :
 Returns   :
 Argument  :
 Throws    :
 Comments  :

See Also   :

=cut

################################################## subroutine header end ##

sub get_chromosomes {
    my $self   = shift;
    my %opts   = @_;
    my $ftid   = $opts{ftid};   #feature_type_id for feature_type of name "chromosome";
    my $length = $opts{length}; #option to return length of chromosomes as well
    my $limit  = $opts{limit};  #optional number of chromosomes to return, sorted by size
    my $max    = $opts{max};    #optional number of chromosomes to avoid slow query, sorted by size
    my @data;

    #this query is faster if the feature_type_id of feature_type "chromosome" is known.
    #features of this type refer to the entire stored sequence which may be a fully
    #assembled chromosome, or a contig, supercontig, bac, etc.
    my $search = {};
    my $search_type = { order_by => { -desc => 'stop' } };
    if ($ftid) {
        $search->{feature_type_id} = $ftid;
    }
    else {
        $search->{name}      = "chromosome";
        $search_type->{join} = "feature_type";
    }
    
    if ($max && $self->features( $search, $search_type )->count() > $max ) {
        return;
    }

    if ($limit) {
        $search_type->{rows} = $limit;
    }
    
    if ($length) {
        @data = $self->features( $search, $search_type );
    }
    else {
        @data = map { $_->chromosome } $self->features( $search, $search_type );
    }
    unless (@data) {
        my %seen;
        foreach my $feat ( $self->features({}, { distinct => 'chromosome' }) ) {
	       $seen{$feat->chromosome} = 1 if $feat->chromosome;
        }
        @data = sort keys %seen;
    }
    return wantarray ? @data : \@data;
}

sub chromosomes {
    my $self = shift;
    $self->get_chromosomes(@_);
}

################################################ subroutine header begin ##

=head2 has_chromosome

 Usage     : $ds->has_chromosome(chr=>"12")
 Purpose   : test to see if a dataset has a particular chromsome
 Returns   : 1 if yes, 0 if no
 Argument  :
 Throws    :
 Comments  :

See Also   :

=cut

################################################## subroutine header end ##

sub has_chromosome {

    my $self = shift;
    my %opts = @_;
    my $chr  = $opts{chr};
    my ($res) =
      $self->features->count( { "feature_type.name" => "chromosome", },
        { join => ["feature_type"] } );
    if ($res) {
        my ($res) = $self->features(
            {
                "feature_type.name" => "chromosome",
                "chromosome"        => "$chr",
            },
            { join => ["feature_type"] }
        );
        return 1 if $res;
        return 0;
    }
    else {
        my ($res) = $self->features->count( { "chromosome" => "$chr", }, );
        return 1 if $res;
        return 0;
    }
}

################################################ subroutine header begin ##

=head2 percent_gc

 Usage     :
 Purpose   :
 Returns   :
 Argument  :
 Throws    :
 Comments  :

See Also   :

=cut

################################################## subroutine header end ##

sub percent_gc {
    my $self  = shift;
    my %opts  = @_;
    my $count = $opts{count};

    #    my $chr = $opts{chr};
    my $seq    = $self->get_genomic_sequence(%opts);
    my $length = length $seq;
    return unless $length;
    my ($gc) = $seq =~ tr/GCgc/GCgc/;
    my ($at) = $seq =~ tr/ATat/ATat/;
    my ($n)  = $seq =~ tr/nN/nN/;
    my ($x)  = $seq =~ tr/xX/xX/;
    return ( $gc, $at, $n, $x ) if $count;
    return sprintf( "%.4f", $gc / $length ), sprintf( "%.4f", $at / $length ),
      sprintf( "%.4f", $n / $length ), sprintf( "%.4f", $x / $length );
}

sub gc_content {
    shift->percent_gc(@_);
}

################################################ subroutine header begin ##

=head2 fasta

 Usage     :
 Purpose   :
 Returns   :
 Argument  :
 Throws    :
 Comments  :

See Also   :

=cut

################################################## subroutine header end ##

sub fasta {
    my $self = shift;
    my %opts = @_;
    my $col  = $opts{col};

    #$col can be set to zero so we want to test for defined variable
    $col = $opts{column} unless defined $col;
    $col = $opts{wrap}   unless defined $col;
    $col = 100           unless defined $col;
    my $chr = $opts{chr};
    ($chr) = $self->get_chromosomes unless defined $chr;
    my $strand = $opts{strand} || 1;
    my $start  = $opts{start}  || 1;
    $start = 1 if $start < 1;
    my $stop  = $opts{stop} || $self->last_chromosome_position($chr);
    my $prot  = $opts{prot};
    my $rc    = $opts{rc};
    my $gstid = $opts{gstid};
    $strand = -1 if $rc;
    my $seq = $self->get_genomic_sequence(
        chr   => $chr,
        start => $start,
        stop  => $stop,
        gstid => $gstid
    );
    $stop = $start + length($seq) - 1 if $stop > $start + length($seq) - 1;
    my $head = ">" . $self->organism->name . " (" . $self->name;
    $head .= ", " . $self->description if $self->description;
    $head .= ", v"
      . $self->version . ")"
      . ", Location: "
      . $start . "-"
      . $stop
      . " (length: "
      . ( $stop - $start + 1 )
      . "), Chromosome: "
      . $chr
      . ", Strand: "
      . $strand;

    $Text::Wrap::columns = $col;
    my $fasta;

    $seq = reverse_complement($seq) if $rc;
    if ($prot) {
        my $trans_type = $self->trans_type;
        my $feat       = new CoGeX::Result::Feature;
        my ( $seqs, $type ) = $feat->frame6_trans(
            seq        => $seq,
            trans_type => $trans_type,
            gstid      => $gstid
        );
        foreach my $frame ( sort { length($a) <=> length($b) || $a cmp $b }
            keys %$seqs )
        {
            $seq = $seqs->{$frame};
            $seq = reverse_complement($seq) if $rc;
            $seq = join( "\n", wrap( "", "", $seq ) ) if $col;
            $fasta .= $head . " $type frame $frame\n" . $seq . "\n";
        }
    }
    else {
        $seq = join( "\n", wrap( "", "", $seq ) ) if $col;
        $fasta = $head . "\n" . $seq . "\n";
    }
    return $fasta;
}

################################################ subroutine header begin ##

=head2 gff

 Usage     : $ds->gff(print=>1)
 Purpose   : generating a gff file for a dataset from all the features it contains
 Returns   : a string
 Argument  : name_re     =>    regular expression for only displaying features containing a name that matches
             print       =>    print the gff file as the lines are retrieved
             annos       =>    print annotations as well (takes longer)
             debug       =>    prints some debugging stuff
             no_gff_head =>    won't print "gff-version 3".  Used when this function is called by Genome->gff(); (default 0)
             ds          =>    Dataset object.  Uses $self if none is specified
             id          =>    Starting number to be used for ID tag.  This in incremented by one with each entry.
             cds         =>    Only print CDS gene features (skip all ncRNA and other features).  Will print genes, mRNA, and CDS entries
             id_type     =>    Specify if the GFF entry IDs are going to be unique numbers or unique names.
             unique_parent_annotations => Flag to NOT print redundant annotations in children entries.  E.g. if parent has an annotation, a child will not have that annotation
             name_unique =>   Flag for specifying that the name tag of an entry will be unique
 Throws    :
 Comments  :

See Also   : genome->gff

=cut

################################################## subroutine header end ##

sub gff {
    my $self = shift;
    my %opts = @_;
    my $name_re = $opts{name_re};  #regular expression to search for a specific name
    my $debug   = $opts{debug};    #debug flag
    my $print   = $opts{print};    #flag to print gff as it is being retrieved
    my $annos   = $opts{annos};    #flag to retrieve and add annotations
    my $no_gff_head = $opts{no_gff_head}; #flag to NOT print gff headers (used in conjunction with genome->gff which generates its own headers
    my $ds    = $opts{ds};  #ds object, uses self if one is not passed in
    my $count = $opts{id};  #number to be used for unique identification of each id.  starts at 0 unless one is passed in
    my $cds   = $opts{cds}; #flag to only print protein coding genes
    my $name_unique = $opts{name_unique}; #flag for making Name tag of output unique by appending type and occurrence to feature name
    my $unique_parent_annotations = $opts{unique_parent_annotations}; #flag so that annotations are not propogated to children if they are contained by their parent
    my $id_type  = $opts{id_type};  #type of ID (name, num):  unique number; unique name
    my $cds_exon = $opts{cds_exon}; #option so that CDSs are used for determining an exon instead of the mRNA.  This keeps UTRs from being called an exon
    my $chromosome = $opts{chr}; #optional, set to only include features on a particular chromosome
    $id_type = "name" unless defined $id_type;
    $count = 0 unless ($count && $count =~ /^\d+$/);
    $ds = $self unless $ds;

    # mdb added 4/22/14 issue 364 - cache db objects to improve performance
    my $cache;
    $cache->{feature_annotations} = {};
    $cache->{annotation_type} = {};

    my $output; # store the goodies

    # Generate GFF header
    my @chrs;
    my %chrs;
    foreach my $chr ( $ds->get_chromosomes ) {
        $chrs{$chr} = $ds->last_chromosome_position($chr);
    }
    if ($chromosome) {
    	@chrs = ($chromosome);
    } else {
	    @chrs = sort { $a cmp $b } keys %chrs;
    }

    my $tmp;
    $tmp = "##gff-version\t3\n" unless $no_gff_head;
    $output .= $tmp if $tmp;
    print $tmp if $print && !$no_gff_head;
    foreach my $chr (@chrs) {
        next unless $chrs{$chr};
        $tmp = "##sequence-region $chr 1 " . $chrs{$chr} . "\n";
        $output .= $tmp;
        print $tmp if $print;
    }

    my %fids = ();  #skip fids that we have processed
    my %types;      #track the number of different feature types encountered
    my %ids2names;  #lookup table for unique id numbers to unique id names (determined by $id_type)
    my %unique_ids; #place to make sure that each ID used is unique;
    my %prev_annos; #hash to store previously used annotations by parents.  Used in conjunction with the $unique_parent_annotations flag
    my %prior_genes;  #place to store previous gene models for alternatively spliced transcript lookup of parents.  keys is the primary name of the transcript.  value is coge feature object
    my %orphaned_RNA; #place to store RNAs without a parent feature
    #my $prior_gene;  #place to store the prior gene, if needed.  Some alternatively spliced transcripts have one gene per transcript, some have one gene for all transcripts.
    #my $prior_gene_id; #place to store the prior gene's ID for use the GFF file.  Use of this is tied to having and using a prior_gene

    my $prefetch = [ 'feature_type', 'feature_names' ];
    #push @$prefetch, {'annotations' => 'annotation_type'} if $annos;
    foreach my $chr (@chrs) {
        my %seen = (); #for storage of seen names organized by $feat_name{$name}
        my $rs_feat = $ds->features(
            { chromosome => $chr }, # mdb added 4/23/14 issue 364
            {
                'prefetch' => $prefetch,
                'order_by' => [ 'me.chromosome', 'me.start', 'me.feature_type_id'
                  ] #go by order in genome, then make sure that genes (feature_type_id == 1) is first
            }
        );

        #gff columns: chr organization feature_type start stop strand . name
        print STDERR "dataset_id: " . $ds->id."\n" if $debug;# . ";  chr: $chr\n" if $debug;
        main: while ( my $feat = $rs_feat->next ) {
            next if ( $fids{ $feat->feature_id } );
            my $ft = $feat->feature_type;
#	        my $chr = $feat->chromosome;
            next unless $feat->start;
            next unless defined $feat->chromosome;
            print STDERR join ("\t", $ft->name, $feat->chromosome, $feat->start),"\n" if $debug;
            $types{ $ft->name }++;
            $count++;
            my @out;      #story hashref of items for output
            my %notes;    #additional annotations to add to gff line
            my @feat_names;
            if ($name_re) {
                @feat_names = grep { $_ =~ /$name_re/i } $feat->names();
                next unless @feat_names;
            }
            else {
                @feat_names = $feat->names();
            }
            $prior_genes{ $feat_names[0] } = $feat
              if $ft->name eq "gene" && !$prior_genes{ $feat_names[0] };
            if ( $ft->name =~ /RNA/ ) { #perhaps an alternatively spliced transcript
                #check for name congruence
                my $match = 0;
                my $prior_gene;
                my $prior_gene_id;
                name_search: foreach my $name ( $feat->names ) {
                    if ( $prior_genes{$name} ) {
                        $match         = 1;
                        $prior_gene    = $prior_genes{$name};
                        $prior_gene_id = $name;
                        last name_search;
                    }
                }
                if ($match) {
                    if (
                        $self->_search_rna(
                            name_search => [ $prior_gene->names ],
                            notes       => \%notes,
                            fids        => \%fids,
                            types       => \%types,
                            count       => \$count,
                            out         => \@out,
                            name_re     => $name_re,
                            parent_feat => $prior_gene,
                            parent_id   => $prior_gene_id,
                            chr         => $chr,
                            ds          => $ds,
                            cds_exon    => $cds_exon,
                        )
                      )
                    {
                        my $tmp = $self->_format_gff_line(
                            cache       => $cache,
                            out         => \@out,
                            notes       => \%notes,
                            cds         => $cds,
                            seen        => \%seen,
                            print       => $print,
                            annos       => $annos,
                            name_unique => $name_unique,
                            ids2names   => \%ids2names,
                            id_type     => $id_type,
                            unique_ids  => \%unique_ids,
                            unique_parent_annotations =>
                              $unique_parent_annotations,
                            prev_annos => \%prev_annos
                        );
                        $output .= $tmp if $tmp;
                        next main;
                    }
                }
                else {
                    $orphaned_RNA{ $feat->id } = $feat;
                    next main;
                }
            }

            foreach my $loc ( sort { $a->start <=> $b->start } $feat->locs() ) {
                push @out,
                  {
                    f         => $feat,
                    start     => $loc->start,
                    stop      => $loc->stop,
                    name_re   => $name_re,
                    id        => $count,
                    parent_id => 0,
                    type      => $ft->name
                  };
                $count++;
            }
            $fids{ $feat->feature_id } = 1;    #feat_id has been used

#			unless ( $ft->id == 1 && @feat_names )    #if not a gene, don't do the next set of searches.
            unless ( $ft->name =~ /gene/i && @feat_names ) {
                my $tmp = $self->_format_gff_line(
                    cache                     => $cache,
                    out                       => \@out,
                    notes                     => \%notes,
                    cds                       => $cds,
                    seen                      => \%seen,
                    print                     => $print,
                    annos                     => $annos,
                    name_unique               => $name_unique,
                    ids2names                 => \%ids2names,
                    id_type                   => $id_type,
                    unique_ids                => \%unique_ids,
                    unique_parent_annotations => $unique_parent_annotations,
                    prev_annos                => \%prev_annos
                );
                $output .= $tmp if $tmp;
                next;
            }

            #does this gene have an RNA?
            if (
                $self->_search_rna(
                    name_search => \@feat_names,
                    notes       => \%notes,
                    fids        => \%fids,
                    types       => \%types,
                    count       => \$count,
                    out         => \@out,
                    name_re     => $name_re,
                    parent_feat => $feat,
                    chr         => $chr,
                    ds          => $ds,
                    cds_exon    => $cds_exon,
                )
              )
            {
                my $tmp = $self->_format_gff_line(
                    cache                     => $cache,
                    out                       => \@out,
                    notes                     => \%notes,
                    cds                       => $cds,
                    seen                      => \%seen,
                    print                     => $print,
                    annos                     => $annos,
                    name_unique               => $name_unique,
                    ids2names                 => \%ids2names,
                    id_type                   => $id_type,
                    unique_ids                => \%unique_ids,
                    unique_parent_annotations => $unique_parent_annotations,
                    prev_annos                => \%prev_annos
                );
                $output .= $tmp if $tmp;
                next main;
            }

            #dump other stuff for gene that does not have mRNAs.
            my $sub_rs = $self->_feat_search(
                name_search => \@feat_names,
                skip_ftids  => [ 1, 2 ],
                ds          => $ds,
                chr         => $chr,
            );
            my $parent_id = $count;
            $parent_id--;
            while ( my $f = $sub_rs->next() ) {
                if ( $fids{ $f->feature_id } ) { next; }
                my $ftn = $self->process_feature_type_name( $f->feature_type->name );
                push @{ $notes{gene}{"Encoded_feature"} }, $self->escape_gff($ftn);
                foreach my $loc ( sort { $a->start <=> $b->start } $f->locs() ) {
                    next if ($loc->start > $feat->stop || $loc->stop < $feat->start);
                    #outside of genes boundaries;  Have to count it as something else
                    #sometimes mRNA features are missing.  This is due to the original dataset not having them enumerated.
                    # Need to do some special stuff for such cases where a CDS retrieved in the absense of an mRNA)
                    if ( $f->feature_type->name eq "CDS" ) {
                        #let's add the mRNA, change the parent and count (id)
                        push @out,
                          {
                            f         => $f,
                            start     => $loc->start,
                            stop      => $loc->stop,
                            name_re   => $name_re,
                            id        => $count,
                            parent_id => $parent_id,
                            type      => "mRNA"
                          };
                        $parent_id = $count;
                        $count++;
                    }
                    push @out,
                      {
                        f         => $f,
                        start     => $loc->start,
                        stop      => $loc->stop,
                        name_re   => $name_re,
                        id        => $count,
                        parent_id => $parent_id,
                        type      => "exon"
                      };
                    $count++;
                    push @out,
                      {
                        f         => $f,
                        start     => $loc->start,
                        stop      => $loc->stop,
                        name_re   => $name_re,
                        id        => $count,
                        parent_id => $parent_id,
                        type      => $f->feature_type->name
                      };
                    $fids{ $f->feature_id } = 1;    #feat_id has been used;
                    $types{ $f->feature_type->name }++;
                }
                my $tmp = $self->_format_gff_line(
                    cache                     => $cache,
                    out                       => \@out,
                    notes                     => \%notes,
                    cds                       => $cds,
                    seen                      => \%seen,
                    print                     => $print,
                    annos                     => $annos,
                    name_unique               => $name_unique,
                    ids2names                 => \%ids2names,
                    id_type                   => $id_type,
                    unique_ids                => \%unique_ids,
                    unique_parent_annotations => $unique_parent_annotations,
                    prev_annos                => \%prev_annos
                );
                $output .= $tmp if $tmp;
                last;
            }
        }
    }
    if ($print) {
        print "#Orphaned RNAs\n";
        foreach my $fid ( keys %orphaned_RNA ) {
            next if $fids{$fid};
            print "#", join( "\t", $fid, $orphaned_RNA{$fid}->names ), "\n";
        }
    }
    return $output, $count;
}

sub _feat_search {
    my $self        = shift;
    my %opts        = @_;
    my $name_search = $opts{name_search};
    my $skip_ftids  = $opts{skip_ftids};
    my $ds          = $opts{ds};
    my $chr         = $opts{chr};
    #print STDERR "_feat_search\n";

    return $ds->features(
        {
            'me.chromosome'      => $chr,
            'feature_names.name' => { 'IN' => $name_search },
            'me.feature_type_id' => { 'NOT IN' => $skip_ftids },
        },
        {
            'join'     => 'feature_names',
            'prefetch' => [ 'feature_type', 'locations' ],
            'order_by' => [ 'me.start', 'locations.start', 'me.feature_type_id' ]
        }
    );
}

sub _search_rna {
    my $self        = shift;
    my %opts        = @_;
    my $name_search = $opts{name_search};
    my $notes       = $opts{notes};
    my $fids        = $opts{fids};
    my $types       = $opts{types};
    my $count       = $opts{count};
    my $out         = $opts{out};
    my $parent_feat = $opts{parent_feat};
    my $parent_id   = $opts{parent_id};
    my $name_re     = $opts{name_re};
    my $chr         = $opts{chr};
    my $ds          = $opts{ds};
    my $cds_exon = $opts{cds_exon}; #option so that CDSs are used for determining an exon instead of the mRNA.  This keeps UTRs from being called an exon
    #print STDERR "_search_rna\n";

    my $rna_rs = $self->_feat_search(
        name_search => $name_search,
        skip_ftids  => [1],
        ds          => $ds,
        chr         => $chr,
    );

    #assemble RNA info
    while ( my $f = $rna_rs->next() ) {
        if ( $fids->{ $f->feature_id } ) { next; }
        next unless $f->feature_type->name =~ /RNA/i; #searching for feat_types of RNA
        #process the RNAs
        $parent_id = $self->_process_rna(
            notes       => $notes,
            fids        => $fids,
            types       => $types,
            count       => $count,
            out         => $out,
            f           => $f,
            name_re     => $name_re,
            parent_feat => $parent_feat,
            parent_id   => $parent_id,
            cds_exon    => $cds_exon
        );

        #get CDSs (mostly)
        my $sub_rs = $self->_feat_search(
            name_search => [ $f->names ],
            skip_ftids  => [ 1, $f->feature_type_id ],
            ds          => $ds,
            chr         => $chr,
        );

        my %tmp_types;    #only want to process one of each type.
        while ( my $f = $sub_rs->next() ) {
            if ( $fids->{ $f->feature_id } ) { next; }

            #next unless join (",", @feat_names) eq join (",", $f->names);
            next if $tmp_types{ $f->feature_type->name };
            $tmp_types{ $f->feature_type->name }++;
            my $ftn =
              $self->process_feature_type_name( $f->feature_type->name );
            $fids->{ $f->feature_id } = 1;    #feat_id has been used;
            $types->{ $f->feature_type->name }++;
	    foreach my $loc ( sort { $a->start <=> $b->start } $f->locs() ) {
                next
                  if $loc->start > $parent_feat->stop
                      || $loc->stop < $parent_feat->start
                ; #outside of parent feature boundaries;  Have to count it as something else
                push @$out,
                  {
                    f         => $f,
                    start     => $loc->start,
                    stop      => $loc->stop,
                    name_re   => $name_re,
                    id        => $$count,
                    parent_id => $parent_id,
                    type      => $f->feature_type->name
                  };
                $$count++ if $cds_exon;
                push @$out,
                  {
                    f         => $f,
                    start     => $loc->start,
                    stop      => $loc->stop,
                    name_re   => $name_re,
                    id        => $$count,
                    parent_id => $parent_id,
                    type      => "exon"
                  }
                  if $cds_exon;

                $$count++;
            }
        }
        return 1;    #return after doing this once
    }
    return 0;
}

sub _process_rna {
    my $self        = shift;
    my %opts        = @_;
    my $notes       = $opts{notes};
    my $fids        = $opts{fids};
    my $types       = $opts{types};
    my $count       = $opts{count};
    my $out         = $opts{out};
    my $f           = $opts{f};
    my $parent_feat = $opts{parent_feat};
    my $parent_id   = $opts{parent_id};
    my $name_re     = $opts{name_re};
    my $cds_exon = $opts{cds_exon}; #option so that CDSs are used for determining an exon instead of the mRNA.  This keeps UTRs from being called an exon
    my $ftn = $self->process_feature_type_name( $f->feature_type->name );
    push @{ $notes->{gene}{"encoded_feature"} }, $self->escape_gff($ftn);
    $fids->{ $f->feature_id } = 1;    #feat_id has been used;
    $types->{ $f->feature_type->name }++;
    #print STDERR "_process_rna\n";

    #have mRNA.  mRNA in CoGe translates to what most people have settled on calling exons.  the output mRNA therefore needs to be a replicate of the gene
    unless ($parent_id) {
        $parent_id = $$count;
        $parent_id--;
    }
    push @$out,
      {
        f         => $f,
        start     => $f->start,
        stop      => $f->stop,
        name_re   => $name_re,
        id        => $$count,
        parent_id => $parent_id,
        type      => $f->feature_type->name()
      };    #need to add a mRNA from its start to stop, no exons/introns
            #end creating entry to mRNA
            #begin dumping exons for mRNA
    $parent_id = $$count;
    $$count++;
    foreach my $loc ( sort { $a->start <=> $b->start } $f->locs() ) {
        next
          if $loc->start > $parent_feat->stop
              || $loc->stop < $parent_feat
              ->start;    #outside of genes boundaries;  Have to skip it
        push @$out,
          {
            f         => $f,
            start     => $loc->start,
            stop      => $loc->stop,
            name_re   => $name_re,
            id        => $$count,
            parent_id => $parent_id,
            type      => "exon"
          }
          unless $cds_exon;
        $$count++ unless $cds_exon;
    }

    #end dumping exons
    return $parent_id;
}

# mdb added 4/22/14 issue 364 - cache DB objects to improve performance
sub _annotation_type {
    my ($feat_anno, $cache) = @_;
    my $annotation_type_id = $feat_anno->annotation_type_id;
#    print STDERR "**** _annotation_type: ".$annotation_type_id."\n";
    if (not exists $cache->{$annotation_type_id}) {
        $cache->{$annotation_type_id} = $feat_anno->annotation_type;
    }
#    else {
#        print STDERR "**** using cache\n";
#    }
    return $cache->{$annotation_type_id};
}

# mdb added 4/22/14 issue 364 - cache DB objects to improve performance
sub _feature_annotations {
    my ($feature, $cache) = @_;
    my $feature_id = $feature->id;
#    print STDERR "**** _feature_annotations: ".$feature_id."\n";
    if (not exists($cache->{$feature_id})) {
        my @annotations = $feature->annotations;
        $cache->{$feature_id} = \@annotations;
    }
#    else {
#        print STDERR "**** using cache\n";
#    }
    return $cache->{$feature_id};
}

sub _format_gff_line {
    my $self  = shift;
    my %opts  = @_;
    my $out   = $opts{out};   #array of hashref of output items
    my $notes = $opts{notes}; #hashref of notes; keyed by feature type
    my $cds   = $opts{cds};   #only print CDS genes
    my $print = $opts{print}; #are lines printed here?
    my $annos = $opts{annos}; #are annotations retrieved?
    my $unique_parent_annos = $opts{unique_parent_annotations}; #parent annotations are NOT propogated to children
    my $prev_annos  = $opts{prev_annos};  #hash for storing previously seen annotations by parents and children -- used in conjuction with $unique_parent_annos flag
    my $seen        = $opts{seen};        #general var for checking if a simlar feature has been seen before (looked up by type and name string)
    my $ids2names   = $opts{ids2names};   #hash to looking up names for a particular id.  May be a number (same as the id) or a unique name;
    my $id_type     = $opts{id_type};     #type of ID (name, num):  unique number; unique name
    my $name_unique = $opts{name_unique}; #flag for making Name tag of output unique by appending type and occurrence to feature name
    my $unique_ids  = $opts{unique_ids};  #hash for making sure that each used ID happens once for each ID
    my $cache = $opts{cache};
    #print STDERR "_format_gff_line\n";

    my $output;
    foreach my $item (@$out) {
        my $f         = $item->{f};         #feature object
        my $type      = $item->{type};      #feature type.  may be retrieved from feature object, but these may differ
        my $name_re   = $item->{name_re};   #regex for searching for a specific name
        my $id        = $item->{id};        #unique id for the gff feature;
        my $parent_id = $item->{parent_id}; #unique id for the parent of the gff feature
        my $start     = $item->{start};     #start of entry.  May be the feat start, may be a loc start.  Need to declare in logic outside of this routine
        my $stop      = $item->{stop};      #stop of entry.  May be the feat stop, may be a loc stop.  Need to declare in logic outside of this routine
        my $parsed_type = $self->process_feature_type_name($type);

        #check to see if we are only printing CDS genes
        return
          if $cds
              && (   $type ne "gene"
                  && $type ne "mRNA"
                  && $type ne "CDS"
                  && $type ne "exon" );

        my @feat_names;
        if ($name_re) {
            @feat_names = grep { $_ =~ /$name_re/i } $f->names();
            next unless @feat_names;
        }
        else {
            @feat_names = $f->names();
        }
        my $strand = $f->strand == 1 ? '+' : '-';
        my ($alias) = join( ",", map { $self->escape_gff($_) } @feat_names );
        my ($name) = @feat_names;
        $name = $parsed_type unless $name;
        $seen->{$parsed_type}{$name}++;

        #create a unique name for the feature type given the name of the feature
        my $unique_name = $name;
        $unique_name .= "." . $parsed_type . $seen->{$parsed_type}{$name}
          if $unique_ids->{$unique_name};

        #store the unqiue name and associate it with the unique ID number
        if ( $ids2names->{$id} ) {
            warn "ERROR!  $id is already in use in \$ids2names lookup table: " . $ids2names->{$id} . "\n";
        }
        $ids2names->{$id} = $unique_name;

        #if unique names are requested for the Name tag, use it
        $name = $unique_name if ($name_unique);

        #for the feature and parent ids, are we using names or numbers?
        if ( $id_type eq "name" ) {
            $id        = $ids2names->{$id}        if $ids2names->{$id};
            $parent_id = $ids2names->{$parent_id} if $ids2names->{$parent_id};
        }
        warn "ERROR:  ID $id has been previously used!" if ( $unique_ids->{$id} );
        $unique_ids->{$id}++;

        my $attrs;
        $attrs .= "Parent=$parent_id;" if $parent_id;
        $attrs .= "ID=$id";
        $attrs .= ";Name=$name"        if $name;
        $attrs .= ";Alias=$alias"      if $alias;
        $attrs .= ";coge_fid=" . $f->id . "";
        foreach my $key ( keys %{ $notes->{$type} } ) {
            $attrs .= ";$key=" . join( ",", @{ $notes->{$type}{$key} } );
        }

        my $anno_stuff;
        if ($annos) {
            my %annos;
            foreach my $anno ( @{_feature_annotations($f, $cache->{feature_annotations})} ) { #$f->annotations ) {
                next unless defined $anno->annotation;
                if (   $unique_parent_annos
                    && $prev_annos->{$parent_id}{ $anno->annotation } )
                {
                    #we have used this annotation in a parent annotation
                    $prev_annos->{$id}{ $anno->annotation } = 1;
                    next;
                }
                if ($unique_parent_annos) {
                    $prev_annos->{$id}{ $anno->annotation } = 1;
                    $prev_annos->{$parent_id}{ $anno->annotation } = 1;
                }
                my $atn;      #attribute name
                my $stuff;    #annotation;
                my $anno_type = _annotation_type($anno, $cache->{annotation_type});

                #some anno_types have a group.  If there is a group, that should be the attr name, otherwise it is the anno type;
                if ( $anno_type->annotation_type_group ) {
                    $atn = $anno_type->annotation_type_group->name;
                    $stuff .= $anno_type->name . ", ";
                }
                else {
                    $atn = $anno_type->name;
                }
                $atn = $self->escape_gff($atn);
                $atn =~ s/\s+/_/g;
                $atn = "Note" unless $atn;
                $stuff .= $anno->annotation;
                $stuff = $self->escape_gff($stuff);
                my $tmp;
                #$tmp .= $atn."=".$stuff;
                $annos{$atn}{$stuff} = 1;
            }

            #$anno_stuff = join (";", keys %annos);
            foreach my $key ( keys %annos ) {
                $anno_stuff .= $key . "=" . join( ",", keys %{ $annos{$key} } ) . ";";
            }
        }

        #escape stuff
        #assemble gene info for printing
        my $str = join(
            "\t",
            (
                $f->chromosome, 'CoGe', $parsed_type, $start,
                $stop,          ".",    $strand,      ".",
                $attrs
            )
        );
        $str .= ";$anno_stuff" if $anno_stuff;
        $str =~ s/;$//g;
        my $tmp = $str . "\n";
        $output .= $tmp;
    }
    print $output if ($print and $output);
    return $output;    #, \@feat_names;
}

sub process_feature_type_name {
    my $self = shift;
    my $ftn  = shift;
    $ftn = lc($ftn);
    $ftn =~ s/\s+/_/;
    $ftn =~ s/rna/RNA/i;
    $ftn =~ s/cds/CDS/i;
    return $ftn;
}

sub escape_gff {
    my $self = shift;
    my $tmp  = shift;

    #escape for gff
    $tmp =~ s/\t/\%09/g;
    $tmp =~ s/\n/\%0A/g;
    $tmp =~ s/\r/\%0D/g;
    $tmp =~ s/;/\%3B/g;
    $tmp =~ s/=/\%3D/g;
    $tmp =~ s/\%/\%25/g;
    $tmp =~ s/&/\%26/g;
    $tmp =~ s/,/\%2C/g;
    return $tmp;
}

sub trans_type {
    my $self = shift;
    my $trans_type;
    foreach
      my $feat ( $self->features( { feature_type_id => 3 }, { rows => 10 } ) )
    {

        #	next unless $feat->type->name =~ /cds/i;
        my ( $code, $type ) = $feat->genetic_code;
        ($type) = $type =~ /transl_table=(\d+)/ if $type =~ /transl_table/;
        return $type if $type;
    }
    return 1;    #universal genetic code type;
}

sub distinct_feature_type_ids {
    my $self = shift;
    my %ids = map { $_->feature_type_id => 1 } $self->features(
        {},
        {
            columns  => ['feature_type_id'],
            distinct => 1
        }
    );
    return wantarray ? keys %ids : [ keys %ids ];
}

sub distinct_feature_type_names {
    my $self = shift;
    my %names = map { $_->feature_type->name => 1 } $self->features(
        {},
        {
            join     => 'feature_type',
            columns  => ['feature_type.name'],
            distinct => 1
        }
    );
    return wantarray ? keys %names : [ keys %names ];
}

sub translation_type {
    my $self = shift;
    foreach my $feat (
        $self->features(
            { 'annotation_type_id' => 10973 },
            { join                 => 'feature_annotations' }
        )
      )
    {
        foreach
          my $anno ( $feat->annotations( { annotation_type_id => 10973 } ) )
        {
            return $anno->annotation;
        }
    }
}

sub user_groups() {
    my $self = shift;

    my @groups = ();
    foreach ( $self->user_group_data_connectors() ) {
        push( @groups, $_->user_group() );
    }

    return @groups;
}

1;
