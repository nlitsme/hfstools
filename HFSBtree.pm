package HFSBtree;
use strict;
use warnings;
use Carp;
use Fcntl qw(:seek);

sub new {
    my $class=shift;
    my $file=shift;
    my $parser=shift;
    my $self= bless {
        file=>$file,
        parser=>$parser,
    }, $class;
    my $hdrdata= $self->readBtreeHeader();
    $self->{btree} = parseBTHeaderRec($hdrdata),
    return $self;
}
sub nodeTypeName {
    if ($_[0]==255) { return "leaf"; }
    elsif ($_[0]==0) { return "index"; }
    elsif ($_[0]==1) { return "header"; }
    elsif ($_[0]==2) { return "map"; }
    else { return sprintf("UNKNOWNTYPE_%02x", $_[0]); }
}
sub readBtreeHeader {
    my $self=shift;
    $self->{file}->seek(0xe, SEEK_SET) or croak "ERROR seeking to btreeheader:$!\n";
    my $data;
    $self->{file}->read($data, 0x78-0xe) or croak "ERROR reading btreeheader:$!\n";
    return $data;
}
sub readNode {
    my ($self, $nodenr)= @_;

    #printf("readNode(%x)\n", $nodenr);
    $self->{file}->seek($nodenr*$self->{btree}{nodeSize}, 0) or croak "ERROR seek-node($nodenr): $!\n";
    my $data;
    $self->{file}->read($data, $self->{btree}{nodeSize}) or croak "ERROR read-node($nodenr): $!\n";
    #printf("readnode -> %d bytes  ns=%d \n", length($data), $self->{btree}{nodeSize});
    return $data;
}


