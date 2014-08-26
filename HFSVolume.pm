package HFSVolume;
use strict;
use warnings;
use HFSForkData;
use HFSUtils;
use Bitmap;

use constant {
    kHFSVolumeHardwareLockBit       => 1<< 7,
    kHFSVolumeUnmountedBit          => 1<< 8,
    kHFSVolumeSparedBlocksBit       => 1<< 9,
    kHFSVolumeNoCacheRequiredBit    => 1<<10,
    kHFSBootVolumeInconsistentBit   => 1<<11,
    kHFSCatalogNodeIDsReusedBit     => 1<<12,
    kHFSVolumeJournaledBit          => 1<<13,
    kHFSVolumeSoftwareLockBit       => 1<<15,
};
# see http://developer.apple.com/technotes/tn/tn1150.html
# or http://fxr.watson.org/fxr/source/bsd/hfs/hfs_format.h?v=xnu-792
sub new {
    my ($class, $disk, %params)=@_;
    
    my $self= bless {
        disk=>$disk,
        %params,
    }, $class;
    # volume header is fixed at sector 2 ( offset 0x400 )
    my $volhdrdata= $params{volhdr} || $disk->readsector($self->{startsector}+2);
    $self->{volhdr}=$self->parseVolumeHeader($volhdrdata),
    return $self;
}
sub blocksize { $_[0]{volhdr}{blockSize} }
sub readblock {
    my ($self, $blocknr, $count)= @_;
    $count=1 unless defined $count;
    #printf("vol-read(%x, %x)\n", $blocknr, $count);
    return "" if $count==0;
    return $self->{disk}->readsector($self->{startsector}+$blocknr*$self->{volhdr}{blockSize}/0x200, $count*$self->{volhdr}{blockSize}/0x200);
}

