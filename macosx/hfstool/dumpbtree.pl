#!perl -w
use strict;
$|=1;
use Dumpvalue;
use Bitmap;
use HFSUtils;
use GetOpt::Long;

use CatalogParser;
use ExtentParser;
use AttributeParser;

use IO::File;
use HFSBtree;
my $d= new Dumpvalue;

sub usage {
    return "Usage: dumpbtree  file.btree [block.bitmap [node.bitmap]]\n";
}
my $filename= shift || die usage();
my $parser= ($filename =~ /cat/i)?CatalogParser->new():
            ($filename =~ /attr/i)?AttributeParser->new():
            ($filename =~ /ext/i)?ExtentParser->new():die "unknown type\n";
# http://www.opensource.apple.com/darwinsource/10.4.9.x86/xnu-792.18.15/bsd/hfs/hfs_format.h
#
#my @nodestats;

my $fh= IO::File->new($filename, "r") or die "$filename: $!\n";
binmode $fh;
my $bt= HFSBtree->new($fh, $parser);


if (-s $filename != $bt->{btree}{totalNodes} * $bt->{btree}{nodeSize}) {
    printf("WARN: filesize: %08lx,  hdr: %08lx\n", -s $filename, $bt->{btree}{totalNodes} * $bt->{btree}{nodeSize});
}

for (my $nodenr=0 ; $nodenr < $bt->{btree}{totalNodes} ; $nodenr++) {
    my $nodedata= eval { $bt->readNode($nodenr) }; last if $@;
    next if ($nodedata =~ /^\x00{14}/);
    my $node= $bt->parseNode($nodedata);
    $node->{id}= $nodenr;
    #printf("---- node%08x  type=%02x prev=node%08lx next=node%08lx  height=%d nr=%d\n", $nodenr, $node->{kind}, $node->{bLink}, $node->{fLink}, $node->{height}, $node->{numRecords});

#   $nodestats[$nodenr] |= 0x40 if $node->{kind}==255;
#   $nodestats[$nodenr] |= 0x80 if $node->{kind}==0;
#   $nodestats[$nodenr] |= 0x100 if $node->{kind}==1;
#   $nodestats[$nodenr] |= 0x200 if $node->{kind}==2;

    $bt->dumpNode($node);
    #$bt->leafDump($node);
}

print $parser->dumpStats();

if (@ARGV) {
    $parser->getBlockBitmap()->save(shift);
}

    #  1: flink
    #  2: blink
    #  4: isroot
    #  8: firstleaf
    # 10: lastleaf
    # 20: pointer
    # 40: leaf
    # 80: index
    #100: header
    #200: mapnode
    #400: in_map
# printf("node usage\n");
# for (my $nr=0 ; $nr<@nodestats ; $nr++) {
#     if (defined $nodestats[$nr]) {
#         printf("node%08lx: usage: %012b\n", $nr, $nodestats[$nr]);
#     }
# }
