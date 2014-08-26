#!perl -w
use strict;
use FindBin;
use lib "$FindBin::Bin";
$|=1;
use Dumpvalue;
use Bitmap;
use HFSUtils;
use Getopt::Long;

use CatalogParser;
use ExtentParser;
use AttributeParser;

use Harddisk;

# todo: add parser for partitionmap
# todo: add option to specify offset to HFS+ disk
# todo add support for HX v5  disks
use HFSVolume;
use HFSBtree;
my $d= new Dumpvalue;

my %cnidmap = (
    3=>{ name=>'extentsFile', parser=>'ExtentParser' },
    4=>{ name=>'catalogFile', parser=>'CatalogParser' },
    8=>{ name=>'attributesFile', parser=>'AttributeParser' },
);

my $diskname= "/dev/rdisk0s2";
my $offset=0;
my $quicklist;
GetOptions(
    "q"=>\$quicklist,
    "disk=s"=>\$diskname,
    "o=s"=>sub { $offset=eval($_[1]); },
) or die usage();

my $cnid= shift;

sub usage {
    return "Usage: $0 [-disk $diskname] [-o OFFSET] <cnid> [blockids]\n";
}

if (!defined $cnid || !exists $cnidmap{$cnid}) {
    die sprintf("unknown cnid(%s): must be one of %s\n", $cnid // "undef", join(" ", map { "$_:$cnidmap{$_}{name}" } keys %cnidmap));
}
else {
    printf("dumping %s\n", $cnidmap{$cnid}{name});
}
my $parser= $cnidmap{$cnid}{parser}->new($quicklist);
# http://www.opensource.apple.com/darwinsource/10.4.9.x86/xnu-792.18.15/bsd/hfs/hfs_format.h
#
#my @nodestats;
my $hd= Harddisk->new($diskname);
my $vol= HFSVolume->new($hd, startsector=>$offset/0x200);
#print("name=$cnidmap{$cnid}{name}  $parser\n");
my $bt= HFSBtree->new($vol->{volhdr}{$cnidmap{$cnid}{name}}, $parser);

print "hfs open\n";
if (@ARGV==0) {
for (my $nodenr=0 ; $nodenr < $bt->{btree}{totalNodes} ; $nodenr++) {
    my $nodedata= $bt->readNode($nodenr);
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
}
else {
    while (@ARGV) {
        my $nodenr= eval(shift);
        my $nodedata= $bt->readNode($nodenr);
        next if ($nodedata =~ /^\x00{14}/);
        my $node= $bt->parseNode($nodedata);
        $node->{id}= $nodenr;
    #printf("---- node%08x  type=%02x prev=node%08lx next=node%08lx  height=%d nr=%d\n", $nodenr, $node->{kind}, $node->{bLink}, $node->{fLink}, $node->{height}, $node->{numRecords});

#   $nodestats[$nodenr] |= 0x40 if $node->{kind}==255;
#   $nodestats[$nodenr] |= 0x80 if $node->{kind}==0;
#   $nodestats[$nodenr] |= 0x100 if $node->{kind}==1;
#   $nodestats[$nodenr] |= 0x200 if $node->{kind}==2;

        $bt->dumpNode($node);
    }
}
print "hfs done\n";

if (!$quicklist) {
    print $parser->dumpStats();
}

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