sub parseVolumeHeader {
    my $self=shift;
    my %hdr;
    my @forks;
    (
        $hdr{signature},               # == kHFSPlusSigWord
        $hdr{version},                 # == kHFSPlusVersion
        $hdr{attributes},              # volume attributes
        $hdr{lastMountedVersion},      # implementation version which last mounted volume
        $hdr{journalInfoBlock},        # block addr of journal info (if volume is journaled, zero otherwise)
        $hdr{createDate},              # date and time of volume creation
        $hdr{modifyDate},              # date and time of last modification
        $hdr{backupDate},              # date and time of last backup
        $hdr{checkedDate},             # date and time of last disk check
        $hdr{fileCount},               # number of files in volume
        $hdr{folderCount},             # number of directories in volume
        $hdr{blockSize},               # size (in bytes) of allocation blocks
        $hdr{totalBlocks},             # number of allocation blocks in volume (includes this header and VBM )
        $hdr{freeBlocks},              # number of unused allocation blocks
        $hdr{nextAllocation},          # start of next allocation search
        $hdr{rsrcClumpSize},           # default resource fork clump size
        $hdr{dataClumpSize},           # default data fork clump size
        $hdr{nextCatalogID},           # next unused catalog node ID
        $hdr{writeCount},              # volume write count
        $hdr{encodingsBitmap},         # which encodings have been use  on this volume
        $hdr{finderInfo},              # information used by the Finder
        @forks[0..4]
    )= unpack("n2N17a8a32a80a80a80a80a80", $_[0]);
    $hdr{allocationFile} = HFSForkData->new($self, 6, $forks[0]);
    $hdr{extentsFile} = HFSForkData->new($self, 3, $forks[1]);
    $hdr{catalogFile} = HFSForkData->new($self, 4, $forks[2]);
    $hdr{attributesFile} = HFSForkData->new($self, 8, $forks[3]);
    $hdr{startupFile} = HFSForkData->new($self, 7, $forks[4]);
    $hdr{finderInfo}= [unpack("N*", $hdr{finderInfo})];
    return \%hdr;
}
sub calc_alloc_bitmap {
    my $self= shift;
    my $bitmap= Bitmap->new();
    $bitmap->set(0);   # mark volume header block
    $bitmap->add($self->{volhdr}{allocationFile}->calc_alloc_bitmap());
    $bitmap->add($self->{volhdr}{extentsFile}->calc_alloc_bitmap());
    $bitmap->add($self->{volhdr}{catalogFile}->calc_alloc_bitmap());
    $bitmap->add($self->{volhdr}{attributesFile}->calc_alloc_bitmap());
    $bitmap->add($self->{volhdr}{startupFile}->calc_alloc_bitmap());

    return $bitmap;
}
sub attribute_string {
    my $attr=shift;
    my @attrs;

    push @attrs, "VolumeHardwareLock"       if $attr & kHFSVolumeHardwareLockBit    ;
    push @attrs, "VolumeUnmounted"          if $attr & kHFSVolumeUnmountedBit       ;
    push @attrs, "VolumeSparedBlocks"       if $attr & kHFSVolumeSparedBlocksBit    ;
    push @attrs, "VolumeNoCacheRequired"    if $attr & kHFSVolumeNoCacheRequiredBit ;
    push @attrs, "BootVolumeInconsistent"   if $attr & kHFSBootVolumeInconsistentBit;
    push @attrs, "CatalogNodeIDsReused"     if $attr & kHFSCatalogNodeIDsReusedBit  ;
    push @attrs, "VolumeJournaled"          if $attr & kHFSVolumeJournaledBit       ;
    push @attrs, "VolumeSoftwareLock"       if $attr & kHFSVolumeSoftwareLockBit    ;

    return join(",", @attrs);
}
sub encodings_string {
    return unpack("H*", shift);
}
sub dump {
    my $self=shift;

    printf("signature           %04x       \n",$self->{volhdr}{signature});               # == kHFSPlusSigWord
    printf("version             %04x       \n",$self->{volhdr}{version});                 # == kHFSPlusVersion
    printf("attributes          %s         \n",attribute_string($self->{volhdr}{attributes}));              # volume attributes
    printf("lastMountedVersion  %08lx      \n",$self->{volhdr}{lastMountedVersion});      # implementation version which last mounted volume
    printf("journalInfoBlock    %08lx      \n",$self->{volhdr}{journalInfoBlock});        # block addr of journal info (if volume is journaled, zero otherwise)
    printf("createDate          %s         \n",HFSUtils::datestring($self->{volhdr}{createDate}));              # date and time of volume creation
    printf("modifyDate          %s         \n",HFSUtils::datestring($self->{volhdr}{modifyDate}));              # date and time of last modification
    printf("backupDate          %s         \n",HFSUtils::datestring($self->{volhdr}{backupDate}));              # date and time of last backup
    printf("checkedDate         %s         \n",HFSUtils::datestring($self->{volhdr}{checkedDate}));             # date and time of last disk check
    printf("fileCount           %08lx      \n",$self->{volhdr}{fileCount});               # number of files in volume
    printf("folderCount         %08lx      \n",$self->{volhdr}{folderCount});             # number of directories in volume
    printf("blockSize           %08lx      \n",$self->{volhdr}{blockSize});               # size (in bytes) of allocation blocks
    printf("totalBlocks         %08lx      \n",$self->{volhdr}{totalBlocks});             # number of allocation blocks in volume (includes this header and VBM )
    printf("freeBlocks          %08lx      \n",$self->{volhdr}{freeBlocks});              # number of unused allocation blocks
    printf("nextAllocation      %08lx      \n",$self->{volhdr}{nextAllocation});          # start of next allocation search
    printf("rsrcClumpSize       %08lx      \n",$self->{volhdr}{rsrcClumpSize});           # default resource fork clump size
    printf("dataClumpSize       %08lx      \n",$self->{volhdr}{dataClumpSize});           # default data fork clump size
    printf("nextCatalogID       %08lx      \n",$self->{volhdr}{nextCatalogID});           # next unused catalog node ID
    printf("writeCount          %08lx      \n",$self->{volhdr}{writeCount});              # volume write count
    printf("encodingsBitmap     %s         \n",encodings_string($self->{volhdr}{encodingsBitmap}));         # which encodings have been use  on this volume
    printf("finderInfo:\n");              # information used by the Finder
    printf("  boot directory    %08lx      \n",$self->{volhdr}{finderInfo}[0]);
    printf("  startup app       %08lx      \n",$self->{volhdr}{finderInfo}[1]);
    printf("  finder start dir  %08lx      \n",$self->{volhdr}{finderInfo}[2]);
    printf("  os9 sytem         %08lx      \n",$self->{volhdr}{finderInfo}[3]);
    printf("  reserved          %08lx      \n",$self->{volhdr}{finderInfo}[4]);
    printf("  osx system        %08lx      \n",$self->{volhdr}{finderInfo}[5]);
    printf("  volume id         %08lx%08lx      \n",$self->{volhdr}{finderInfo}[6], $self->{volhdr}{finderInfo}[7]);
}
1;