sub parseBTNodeDescriptor {
    my %hdr;
    (
        $hdr{fLink},
        $hdr{bLink},
        $hdr{kind},
        $hdr{height},
        $hdr{numRecords},
        $hdr{reserved},  
    )= unpack("NNCCnn", $_[0]);
    $hdr{kindname}=nodeTypeName($hdr{kind});
#   $nodestats[$hdr{fLink}] |= 1 if $hdr{fLink};
#   $nodestats[$hdr{bLink}] |= 2 if $hdr{bLink};
    return \%hdr;
}
sub parseBTHeaderRec{
    my %hdr;
    (
        $hdr{treeDepth},              # maximum height (usually leaf nodes) */
        $hdr{rootNode},               # node number of root node */
        $hdr{leafRecords},            # number of leaf records in all leaf nodes */
        $hdr{firstLeafNode},          # node number of first leaf node */
        $hdr{lastLeafNode},           # node number of last leaf node */
        $hdr{nodeSize},               # size of a node, in bytes */
        $hdr{maxKeyLength},           # reserved */
        $hdr{totalNodes},             # total number of nodes in tree */
        $hdr{freeNodes},              # number of unused (free) nodes in tree */
        $hdr{reserved1},              # unused */
        $hdr{clumpSize},              # reserved */
        $hdr{btreeType},              # reserved */
        $hdr{keyCompareType},         # Key string Comparison Type */
        $hdr{attributes},             # persistent attributes about the tree */
        $hdr{reserved3},              # reserved */
    )= unpack("nNNNNnnNNnNCCNa64", $_[0]);

    #printf("bt-hdrl=%d  ns=%d : %s\n", length($_[0]), $hdr{nodeSize}, unpack("H*", $_[0]));

#   $nodestats[$hdr{rootNode}] |= 4 if $hdr{rootNode};
#   $nodestats[$hdr{firstLeafNode}] |= 8 if $hdr{firstLeafNode};
#   $nodestats[$hdr{lastLeafNode}] |= 0x10 if $hdr{lastLeafNode};

    return \%hdr;
}
sub parseKeyRecord {
    my $self=shift;
    if (length($_[0])<2) {
        printf("WARN: short key record\n");
    }
    my $bigkey= ($self->{btree}{attributes}&2);
    my $varkey= ($self->{btree}{attributes}&4);
    my $keylen= $varkey ? unpack($bigkey?"n":"C", $_[0]) : $self->{btree}{maxKeyLength};
    my $keydata= substr($_[0], $bigkey?2:1, $keylen);
    my $keysize= length($keydata)+($bigkey?2:1);
    my $data= substr($_[0], $keysize+($keysize&1));

    return [$keydata, $data];
}
sub parseMapData {
    my $bm= Bitmap->new($_[0]);
#   for (my $bit=0 ; $bit<$bm->size() ; $bit++) {
#       if ($bm->test($bit)) {
#           $nodestats[$bit] |= 0x400;
#       }
#   }
    return $bm;
}
sub parseNode {
    my $self=shift;
    my $hdr= parseBTNodeDescriptor($_[0]);
    my @recofs= reverse unpack("n*", substr($_[0], -2*$hdr->{numRecords}-2));
    $hdr->{recofs}= \@recofs;
    if (@recofs==1) {
        return $hdr;
    }
    my @recdata= map { substr($_[0], $recofs[$_-1], $recofs[$_]-$recofs[$_-1]) } (1..$#recofs);
    $hdr->{freespace}= substr($_[0], $recofs[-1], length($_[0])-($recofs[-1]+2*$hdr->{numRecords}+2));
    #printf("recofs: %s\n", join(",", map { sprintf("%d:%d", $_, $recofs[$_]-$recofs[$_-1]) } 1..$#recofs));
    if ($hdr->{kind}==255) {    # leaf node
        $hdr->{recs}= [ map { $self->parseKeyRecord($_) } @recdata ];
    }
    elsif ($hdr->{kind}==0) {   # index node
        $hdr->{recs}= [ map { $self->parseKeyRecord($_) } @recdata ];

        for (@{$hdr->{recs}}) {
            if (length($_->[1])!=4) {
                printf("WARN: index record datalen=%d ( != 4 )\n", length($_->[1]));
            }
            my $pointer= unpack("N", $_->[1]);
            if ($pointer) {
#               $nodestats[$pointer] |= 0x20;
            }
            else {
                printf("WARN: NULL pointer\n");
            }
        }
    }
    elsif ($hdr->{kind}==1) {
        push @{$hdr->{recs}}, parseBTHeaderRec($recdata[0]);
        push @{$hdr->{recs}}, $recdata[1]; # user data
        push @{$hdr->{recs}}, $recdata[2]; # map data
        parseMapData($recdata[2]);
    }
    elsif ($hdr->{kind}==2) {
        $hdr->{recs}= \@recdata;     # map data
    }
    else {
        warn "unknown node kind $hdr->{kind}\n";
    }

    return $hdr;
}
sub dumpNode {
    my $self=shift;
    my $node=shift;
    if ($node->{kind}==0) { # index
        for my $r (0 .. $#{$node->{recs}}) {
            my $pointer= unpack("N", $node->{recs}[$r][1]);
            if ($pointer >= $self->{btree}{totalNodes}) {
                printf("WARN: node%08lx: rec %02x : pointer=node%08lx: ge totalnodes\n", $node->{id}, $r, $pointer);
            }
            # todo: do something with index keys too.
            my $kv= $self->{parser}->parse($node->{recs}[$r][0]);
            #printf("node%08lx:%02x  %-40s  ---> node%08lx\n", $node->{id}, $r, $self->{parser}->dump($kv), $pointer);
        }
    }
    elsif ($node->{kind}==255) { # leaf
        for my $r (0 .. $#{$node->{recs}}) {
            my $kv= $self->{parser}->parse($node->{recs}[$r][0], $node->{recs}[$r][1]);
            #printf("node%08lx:%02x %s\n", $node->{id}, $r, $self->{parser}->dump($kv));
        }
    }
    elsif ($node->{kind}==1) {
        #$d->dumpValue($node);
        printf("TODO: dump kind 1\n");
    }
    elsif ($node->{kind}==2) {
        #$d->dumpValue($node);
        printf("TODO: dump kind 2\n");
    }
}
sub leafDump {
    my $self=shift;
    my $node=shift;
    if ($node->{kind}==255) { # leaf
        for my $r (0 .. $#{$node->{recs}}) {
            printf("%s %s\n", unpack("H*", $node->{recs}[$r][0]), unpack("H*", $node->{recs}[$r][1]));
        }
    }
}
1;
